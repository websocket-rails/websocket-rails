WebsocketRails::EventMap.describe do
  subscribe :client_connected, :to => ChatController, :with_method => :client_connected
  subscribe :new_message, :to => ChatController, :with_method => :new_message
  subscribe :new_user, :to => ChatController, :with_method => :new_user
  subscribe :change_username, :to => ChatController, :with_method => :change_username
  subscribe :client_disconnected, :to => ChatController, :with_method => :delete_user
end
