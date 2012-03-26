$:.push File.expand_path("../lib", __FILE__)
require "websocket_rails/version"

Gem::Specification.new do |s|
  s.name         = "websocket-rails"
  s.summary      = "Plug and play websocket support for ruby on rails. Includes event router for mapping javascript events to controller actions."
  s.description  = "Seamless Ruby on Rails websocket integration."
  s.files        = Dir["{lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version      = WebsocketRails::VERSION
  s.platform     = Gem::Platform::RUBY
  s.authors      = [ "Dan Knox", "Three Dot Loft LLC" ]
  s.email        = [ "dknox@threedotloft.com" ]
  
  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
  
  s.add_dependency "rack"
  s.add_dependency "em-websocket", '~> 0.3.6'
  s.add_dependency "websocket-rack"
  s.add_dependency "thin"
  s.add_dependency "rake"
end