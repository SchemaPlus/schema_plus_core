module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module AbstractMysqlAdapter
          module SchemaCreation
            def visit_TableDefinition(o)
              SchemaMonkey::Middleware::Sql::Table.start(caller: self, connection: self.instance_variable_get('@conn'), table_definition: o, sql: SqlStruct::Table.new) { |env|
                env.sql.parse! super env.table_definition
              }.sql.assemble
            end
          end
        end
      end
    end
  end
end
