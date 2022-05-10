# frozen_string_literal: true

module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module PostgreSQL
          module PostgreSQL # need two PostgreSQLs because the first gets stripped by schema_monkey
            module SchemaDumper
              # quick hack fix quoting of column default functions to allow eval() when we
              # capture the stream.
              #
              # AR's PostgresqlAdapter#prepare_column_options wraps the
              # function in double quotes, which doesn't work because the
              # function itself may have doublequotes in it which don't get
              # escaped properly.
              #
              # Arguably that's a bug in AR, but then again default function
              # expressions don't work well in AR anyway.  (hence
              # schema_plus_default_expr )
              #
              def prepare_column_options(column, *) # :nodoc:
                spec = super
                spec[:default] = "%q{#{column.default_function}}" if column.default_function && !column.serial?
                spec
              end

              def extensions(_)
                stream = StringIO.new
                super stream
                @dump.extensions << stream.string unless stream.string.blank?
              end

              def types(_)
                stream = StringIO.new
                super stream
                @dump.types << stream.string unless stream.string.blank?
              end
            end
          end
        end
      end
    end
  end
end
