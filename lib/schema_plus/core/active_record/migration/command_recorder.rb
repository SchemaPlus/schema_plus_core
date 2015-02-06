module SchemaPlus
  module Core
    module ActiveRecord
      module Migration
        module CommandRecorder

          def add_column(table_name, column_name, type, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :record, table_name: table_name, column_name: column_name, type: type, options: options.deep_dup) do |env|
              super env.table_name, env.column_name, env.type, env.options
            end
          end
        end
      end
    end
  end
end
