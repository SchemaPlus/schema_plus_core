module TestReporter

  class Called < Exception
    attr_accessor :middleware, :env
    def initialize(middleware:, env:)
      @middleware = middleware
      @env = env
    end
  end

  module Notify
    def self.included(base)
      base.send :include, Enableable
    end

    def after(env)
      return unless middleware = enabled_middleware(TestReporter, env)
      raise Called, middleware: middleware, env: env
    end
  end

  module Middleware
    module Query
      module Exec ;                     include Notify ; end
    end

    module Schema
      module Define ;                   include Notify ; end
      module Indexes ;                  include Notify ; end
      module Tables ;                   include Notify ; end
    end

    module Migration
      module Column ;                   include Notify ; end
      module CreateTable ;              include Notify ; end
      module DropTable ;                include Notify ; end
      module RenameTable ;              include Notify ; end
      module Index ;                    include Notify ; end
    end

    module Sql
      module ColumnOptions ;            include Notify ; end
      module IndexComponents ;          include Notify ; end
      module Table ;                    include Notify ; end
    end

    module Model
      module Columns ;                  include Notify ; end
      module ResetColumnInformation ;   include Notify ; end
      module Association
        module Declaration ;            include Notify ; end
      end
    end

    module Dumper
      module Initial ;                  include Notify ; end
      module Tables ;                   include Notify ; end
      module Table ;                    include Notify ; end
      module Indexes ;                  include Notify ; end
    end
  end
end

SchemaMonkey.register(TestReporter)
