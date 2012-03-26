# Websocket-Rails

Plug and play websocket support for ruby on rails. Includes event router for mapping javascript events to controller actions and basic javascript client.

## Installation

Add the gem to your Gemfile

*important*
Thin is the only web server currently supported.

````ruby
gem 'websocket-ruby'
````

Map websocket events to controller actions by creating an `events.rb` file in your app/config/initializers directory

````ruby
# app/config/initializers

WebsocketRails::Dispatcher.describe_events do
  subscribe :client_connected, to: ChatController, with_method: :client_connected
  subscribe :new_message, to: ChatController, with_method: :new_message
  subscribe :new_user, to: ChatController, with_method: :new_user
  subscribe :change_username, to: ChatController, with_method: :change_username
  subscribe :client_disconnected, to: ChatController, with_method: :delete_user
end
````

The `subscribe` method takes the event name as the first argument then a hash where :to is the Controller class and :with_method is the action to execute.

Web socket connections can be opening by hitting the /websocket route. You can connect using the following javascript. Replace the port with the port that your webserver is running on.

````javascript
var conn = new WebSocket("ws://localhost:8090/websocket")
conn.onopen = function(evt) {
	dispatcher.trigger('new_user',current_user)
}

conn.onmessage = function(evt) {
	var data = JSON.parse(evt.data),
		event_name = data[0],
		message = data[1];
	console.log(data)
}
````

I will be posting a basic javascript event dispatcher soon.

## Controllers

The Websocket::BaseController class provides methods for working with the websocket connection. Make sure you extend this class for controllers that you are using. The two most important methods are `send_data` and `broadcast_data`. The `send_data` method sends a message to the client that initiated this event, the `broadcast_data` method broadcasts messages to all connected clients. Both methods take two arguments, the event name to trigger on the client, and the message that accompanies it.

````ruby
message = {:message => 'this is a message'}
broadcast_message :event_name, message
send_message :event_name, message
````

The message can be a string, hash, or array. The message is serialized as JSON before being sent to the client.

TODO: Show examples of using these methods.

## Data Store

TODO: write documentation for the data store

## Development

This gem is created and maintained by Dan Knox under the MIT License.

Brought to you by
Three Dot Loft LLC