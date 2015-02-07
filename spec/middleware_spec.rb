require 'spec_helper'

describe SchemaMonkey::Middleware do

  let(:migration) { ::ActiveRecord::Migration }
  let(:connection) { ::ActiveRecord::Base.connection }

  around(:each) do |example|
    class Thing < ActiveRecord::Base
    end
    migration.suppress_messages do
      migration.create_table("things", force: :cascade)
      example.run
    end
  end

  context SchemaMonkey::Middleware::Query do

    context Reporter::Middleware::Query::ExecCache do
      Given { migration.add_column("things", "column", "integer") }
      Given(:thing) { Thing.create!  }
      Then { expect_middleware { thing.update_attributes!(column: 3) } }
    end

    context Reporter::Middleware::Query::Tables do
      Then { expect_middleware { connection.tables() } }
    end

    context Reporter::Middleware::Query::Indexes do
      Then { expect_middleware { connection.indexes("table") } }
    end

  end

  context SchemaMonkey::Middleware::Migration do

    context Reporter::Middleware::Migration::Column do
      Given { migration.add_column("things", "column1", "integer") }
      Then { expect_middleware(env: {operation: :add})  { migration.add_column("things", "column2", "integer") } }
      Then { expect_middleware(env: {operation: :change}) { migration.change_column("things", "column1", "integer") } }
      Then { expect_middleware(enable: {type: :reference}, env: {column_name: "ref_id"}) { migration.add_reference("things", "ref") } }

      Given(:change) {
        Class.new ::ActiveRecord::Migration do
          def change
            change_table("things") do |t|
              t.integer "column2"
            end
          end
        end
      }
      Then { expect_middleware(env: {operation: :record}) { change.migrate(:down) } }
      Then { expect_middleware(env: {operation: :define, type: :primary_key}) { migration.create_table("things", force: :cascade) } }
      Then { expect_middleware(env: {operation: :define}) { table_statement(:integer, "column") } }
      Then { expect_middleware(enable: {type: :reference}, env: {operation: :define, column_name: "ref_id"}) { table_statement(:references, "ref") } }
      Then { expect_middleware(enable: {type: :reference}, env: {operation: :define, column_name: "ref_id"}) { table_statement(:belongs_to, "ref") } }
    end

    context Reporter::Middleware::Migration::ColumnOptionsSql do
      Then { expect_middleware { migration.add_column("things", "column", "integer") } }
    end

    context Reporter::Middleware::Migration::Index do
      Then { expect_middleware { table_statement(:index, "id") } }
    end

    context Reporter::Middleware::Migration::IndexComponentsSql do
      Given { migration.add_column("things", "column", "integer") }
      Then { expect_middleware { migration.add_index("things", "column") } }
    end

  end

  context SchemaMonkey::Middleware::Model do

    context Reporter::Middleware::Model::Columns do
      Then { expect_middleware { Thing.columns } }
    end

    context Reporter::Middleware::Model::ResetColumnInformation do
      Then { expect_middleware { Thing.reset_column_information } }
    end

  end

  context SchemaMonkey::Middleware::Dumper do

    let(:dumper) { ::ActiveRecord::SchemaDumper }

    context Reporter::Middleware::Dumper::Extensions do
      Then { expect_middleware(env: {extensions: []}) { dump }  }
    end

    context Reporter::Middleware::Dumper::Tables do
      Then { expect_middleware { dump }  }
    end

    context Reporter::Middleware::Dumper::Table do
      Then { expect_middleware(env: {table: { name: "things"} }) { dump }  }
    end

    context Reporter::Middleware::Dumper::Indexes do
      Then { expect_middleware(env: {table: { name: "things"} }) { dump }  }
    end

    private

    def dump
      ::ActiveRecord::SchemaDumper.dump(connection, StringIO.new)
    end

  end

  def table_statement(method, *args)
    migration.create_table("things", force: :cascade) do |t|
      t.send method, *args
    end
  end

  def expect_middleware(env: {}, enable: {})
    middleware = described_class
    begin
      _enable = enable
      middleware.enable(-> (env) {
        _enable.all?{ |key, val|
          env.send(key) == val
        }
      })
      expect { yield }.to raise_error { |error|
        expect(error).to be_a Reporter::Called
        expect(error.middleware).to eq middleware
        env.each do |key, val|
          actual = error.env.send key

          if val.is_a? Hash and not actual.is_a? Hash
            val.each do |subkey, subval|
              expect(actual.send subkey).to eq subval
            end
          else
            expect(actual).to eq val
          end
        end
      }
    ensure
      middleware.disable
    end
  end

end
