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
            super nil
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
            env.table.pname = m[:name]
            env.table.options = m[:options].strip
            env.table.trailer = m[:trailer].split("\n").map(&:strip).reject{|s| s.blank?}
            env.table.columns = m[:columns].strip.split("\n").map { |col|
              m = col.strip.match %r{
              ^
              t\.(?<type>\S+) \s*
                [:'"](?<name>[^"\s]+)[,"]? \s*
                ,? \s*
                (?<options>.*)
              $
              }x
              SchemaDump::Table::Column.new(name: m[:name], type: m[:type], options: m[:options])
            }
          end
        end

        def indexes(table, _)
          SchemaMonkey::Middleware::Dumper::Indexes.start(dumper: self, connection: @connection, dump: @dump, table: @dump.tables[table]) do |env|
            stream = StringIO.new
            super env.table.name, stream
            env.table.indexes += stream.string.split("\n").map { |string|
              m = string.strip.match %r{
              ^
              add_index \s*
                [:'"](?<table>[^'"\s]+)['"]? \s* , \s*
                (?<columns>.*) \s*
                name: \s* [:'"](?<name>[^'"\s]+)['"]? \s*
                (, \s* (?<options>.*))?
                $
              }x
              columns = m[:columns].tr(%q{[]'":}, '').strip.split(/\s*,\s*/)
              SchemaDump::Table::Index.new name: m[:name], columns: columns, options: m[:options]
            }
          end
        end
      end
    end
  end
end
