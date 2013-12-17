window.helpers =
  startConnection: (dispatcher, connection_id = 1) ->
    dispatcher.new_message ['client_connected', {data: ""}, {connection_id: connection_id}]


# live reload
document.write '<script src="http://localhost:35729/livereload.js?host=localhost"></script>'
