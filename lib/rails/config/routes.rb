Rails.application.routes.draw do
  if WebsocketRails.stage?
    match "/websocket", :to => WebsocketRails::ConnectionManager.new
    #reject all path after
    #match ':controller/:action/*any' , :to => WebsocketRails::WtfHandler.new ?  
  end
end 
