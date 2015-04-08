require 'spec_helper'

describe SchemaMonkey::Middleware::Dumper do

  let(:migration) { ::ActiveRecord::Migration }

  before(:each) do
    migration.create_table "things" do |t|
      t.integer :column
      t.index :column
    end
    migration.create_table "other" do |t|
      t.references :thing
    end
    migration.add_foreign_key("other", "things")
  end

  context TestDumper::Middleware::Dumper::Initial do
    Then { expect(dump).to match(/Schema[.]define.*do\s+#{middleware}/) }
  end

  context TestDumper::Middleware::Dumper::Tables do
    Then { expect(dump).to match(/create_table "other".*create_table "#{middleware}".*create_table "things"/m) }
  end

  context TestDumper::Middleware::Dumper::Table do
    Then { expect(dump).to match(/t[.]integer.*option: #{middleware} \# comment: #{middleware}/) }
    Then { expect(dump).to match(/statement: #{middleware}\s+end\s+(add_index.*)?\s+trailer: #{middleware}/) }
  end

  context TestDumper::Middleware::Dumper::Indexes do
    Then { expect(dump).to match(/add_index.*#{middleware}/) }
  end


  private

  def middleware
    described_class
  end

  def dump
    begin
      middleware.enable
      stream = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      return stream.string
    ensure
      middleware.disable
    end
  end

end
