# WebsocketRails Change Log

## Version 0.7.0

March 14 2014

* Add verification of parsing results in Event. (Prevents a possible
  denial of service attack when sending improperly formatted but valid
  JSON. Thanks to @maharifu

* Support HTTP streaming for Internet Explorer versions 8+ by using
  XDomainRequest - Thanks to @lkol

* Added a possibility to set channel success and failure callbacks on
  subscribe. - Thanks to @lkol

* Rescue symbolizing of channel names. fixes #166 - Thanks to @KazW

* Refactor *.coffee files. Add reconnect() method. - Thanks to @jtomaszewski

* Add Channel tokens to prevent unauthorized subscriptions to channels.
  Thanks - @moaa and @elthariel

* Fixed a bug where a newline was being outputted in the log regardless of log level - Thanks to @markmalek

* Properly handle WSS and WS protocols in the JavaScript client - Thanks
  to @markee

* Defer #on_open to EM.next_tick. fixes #135 - Thanks to @moaa

* Add subscriber Join/Part events for channels - Thanks to @moaa

* Convert controller's `action_name` to a string to get AbstractController::Callbacks (`before_action`) working properly [fixes #150] - Thanks to @Pitr

## Version 0.6.2

September 8 2013

* Updated Dispatcher#broadcast_message to work with the new
ConnectionManager connections hash. - Thanks to @Frustrate @moaa

## Version 0.6.1

September 6 2013

* Fixed the loading of event routes when launched in the production
environment.

## Version 0.6.0

September 3 2013

* Added the UserManager accessible through the `WebsocketRails.users`
method. This allows for triggering events on individual logged in users
from anywhere inside of your application without the need to create a
channel for that user.

## Version 0.5.0

September 2 2013

* Use window.location.protocol to choose between ws:// and wss://
shcheme. - Thanks to @depili
* Override ConnectionManager#inspect to clean up the output from `rake
routes`
* Added a basic Global UserManager for triggering events on specific users
from anywhere inside your app without creating a dedicated user channel.
* Deprecate the old controller observer system and implement full Rails
AbstractController::Callbacks support. - Thanks to @pitr
* Reload the events.rb event route file each time an event is fired. -
Thanks to @moaa
* Separated the event route file and WebsocketRails configuration files.
The events.rb now lives in `config/events.rb`. The configuration should
remain in an initializer located at `config/initializers/websocket_rails.rb`. - Thanks to @moaa

## Version 0.4.9

July 9 2013

* Updated JavaScript client to properly keep track of the connection state.
* Added .connection_stale() function to the JavaScript client for easily checking connection state.

## Version 0.4.8

July 6 2013

* Fix error with class reloading in development with Rails 4
* Added `connection.close!` method to allow for manually disconnecting users from a WebsocketRails controller.
* Add a way to unsubscribe from channels via the JavaScript client. - Thanks to @Oxynum
* Fix handling of `on_error` event in the JavaScript client. - Thanks to @imton

## Version 0.4.7

June 6 2013

* Fix observer system - Thanks to @pitr
* Fix spelling mistake in ConnectionAdapters#inspect - Thanks to
@bmxpert1
* Prevent duplicate events from being triggered when events are added
directly to Redis from an outside process. - Thanks to @moaa
* Only log event data if it is a Hash or String to drastically reduce
the log file size. - Thanks to @florianguenther
* Fix the intermittent uninitialized constant
"WebsocketRails::InternalEvents" error in development. - Thanks to
@DarkSwoop

## Version 0.4.6

May 9 2013

* Manually load the Faye::WebSocket Thin adapter to support the latest
version of the Faye::WebSocket gem. - Thanks to @Traxmaxx

## Version 0.4.5

May 5 2013

* Fix controller class reloading in development. - Thanks to @florianguenther

## Version 0.4.4

April 28 2013

* Remove existing subscribers from a channel when making it private to
eliminate the potential for malicious users to eavesdrop on private
channels. Addresses issue #72.
* Prevent the server from crashing when receiving an uploaded file.
Addresses issue #68.
* Allow custom routes for the WebSocket server. Users of are
no longer forced to use the `/websocket` route. - Thanks to @Cominch

## Version 0.4.3

March 12 2013

* Change the log output in Channel#trigger_event. Fixes issue #61.
* Cancel the ping timer when removing disconnecting a Connection.
* Fix uninitialized constant WebsocketRails::Internal controller error.

## Version 0.4.2

March 1 2013

* Check to make sure ActiveRecord is defined before calling
ActiveRecord::RecordInvalid in Dispatcher. Fixes issue #54. - Thanks to
@nessche

## Version 0.4.1

February 28 2013

* Fix bug in ControllerFactory#reload! that prevented the handling of
internal events when running in the Development environment. Fixes issue #50. - Thanks to @nessche

* Only reload controller classes when Rails config.cache_classes is set
to false instead of always reloading when in the Rails development
environment. This better respects the Rails configuration options.
Addresses issue #51. - Thanks to @ngauthier

* Update the Rails engine to handle the new Rails 4 route path. Checks
the Rails version and adds the correct path for the routes file. Fixes
issue #49. - Thanks to @sgerrand

## Version 0.4.0

February 27 2013

__There have been a few breaking changes in the public API since the
last release. Please review the list below and consult the Wiki for more
information regarding the usage of the new features.__

* Controller instances no longer persist between events that are
  triggered. Each event is processed by a new controller instance,
similar to a standard Rails request. Since you can no longer use
instance variables to temporarily persist data between events, there is
a new Controller Data Store that can be used for this purpose. This
change addresses issue #31.

* The original DataStore class has been deprecated. In it's place are
  the new Controller Data Store and Connection Data Store. As mentioned
above, the Controller Data Store can be used to persist data between
events in much the same way that you would use instance variables. The
Connection Data Store acts like the Rails session store. Use it to store
data private to a connection. Data in the Connection Data Store can be
accessed from any controller. Check out the Wiki for more information on
both.

* The `websocket_rails.reload_controllers` event has been deprecated.
  The new Controller instantiation model allows for automatic controller
class reloading while in the development environment. You no longer
need to trigger an event to pick up code changes in controllers while
connections are active.

* Real logging support has _finally_ been implemented. Check out the
  configuration WIki for more information on the various logging options
available.

## Version 0.3.0

February 6 2013

* Extend the event router DSL to accept routes similar to the routes.rb
  shorthand `controller#action`. - Thanks to @nessche.

* Add a custom RSpec matcher suite for verifying event routes
  and easily asserting that WebsocketRails controller actions are
  triggering  events correctly. - Also thanks to @nessche.

* Fix fiber yielded across threads bug when running in standalone mode
  by disabling Thin threaded mode as default option.

## Version 0.2.1

January 29 2013

* Fix default redis driver issue that was causing problems when using
  redis while event machine was not running.

* Fix undefined data store value issue. Thanks to @burninggramma.

## Version 0.2.0

November 25 2012

* Add standalone server mode to support non event machine
based web servers.

## Version 0.1.9

November 19 2012

* Fix bug that crashed the server when receiving badly formed messages
  through an open websocket. Fixes issue #27.

* Add support for communication between multiple server instances and
  background jobs. Solves scaling problems discussed in issue #21.

* Fixed client_disconnected event firing twice - Thanks to
  @nickdesaulniers

## Version 0.1.8

July 18 2012

* Fix bug in Channel#trigger preventing the data from coming through
  properly.

## Version 0.1.7

July 17 2012

* Fixed botched release of 0.1.6
* Reorganized directory structure

## Version 0.1.6

July 17 2012

* Added private channel support - Thanks to @MhdSyrwan
* Added DSL method for marking channels as private.
* Added support for attaching success and failure callbacks to triggered
  events on the JavaScript client.
* Fixed JSON parsing bug in HTTP streaming client when multiple events
  were received together.
* Added connection keepalive ping/pong timers to ensure clients do not
  disconnect automatically. Ensures HTTP streaming works well on Heroku.
* Removed the requirement of using the thin-socketrails executable. The
  executable will be removed entirely in the next release.
* Added Jasmine specs for CoffeeScript client.
* Exceptions triggered in controller actions are now serialized and
  passed to the failure callback on the client that triggered the
  action.
* Events triggered on the client before the connection is fully
  established are now queued and sent in bulk once the connection is
  ready.

## Version 0.1.5

July 3 2012

* Fixed bug in JavaScript client that caused Channels not to dispatch
  correctly.
* Rewrote JavaScript client in CoffeeScript.
* Created project Wiki

## Version 0.1.4

June 30 2012

* Added channel support
* Fix the JavaScript client to work on the iPad - Thanks to @adamkittelson
* Add an event queue on the connection object to allow for queueing up
  multiple events before flushing to the client.
* Add generator for creating the events.rb intializer and requiring the
  client in the application.js sprockets manifest file.

## Version 0.1.3

June 22 2012

* Added support for namespaced events.
* Improved event machine scheduling for action processing.
* Made a client's connection ID private.
* Bugfixes in the JavaScript event dispatchers.

## Version 0.1.2

June 10 2012

* Added streaming HTTP support as a fallback from WebSockets.
* Added example JavaScript event dispatchers.

## Version 0.1.1

June 2 2012

* Created project home page.
* Improved test coverage and cleaned up the internals.

## Version 0.1.0

April 14 2012

* Complete project rewrite.
* Removed websocket-rack dependency.
* Enhanced documentation.
* Added event observers in WebsocketRail Controllers.
* First stable release!
