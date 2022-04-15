# frozen_string_literal: true

require 'spec_helper'

module TestImplementsReference
  module Middleware
    module Migration
      module Column
        SPY = []

        include Enableable

        def before(env)
          return unless middleware = enabled_middleware(TestImplementsReference, env)
          SPY << env.to_hash.slice(:column_name, :type, :implements_reference)
        end
      end
    end
  end
end

SchemaMonkey.register TestImplementsReference

describe SchemaMonkey::Middleware::Migration::Column do

  let(:migration) { ::ActiveRecord::Migration }

  context TestImplementsReference::Middleware::Migration::Column do
    let (:spy) { described_class.const_get(:SPY) }

    let (:pk_type) do
      if ActiveRecord.version >= Gem::Version.new('5.1') &&
         ActiveRecord::Base.connection.adapter_name =~ /mysql|postgresql/i
        :bigint
      else
        :integer
      end
    end

    around(:each) do |example|
      middleware = described_class
      begin
        spy.clear
        middleware.enable once: false
        example.run
      ensure
        middleware.disable
      end
    end

    context "when add ordinary column" do
      When { migration.create_table("things") { |t| t.integer "test_column" } }
      Then { expect(spy).to match_array [
        { column_name: "id", type: :primary_key, implements_reference: nil },
        { column_name: "test_column", type: :integer, implements_reference: nil }
      ] }
    end

    [:references, :belongs_to].each do |method|

      context "when add reference using t.#{method}" do
        When { migration.create_table("things") { |t| t.send method, "test_reference" } }
        Then { expect(spy).to match_array [
          { column_name: "id", type: :primary_key, implements_reference: nil },
          { column_name: "test_reference_id", type: :reference, implements_reference: nil },
          { column_name: "test_reference_id", type: pk_type, implements_reference: true }
        ] }
      end

      context "when add polymorphic reference using t.#{method}" do
        When { migration.create_table("things") { |t| t.send method, "test_reference", polymorphic: true, index: true } }
        Then { expect(spy).to match_array [
          { column_name: "id", type: :primary_key, implements_reference: nil },
          { column_name: "test_reference_id", type: :reference, implements_reference: nil },
          { column_name: "test_reference_id", type: pk_type, implements_reference: true },
          { column_name: "test_reference_type", type: :string, implements_reference: nil }
        ] }
      end
    end

    context "with an existing table" do
      Given {
        migration.create_table("things") { |t| }
        spy.clear
      }

      context "when add reference using migration.add_reference" do

        When { migration.add_reference("things", "test_reference") }
        Then { expect(spy).to match_array [
          { column_name: "test_reference_id", type: :reference, implements_reference: nil },
          { column_name: "test_reference_id", type: pk_type, implements_reference: true }
        ] }
      end

      context "when add polymorphic reference using migration.add_reference" do

        When {
          migration.add_reference("things", "test_reference", polymorphic: true)
        }
        Then { expect(spy).to match_array [
          { column_name: "test_reference_id", type: :reference, implements_reference: nil },
          { column_name: "test_reference_id", type: pk_type, implements_reference: true },
          { column_name: "test_reference_type", type: :string, implements_reference: nil }
        ] }
      end

    end

  end
end
