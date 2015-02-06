module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module AbstractAdapter

          def initialize(*args)
            super

            dbm = case adapter_name
                  when /^MySQL/i                 then :Mysql
                  when 'PostgreSQL', 'PostGIS'   then :PostgreSQL
                  when 'SQLite'                  then :SQLite3
                  end

            SchemaMonkey.insert(dbm: dbm)
          end

          module SchemaCreation
            def self.prepended(base)
              base.class_eval do
                public :options_include_default?
              end
            end

            def add_column_options!(sql, options)
              SchemaMonkey::Middleware::Migration::ColumnOptionsSql.start(caller: self, connection: self.instance_variable_get('@conn'), sql: sql, options: options) { |env|
                super env.sql, env.options
              }.sql
            end
          end
        end
      end
    end
  end
end
