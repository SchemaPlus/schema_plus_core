# frozen_string_literal: true

require 'spec_helper'

describe SchemaMonkey::Middleware::Migration::Index do

  let(:migration) {::ActiveRecord::Migration}
  let(:connection) {::ActiveRecord::Base.connection}

  describe '#add_index' do
    before(:each) do
      migration.create_table :things, :force => true do |t|
        t.string :test_column
      end
    end

    context "when add an index with an expression", postgresql: :only do
      it 'should create the index successfully' do
        migration.add_index 'things', 'lower(test_column)'
        expect(connection.indexes(:things).first.columns).to eq('lower((test_column)::text)')
      end
    end
  end
end
