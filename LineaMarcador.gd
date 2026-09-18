tool
extends PathFollow

export var textura: Texture setget set_textura
export var ancho_pista = 12.0 setget set_ancho_pista
export var grosor_linea = 1.0 setget set_grosor_linea

func _ready():
	construir_linea()

func set_textura(valor):
	textura = valor
	construir_linea()

func set_ancho_pista(valor):
	ancho_pista = valor
	construir_linea()

func set_grosor_linea(valor):
	grosor_linea = valor
	construir_linea()

func construir_linea():
	var anterior = get_node_or_null("LineaVisual")
	if anterior:
		anterior.queue_free()

	var malla = PlaneMesh.new()
	malla.size = Vector2(ancho_pista, grosor_linea)

	var material = SpatialMaterial.new()
	if textura:
		material.albedo_texture = textura

	var instancia = MeshInstance.new()
	instancia.name = "LineaVisual"
	instancia.mesh = malla
	instancia.material_override = material
	instancia.translation = Vector3(0, 0.05, 0)
	add_child(instancia)
	if Engine.editor_hint and get_tree() and get_tree().edited_scene_root:
		instancia.owner = get_tree().edited_scene_root
