# frozen_string_literal: true

require "schema_monkey"
require 'active_support/core_ext/array/wrap'
require "pathname"

module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        DIR = Pathname.new(__FILE__).dirname + "core/active_record/connection_adapters"
        autoload :PostgresqlAdapter,     DIR + "postgresql_adapter"
        autoload :Mysql2Adapter,         DIR + "mysql2_adapter"
        autoload :Sqlite3Adapter,        DIR + "sqlite3_adapter"
      end
    end
  end
end

require_relative "core/active_record/base"
require_relative "core/active_record/connection_adapters/abstract_adapter"
require_relative "core/active_record/connection_adapters/table_definition"
require_relative "core/active_record/migration/command_recorder"
require_relative "core/active_record/schema"
require_relative "core/active_record/schema_dumper"
require_relative "core/middleware"
require_relative "core/schema_dump"
require_relative "core/sql_struct"
require_relative "core/version"

require_relative "core/active_record/connection_adapters/postgresql/schema_dumper"

SchemaMonkey.register(SchemaPlus::Core)
