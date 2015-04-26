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

          # has_many, has_one, has_and_belongs_to_many, and belongs_to
          # don't have a documented return value.  But at least one gem
          # (https://github.com/hzamani/active_record-acts_as/blob/master/lib/active_record/acts_as/relation.rb#L14)
          # relies on the undocumented return value.
          def has_many(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do |env|
              env.result = super(env.name, env.scope, env.options, &env.extension)
            end.result
          end

          def has_one(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do |env|
              env.result = super(env.name, env.scope, env.options, &env.extension)
            end.result
          end

          def has_and_belongs_to_many(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do |env|
              env.result = super(env.name, env.scope, env.options, &env.extension)
            end.result
          end

          def belongs_to(name, scope = nil, options = {}, &extension)
            SchemaMonkey::Middleware::Model::Association::Declaration.start(model: self, name: name, scope: scope, options: options, extension: extension) do |env|
              env.result = super(env.name, env.scope, env.options, &env.extension)
            end.result
          end
        end
      end
    end
  end
end
