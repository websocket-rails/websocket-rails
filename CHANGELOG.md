# WebsocketRails Change Log

February 28 2013

## Version 0.4.1

* Fix bug in ControllerFactory#reload! that prevented the handling of
internal events when running in the Development environment. Fixes issue #50. - Thanks to @nessche

* Only reload controller classes when Rails config.cache_classes is set
to false instead of always reloading when in the Rails development
environment. This better respects the Rails configuration options.
Addresses issue #51. - Thanks to @ngauthier

February 27 2013

## Version 0.4.0

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
