require 'spec_helper'

describe SchemaMonkey::Middleware do

  let(:migration) { ::ActiveRecord::Migration }
  let(:connection) { ::ActiveRecord::Base.connection }

  Given {
    migration.create_table "things"
    class Thing < ActiveRecord::Base ; end
  }

  context SchemaMonkey::Middleware::Query do

    Given { migration.add_column("things", "column1", "integer") }
    Given(:thing) { Thing.create!  }

    context TestReporter::Middleware::Query::Exec do
      Then { expect_middleware(enable: {sql: /SELECT column1/}) { connection.select_values("SELECT column1 FROM things") } }
      Then { expect_middleware(enable: {sql: /^UPDATE/}) { thing.update_attributes!(column1: 3) } }
      Then { expect_middleware(enable: {sql: /^DELETE/}) { thing.delete } }
    end
  end

  context SchemaMonkey::Middleware::Schema do

    context TestReporter::Middleware::Schema::Define do
      Then { expect_middleware { ActiveRecord::Schema.define { } } }
    end

    context TestReporter::Middleware::Schema::Tables do
      Then { expect_middleware { connection.tables() } }
    end

    context TestReporter::Middleware::Schema::Indexes do
      Then { expect_middleware { connection.indexes("things") } }
    end

  end

  context SchemaMonkey::Middleware::Migration do

    context TestReporter::Middleware::Migration::Column do
      Given { migration.add_column("things", "column1", "integer") }
      Then { expect_middleware(env: {operation: :add})  { migration.add_column("things", "column2", "integer") } }
      # Note, sqlite3 emits both a :change and a :define
      Then { expect_middleware(enable: {operation: :change}) { migration.change_column("things", "column1", "integer") } }
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
      Then { expect_middleware(env: {operation: :define, type: :primary_key}) { migration.create_table "other" } }
      Then { expect_middleware(env: {operation: :define}) { table_statement(:integer, "column1") } }
      Then { expect_middleware(enable: {type: :reference}, env: {operation: :define, column_name: "ref_id"}) { table_statement(:references, "ref") } }
      Then { expect_middleware(enable: {type: :reference}, env: {operation: :define, column_name: "ref_id"}) { table_statement(:belongs_to, "ref") } }
    end

    context TestReporter::Middleware::Migration::CreateTable do
      Then { expect_middleware { connection.create_table "other" } }
    end

    context TestReporter::Middleware::Migration::DropTable do
      Then { expect_middleware { connection.drop_table "things" } }
    end

    context TestReporter::Middleware::Migration::RenameTable do
      Then { expect_middleware { connection.rename_table "things", "newthings" } }
    end

    context TestReporter::Middleware::Migration::Index do
      Given { migration.add_column("things", "column1", "integer") }
      Then { expect_middleware { table_statement(:index, "id") } }
      Then { expect_middleware { migration.add_index("things", "column1") } }
    end

  end

  context SchemaMonkey::Middleware::Sql do
    context TestReporter::Middleware::Sql::ColumnOptions do
      Then { expect_middleware { migration.add_column("things", "column1", "integer") } }
    end

    context TestReporter::Middleware::Sql::IndexComponents do
      Given { migration.add_column("things", "column1", "integer") }
      Then { expect_middleware { migration.add_index("things", "column1") } }
    end

    context TestReporter::Middleware::Sql::Table do
      Then { expect_middleware { migration.create_table "other" } }
    end
  end

  context SchemaMonkey::Middleware::Model do

    context TestReporter::Middleware::Model::Columns do
      Then { expect_middleware { Thing.columns } }
    end

    context TestReporter::Middleware::Model::ResetColumnInformation do
      Then { expect_middleware { Thing.reset_column_information } }
    end

    context TestReporter::Middleware::Model::Association::Declaration do
      Then do
        class Thingamajig < ActiveRecord::Base; end
        expect_middleware { Thingamajig.has_many :things, class_name: Thing.name }
        expect_middleware { Thingamajig.has_one :thing, class_name: Thing.name }
        expect_middleware { Thingamajig.belongs_to :another_thing, class_name: Thing.name }
        expect_middleware { Thingamajig.has_and_belongs_to_many :other_things, class_name: Thing.name }
      end
    end

  end

  context SchemaMonkey::Middleware::Dumper do

    let(:dumper) { ::ActiveRecord::SchemaDumper }

    context TestReporter::Middleware::Dumper::Initial do
      Then { expect_middleware { dump }  }
    end

    context TestReporter::Middleware::Dumper::Tables do
      Then { expect_middleware { dump }  }
    end

    context TestReporter::Middleware::Dumper::Table do
      Then { expect_middleware(env: {table: { name: "things"} }) { dump }  }
    end

    context TestReporter::Middleware::Dumper::Indexes do
      Then { expect_middleware(env: {table: { name: "things"} }) { dump }  }
    end

    private

    def dump
      ::ActiveRecord::SchemaDumper.dump(connection, StringIO.new)
    end

  end

  def table_statement(method, *args)
    migration.create_table("other", force: :cascade) do |t|
      t.send method, *args
    end
  end

  def env_match(env, matcher, bool: false)
    matcher.each do |key, val|
      actual = env.send key
      case val
      when Hash
        val.each do |subkey, subval|
          subactual = actual.send subkey
          if bool
            return false unless subactual == subval
          else
            expect(subactual).to eq subval
          end
        end
      when Regexp
        if bool
          return false unless actual =~ val
        else
          expect(actual).to match val
        end
      else
        if bool
          return false unless actual == val
        else
          expect(actual).to eq val
        end
      end
    end
    true if bool
  end

  def expect_middleware(env: {}, enable: {})
    middleware = described_class
    begin
      middleware.enable(-> (_env) { env_match(_env, enable, bool: true) })
      expect { yield }.to raise_error { |error|
        expect(error).to be_a TestReporter::Called
        expect(error.middleware).to eq middleware
        env_match(error.env, env)
      }
    ensure
      middleware.disable
    end
  end

end
