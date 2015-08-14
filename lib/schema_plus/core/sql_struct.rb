module SchemaPlus
  module Core
    module SqlStruct
      IndexComponents = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]

      class Table < KeyStruct[:command, :name, :body, :options, :quotechar]
        def parse!(sql)
          m = sql.strip.match %r{
          ^
          (?<command>.*\bTABLE\b) \s*
            (?<quote>['"`])(?<name>\S+)\k<quote> \s*
            \( \s*
            (?<body>.*) \s*
            \) \s*
            (?<options> \S.*)?
            $
          }mxi
          self.command = m[:command]
          self.quotechar = m[:quote]
          self.name = m[:name]
          self.body = m[:body]
          self.options = m[:options]
        end
        def assemble
          ["#{command} #{quotechar}#{name}#{quotechar} (#{body})", options].reject(&:blank?).join(" ")
        end
      end
    end
  end
end
