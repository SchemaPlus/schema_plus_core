module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module PostgresqlAdapter

          # quick hack fix quoting of column default functions to allow eval() when we
          # capture the stream.
          #
          # AR's PostgresqlAdapter#prepare_column_options wraps the
          # function in double quotes, which doesn't work because the
          # function itself may have doublequotes in it which don't get
          # escaped properly.  
          #
          # Arguably that's a bug in AR, but then again default function
          # expressions don't work well in AR anyway.  (hence
          # schema_plus_default_expr )
          #
          def prepare_column_options(column, *) # :nodoc:
            spec = super
            spec[:default] = "%q{#{column.default_function}}" if column.default_function
            spec
          end

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

          def exec_cache(sql, name, binds)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds
            }.result
          end

          def exec_no_cache(sql, name, binds)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds
            }.result
          end

          def indexes(table_name, query_name=nil)
            SchemaMonkey::Middleware::Schema::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
              env.index_definitions += super env.table_name, env.query_name
            }.index_definitions
          end

          def data_sources
            SchemaMonkey::Middleware::Schema::DataSources.start(connection: self, sources: []) { |env|
              env.sources += super
            }.sources
          end
        end
      end
    end
  end
end
