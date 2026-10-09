tool
extends "res://Barandas.gd"

# ============================================================
# BARANDAS DE LA PISTA DE ARENA (la naranja de adentro)
# ============================================================
# Usa el mismo dibujo de tubos de Barandas.gd (mismos colores,
# grosores y malla), pero sigue la forma de la pista de arena
# (el nodo MeshInstance) en vez de TrackPath.
#   - Lado de adentro (hacia el jardin): cuello de ganso.
#   - Lado de afuera (hacia la grama): dos tubos con malla.
# Las dos miran hacia la arena.
# Este script solo construye: NO mueve ningun nodo.
# ============================================================

export(NodePath) var arena_path = NodePath("../MeshInstance") setget set_arena_path
# Medidas del dibujo de la arena, en sus propias unidades
# (antes de la escala 0.85 que tiene el nodo MeshInstance)
export var mitad_recta_arena = 201.0 setget set_mitad_recta_arena
export var radio_interior_arena = 159.0 setget set_radio_interior_arena
export var radio_exterior_arena = 329.0 setget set_radio_exterior_arena
# Cuanto se meten las barandas dentro de la arena (mas alto = mas adentro de la arena)
export var retiro_del_borde = 0.5 setget set_retiro_del_borde
export var poner_baranda_interior = true setget set_poner_baranda_interior
export var poner_baranda_exterior = true setget set_poner_baranda_exterior


func _init():
	altura_baranda = 5.0


func set_arena_path(valor):
	arena_path = valor
	_reconstruir()

func set_mitad_recta_arena(valor):
	mitad_recta_arena = valor
	_reconstruir()

func set_radio_interior_arena(valor):
	radio_interior_arena = valor
	_reconstruir()

func set_radio_exterior_arena(valor):
	radio_exterior_arena = valor
	_reconstruir()

func set_retiro_del_borde(valor):
	retiro_del_borde = valor
	_reconstruir()

func set_poner_baranda_interior(valor):
	poner_baranda_interior = valor
	_reconstruir()

func set_poner_baranda_exterior(valor):
	poner_baranda_exterior = valor
	_reconstruir()


func _reconstruir():
	if not is_inside_tree():
		return
	var arena = get_node_or_null(arena_path)
	if arena == null:
		return
	_limpiar_barandas_anteriores()
	var mats = _materiales_tubo()
	if poner_baranda_interior:
		_baranda_arena(arena, radio_interior_arena, 1.0, "cuello", mats, "Baranda_Interior_Arena")
	if poner_baranda_exterior:
		_baranda_arena(arena, radio_exterior_arena, -1.0, "tubos", mats, "Baranda_Exterior_Arena")


func _baranda_arena(arena, radio, signo, estilo, mats, nombre):
	var xf = arena.global_transform
	var escala = xf.basis.x.length()
	if escala <= 0.0 or radio <= 0.0:
		return
	var recta = 2.0 * mitad_recta_arena
	var curva = PI * radio
	var perimetro = 2.0 * recta + 2.0 * curva
	var n = int(perimetro * escala / max(separacion_postes_tubo, 1.0))
	if n < 4:
		return
	var inv = global_transform.basis.inverse()
	var pts = []
	var dirs = []
	for i in range(n):
		var d = perimetro * float(i) / float(n)
		var pn = _punto_estadio(d, radio, recta, curva)
		var dir_g = xf.basis.xform(pn[1] * signo)
		dir_g.y = 0
		dir_g = dir_g.normalized()
		var p_g = xf.xform(pn[0]) + dir_g * retiro_del_borde
		pts.append(to_local(p_g))
		dirs.append(inv.xform(dir_g).normalized())
	_armar_tubos(pts, dirs, altura_baranda, estilo, mats, nombre)


# Punto del ovalo de la arena y su direccion hacia afuera del ovalo
func _punto_estadio(d, r, recta, curva):
	var m = mitad_recta_arena
	if d < recta:
		return [Vector3(-m + d, 0, -r), Vector3(0, 0, -1)]
	d -= recta
	if d < curva:
		var t = d / r
		return [Vector3(m + r * sin(t), 0, -r * cos(t)), Vector3(sin(t), 0, -cos(t))]
	d -= curva
	if d < recta:
		return [Vector3(m - d, 0, r), Vector3(0, 0, 1)]
	d -= recta
	var t2 = d / r
	return [Vector3(-m - r * sin(t2), 0, r * cos(t2)), Vector3(-sin(t2), 0, cos(t2))]
