module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module AbstractAdapter

          def add_column(table_name, name, type, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: name, type: type, options: options.deep_dup) do |env|
              super env.table_name, env.column_name, env.type, env.options
            end
          end

          def add_reference(table_name, name, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: "#{name}_id", type: :reference, options: options.deep_dup) do |env|
              super env.table_name, env.column_name.sub(/_id$/, ''), env.options
            end
          end

          def add_index_options(table_name, column_names, options={})
            SchemaMonkey::Middleware::Sql::IndexComponents.start(connection: self, table_name: table_name, column_names: Array.wrap(column_names), options: options.deep_dup, sql: SqlStruct::IndexComponents.new) { |env|
              env.sql.name, env.sql.type, env.sql.columns, env.sql.options, env.sql.algorithm, env.sql.using = super env.table_name, env.column_names, env.options
            }.sql.to_hash.values
          end

          module SchemaCreation

            def add_column_options!(sql, options)
              SchemaMonkey::Middleware::Sql::ColumnOptions.start(caller: self, connection: self.instance_variable_get('@conn'), sql: sql, options: options) { |env|
                super env.sql, env.options
              }.sql
            end

            def visit_TableDefinition(o)
              SchemaMonkey::Middleware::Sql::Table.start(caller: self, connection: self.instance_variable_get('@conn'), table_definition: o, sql: SqlStruct::Table.new) { |env|
                env.sql.parse! super env.table_definition
              }.sql.assemble
            end
          end
        end
      end
    end
  end
end
