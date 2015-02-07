require 'simplecov'
require 'simplecov-gem-profile'
SimpleCov.start "gem"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'rspec/given'
require 'active_record'
require 'schema_plus/core'
require 'schema_dev/rspec'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

SchemaDev::Rspec.setup

RSpec.configure do |config|
  config.warnings = true
  config.around(:each) do |example|
    ActiveRecord::Migration.suppress_messages do
      begin
        example.run
      ensure
        ActiveRecord::Base.connection.tables.each do |table|
          ActiveRecord::Migration.drop_table table, force: :cascade
        end
      end
    end
  end

end

SimpleCov.command_name "[ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING} - #{ActiveRecord::Base.connection.adapter_name}]"

