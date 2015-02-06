module SchemaPlus
  module Core
    module Middleware
      module Query
        module ExecCache
          ENV = [:connection, :sql, :name, :binds, :result]
        end

        module Tables
          # :database and :like are only for mysql
          # :table_name is only for sqlite3
          ENV = [:connection, :query_name, :table_name, :database, :like, :tables]
        end

        module Indexes
          ENV = [:connection, :table_name, :query_name, :index_definitions]
        end
      end

      module Migration
        module Column
          ENV = [:caller, :operation, :table_name, :column_name, :type, :options]
        end

        module ColumnOptionsSql
          ENV = [:caller, :connection, :sql, :options]
        end

        module Index
          ENV = [:caller, :operation, :table_name, :column_names, :options]
        end

        module IndexComponentsSql
          ENV = [:connection, :table_name, :column_names, :options, :sql]
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
