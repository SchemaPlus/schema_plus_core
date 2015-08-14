require 'spec_helper'

describe SchemaPlus::Core::SqlStruct do

  describe SchemaPlus::Core::SqlStruct::Table do

    Given(:struct) { described_class.new }

    When { struct.parse! sql }

    Invariant { expect(struct.assemble).to eq sql }

    context "with options (mysql syntax)" do
      Given(:sql) { %q<CREATE TABLE `things` (`id` int(11) auto_increment PRIMARY KEY, `column` int(11),  INDEX `index_things_on_column`  (`column`) ) ENGINE=InnoDB> }
      Then { expect(struct.command).to eq "CREATE TABLE" }
      Then { expect(struct.name).to eq "things" }
      Then { expect(struct.options).to eq "ENGINE=InnoDB" }
    end

    context "temporary table (sqlite3 syntax)" do
      Given(:sql) { %q<CREATE TEMPORARY TABLE "athings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "column1" integer)> }
      Then { expect(struct.command).to eq "CREATE TEMPORARY TABLE" }
      Then { expect(struct.name).to eq "athings" }
      Then { expect(struct.options).to be_blank }
    end

    context "a table with quoted newline" do
      Given(:sql) { %q<CREATE TABLE "things" ("id" serial primary key, "name" character varying DEFAULT 'hey\nhey')>}
      Then { expect(struct.command).to eq "CREATE TABLE" }
      Then { expect(struct.name).to eq "things" }
    end

  end

end
