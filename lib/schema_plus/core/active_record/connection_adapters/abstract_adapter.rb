# frozen_string_literal: true

module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module AbstractAdapter
          def add_column(table_name, name, type, **options)
            options = options.deep_dup
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: name, type: type, implements_reference: options.delete(:_implements_reference), options: options) do |env|
              super env.table_name, env.column_name, env.type, **env.options
            end
          end

          def add_index_options(table_name, column_names, **options)
            SchemaMonkey::Middleware::Sql::IndexComponents.start(connection: self, table_name: table_name, column_names: Array.wrap(column_names), options: options.deep_dup, sql: SqlStruct::IndexComponents.new) { |env|
              env.sql.name, env.sql.type, env.sql.columns, env.sql.options, env.sql.algorithm, env.sql.using = super env.table_name, env.column_names, **env.options
            }.sql.to_h.values
          end

          def add_reference(table_name, name, **options)
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: "#{name}_id", type: :reference, options: options.deep_dup) do |env|
              super env.table_name, env.column_name.sub(/_id$/, ''), **env.options.merge(_implements_reference: true)
            end
          end

          def create_table(table_name, **options, &block)
            SchemaMonkey::Middleware::Migration::CreateTable.start(connection: self, table_name: table_name, options: options.deep_dup, block: block) do |env|
              super env.table_name, **env.options, &env.block
            end
          end

          def drop_table(table_name, **options)
            SchemaMonkey::Middleware::Migration::DropTable.start(connection: self, table_name: table_name, options: options.dup) do |env|
              super env.table_name, **env.options
            end
          end
        end
      end

      if Gem::Version.new(::ActiveRecord::VERSION::STRING) < Gem::Version.new('6.1')
        module ConnectionAdapters
          module AbstractAdapter
            # replaced version to handle array of columns with expressions
            def quoted_columns_for_index(column_names, **options)
              output_columns = []

              column_names.each do |column|
                if column.is_a?(String) && column.include?('(')
                  output_columns << column
                else
                  quoted = {column.to_sym => quote_column_name(column).dup}
                  output_columns.concat add_options_for_index_columns(quoted, **options).values
                end
              end

              output_columns
            end

            private :quoted_columns_for_index

            module SchemaCreation

              def add_column_options!(sql, options)
                sql << +" " + SchemaMonkey::Middleware::Sql::ColumnOptions.start(caller: self, connection: self.instance_variable_get('@conn'), sql: +"", column: options[:column], options: options.except(:column)) { |env|
                  super env.sql, env.options.merge(column: env.column)
                }.sql.lstrip
              end

              def visit_TableDefinition(o)
                SchemaMonkey::Middleware::Sql::Table.start(caller: self, connection: self.instance_variable_get('@conn'), table_definition: o, sql: SqlStruct::Table.new) { |env|
                  env.sql.parse! super env.table_definition
                }.sql.assemble
              end
            end
          end
        end
      else
        # In AR 6.1+ quoted_columns_for_index has slightly different paramater style and a different return type
        # Also SchemaCreation is no longer nested beneath AbstractAdapter
        module ConnectionAdapters
          module AbstractAdapter
            # replaced version to handle array of columns with expressions
            def quoted_columns_for_index(column_names, options)
              column_names.each_with_object([]) do |column, output_columns|
                if column.is_a?(String) && column.include?('(')
                  output_columns << column
                else
                  quoted = {column.to_sym => quote_column_name(column).dup}
                  output_columns.concat add_options_for_index_columns(quoted, **options).values
                end
              end.join(', ')
            end
          end

          module SchemaCreation
            def add_column_options!(sql, options)
              sql << +" " + SchemaMonkey::Middleware::Sql::ColumnOptions.start(caller: self, connection: self.instance_variable_get('@conn'), sql: +"", column: options[:column], options: options.except(:column)) { |env|
                super env.sql, env.options.merge(column: env.column)
              }.sql.lstrip
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
