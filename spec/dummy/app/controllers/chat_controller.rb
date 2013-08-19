class ChatController < WebsocketRails::BaseController

  before_action do
    if message_counter > 10
      self.message_counter = 0
    end
  end

  before_action :only => :new_message do
    true
  end

  attr_accessor :message_counter

  def initialize
    # perform application setup here
    @message_counter = 0
  end

  def client_connected
    # do something when a client connects
  end

  def error_occurred
    # do something when an error occurs
  end

  def new_message
    @message_counter += 1
    broadcast_message :new_message, message
  end

  def new_user
    controller_store[:user] = message
    broadcast_user_list
  end

  def change_username
    controller_store[:user] = message
    broadcast_user_list
  end

  def delete_user
    controller_store[:user] = nil
    broadcast_user_list
  end

  def broadcast_user_list
    users = ['user']
    broadcast_message :user_list, users
  end

end
