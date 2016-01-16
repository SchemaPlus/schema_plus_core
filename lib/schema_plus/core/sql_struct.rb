module SchemaPlus
  module Core
    module SqlStruct
      IndexComponents = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]

      class Table < KeyStruct[:command, :name, :body, :options, :quotechar, :inheritance]
        INHERITANCE = 'inheritance'
        INHERITANCE_KEY = 'INHERITS'
        INHERITANCE_REGEX = '(?<inheritance>INHERITS \s* \( .* \)) \s*'

        def parse!(sql)
          m = sql.strip.match %r{
          ^
          (?<command>.*\bTABLE\b) \s*
            (?<quote>['"`])(?<name>\S+)\k<quote> \s*
            \( \s*
            (?<body>.*) \s*
            \) \s*
            #{INHERITANCE_REGEX if sql[INHERITANCE_KEY]}
            (?<options> \S.*)?
            $
          }mxi
          self.command = m[:command]
          self.quotechar = m[:quote]
          self.name = m[:name]
          self.body = m[:body]
          self.options = m[:options]
          self.inheritance = m[:inheritance] if m.names.include? INHERITANCE
        end
        def assemble
          ["#{command} #{quotechar}#{name}#{quotechar} (#{body})", inheritance, options].reject(&:blank?).join(" ")
        end
      end
    end
  end
end
