module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module TableDefinition

          def column(name, type, options = {})
            options = options.deep_dup
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :define, table_name: self.name, column_name: name, type: type, implements_reference: options.delete(:_implements_reference), options: options) do |env|
              super env.column_name, env.type, env.options
            end
          end

          def references(name, options = {})
            options = options.deep_dup
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :define, table_name: self.name, column_name: "#{name}_id", type: :reference, options: options) do |env|
              super env.column_name.sub(/_id$/, ''), env.options.merge(_implements_reference: true)
            end
          end

          def belongs_to(name, options = {})
            options = options.deep_dup
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :define, table_name: self.name, column_name: "#{name}_id", type: :reference, options: options) do |env|
              super env.column_name.sub(/_id$/, ''), env.options.merge(_implements_reference: true)
            end
          end

          def index(*args)
            options = args.extract_options!
            column_name = args.first
            SchemaMonkey::Middleware::Migration::Index.start(caller: self, operation: :define, table_name: self.name, column_names: column_name, options: options.deep_dup) do |env|
              super env.column_names, env.options
            end
          end
        end
      end
    end
  end
end
