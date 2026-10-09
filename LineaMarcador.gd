tool
extends PathFollow

# Dibuja la raya (de salida o de llegada) sobre la pista.
#
# ARREGLO - antes, cada vez que se abria el editor se agregaba OTRA raya
# y se guardaba en la escena: se juntaron 164 rayas de salida y 165 de
# llegada, una encima de otra (peso inutil para la laptop). Ahora la raya
# se arma una sola vez, NO se guarda en la escena, y al abrir la escena
# se borran todas las copias viejas. Para limpiarlas del archivo basta
# con abrir PistaDeCarrera y guardar (Ctrl+S).

export var textura: Texture setget set_textura
export var ancho_pista = 12.0 setget set_ancho_pista
export var grosor_linea = 1.0 setget set_grosor_linea

func _ready():
	construir_linea()

func set_textura(valor):
	textura = valor
	if is_inside_tree():
		construir_linea()

func set_ancho_pista(valor):
	ancho_pista = valor
	if is_inside_tree():
		construir_linea()

func set_grosor_linea(valor):
	grosor_linea = valor
	if is_inside_tree():
		construir_linea()

func construir_linea():
	# Borra todas las rayas que haya (la de antes y las copias viejas).
	for hijo in get_children():
		if hijo is MeshInstance and hijo.name.begins_with("LineaVisual"):
			remove_child(hijo)
			hijo.queue_free()

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
	# Sin "owner": la raya se arma sola al abrir, no se guarda en la escena.
	add_child(instancia)
