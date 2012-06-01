class ChatController < WebsocketRails::BaseController

  observe {
    if data_store.each_user.count > 0
      puts 'it worked'
    end
    
    if message_counter > 10
      puts 'message counter needs to be dumped'
      self.message_counter = 0
    end
  }
  
  observe(:new_message) {
    puts "message observer fired for #{message}"
  }
  
  attr_accessor :message_counter

  def initialize_session
    # perform application setup here
    @message_counter = 0
  end
  
  def client_connected
    # do something when a client connects
  end
  
  def new_message
    puts "Message from UID: #{client_id}\n"
    @message_counter += 1
    broadcast_message :new_message, message
  end
  
  def new_user
    puts "storing user in data store\n"
    data_store[:user] = message
    broadcast_user_list
  end
  
  def change_username
    data_store[:user] = message
    broadcast_user_list
  end
  
  def delete_user
    data_store.remove_client
    broadcast_user_list
  end
  
  def broadcast_user_list
    users = data_store.each_user
    puts "broadcasting user list: #{users}\n"
    broadcast_message :user_list, users
  end
  
end
