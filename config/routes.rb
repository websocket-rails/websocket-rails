Rails.application.routes.draw do
  match "/websocket", :to => WebsocketRails::ConnectionManager.new
end
