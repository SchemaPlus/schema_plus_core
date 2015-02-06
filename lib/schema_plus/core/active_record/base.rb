module SchemaPlus
  module Core
    module ActiveRecord

      module Base
        def self.prepended(base)
          base.singleton_class.prepend ClassMethods
        end

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
