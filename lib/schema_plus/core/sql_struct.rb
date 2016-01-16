module SchemaPlus
  module Core
    module SqlStruct
      IndexComponents = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]

      class Table < KeyStruct[:command, :name, :body, :options, :quotechar, :inheritance]

        INHERITANCE_REGEX = %r{ \s* (?<inheritance>INHERITS \s* \( [^)]* \)) }mxi

        def parse!(sql)
          m = sql.strip.match %r{
          \A
          (?<command>.*\bTABLE\b) \s*
            (?<quote>['"`])(?<name>\S+)\k<quote> \s*
            \( \s*
            (?<body>.*) \s*
            \) \s*
            # can't use optional ? for inheritance because it would be greedily grabbed into body;
            # ideally this would use an actual parser rather than regex
            #{INHERITANCE_REGEX if sql.match INHERITANCE_REGEX}
            (?<options> \S.*)?
          \Z
          }mxi
          self.command = m[:command]
          self.quotechar = m[:quote]
          self.name = m[:name]
          self.body = m[:body]
          self.options = m[:options]
          self.inheritance = m[:inheritance] rescue nil
        end
        def assemble
          ["#{command} #{quotechar}#{name}#{quotechar} (#{body})", inheritance, options].reject(&:blank?).join(" ")
        end
      end
    end
  end
end
