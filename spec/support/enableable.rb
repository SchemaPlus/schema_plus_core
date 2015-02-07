module Enableable

  def enabled_middleware(root, env)
    middleware = self.singleton_class.ancestors.find(&it.to_s.start_with?("#{root}::Middleware"))
    return nil unless middleware.enabled?(env)
    middleware.disable
    middleware
  end

  def self.included(base)
    base.module_eval do
      def self.enable(condition = true)
        @enabled = condition
      end
      def self.enabled?(env)
        case @enabled
        when Proc then @enabled.call(env)
        else @enabled
        end
      end
      def self.disable
        @enabled = false
      end

      disable
    end
  end
end


