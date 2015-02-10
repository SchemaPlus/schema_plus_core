module TestDumper
  module Middleware
    module Dumper
      module Initial
        include Enableable
        def after(env)
          return unless middleware = enabled_middleware(TestDumper, env)
          env.initial.unshift middleware.to_s
        end
      end
      module Tables
        include Enableable
        def after(env)
          return unless middleware = enabled_middleware(TestDumper, env)
          env.dump.tables[middleware.to_s] = env.dump.tables.values.first.dup.tap {|t| t.pname = middleware.to_s }
          env.dump.depends("things", middleware.to_s)
          env.dump.depends(middleware.to_s, "other")
        end
      end
      module Table
        include Enableable
        def after(env)
          return unless middleware = enabled_middleware(TestDumper, env)
          env.table.columns.first.add_option "option: #{middleware}"
          env.table.columns.first.add_comment "comment: #{middleware}"
          env.table.statements << "statement: #{middleware}"
          env.table.trailer << "trailer: #{middleware}"
        end
      end
      module Indexes
        include Enableable
        def after(env)
          return unless env.table.indexes.any?
          return unless middleware = enabled_middleware(TestDumper, env)
          env.table.indexes.first.add_option middleware.to_s
        end
      end
    end
  end
end

SchemaMonkey.register(TestDumper)
