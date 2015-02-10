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

      class Table < KeyStruct[:name, :pname, :options, :columns, :indexes, :statements, :trailer]
        def initialize(*args)
          super
          self.columns ||= []
          self.indexes ||= []
          self.statements ||= []
          self.trailer ||= []
        end

        def assemble(stream)
          stream.write "  create_table #{pname.inspect}"
          stream.write ", #{options}" unless options.blank?
          stream.puts " do |t|"
          typelen = columns.map{|col| col.type.length}.max
          namelen = columns.map{|col| col.name.length}.max
          columns.each do |column|
            stream.write "    "
            column.assemble(stream, typelen, namelen)
            stream.puts ""
          end
          statements.each do |statement|
            stream.puts "    #{statement}"
          end
          stream.puts "  end"
          indexes.each do |index|
            stream.write "  add_index #{pname.inspect}, "
            index.assemble(stream)
            stream.puts ""
          end
          trailer.each do |statement|
            stream.puts "  #{statement}"
          end
          stream.puts ""
        end

        class Column < KeyStruct[:name, :type, :options, :comments]

          def add_option(option)
            self.options = [options, option].reject(&:blank?).join(', ')
          end

          def add_comment(comment)
            self.comments = [comments, comment].reject(&:blank?).join('; ')
          end

          def assemble(stream, typelen, namelen)
            stream.write "t.%-#{typelen}s " % type
            if options.blank? && comments.blank?
              stream.write name.inspect
            else
              pr = name.inspect
              pr += "," unless options.blank?
              stream.write "%-#{namelen+3}s " % pr
            end
            stream.write "#{options}" unless options.blank?
            stream.write " " unless options.blank? or comments.blank?
            stream.write "# #{comments}" unless comments.blank?
          end
        end

        class Index < KeyStruct[:name, :columns, :options]

          def add_option(option)
            self.options = [options, option].reject(&:blank?).join(', ')
          end

          def assemble(stream)
            stream.write [
              columns.inspect,
              "name: #{name.inspect}",
              options
            ].reject(&:blank?).join(", ")
          end
        end
      end
    end
  end
end
