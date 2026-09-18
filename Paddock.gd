tool
extends Spatial

# ============================================================
# PADDOCK (corral donde desfilan los caballos antes de la carrera)
# ============================================================
# Ovalo de postes con baranda de dos travesanos (blanco, con dos
# postes en vino tinto marcando la entrada).
#
# El paddock NO sigue a la meta ni a nada: es un lugar fijo. Se
# ubica y se gira a mano en el editor, como las tribunas. El
# script solo construye la estructura, NUNCA mueve el nodo.
#
# La entrada es siempre el mismo tramo del ovalo: el que cierra
# entre el ultimo poste y el primero (indice 0). Para apuntarla
# hacia otro lado, se gira el nodo completo.
#
# ------------------------------------------------------------
# ITERACION 2: DE CIRCULO A OVALO
# ------------------------------------------------------------
# Antes era un circulo perfecto (un solo "radio_paddock"). Ahora
# son dos medidas:
#   Radio Largo -> mitad del ancho, sobre el eje X
#   Radio Corto -> mitad del fondo, sobre el eje Z
# Un paddock real es mas ancho que profundo, tipo 20 x 12.
#
# Los postes se reparten por DISTANCIA REAL a lo largo del ovalo,
# no por angulo. En un circulo da lo mismo, pero en un ovalo
# repartir por angulo apiña los postes en las puntas y los separa
# en los lados largos. Por eso se mide el contorno primero.
#
# El mismo script sirve para el PADDOCK DE VENCEDORES: se crea
# otro nodo, se le asigna este script y se le ponen radios mas
# chicos.
#
# Las piezas se crean sin "owner" a proposito: NO se guardan en el
# archivo de la escena, se regeneran cada vez.
#
# AVISO DE UBICACION: si lo pones sobre el jardin central, acordate
# que Jardin_Central es un bloque de 30 de alto centrado en y=0,
# o sea que su techo esta en y=15. Con el paddock en y=0 queda
# enterrado adentro y no se ve. Sobre el terreno, en cambio, y=0
# esta bien.
# ============================================================

export var radio_largo = 20.0 setget _set_radio_largo
export var radio_corto = 12.0 setget _set_radio_corto
export var cantidad_segmentos = 20 setget _set_cantidad_segmentos
export var segmentos_entrada = 1 setget _set_segmentos_entrada

export var altura_poste = 1.3 setget _set_altura_poste
export var ancho_poste = 0.25 setget _set_ancho_poste

export var alto_baranda_superior = 1.1 setget _set_alto_baranda_superior
export var alto_baranda_inferior = 0.55 setget _set_alto_baranda_inferior
export var grosor_baranda = 0.1 setget _set_grosor_baranda

export var color_poste = Color(1.0, 1.0, 1.0) setget _set_color_poste
export var color_baranda = Color(1.0, 1.0, 1.0) setget _set_color_baranda
export var color_ribete = Color(0.48, 0.08, 0.17) setget _set_color_ribete

export var sin_sombreado = true setget _set_sin_sombreado
export var mostrar_diagnostico = true setget _set_mostrar_diagnostico

var _reconstruccion_pedida = false


# ------------------------------------------------------------
# ARRANQUE
# ------------------------------------------------------------
func _ready():
	_reconstruir()


# ------------------------------------------------------------
# RECONSTRUCCION
# ------------------------------------------------------------
func _pedir_reconstruccion():
	if not is_inside_tree():
		return
	if _reconstruccion_pedida:
		return
	_reconstruccion_pedida = true
	call_deferred("_reconstruir")


func _reconstruir():
	_reconstruccion_pedida = false
	if not is_inside_tree():
		return
	_borrar_lo_construido()
	_construir_paddock()


func _borrar_lo_construido():
	for hijo in get_children():
		if hijo.name.begins_with("Paddock_"):
			remove_child(hijo)
			hijo.queue_free()


# ------------------------------------------------------------
# GEOMETRIA DEL OVALO
# ------------------------------------------------------------
func _punto_en_angulo(angulo) -> Vector3:
	return Vector3(cos(angulo) * radio_largo, 0, sin(angulo) * radio_corto)


# Devuelve los puntos del ovalo repartidos a distancia igual.
# Primero se recorre el contorno con muchas muestras chicas para
# saber cuanto mide, y despues se va cortando en partes iguales.
func _puntos_repartidos(segmentos) -> Array:
	var muestras = 720
	var puntos_finos = []
	var largo_acumulado = []
	var total = 0.0

	var anterior = _punto_en_angulo(0.0)
	puntos_finos.append(anterior)
	largo_acumulado.append(0.0)

	for i in range(1, muestras + 1):
		var angulo = i * (2.0 * PI / muestras)
		var punto = _punto_en_angulo(angulo)
		total += anterior.distance_to(punto)
		puntos_finos.append(punto)
		largo_acumulado.append(total)
		anterior = punto

	var resultado = []
	if total <= 0.0:
		for s in range(segmentos):
			resultado.append(Vector3.ZERO)
		return resultado

	var paso = total / float(segmentos)
	var indice = 0
	for s in range(segmentos):
		var objetivo = s * paso
		while indice < largo_acumulado.size() - 1 and largo_acumulado[indice + 1] < objetivo:
			indice += 1
		resultado.append(puntos_finos[indice])

	return resultado


