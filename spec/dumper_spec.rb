require 'spec_helper'

module TestDumper
  module Middleware
    module Dumper
      module Initial
        include Enableable
        def after(env)
          return unless middleware = enabled_middleware(TestDumper, env)
          env.initial.unshift middleware.to_s
        end
      end
      module Tables
        include Enableable
        def after(env)
          return unless middleware = enabled_middleware(TestDumper, env)
          env.dump.tables[middleware.to_s] = env.dump.tables.values.first.dup.tap {|t| t.pname = middleware.to_s }
          env.dump.depends("things", middleware.to_s)
          env.dump.depends(middleware.to_s, "other")
        end
      end
      module Table
        include Enableable
        def after(env)
          return unless middleware = enabled_middleware(TestDumper, env)
          if column = env.table.columns.first
            column.options[:option] = middleware.to_s
            column.comments << "comment: #{middleware}"
          end
          if index = env.table.indexes.first
            index.options[:option] = middleware.to_s
          end
          env.table.statements << "statement: #{middleware}"
          env.table.trailer << "trailer: #{middleware}"
        end
      end
    end
  end
end

SchemaMonkey.register(TestDumper)

describe SchemaMonkey::Middleware::Dumper do

  let(:migration) { ::ActiveRecord::Migration }

  TestCustomType = SchemaDev::Rspec::Helpers.postgresql?

  around(:each) do |example|
    begin
      migration.execute "CREATE TYPE custom_type AS ENUM ('a', 'b')";
      example.run
    ensure
      migration.execute "DROP TYPE IF EXISTS custom_type CASCADE";
    end
  end if TestCustomType

  before(:each) do
    migration.create_table "things" do |t|
      t.integer :column
      t.index :column
    end
    migration.create_table "other" do |t|
      t.references :thing
    end
    migration.add_foreign_key("other", "things")
    migration.execute "CREATE TABLE custom_table ( my_column custom_type DEFAULT 'a'::custom_type NOT NULL)" if TestCustomType
  end

  context "column default expressions", postgresql: :only do

    before(:each) do
      migration.execute %Q{ALTER TABLE "things" ADD "defexpr" character varying DEFAULT substring((random())::text, 3, 6)}
    end

    Then { expect(dump use_middleware: false).to match(/\\"substring\\"\(\(random/) }
  end

  context TestDumper::Middleware::Dumper::Initial do
    Then { expect(dump).to match(/Schema[.]define.*do\s+#{middleware}/) }
  end

  context TestDumper::Middleware::Dumper::Tables do
    Then { expect(dump).to match(/create_table "other".*create_table "#{middleware}".*create_table "things"/m) }

    context 'int PK handling in rails 5.2+', postgresql: :only, rails: ['>= 5.2.0'] do
      before(:each) do
        migration.create_table "inttable", id: :serial do |t|
        end
      end

      Then { expect(dump).to_not match(/create_table "inttable", id: :serial.*default:/m) }
    end
  end

  context TestDumper::Middleware::Dumper::Table do
    Then { expect(dump).to match(/t[.]integer.*:option=>"#{middleware}" \# comment: #{middleware}/) }
    Then { expect(dump).to match(/statement: #{middleware}\s+end\s+(add_index.*)?\s+trailer: #{middleware}/) }
    Then { expect(dump).to match(/could not dump table.*custom_table.*unknown type.*custom_type/mi) } if TestCustomType
    Then { expect(dump).to match(/t[.]index.*:option=>"#{middleware}"/) }
  end

  private

  def middleware
    described_class
  end

  def dump(use_middleware: true)
    begin
      middleware.enable once:false if use_middleware
      stream = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      return stream.string
    ensure
      middleware.disable if use_middleware
    end
  end

end
