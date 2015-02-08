module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module PostgresqlAdapter

          def change_column(table_name, name, type, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :change, table_name: table_name, column_name: name, type: type, options: options.deep_dup) do |env|
              super env.table_name, env.column_name, env.type, env.options
            end
          end

          def exec_cache(sql, name, binds)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, name: name, binds: binds) { |env|
              env.result = super env.sql, env.name, env.binds
            }.result
          end

          def exec_no_cache(sql, name, binds)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, name: name, binds: binds) { |env|
              env.result = super env.sql, env.name, env.binds
            }.result
          end

          def indexes(table_name, query_name=nil)
            SchemaMonkey::Middleware::Query::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
              env.index_definitions += super env.table_name, env.query_name
            }.index_definitions
          end

          def tables(query_name=nil)
            SchemaMonkey::Middleware::Query::Tables.start(connection: self, query_name: query_name, tables: []) { |env|
              env.tables += super env.query_name
            }.tables
          end
        end
      end
    end
  end
end
