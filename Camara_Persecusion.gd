tool
extends Spatial

export(NodePath) var trackpath_path = NodePath("../TrackPath")
export var offset_interior = 0.0 setget set_offset_interior
export var offset_exterior = 120.0 setget set_offset_exterior
export var segmentos = 200
export var altura = 0.05
export var texturas_por_vuelta = 20.0 setget set_texturas_por_vuelta
export var repeticiones_ancho = 6.0 setget set_repeticiones_ancho
export(Texture) var textura setget set_textura

func _ready():
	_reconstruir()

func set_offset_interior(valor):
	offset_interior = valor
	_reconstruir()

func set_offset_exterior(valor):
	offset_exterior = valor
	_reconstruir()

func set_texturas_por_vuelta(valor):
	texturas_por_vuelta = valor
	_reconstruir()

func set_repeticiones_ancho(valor):
	repeticiones_ancho = valor
	_reconstruir()

func set_textura(valor):
	textura = valor
	_reconstruir()

func _limpiar_anterior():
	for hijo in get_children():
		if hijo.name.begins_with("Superficie"):
			remove_child(hijo)
			hijo.free()

func _reconstruir():
	var trackpath = get_node_or_null(trackpath_path)
	if trackpath == null or trackpath.curve == null:
		return
	var curve = trackpath.curve
	var largo_total = curve.get_baked_length()
	if largo_total <= 0:
		return

	_limpiar_anterior()

	var puntos = []
	for i in range(segmentos + 1):
		var idx = i % segmentos
		var dist = largo_total * float(idx) / float(segmentos)
		var punto_local = curve.interpolate_baked(dist)
		puntos.append(trackpath.to_global(punto_local))

	var centro_oval = Vector3.ZERO
	for i in range(segmentos):
		centro_oval += puntos[i]
	centro_oval /= segmentos

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in range(puntos.size() - 1):
		var punto = puntos[i]
		var punto_sig = puntos[i + 1]

		var tangente = (punto_sig - punto).normalized()
		var lateral = Vector3(tangente.z, 0, -tangente.x)

		var hacia_afuera = punto - centro_oval
		hacia_afuera.y = 0
		if lateral.dot(hacia_afuera) < 0:
			lateral = -lateral

		var punto_interior = to_local(punto + lateral * offset_interior)
		var punto_exterior = to_local(punto + lateral * offset_exterior)
		punto_interior.y += altura
		punto_exterior.y += altura

		var v_uv = float(i) * texturas_por_vuelta / float(segmentos)

		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(0, v_uv))
		st.add_vertex(punto_interior)

		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(repeticiones_ancho, v_uv))
		st.add_vertex(punto_exterior)

	var mesh = st.commit()

	var superficie = MeshInstance.new()
	superficie.name = "Superficie"
	superficie.mesh = mesh

	if textura != null:
		var mat = SpatialMaterial.new()
		mat.albedo_texture = textura
		mat.flags_unshaded = true
		mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
		superficie.material_override = mat

	add_child(superficie)
	if Engine.editor_hint and get_tree() and get_tree().edited_scene_root:
		superficie.owner = get_tree().edited_scene_root
