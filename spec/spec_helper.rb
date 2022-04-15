# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

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

  config.filter_run_excluding rails: -> (v) {
    rails_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
    test = Gem::Requirement.new(v)
    !test.satisfied_by?(rails_version)
  }
  config.warnings = true
  config.around(:each) do |example|
    ActiveRecord::Migration.suppress_messages do
      begin
        example.run
      ensure
        ActiveRecord::Base.connection.data_sources.each do |table|
          ActiveRecord::Migration.drop_table table, force: :cascade
        end
      end
    end
  end

end

SimpleCov.command_name "[ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING} - #{ActiveRecord::Base.connection.adapter_name}]"

