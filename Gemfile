source "http://rubygems.org"

gemspec

gem "rspec-rails"
gem "therubyrhino"
gem "therubyracer"
gem "jasmine"
gem "headless"
gem "selenium-webdriver"
gem "coffee-script"
gem "faye-websocket"
gem "simplecov"
gem "guard"
gem "guard-rspec"
gem "guard-coffeescript"
gem "guard-bundler"
gem "guard-livereload"
gem "rb-fsevent"
gem "terminal-notifier-guard"

platforms :jruby do
  gem 'activerecord-jdbcsqlite3-adapter', :require => 'jdbc-sqlite3', :require => 'arjdbc'
end
platforms :ruby do
  gem 'sqlite3'
end
