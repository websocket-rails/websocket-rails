# Websocket-Rails

[![Build Status](https://secure.travis-ci.org/DanKnox/websocket-rails.png)](https://secure.travis-ci.org/DanKnox/websocket-rails)

If you haven't done so yet, check out the [Project Page](http://danknox.github.com/websocket-rails/) to get a feel for the project direction. Feedback is very much appreciated. Post an issue on the issue tracker or [shoot us an email](mailto://support@threedotloft.com) to give us your thoughts.

## Update July 17 2012

We just released a new version containing significant new functionality. 
We will be updating the documentation and wiki guides to cover it all over the next day
or two but check out the
[CHANGELOG](https://github.com/DanKnox/websocket-rails/blob/master/CHANGELOG.md) to get an early preview.

**Do not use version `0.1.6`. If you had updated your gem version this
morning please update again to `0.1.7`.

## Overview

Start treating client side events as first class citizens inside your
Rails application with a built in WebSocket server. Sure, WebSockets
aren't quite universal yet. That's why we also support streaming HTTP.
Oh, and if you don't mind running a separate process, you can support
just about any browser with Flash sockets.

## Respond Quicker with Socket Events

Map events to controller actions using an Event Router.

````ruby
WebsocketRails::EventMap.describe do
  namespace :tasks do
    subscribe :create, :to => TaskController, :with_method => :create
  end
end
````

Trigger events using our JavaScript client.

````javascript
var task = {
  name: 'Start taking advantage of WebSockets',
  completed: false
}
dispatcher = new WebSocketRails('localhost:3000/websocket');
dispatcher.trigger('tasks.create', task);
````

Handle events in your controller.

````ruby
class TaskController < WebsocketRails::BaseController
  def create
    # The `message` method contains the data received
    task = Task.new message
    if task.save
      send_message :create_success, task, :namespace => :tasks
    else
      send_message :create_fail, task, :namespace => :tasks
    end
  end
end
````

Receive the response in the client.

````javascript
dispatcher.bind('tasks.create_successful', function(task) {
  console.log('successfully created ' + task.name);
});
````

## Channel Support

Keep your users up to date without waiting for them to refresh the page.
Subscribe them to a channel and update it from wherever you please.

Tune in on the client side.

````javascript
channel = dispatcher.subscribe('posts');
channel.bind('new', function(post) {
  console.log('a new post about '+post.title+' arrived!');
});
````

Broadcast to the channel from anywhere inside your Rails application. An
existing controller, a model, a background job, or a new WebsocketRails
controller.

````ruby
latest_post = Post.latest
WebsocketRails[:posts].trigger('new', latest_post)
````

## Installation and Usage Guides

Check out the [Example Application](https://github.com/DanKnox/websocket-rails-Example-Project) for an example implementation.

* [Installation
  Guide](https://github.com/DanKnox/websocket-rails/wiki/Installation-and-Setup)
* [Event
  Router](https://github.com/DanKnox/websocket-rails/wiki/The-Event-Router)
* [WebsocketRails Controllers](https://github.com/DanKnox/websocket-rails/wiki/WebsocketRails Controllers)
* [Using the JavaScript
  Client](https://github.com/DanKnox/websocket-rails/wiki/Using-the-JavaScript-Client)
* [Using
  Channels](https://github.com/DanKnox/websocket-rails/wiki/Working-with-Channels)
* [The
  DataStore](https://github.com/DanKnox/websocket-rails/wiki/Using-the-DataStore)

## Development

This gem is created and maintained by Dan Knox and Kyle Whalen under the MIT License.

Brought to you by:

Three Dot Loft LLC
