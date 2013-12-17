Rails.application.routes.draw do
  if Rails.version >= '4.0.0'
    get "/websocket", :to => WebsocketRails.connection_manager
  else
    get "/websocket", :to => WebsocketRails.connection_manager
  end
end
