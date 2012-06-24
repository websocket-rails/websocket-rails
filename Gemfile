source "http://rubygems.org"

gemspec

gem "rspec-rails"
gem "eventmachine", ">= 1.0.0.beta.3"
gem "faye-websocket"
gem "simplecov"
gem "ruby_gntp"
gem "guard"
gem "guard-rspec"

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter', :require => 'jdbc-sqlite3', :require => 'arjdbc'
end
platforms :ruby do
  gem 'sqlite3'
end
