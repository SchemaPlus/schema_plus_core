module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module Mysql2Adapter

          def change_column(table_name, name, type, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :change, table_name: table_name, column_name: name, type: type, options: options.deep_dup) do |env|
              super env.table_name, env.column_name, env.type, env.options
            end
          end

          def add_index(table_name, column_names, options={})
            SchemaMonkey::Middleware::Migration::Index.start(caller: self, operation: :add, table_name: table_name, column_names: column_names, options: options.deep_dup) do |env|
              super env.table_name, env.column_names, env.options
            end
          end

          def drop_table(table_name, options={})
            SchemaMonkey::Middleware::Migration::DropTable.start(connection: self, table_name: table_name, options: options.dup) do |env|
              super env.table_name, env.options
            end
          end

          def rename_table(table_name, new_name)
            SchemaMonkey::Middleware::Migration::RenameTable.start(connection: self, table_name: table_name, new_name: new_name) do |env|
              super env.table_name, env.new_name
            end
          end

          def indexes(table_name, query_name=nil)
            SchemaMonkey::Middleware::Schema::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
              env.index_definitions += super env.table_name, env.query_name
            }.index_definitions
          end

          def tables(query_name=nil, database=nil, like=nil)
            SchemaMonkey::Middleware::Schema::Tables.start(connection: self, query_name: query_name, database: database, like: like, tables: []) { |env|
              env.tables += super env.query_name, env.database, env.like
            }.tables
          end

          def select_rows(sql, name=nil, binds=[])
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds
            }.result
          end

          def exec_query(sql, name='SQL', binds=[])
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds
            }.result
          end

          alias exec_without_stmt exec_query

          def exec_insert(sql, name, binds, pk = nil, sequence_name = nil)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds, pk, sequence_name
            }.result
          end

          def exec_delete(sql, name, binds)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds
            }.result
          end

          alias :exec_update :exec_delete

        end
      end
    end
  end
end

