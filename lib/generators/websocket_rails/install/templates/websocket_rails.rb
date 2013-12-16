WebsocketRails.setup do |config|

  # Uncomment to override the default log level. The log level can be
  # any of the standard Logger log levels. By default it will mirror the
  # current Rails environment log level.
  # config.log_level = :debug

  # Uncomment to change the default log file path.
  # config.log_path = "#{Rails.root}/log/websocket_rails.log"

  # Set to true if you wish to log the internal websocket_rails events
  # such as the keepalive `websocket_rails.ping` event.
  # config.log_internal_events = false

  # Change to true to enable standalone server mode
  # Start the standalone server with rake websocket_rails:start_server
  # * Requires Redis
  config.standalone = false

  # Change to true to enable channel synchronization between
  # multiple server instances.
  # * Requires Redis.
  config.synchronize = false

  # Prevent Thin from daemonizing (default is true)
  # config.daemonize = false

  # Uncomment and edit to point to a different redis instance.
  # Will not be used unless standalone or synchronization mode
  # is enabled.
  # config.redis_options = {:host => 'localhost', :port => '6379'}

  # By default, all subscribers in to a channel will be removed
  # when that channel is made private. If you don't wish active
  # subscribers to be removed from a previously public channel
  # when making it private, set the following to true.
  # config.keep_subscribers_when_private = false

  # Set to true if you wish to broadcast channel subscriber_join and
  # subscriber_part events. All subscribers of a channel will be 
  # notified when other clients join and part the channel. If you are
  # using the UserManager, the current_user object will be sent along
  # with the event.
  # config.broadcast_subscriber_events = true

  # Used as the key for the WebsocketRails.users Hash. This method
  # will be called on the `current_user` object in your controller
  # if one exists. If `current_user` does not exist or does not
  # respond to the identifier, the key will default to `connection.id`
  # config.user_identifier = :id

  # Uncomment and change this option to override the class associated
  # with your `current_user` object. This class will be used when
  # synchronization is enabled and you trigger events from background
  # jobs using the WebsocketRails.users UserManager.
  # config.user_class = User

  # Supporting HTTP streaming on Internet Explorer versions 8 & 9
  # requires CORS to be enabled for GET "/websocket" request.
  # List here the origin domains allowed to perform the request.
  # config.allowed_origins = ['http://localhost:3000']

end
