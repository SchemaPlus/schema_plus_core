module SchemaPlus
  module Core
    module ActiveRecord
      module Base
        module ClassMethods

          def columns
            SchemaMonkey::Middleware::Model::Columns.start(model: self, columns: []) { |env|
              env.columns += super
            }.columns
          end

          def reset_column_information
            SchemaMonkey::Middleware::Model::ResetColumnInformation.start(model: self) do |env|
              super
            end
          end
        end
      end
    end
  end
end
