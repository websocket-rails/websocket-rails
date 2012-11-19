$:.push File.expand_path("../lib", __FILE__)
require "websocket_rails/version"

Gem::Specification.new do |s|
  s.name         = "websocket-rails"
  s.summary      = "Plug and play websocket support for ruby on rails. Includes event router for mapping javascript events to controller actions."
  s.description  = "Seamless Ruby on Rails websocket integration."
  s.homepage     = "http://danknox.github.com/websocket-rails/"
  s.version      = WebsocketRails::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = [ "Dan Knox", "Kyle Whalen", "Three Dot Loft LLC" ]
  s.email        = [ "dknox@threedotloft.com" ]

  s.rubyforge_project = "websocket-rails"

  s.files        = Dir["{lib,bin,spec}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.md", "CHANGELOG.md"]
  s.executables  = ['thin-socketrails']
  s.require_path = 'lib'

  s.add_dependency "rails"
  s.add_dependency "rack"
  s.add_dependency "faye-websocket"
  s.add_dependency "thin"
  s.add_dependency "redis"
  s.add_dependency "hiredis"
  s.add_dependency "em-synchrony"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-rails"
end
