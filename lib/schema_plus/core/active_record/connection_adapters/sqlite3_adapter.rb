module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module Sqlite3Adapter
          def _data_sources_sql(types = nil)
            supported_types = %i[table view]
            types = types & supported_types || supported_types
            if types.length == 0
              raise 'No supported data source types: please specify at least one of :table, :view'
            elsif types.length == 1
              type_query = "type = '#{types.first}'"
            else
              type_list = types.map{|x| "'#{x}'"}.join ','
              type_query = "type IN (#{type_list})"
            end
            "SELECT name FROM sqlite_master WHERE #{type_query} AND name <> 'sqlite_sequence'"
          end

          def rename_table(table_name, new_name)
            SchemaMonkey::Middleware::Migration::RenameTable.start(connection: self, table_name: table_name, new_name: new_name) do |env|
              super env.table_name, env.new_name
            end
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

          def exec_query(sql, name=nil, binds=[], prepare: false)
            SchemaMonkey::Middleware::Query::Exec.start(connection: self, sql: sql, query_name: name, binds: binds, prepare: prepare) { |env|
              env.result = super env.sql, env.query_name, env.binds, prepare: env.prepare
            }.result
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
        end
      end
    end
  end
end


