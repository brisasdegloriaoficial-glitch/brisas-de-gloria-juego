extends Camera

export(NodePath) var objetivo_node
export var altura = 160.0 setget set_altura
export var altura_minima = 25.0
export var altura_maxima = 350.0
export var velocidad_zoom = 0.4
export var velocidad_zoom_rueda = 40.0
export var suavidad_zoom = 8.0

var objetivo: Spatial
var _toques = {}
var _distancia_anterior = 0.0
var _altura_objetivo = 160.0


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	if objetivo_node:
		objetivo = get_node(objetivo_node)
	altura = clamp(altura, altura_minima, altura_maxima)
	_altura_objetivo = altura
	_colocar_camara()


func set_altura(valor):
	altura = clamp(valor, altura_minima, altura_maxima)
	_altura_objetivo = valor


func _colocar_camara():
	if objetivo:
		global_transform.origin = objetivo.global_transform.origin + Vector3(0, altura, 0)
		rotation_degrees = Vector3(-90, 0, 0)


func _process(delta):
	altura = lerp(altura, _altura_objetivo, min(suavidad_zoom * delta, 1.0))
	_colocar_camara()


func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_toques[event.index] = event.position
		else:
			_toques.erase(event.index)
			_distancia_anterior = 0.0

	elif event is InputEventScreenDrag:
		_toques[event.index] = event.position

		if _toques.size() == 2:
			var puntos = _toques.values()
			var distancia_actual = puntos[0].distance_to(puntos[1])

			if _distancia_anterior > 0.0:
				var diferencia = distancia_actual - _distancia_anterior
				_altura_objetivo += diferencia * velocidad_zoom
				_altura_objetivo = clamp(_altura_objetivo, altura_minima, altura_maxima)

			_distancia_anterior = distancia_actual

	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				_altura_objetivo -= velocidad_zoom_rueda
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_altura_objetivo += velocidad_zoom_rueda
			_altura_objetivo = clamp(_altura_objetivo, altura_minima, altura_maxima)
