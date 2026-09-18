extends Camera

export(NodePath) var objetivo_node
export var altura = 40.0
export var desplazamiento_x = 0.0
export var desplazamiento_z = 0.0
var objetivo: Spatial

func _ready():
	if objetivo_node:
		objetivo = get_node(objetivo_node)

func _process(delta):
	if objetivo:
		global_transform.origin = objetivo.global_transform.origin + Vector3(desplazamiento_x, altura, desplazamiento_z)
		rotation_degrees = Vector3(-90, 0, 0)
