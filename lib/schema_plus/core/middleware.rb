module SchemaPlus
  module Core
    module Middleware
      module Query
        module Exec
          ENV = [:connection, :sql, :name, :binds, :result]
        end
      end

      module Schema
        module Tables
          # :database and :like are only for mysql
          # :table_name is only for sqlite3
          ENV = [:connection, :query_name, :table_name, :database, :like, :tables]
        end

        module Indexes
          ENV = [:connection, :query_name, :table_name, :index_definitions]
        end
      end

      module Migration
        module Column
          ENV = [:caller, :operation, :table_name, :column_name, :type, :options]
        end

        module Index
          ENV = [:caller, :operation, :table_name, :column_names, :options]
        end
      end

      module Sql
        module ColumnOptions
          ENV = [:caller, :connection, :sql, :options]
        end

        module IndexComponents
          ENV = [:connection, :table_name, :column_names, :options, :sql]
        end

        module Table
          ENV = [:caller, :connection, :table_definition, :sql]
        end
      end

      module Dumper
        module Extensions
          ENV = [:dumper, :connection, :dump, :extensions]
        end
        module Tables
          ENV = [:dumper, :connection, :dump]
        end
        module Table
          ENV = [:dumper, :connection, :dump, :table]
        end
        module Indexes
          ENV = [:dumper, :connection, :dump, :table]
        end
      end

      module Model
        module Columns
          ENV = [:model, :columns]
        end
        module ResetColumnInformation
          ENV = [:model]
        end
      end
    end
  end
end
