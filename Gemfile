source "http://rubygems.org"

gemspec

gem "rspec-rails"
gem "jasmine"
gem "headless"
gem "coffee-script"
gem "thin"
gem "eventmachine"
gem "faye-websocket"
gem "simplecov"
gem "ruby_gntp"
gem "guard"
gem "guard-rspec"
gem "guard-coffeescript"

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter', :require => 'jdbc-sqlite3', :require => 'arjdbc'
end
platforms :ruby do
  gem 'sqlite3'
end
