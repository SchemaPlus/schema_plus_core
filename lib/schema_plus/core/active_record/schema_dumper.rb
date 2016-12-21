require 'ostruct'
require 'tsort'

module SchemaPlus
  module Core
    module ActiveRecord
      module SchemaDumper

        def self.prepended(base)
          base.class_eval do
            public :ignored?
          end
        end

        def dump(stream)
          @dump = SchemaDump.new(self)
          super stream
          @dump.assemble(stream)
        end

        def foreign_keys(table, _)
          stream = StringIO.new
          super table, stream
          @dump.final += stream.string.split("\n").map(&:strip)
        end

        def trailer(_)
          stream = StringIO.new
          super stream
          @dump.trailer = stream.string
        end

        def extensions(_)
          SchemaMonkey::Middleware::Dumper::Initial.start(dumper: self, connection: @connection, dump: @dump, initial: @dump.initial) do |env|
            stream = StringIO.new
            super stream
            env.dump.initial << stream.string unless stream.string.blank?
          end
        end

        def tables(_)
          SchemaMonkey::Middleware::Dumper::Tables.start(dumper: self, connection: @connection, dump: @dump) do |env|
            super
          end
        end

        def table(table, _)
          SchemaMonkey::Middleware::Dumper::Table.start(dumper: self, connection: @connection, dump: @dump, table: @dump.tables[table] = SchemaDump::Table.new(name: table)) do |env|
            stream = StringIO.new
            super env.table.name, stream
            m = stream.string.match %r{
            \A \s*
              create_table \s*
              [:'"](?<name>[^'"\s]+)['"]? \s*
              ,? \s*
              (?<options>.*) \s+
              do \s* \|t\| \s* $
            (?<columns>.*)
            ^\s*end\s*$
            (?<trailer>.*)
            \Z
            }xm
            if m.nil?
              env.table.alt = stream.string
            else
              env.table.pname = m[:name]
              env.table.options = m[:options].strip
              env.table.trailer = m[:trailer].split("\n").map(&:strip).reject{|s| s.blank?}
              table_objects = m[:columns].strip.split("\n").map { |col|
                cs = col.strip
                m = cs.match %r{
                ^
                t\.(?<type>\S+) \s*
                  [:'"](?<name>[^"\s]+)[,"]? \s*
                  ,? \s*
                  (?<options>.*)
                $
                }x
                if !m.nil?
                  SchemaDump::Table::Column.new name: m[:name], type: m[:type], options: eval("{" + m[:options] + "}"), comments: []
                else
                  m = cs.match %r{
                  ^
                  t\.index \s*
                    \[(?<index_cols>.*?)\] \s*
                    , \s*
                    name\: \s* [:'"](?<name>[^"\s]+)[,"]? \s*
                    ,? \s*
                    (?<options>.*)
                  $
                  }x
                  if m.nil?
                    nil
                  else
                    index_cols = m[:index_cols].tr(%q{'":}, '').strip.split(/\s*,\s*/)
                    SchemaDump::Table::Index.new name: m[:name], columns: index_cols, options: eval("{#{m[:options]}}")
                  end
                end
              }.reject { |o| o.nil? }
              env.table.columns = table_objects.select { |o| o.is_a? SchemaDump::Table::Column }
              env.table.indexes = table_objects.select { |o| o.is_a? SchemaDump::Table::Index }
            end
          end
        end
      end
    end
  end
end
