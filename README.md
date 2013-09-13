# Websocket-Rails

[![Build Status](https://travis-ci.org/websocket-rails/websocket-rails.png?branch=master)](https://travis-ci.org/websocket-rails/websocket-rails)

If you haven't done so yet, check out the [Project
Page](http://websocket-rails.github.io) to get a feel for the project direction. Feedback is very much appreciated. Post an issue on the issue tracker or [shoot us an email](mailto:support@threedotloft.com) to give us your thoughts.

**Find us on IRC #websocket-rails**

Stop by #websocket-rails on freenode if you would like to chat or have any
questions.

## Recent Updates

Check out the [CHANGELOG](https://github.com/websocket-rails/websocket-rails/blob/master/CHANGELOG.md) to find out what's new.

As of version 0.2.0, non event machine based web servers such as Phusion
Passenger are supported through the use of the [Standalone Server Mode](https://github.com/websocket-rails/websocket-rails/wiki/Standalone-Server-Mode).

## Overview

Start treating client side events as first class citizens inside your
Rails application with a built in WebSocket server. Sure, WebSockets
aren't quite universal yet. That's why we also support streaming HTTP.
Oh, and if you don't mind running a separate process, you can support
just about any browser with Flash sockets.

## Installation and Usage Guides

* [Installation
  Guide](https://github.com/websocket-rails/websocket-rails/wiki/Installation-and-Setup)
* [Event
  Router](https://github.com/websocket-rails/websocket-rails/wiki/The-Event-Router)
* [WebsocketRails Controllers](https://github.com/websocket-rails/websocket-rails/wiki/WebsocketRails Controllers)
* [Using the JavaScript
  Client](https://github.com/websocket-rails/websocket-rails/wiki/Using-the-JavaScript-Client)
* [Using
  Channels](https://github.com/websocket-rails/websocket-rails/wiki/Working-with-Channels)
* [Using Private Channels](https://github.com/websocket-rails/websocket-rails/wiki/Using-Private-Channels)
* [The
  DataStore](https://github.com/websocket-rails/websocket-rails/wiki/Using-the-DataStore)
* [Reloading Controllers In Development](https://github.com/websocket-rails/websocket-rails/wiki/Reloading-Controllers-In-Development)
* [Multiple Servers and Background Jobs](https://github.com/websocket-rails/websocket-rails/wiki/Multiple-Servers-and-Background-Jobs)
* [Standalone Server Mode](https://github.com/websocket-rails/websocket-rails/wiki/Standalone-Server-Mode)

## Handle Events With Class

Map events to controller actions using an Event Router.

````ruby
WebsocketRails::EventMap.describe do
  namespace :tasks do
  
    # using a Hash to specify the target
    subscribe :create, :to => TaskController, :with_method => :create
    
    # using the same syntax as routes.rb
    subscribe :update, 'task#update'
    
    # if your controller is not a top-level object
    subscribe :create_admin, :to => Admin::TaskController, :with_method => :create

    subscribe :update_admin, 'admin/task#update'

  end
end
````

Trigger events using our JavaScript client.

````javascript
var task = {
  name: 'Start taking advantage of WebSockets',
  completed: false
}

var dispatcher = new WebSocketRails('localhost:3000/websocket');

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
dispatcher.bind('tasks.create_success', function(task) {
  console.log('successfully created ' + task.name);
});
````

Or just attach success and failure callbacks to your client events.

````javascript
var success = function(task) { console.log("Created: " + task.name); }

var failure = function(task) {
  console.log("Failed to create Product: " + product.name)
}

dispatcher.trigger('products.create', task, success, failure);
````

Then trigger them in your controller:

````ruby
def create
  task = Task.create message
  if task.save
    trigger_success task
  else
    trigger_failure task
  end
end
````

If you're feeling truly lazy, just trigger the failure callback with an
exception.

````ruby
def create
  task = Task.create! message
  trigger_success task # trigger success if the save went alright
end
````

That controller is starting to look pretty clean.

Now in the failure callback on the client we have access to the record
and the errors.

````javascript
var failureCallback = function(task) {
  console.log( task.name );
  console.log( task.errors );
  console.log( "You have " + task.errors.length + " errors." );
}
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
WebsocketRails[:posts].trigger 'new', latest_post
````

## Private Channel Support

Need to restrict access to a particular channel? No problem. We've got
that. 

Private channels give you the ability to authorize a user's
subscription using the authorization mechanism of your choice.

Just tell WebsocketRails which channels you would like to make private by using the `private_channel` method in the Event Router.
Then handle the channel authorization by subscribing to the `websocket_rails.subscribe_private` event.

````ruby
WebsocketRails::EventMap.describe do
  private_channel :secret_posts
  
  namespace :websocket_rails
    subscribe :subscribe_private, :to => AuthorizationController, :with_method => :authorize_channels
  end
```` 

Or you can always mark any channel as private later on.

````ruby
WebsocketRails[:secret_posts].make_private
````

On the client side, you can use the `dispatcher.subscribe_private()`
method to subscribe to a private channel.

Read the [Private Channel Wiki](https://github.com/websocket-rails/websocket-rails/wiki/Using-Private-Channels) for more information on subscribing to private channels from the JavaScript client and handling the authorization in your controller.

## Credit where credit is due

Big thanks to our [contributors](https://github.com/websocket-rails/websocket-rails/graphs/contributors) who have helped keep this project moving.

Special thanks to [@nessche](https://github.com/nessche) who provided the improved routing DSL and RSpec matcher suite.

The `websocket-rails` organization logo was kindly provided by [Uken Games](http://www.uken.com/).

## Development

Please check out the [Development Guide](https://github.com/websocket-rails/websocket-rails/wiki/Development) if you are interested in contributing. It should cover everything you need to get up and running.

## Core Team

The current `websocket-rails` core team consists of the following individuals:

* [@DanKnox](https://github.com/DanKnox)
* [@Pitr](https://github.com/pitr)
* [@moaa](https://github.com/moaa)

New contributors and pull requests are always welcome.
