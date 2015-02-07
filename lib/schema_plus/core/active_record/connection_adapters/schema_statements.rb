module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module SchemaStatements

          #
          # The hooks at the top level of this module are for the base class, which are not overriden by
          # any specific adapters in AR.
          #
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_index_options, :schema_monkey
            end
          end

          IndexComponentsSql = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]

          def add_index_options_with_schema_monkey(table_name, column_names, options={})
            SchemaMonkey::Middleware::Migration::IndexComponentsSql.start(connection: self, table_name: table_name, column_names: Array.wrap(column_names), options: options.deep_dup, sql: IndexComponentsSql.new) { |env|
              env.sql.name, env.sql.type, env.sql.columns, env.sql.options, env.sql.algorithm, env.sql.using = add_index_options_without_schema_monkey(env.table_name, env.column_names, env.options)
            }.sql.to_hash.values
          end

          #
          # The hooks below here are grouped into modules.  Different
          # connection adapters define this methods in different places, so
          # each will include the hooks into the appropriate class
          #

          module Column
            def self.included(base)
              base.class_eval do
                alias_method_chain :add_column, :schema_monkey
                alias_method_chain :change_column, :schema_monkey
              end
            end

            def add_column_with_schema_monkey(table_name, name, type, options = {})
              SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: name, type: type, options: options.deep_dup) do |env|
                add_column_without_schema_monkey env.table_name, env.column_name, env.type, env.options
              end
            end

            def change_column_with_schema_monkey(table_name, name, type, options = {})
              SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :change, table_name: table_name, column_name: name, type: type, options: options.deep_dup) do |env|
                change_column_without_schema_monkey env.table_name, env.column_name, env.type, env.options
              end
            end
          end

          module Reference
            def self.included(base)
              base.class_eval do
                alias_method_chain :add_reference, :schema_monkey
              end
            end

            def add_reference_with_schema_monkey(table_name, name, options = {})
              SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: "#{name}_id", type: :reference, options: options.deep_dup) do |env|
                add_reference_without_schema_monkey env.table_name, env.column_name.sub(/_id$/, ''), env.options
              end
            end


          end

          module Index
            def self.included(base)
              base.class_eval do
                alias_method_chain :add_index, :schema_monkey
              end
            end
            def add_index_with_schema_monkey(*args)
              options = args.extract_options!
              table_name, column_names = args
              SchemaMonkey::Middleware::Migration::Index.start(caller: self, operation: :add, table_name: table_name, column_names: column_names, options: options.deep_dup) do |env|
                add_index_without_schema_monkey env.table_name, env.column_names, env.options
              end
            end
          end
        end
      end
    end
  end
end
