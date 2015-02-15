module SchemaPlus::Core
  module ActiveRecord
    module Schema
      module ClassMethods
        def define(info={}, &block)
          SchemaMonkey::Middleware::Schema::Define.start(info: info, block: block) do |env|
            super env.info, &env.block
          end
        end
      end
    end
  end
end
