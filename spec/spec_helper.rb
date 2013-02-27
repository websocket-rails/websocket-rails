ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start if ENV["COVERAGE"]

require File.expand_path("../../spec/dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'thin'

$:.push File.expand_path("../../lib", __FILE__)
require 'websocket-rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["./spec/support/**/*.rb"].each {|f| require f}
require 'websocket_rails/spec_helpers'
require 'rspec-matchers-matchers'

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.include WebsocketRails::HelperMethods

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.before(:each) do
    WebsocketRails.config.logger = Logger.new(StringIO.new)
  end

end
