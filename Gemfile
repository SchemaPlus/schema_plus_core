source "http://rubygems.org"

gemspec

gemfile_local = File.expand_path('../Gemfile.local', __FILE__)

File.exist?(gemfile_local) and eval File.read(gemfile_local), binding, gemfile_local
