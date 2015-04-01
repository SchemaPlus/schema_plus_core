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

          def has_many(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do
            |env|
              super(env.name, env.scope, env.options, &env.extension)
            end
          end

          def has_one(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do
            |env|
              super(env.name, env.scope, env.options, &env.extension)
            end
          end

          def has_and_belongs_to_many(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do
            |env|
              super(env.name, env.scope, env.options, &env.extension)
            end
          end

          def belongs_to(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do
            |env|
              super(env.name, env.scope, env.options, &env.extension)
            end
          end
        end
      end
    end
  end
end
