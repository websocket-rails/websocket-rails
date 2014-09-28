$:.push File.expand_path("../lib", __FILE__)
require "websocket_rails/version"

Gem::Specification.new do |s|
  s.name         = "websocket-rails"
  s.summary      = "Plug and play websocket support for ruby on rails. Includes event router for mapping javascript events to controller actions."
  s.description  = "Seamless Ruby on Rails websocket integration."
  s.homepage     = "http://websocket-rails.github.io"
  s.version      = WebsocketRails::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = [ "Dan Knox", "Rory Low", "Three Dot Loft LLC" ]
  s.email        = [ "dknox@threedotloft.com", "rory@threedotloft.com" ]
  s.license      = "MIT"

  s.rubyforge_project = "websocket-rails"

  s.files        = Dir["{lib,spec}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.md", "CHANGELOG.md"]
  s.require_path = 'lib'

  #TODO: Uncomment the following after publishing the websocket-rails-js gem.
  #s.add_runtime_dependency "websocket-rails-js"
  s.add_runtime_dependency "rails"
  s.add_runtime_dependency "rack"
  s.add_runtime_dependency "faye-websocket"
  s.add_runtime_dependency "eventmachine"
  s.add_runtime_dependency "thin"
  s.add_runtime_dependency "redis"
  s.add_runtime_dependency "hiredis"
  s.add_runtime_dependency "em-synchrony"
  s.add_runtime_dependency "redis-objects"
  s.add_runtime_dependency "uuidtools"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-rails", "~> 2.14.0"
  s.add_development_dependency 'rspec-matchers-matchers'

  s.post_install_message = "Welcome to WebsocketRails v#{WebsocketRails::VERSION}!"

end
