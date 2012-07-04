# WebsocketRails Change Log

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
