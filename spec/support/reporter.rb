module Reporter
  
  class Called < Exception
    attr_accessor :middleware, :env
    def initialize(middleware:, env:)
      @middleware = middleware
      @env = env
    end
  end

  module Notify

    def after(env)
      middleware = self.singleton_class.ancestors.find(&it.to_s =~ /Reporter::Middleware/)
      return unless middleware.enabled?(env)
      middleware.disable
      raise Called, middleware: middleware, env: env
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

  module Middleware
    module Query
      module ExecCache ;        include Notify ; end
      module Tables ;           include Notify ; end
      module Indexes ;          include Notify ; end
    end

    module Migration
      module Column ;                   include Notify ; end
      module ColumnOptionsSql ;         include Notify ; end
      module Index ;                    include Notify ; end
      module IndexComponentsSql ;       include Notify ; end
    end

    module Model
      module Columns ;                  include Notify ; end
      module ResetColumnInformation ;   include Notify ; end
    end

    module Dumper
      module Extensions ;               include Notify ; end
      module Tables ;                   include Notify ; end
      module Table ;                    include Notify ; end
      module Indexes ;                  include Notify ; end
    end
  end
end

SchemaMonkey.register(Reporter)
