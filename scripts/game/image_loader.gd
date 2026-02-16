class_name ImageLoader extends RefCounted

var http: HTTPRequest

func load_http(url: String, callback: Callable):
	http = HTTPRequest.new()
	# Se debe añadir a un árbol para que funcione; lo haremos desde un nodo
	# Alternativa: usar un nodo global. Aquí simplificamos asumiendo que se llama desde un nodo.
	var tree = Engine.get_main_loop()
	tree.root.add_child(http)
	http.request_completed.connect(func(result, response_code, headers, body):
		if result == HTTPRequest.RESULT_SUCCESS:
			var image = Image.new()
			var error = image.load_png_from_buffer(body)
			if error != OK:
				error = image.load_jpg_from_buffer(body)
			if error == OK:
				var texture = ImageTexture.create_from_image(image)
				callback.call(texture)
			else:
				push_error("No se pudo cargar la imagen desde URL")
		else:
			push_error("Error descargando imagen")
		http.queue_free()
	)
	http.request(url)
