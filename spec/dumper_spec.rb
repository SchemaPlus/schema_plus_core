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
            column.add_option "option: #{middleware}"
            column.add_comment "comment: #{middleware}"
          end
          env.table.statements << "statement: #{middleware}"
          env.table.trailer << "trailer: #{middleware}"
        end
      end
      module Indexes
        include Enableable
        def after(env)
          return unless env.table.indexes.any?
          return unless middleware = enabled_middleware(TestDumper, env)
          env.table.indexes.first.add_option middleware.to_s
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

  context TestDumper::Middleware::Dumper::Initial do
    Then { expect(dump).to match(/Schema[.]define.*do\s+#{middleware}/) }
  end

  context TestDumper::Middleware::Dumper::Tables do
    Then { expect(dump).to match(/create_table "other".*create_table "#{middleware}".*create_table "things"/m) }
  end

  context TestDumper::Middleware::Dumper::Table do
    Then { expect(dump).to match(/t[.]integer.*option: #{middleware} \# comment: #{middleware}/) }
    Then { expect(dump).to match(/statement: #{middleware}\s+end\s+(add_index.*)?\s+trailer: #{middleware}/) }
    Then { expect(dump).to match(/could not dump table.*custom_table.*unknown type.*custom_type/mi) } if TestCustomType
  end

  context TestDumper::Middleware::Dumper::Indexes do
    Then { expect(dump).to match(/add_index.*#{middleware}/) }
  end


  private

  def middleware
    described_class
  end

  def dump
    begin
      middleware.enable once:false
      stream = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      return stream.string
    ensure
      middleware.disable
    end
  end

end
