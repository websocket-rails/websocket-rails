# WebsocketRails Change Log

## Version 0.2.1

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
