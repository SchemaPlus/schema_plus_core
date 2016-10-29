module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module Mysql2Adapter

          def _data_sources_sql(types = nil)
            sql = "SELECT table_name FROM information_schema.tables\n"
            sql << "WHERE table_schema = #{quote(@config[:database])}"
            if types
              supported_types = types & %i[table view]
              if supported_types.length == 0
                raise 'No supported data source types: please specify at least one of :table, :view'
              elsif supported_types.length == 1
                # If both tables and views are requested, no need to add an extra clause
                if supported_types[0] == :table
                  table_type = 'BASE_TABLE'
                else
                  table_type = 'VIEW'
                end
                sql << " AND table_type = '#{table_type}'"
              end
            end
            sql
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

          def indexes(table_name, query_name=nil)
            SchemaMonkey::Middleware::Schema::Indexes.start(connection: self, table_name: table_name, query_name: query_name, index_definitions: []) { |env|
              env.index_definitions += super env.table_name, env.query_name
            }.index_definitions
          end

          def data_sources
            SchemaMonkey::Middleware::Schema::DataSources.start(connection: self, sources: [], where_constraints: []) { |env|
              env.sources += _select_data_sources env.where_constraints
            }.sources
          end

          def views
            SchemaMonkey::Middleware::Schema::Views.start(connection: self, views: [], where_constraints: []) { |env|
              env.views += _select_data_sources env.where_constraints, [:view]
            }.views
          end

          def select_rows(sql, name=nil, binds=[])
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds) { |env|
              env.result = super env.sql, env.query_name, env.binds
            }.result
          end

          def exec_query(sql, name='SQL', binds=[], prepare: false)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds, prepare: prepare) { |env|
              env.result = super env.sql, env.query_name, env.binds, prepare: env.prepare
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