# ------------------------------------------------------------
# CONSTRUCCION
# ------------------------------------------------------------
func _construir_paddock():
	var segmentos = int(max(cantidad_segmentos, 6))
	var entrada = int(clamp(segmentos_entrada, 1, segmentos - 2))
	var puntos = _puntos_repartidos(segmentos)

	if mostrar_diagnostico:
		print("[BDG-Paddock] ovalo de ", segmentos, " postes | radio largo=", radio_largo, " radio corto=", radio_corto, " | entrada de ", entrada, " tramo/s.")

	var postes = Spatial.new()
	postes.name = "Paddock_Postes"
	add_child(postes)

	var barandas = Spatial.new()
	barandas.name = "Paddock_Barandas"
	add_child(barandas)

	var ultimo_tramo_con_baranda = segmentos - entrada

	for i in range(segmentos):
		var punto = puntos[i]
		var es_poste_de_entrada = i == 0 or i == ultimo_tramo_con_baranda
		var color_de_este_poste = color_ribete if es_poste_de_entrada else color_poste
		_crear_caja(postes, "Poste_%d" % i, Vector3(ancho_poste, altura_poste, ancho_poste), Vector3(punto.x, altura_poste / 2.0, punto.z), 0.0, color_de_este_poste)

	for s in range(segmentos):
		if s >= ultimo_tramo_con_baranda:
			continue
		var siguiente = (s + 1) % segmentos
		_crear_tramo_baranda(barandas, s, puntos[s], puntos[siguiente])


func _crear_tramo_baranda(contenedor, indice, punto_a, punto_b):
	var medio = (punto_a + punto_b) / 2.0
	var largo = punto_a.distance_to(punto_b)
	var direccion = punto_b - punto_a
	var angulo_y = rad2deg(atan2(direccion.x, direccion.z))

	_crear_caja(contenedor, "BarandaSup_%d" % indice, Vector3(grosor_baranda, grosor_baranda, largo), Vector3(medio.x, alto_baranda_superior, medio.z), angulo_y, color_baranda)
	_crear_caja(contenedor, "BarandaInf_%d" % indice, Vector3(grosor_baranda, grosor_baranda, largo), Vector3(medio.x, alto_baranda_inferior, medio.z), angulo_y, color_baranda)


func _hacer_material(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	material.flags_unshaded = sin_sombreado
	return material


func _crear_caja(padre, nombre, tamano, posicion, rotacion_y, color):
	var caja = MeshInstance.new()
	var malla = CubeMesh.new()
	malla.size = tamano
	caja.mesh = malla
	caja.material_override = _hacer_material(color)
	caja.translation = posicion
	caja.rotation_degrees = Vector3(0, rotacion_y, 0)
	caja.name = nombre
	padre.add_child(caja)
	return caja


# ------------------------------------------------------------
# SETTERS
# ------------------------------------------------------------
func _set_radio_largo(valor):
	radio_largo = valor
	_pedir_reconstruccion()


func _set_radio_corto(valor):
	radio_corto = valor
	_pedir_reconstruccion()


func _set_cantidad_segmentos(valor):
	cantidad_segmentos = valor
	_pedir_reconstruccion()


func _set_segmentos_entrada(valor):
	segmentos_entrada = valor
	_pedir_reconstruccion()


func _set_altura_poste(valor):
	altura_poste = valor
	_pedir_reconstruccion()


func _set_ancho_poste(valor):
	ancho_poste = valor
	_pedir_reconstruccion()


func _set_alto_baranda_superior(valor):
	alto_baranda_superior = valor
	_pedir_reconstruccion()


func _set_alto_baranda_inferior(valor):
	alto_baranda_inferior = valor
	_pedir_reconstruccion()


func _set_grosor_baranda(valor):
	grosor_baranda = valor
	_pedir_reconstruccion()


func _set_color_poste(valor):
	color_poste = valor
	_pedir_reconstruccion()


func _set_color_baranda(valor):
	color_baranda = valor
	_pedir_reconstruccion()


func _set_color_ribete(valor):
	color_ribete = valor
	_pedir_reconstruccion()


func _set_sin_sombreado(valor):
	sin_sombreado = valor
	_pedir_reconstruccion()


func _set_mostrar_diagnostico(valor):
	mostrar_diagnostico = valor
