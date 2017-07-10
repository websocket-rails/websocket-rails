Rails.application.routes.draw do
  if Rails.version >= '4.0.0'
    match "/websocket", :to => WebsocketRails::ConnectionManager.mount, via: [:get, :post]
  else
    match "/websocket", :to => WebsocketRails::ConnectionManager.mount
  end
end
