# frozen_string_literal: true

module SchemaPlus
  module Core
    class SchemaDump
      include TSort

      attr_reader :initial, :tables, :dependencies, :data
      attr_accessor :final, :trailer

      def initialize(dumper)
        @dumper = dumper
        @dependencies = Hash.new { |h, k| h[k] = [] }
        @initial = []
        @tables = {}
        @final = []
        @data = OpenStruct.new # a place for middleware to leave data
      end

      def depends(tablename, dependents)
        @tables[tablename] ||= false # placeholder for dependencies applied before defining the table
        @dependencies[tablename] += Array.wrap(dependents)
      end

      def assemble(stream)
        stream.puts @initial.join("\n") if initial.any?
        assemble_tables(stream)
        final.each do |statement|
          stream.puts "  #{statement}"
        end
        stream.puts @trailer
      end

      def assemble_tables(stream)
        tsort().each do |table|
          @tables[table].assemble(stream) if @tables[table]
        end
      end

      def tsort_each_node(&block)
        @tables.keys.sort.each(&block)
      end

      def tsort_each_child(tablename, &block)
        @dependencies[tablename].sort.uniq.reject{|t| @dumper.ignored? t}.each(&block)
      end

      class Table < Struct.new(:name, :pname, :options, :columns, :indexes, :statements, :trailer, :alt,
                               keyword_init: true)
        def initialize(*args)
          super
          self.columns ||= []
          self.indexes ||= []
          self.statements ||= []
          self.trailer ||= []
        end

        def assemble(stream)
          if pname.nil?
            stream.puts alt
            stream.puts ""
            return
          end
          stream.write "  create_table #{pname.inspect}"
          stream.write ", #{options}" unless options.blank?
          stream.puts " do |t|"
          typelen = columns.map{|col| col.type.length}.max
          namelen = columns.map{|col| col.name.length}.max
          indexes
          columns.each do |column|
            stream.write "    "
            column.assemble(stream, typelen, namelen)
            stream.puts ""
          end
          stream.puts "" unless indexes.empty?
          indexes.each do |index|
            stream.write "    t.index "
            index.assemble(stream)
            stream.puts ""
          end
          statements.each do |statement|
            stream.puts "    #{statement}"
          end
          stream.puts "  end"
          trailer.each do |statement|
            stream.puts "  #{statement}"
          end
          stream.puts ""
        end

        class Column < Struct.new(:name, :type, :options, :comments, keyword_init: true)

          def assemble(stream, typelen, namelen)
            stream.write "t.%-#{typelen}s " % type
            if options.blank? && comments.blank?
              stream.write name.inspect
            else
              pr = name.inspect
              pr += ',' unless options.blank?
              stream.write "%-#{namelen+3}s " % pr
            end
            stream.write options.to_s.sub(/^{(.*)}$/, '\1') unless options.blank?
            stream.write ' ' unless options.blank? or comments.blank?
            stream.write '# ' + comments.join('; ') unless comments.blank?
          end
        end

        class Index < Struct.new(:name, :columns, :options, keyword_init: true)

          def assemble(stream)
            stream.write columns.inspect + ", " + {name: name}.merge(options).to_s.sub(/^{(.*)}$/, '\1')
          end
        end
      end
    end
  end
end
