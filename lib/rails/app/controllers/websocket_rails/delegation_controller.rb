module WebsocketRails
  # This class provides a means for accessing the Rails
  # controller helper methods defined in a user's application
  # or in gems that the user has added to the project.
  #
  # Each active connection creates and stores it's own
  # instance with the correct @_request and @_env objects
  # set. WebsocketRails::BaseController sends missing
  # methods to the active connection's delegation controller
  # instance.
  class DelegationController < ApplicationController
  end
end
