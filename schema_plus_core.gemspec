# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_plus/core/version'

Gem::Specification.new do |gem|
  gem.name          = "schema_plus_core"
  gem.version       = SchemaPlus::Core::VERSION
  gem.authors       = ["ronen barzel"]
  gem.email         = ["ronen@barzel.org"]
  gem.summary       = %q{Provides an internal extension API to ActiveRecord}
  gem.description   = %q{Provides an internal extension API to ActiveRecord, in the form of middleware-style callback stacks}
  gem.homepage      = "https://github.com/SchemaPlus/schema_plus_core"
  gem.license       = "MIT"

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activerecord", "~> 5.0"
  gem.add_dependency "schema_monkey", "~> 2.1"
  gem.add_dependency "its-it", "~> 1.2"

  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0.0"
  gem.add_development_dependency "rspec-given"
  gem.add_development_dependency "schema_dev", "~> 3.7"
  #gem.add_development_dependency "schema_compatibility", "~> 0.3"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "simplecov-gem-profile"
  gem.add_development_dependency "its-it"
end
