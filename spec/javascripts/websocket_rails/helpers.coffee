window.helpers = 
  startConnection: (dispatcher, connection_id = 1) ->
    message =
      data:
        connection_id: connection_id
    dispatcher.new_message [['client_connected', message]]
