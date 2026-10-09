extends CanvasLayer
# VERSION: lista de llegada que se actualiza (oct 2026)

# ============================================================
#  FOTO FINISH  -  Brisas de Gloria
# ============================================================
#  Camara propia plantada SOBRE la linea de meta, mirando a lo
#  largo de la raya (perpendicular a la pista). Renderiza en su
#  propia ventanita y, en el cuadro exacto en que el primer
#  caballo toca la raya, deja de actualizarse: ahi queda la
#  foto congelada. Encima se le dibuja la raya de meta y el
#  orden de llegada.
#
#  QUE NO TOCA ESTE SCRIPT:
#   - GestorNivel.gd  (solo lee)
#   - Camara_de_Llegada.gd  (no se toca, quedo terminada)
#   - TrackPath.gd, los caballos, el jinete  (nada)
#
#  NODO: CanvasLayer llamado "FotoFinish", hijo de
#  PistaDeCarrera. El script se llama igual que el nodo.
# ============================================================


# ---------- DONDE SE PLANTA LA CAMARA ----------

# Nodo TrackPath. Si lo dejas vacio lo busca solo en "../TrackPath".
export(NodePath) var camino_pista_path

# Tu caballo, para marcarte en la lista con "<-- TU".
# Si lo dejas vacio busca "../TrackPath/Enrutador_Caballo1".
export(NodePath) var enrutador_jugador_path

# A cuantas unidades al costado de la meta se para la camara.
# Mas chico = mas encima de los caballos.
export var distancia_lateral = 40.0

# De que lado de la pista se para. Si la foto sale del lado
# equivocado (ves el pasto en vez de los caballos), tilda esto.
export var invertir_lado = false

# Altura de la camara sobre el piso.
export var altura = 3.0

# A que altura mira sobre la meta. Subilo para mirar mas al
# jinete, bajalo para mirar mas a las patas.
export var altura_mira = 2.0

# Zoom. Numero CHICO = mas zoom (mas telefoto, como una foto
# finish real). Numero grande = plano mas abierto.
export var campo_vision = 18.0

# Gira la camara sobre su eje, en grados, para dejarla bien
# frontal a la pista. Positivo la gira hacia un lado, negativo
# hacia el otro. Movelo de a 2 o 3 grados.
# La raya roja se reacomoda sola, no hay que tocarla.
export var girar_camara = 0.0

# Cuantas unidades adelante y atras de la meta se miden para
# saber hacia donde apunta la pista. Mas grande = medicion mas
# estable en las curvas. Si la meta cae justo donde empieza una
# curva, subilo a 8 o 10.
export var paso_tangente = 4.0

# Hasta donde dibuja la camara. Si el fondo se ve cortado, subilo.
export var distancia_dibujo = 6000.0


# ---------- CUANDO SE ENCIENDE ----------

# Unidades que le tienen que faltar al puntero para que la
# ventanita empiece a renderizar. Antes de eso esta apagada
# para no gastar telefono. Subilo si alguna vez la foto sale
# en negro.
export var distancia_para_encender = 200.0


# ---------- CUANDO APARECE EL CARTEL ----------

# El cartel salia apenas el JUEZ tenia ganador, o sea cuando cruzaba
# el puntero. Si TU no eras el puntero, aparecia varios segundos
# antes que tu propio aviso violeta. Con esto espera a que cruces
# TU, igual que el aviso.
# Apagalo (false) y vuelve a salir con el puntero, como antes.
export var esperar_al_jugador = true

# Segundos que espera DESPUES de que aparece el aviso violeta, para
# que no salgan los dos encimados. 0 = salen juntos.
export var demora_despues_del_aviso = 1.5


# ---------- PUNTERIA DE LA FOTO (el ajuste fino) ----------

# Cuantas unidades ANTES de la raya se congela la imagen.
#
# Por que hace falta: GestorNivel corre antes que los caballos en
# cada cuadro, y la imagen se dibuja despues de que los caballos ya
# se movieron. Si esperaramos a que el juego diga "cruzo", la foto
# saldria siempre pasada. Adelantandose unas unidades, la imagen
# cae justo sobre la raya.
#
# COMO GRADUARLO, mirando la foto que te queda:
#   - Si los caballos salen YA PASADOS de la raya  -> SUBI este numero.
#   - Si salen todavia CORTOS, antes de la raya    -> BAJA este numero.
# Subilo y bajalo de a 3 o 4 hasta que el puntero quede tocando la
# raya. Depende de la velocidad y de los cuadros por segundo, asi
# que es a ojo y no hay una cuenta que lo adivine.
export var congelar_antes_de_la_raya = 8.0

# --- Congelado por prediccion (recomendado) ---
# En vez de disparar con un numero fijo de unidades, mide cuanto
# avanzo el puntero en el ultimo cuadro y congela en el ultimo
# cuadro antes de cruzar. Se adapta solo a la velocidad del que
# viene ganando, sea el jugador o un rival.
# Si lo destildas, vuelve al sistema viejo con el numero fijo.
export var usar_prediccion = true
# Corrimiento fino, en unidades. Positivo congela un toque ANTES
# (la nariz queda mas atras), negativo congela un toque DESPUES
# (la nariz pasa mas la raya). Sirve porque el punto que se mide
# no es la nariz sino el centro del caballo.
export var ajuste_nariz = 0.0


# ---------- TAMAÑO DE LA FOTO ----------

# Resolucion interna de la foto. Ancha y baja, como una tira de
# foto finish de verdad.
export var ancho_foto = 1200
export var alto_foto = 420

# Si la imagen sale dada vuelta (cabeza abajo), tilda esto.
export var voltear_imagen = false


# ---------- COMO SE VE EN PANTALLA ----------

# Cuanto del ancho de la pantalla ocupa el cartel (0.9 = 90%).
export var ancho_relativo = 0.9

# Cuantos pixeles desde el borde de arriba de la pantalla.
export var margen_arriba = 15.0

# --- DONDE SE PLANTA EL CARTEL DE LA FOTO ---
# X:  0 = pegado a la izquierda   0.5 = centro   1 = pegado a la derecha
# Y:  0 = pegado arriba           0.5 = centro   1 = pegado abajo
export var posicion_foto = Vector2(0.0, 0.0)

# Empujoncito fino en pixeles. X positivo lo corre a la derecha,
# Y positivo lo baja.
export var desplazar_foto = Vector2(16, 0)

# Margen interno del cartel.
export var margen_interno = 10.0

# Capa de dibujo. Subilo si algo se le pone encima.
export var capa = 6

export var color_fondo = Color(0.03, 0.03, 0.05, 0.92)
export var color_borde = Color(0.82, 0.66, 0.26)
export var grosor_borde = 3
export var color_titulo = Color(1.0, 0.45, 0.2)
export var color_texto = Color(0.95, 0.95, 0.9)


# ---------- LA RAYA DE META ----------

export var mostrar_raya = true

# La raya se planta sola preguntandole a la camara en que pixel
# de la imagen cae el punto de la meta. Asi es exacta aunque la
# camara este ladeada o la pista venga de una curva.
# Destildalo solo si queres ponerla a mano.
export var raya_automatica = true

# A mano: donde cae la raya, de 0 a 1. Solo se usa si destildas
# Raya Automatica.
export var posicion_raya = 0.5
export var grosor_raya = 3
export var color_raya = Color(1.0, 0.15, 0.15, 0.85)


# ---------- EL ORDEN DE LLEGADA ----------

# Titulo de arriba del cartel ("¡PHOTO FINISH!" / "FOTO DE LLEGADA").
# Destildalo si ya lo dice el aviso violeta y no queres repetirlo.
export var mostrar_titulo = true

export var mostrar_orden = true
export var cuantos_puestos_mostrar = 5
export var escala_titulo = 1.2

export var mostrar_boton_cerrar = true
export var texto_boton_cerrar = "CERRAR"

export var mostrar_diagnostico = true


# ------------------------------------------------------------
#  De aca para abajo no hace falta tocar nada
# ------------------------------------------------------------

var _viewport = null
var _camara = null
var _rastreador = null

var _panel = null
var _foto = null
var _raya = null
var _titulo = null
var _lista = null
var _boton = null

var _enrutador_jugador = null
var _falta_anterior = -1.0
var _jockey_jugador = null
var _espera_cartel = 0.0
var _encendida = false
var _congelada = false
var _cartel_mostrado = false
var _punto_meta = Vector3()
var _hay_punto_meta = false


func _ready():
	layer = capa
	_buscar_jugador()
	_crear_rastreador()
	_crear_ventana()
	_crear_cartel()
	set_process(true)


func _buscar_jugador():
	if enrutador_jugador_path:
		_enrutador_jugador = get_node_or_null(enrutador_jugador_path)
	if not _enrutador_jugador:
		_enrutador_jugador = get_node_or_null("../TrackPath/Enrutador_Caballo1")


# El rastreador es un PathFollow prestado sobre la pista, que
# sirve para preguntarle a la curva donde queda exactamente la
# meta. Se llama "RastreadorFotoFinish" a proposito: TrackPath.gd
# solo le pisa el offset a los hijos que empiezan con
# "Enrutador_Caballo", asi que a este no lo toca.
func _crear_rastreador():
	var camino = null
	if camino_pista_path:
		camino = get_node_or_null(camino_pista_path)
	if not camino:
		camino = get_node_or_null("../TrackPath")
	if not camino:
		if mostrar_diagnostico:
			print("[BDG-FotoFinish] ERROR: no encontre el TrackPath.")
		return
	_rastreador = PathFollow.new()
	_rastreador.name = "RastreadorFotoFinish"
	_rastreador.rotation_mode = PathFollow.ROTATION_NONE
	camino.add_child(_rastreador)
	if mostrar_diagnostico:
		print("[BDG-FotoFinish] pista encontrada: ", camino.get_path())


func _crear_ventana():
	_viewport = Viewport.new()
	_viewport.name = "VentanaFoto"
	_viewport.size = Vector2(ancho_foto, alto_foto)
	_viewport.usage = Viewport.USAGE_3D
	_viewport.own_world = false
	_viewport.transparent_bg = false
	_viewport.render_target_v_flip = voltear_imagen
	_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	add_child(_viewport)

	_camara = Camera.new()
	_camara.name = "CamaraFotoFinish"
	_camara.fov = campo_vision
	_camara.near = 0.5
	_camara.far = distancia_dibujo
	_viewport.add_child(_camara)
	_camara.current = true


func _crear_cartel():
	_panel = Panel.new()
	_panel.name = "Cartel"
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var estilo = StyleBoxFlat.new()
	estilo.bg_color = color_fondo
	estilo.border_color = color_borde
	estilo.set_border_width_all(grosor_borde)
	estilo.set_corner_radius_all(6)
	_panel.add_stylebox_override("panel", estilo)
	add_child(_panel)

	_titulo = Label.new()
	_titulo.name = "Titulo"
	_titulo.add_color_override("font_color", color_titulo)
	_titulo.rect_scale = Vector2(escala_titulo, escala_titulo)
	_panel.add_child(_titulo)

	_foto = TextureRect.new()
	_foto.name = "Foto"
	_foto.expand = true
	_foto.stretch_mode = TextureRect.STRETCH_SCALE
	_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_foto)

	var textura = _viewport.get_texture()
	textura.flags = Texture.FLAG_FILTER
	_foto.texture = textura

	_raya = ColorRect.new()
	_raya.name = "RayaMeta"
	_raya.color = color_raya
	_raya.visible = mostrar_raya
	_raya.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto.add_child(_raya)

	_lista = Label.new()
	_lista.name = "Orden"
	_lista.add_color_override("font_color", color_texto)
	_lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foto.add_child(_lista)

	if mostrar_boton_cerrar:
		_boton = Button.new()
		_boton.name = "BotonCerrar"
		_boton.text = texto_boton_cerrar
		_boton.connect("pressed", self, "_al_cerrar")
		_panel.add_child(_boton)


func _al_cerrar():
	if _panel:
		_panel.visible = false


func _process(_delta):
	if not GestorNivel:
		return

	if not _congelada:
		_revisar_congelado()

	# El cartel va aparte: la imagen se congela adelantandose a la
	# raya, pero el orden de llegada recien existe cuando el juez
	# lo calcula, uno o dos cuadros despues.
	if _congelada and not _cartel_mostrado:
		if GestorNivel.obtener_ganador() != null and _jugador_ya_llego():
			_espera_cartel += _delta
			if _espera_cartel >= demora_despues_del_aviso:
				_mostrar_cartel()


# True cuando el jugador ya cruzo la meta, que es el mismo instante
# en que Jockey_final.gd prende el aviso violeta. Si no encuentra al
# jinete, devuelve true para no dejar el cartel colgado nunca.
func _jugador_ya_llego() -> bool:
	if not esperar_al_jugador:
		return true
	if _jockey_jugador == null and _enrutador_jugador:
		_jockey_jugador = _enrutador_jugador.get_node_or_null("Jockey")
	if _jockey_jugador == null:
		return true
	if not ("carrera_terminada" in _jockey_jugador):
		return true
	return _jockey_jugador.carrera_terminada


func _revisar_congelado():
	var falta = GestorNivel.obtener_distancia_lider_hasta_meta()
	var hay_ganador = GestorNivel.obtener_ganador() != null

	if not _encendida:
		if hay_ganador or (falta >= 0.0 and falta <= distancia_para_encender):
			_encender()
		else:
			return

	# Lo normal: el puntero esta entrando a la raya.
	if usar_prediccion:
		# Cuanto avanzo el puntero desde el cuadro anterior.
		var paso = 0.0
		if _falta_anterior >= 0.0 and falta >= 0.0 and _falta_anterior > falta:
			paso = _falta_anterior - falta
		_falta_anterior = falta
		# Si con otro paso igual ya estaria cruzando, este es el
		# ultimo cuadro bueno: se congela aca.
		if falta >= 0.0 and (falta - paso) <= ajuste_nariz:
			_congelar_imagen(falta)
			return
	else:
		if falta >= 0.0 and falta <= congelar_antes_de_la_raya:
			_congelar_imagen(falta)
			return

	# Red de seguridad: si por lo que sea se paso de largo sin que
	# lo agarraramos (cuadro lento, salto grande), se congela igual
	# apenas hay ganador. Va a salir pasada, y eso significa que
	# hay que subir "Congelar Antes De La Raya".
	if hay_ganador:
		_congelar_imagen(falta)


func _congelar_imagen(falta):
	_congelada = true
	if not _encendida:
		_ubicar_camara()
		_encendida = true
	if _viewport:
		# UPDATE_ONCE dibuja ESTE cuadro y despues se apaga sola.
		_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	if mostrar_diagnostico:
		print("[BDG-FotoFinish] IMAGEN CONGELADA con el puntero a ",
			falta, " unidades de la raya.")


func _encender():
	_ubicar_camara()
	if _viewport:
		_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	_encendida = true
	if mostrar_diagnostico:
		print("[BDG-FotoFinish] ventana encendida.")


# Planta la camara sobre la linea de meta, mirando a lo largo
# de la raya. Asi la meta cae justo en el centro de la imagen.
func _ubicar_camara():
	var datos = _obtener_datos_meta()
	if datos == null:
		if mostrar_diagnostico:
			print("[BDG-FotoFinish] ERROR: no pude ubicar la meta.")
		return

	var lado = datos["avance"].cross(Vector3.UP).normalized()
	if invertir_lado:
		lado = -lado

	_punto_meta = datos["punto"]
	_hay_punto_meta = true

	_camara.fov = campo_vision
	_camara.far = distancia_dibujo
	_camara.global_transform.origin = datos["punto"] - (lado * distancia_lateral) + Vector3.UP * altura
	_camara.look_at(datos["punto"] + Vector3.UP * altura_mira, Vector3.UP)

	# Giro fino para dejarla frontal. Va despues del look_at.
	if abs(girar_camara) > 0.001:
		_camara.rotate_y(deg2rad(girar_camara))

	if mostrar_diagnostico:
		print("[BDG-FotoFinish] camara en ", _camara.global_transform.origin,
			" | meta en ", datos["punto"])


# Solo lectura de GestorNivel: en que offset esta la meta de
# esta carrera (cambia segun sea modo recta u ovalo).
func _obtener_offset_meta() -> float:
	if not GestorNivel:
		return -1.0
	if GestorNivel.modo_recta and GestorNivel._meta_recta:
		return GestorNivel._meta_recta.offset
	elif GestorNivel._meta_ovalo:
		return GestorNivel._meta_ovalo.offset
	return -1.0


func _obtener_datos_meta():
	var offset_meta = _obtener_offset_meta()
	if offset_meta < 0.0 or not _rastreador:
		return null

	_rastreador.offset = offset_meta
	var punto = _rastreador.global_transform.origin

	# Se mide un tramo ANTES y otro DESPUES de la meta y se toma
	# la direccion entre los dos. Medir solo hacia adelante hace
	# que la camara quede ladeada si la meta cae cerca de una curva.
	var paso = max(0.5, paso_tangente)
	_rastreador.offset = offset_meta - paso
	var atras = _rastreador.global_transform.origin
	_rastreador.offset = offset_meta + paso
	var adelante = _rastreador.global_transform.origin
	_rastreador.offset = offset_meta

	var avance = adelante - atras
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()

	return {"punto": punto, "avance": avance}


func _mostrar_cartel():
	if not _panel:
		return

	var pantalla = get_viewport().get_visible_rect().size

	var ancho_cartel = pantalla.x * ancho_relativo
	var ancho_util = ancho_cartel - margen_interno * 2.0
	var alto_util = ancho_util * (float(alto_foto) / float(ancho_foto))
	# Si no hay titulo ni boton, la franja de arriba no existe y el
	# cartel queda todo foto.
	var alto_titulo = 34.0 * escala_titulo
	if not mostrar_titulo:
		alto_titulo = 36.0 if mostrar_boton_cerrar else 0.0
	var alto_cartel = alto_util + alto_titulo + margen_interno * 2.0

	# Se reparte el espacio que sobra segun posicion_foto: con 0 queda
	# pegado a un borde y con 1 al otro, mida lo que mida el cartel y
	# sea cual sea la resolucion. Asi no se sale nunca de pantalla.
	var libre_x = max(0.0, pantalla.x - ancho_cartel)
	var libre_y = max(0.0, pantalla.y - alto_cartel)
	_panel.rect_position = Vector2(
		libre_x * clamp(posicion_foto.x, 0.0, 1.0) + desplazar_foto.x,
		libre_y * clamp(posicion_foto.y, 0.0, 1.0) + desplazar_foto.y + margen_arriba)
	_panel.rect_size = Vector2(ancho_cartel, alto_cartel)

	_titulo.visible = mostrar_titulo
	_titulo.rect_position = Vector2(margen_interno, margen_interno)
	_titulo.text = _armar_titulo()

	_foto.rect_position = Vector2(margen_interno, margen_interno + alto_titulo)
	_foto.rect_size = Vector2(ancho_util, alto_util)

	_raya.visible = mostrar_raya
	_raya.color = color_raya
	var donde = _calcular_posicion_raya()
	_raya.rect_position = Vector2(ancho_util * donde - grosor_raya / 2.0, 0)
	_raya.rect_size = Vector2(grosor_raya, alto_util)

	_lista.visible = mostrar_orden
	_lista.text = _armar_orden()
	if GestorNivel and not GestorNivel.is_connected("orden_llegada_actualizado", self, "_al_cambiar_orden"):
		GestorNivel.connect("orden_llegada_actualizado", self, "_al_cambiar_orden")
	_lista.rect_position = Vector2(10, 8)

	if _boton:
		_boton.rect_size = Vector2(110, 32)
		_boton.rect_position = Vector2(ancho_cartel - 110 - margen_interno, margen_interno)

	_panel.visible = true
	_cartel_mostrado = true
	if mostrar_diagnostico:
		print("[BDG-FotoFinish] cartel mostrado.")


# Le pregunta a la camara en que pixel de la imagen cae el punto
# exacto de la meta. unproject_position hace la cuenta real de la
# perspectiva, asi que la raya queda clavada sobre la meta aunque
# la camara este girada o con otro zoom.
func _calcular_posicion_raya() -> float:
	if not raya_automatica or not _hay_punto_meta or not _camara:
		return clamp(posicion_raya, 0.0, 1.0)
	var pixel = _camara.unproject_position(_punto_meta)
	var fraccion = clamp(pixel.x / float(max(1, ancho_foto)), 0.0, 1.0)
	if mostrar_diagnostico:
		print("[BDG-FotoFinish] raya calculada en ", fraccion, " del ancho.")
	return fraccion


func _armar_titulo() -> String:
	if not GestorNivel:
		return "FOTO DE LLEGADA"
	if GestorNivel.es_photo_finish():
		return "¡PHOTO FINISH!   por %.2f" % GestorNivel.obtener_diferencia_photo_finish()
	return "FOTO DE LLEGADA"


func _armar_orden() -> String:
	if not GestorNivel:
		return ""
	var orden = GestorNivel.obtener_orden_llegada_congelado()
	if orden.size() == 0:
		return ""

	var texto = ""
	var cuantos = int(min(cuantos_puestos_mostrar, orden.size()))
	for i in range(cuantos):
		var corredor = orden[i]
		if not is_instance_valid(corredor):
			continue
		texto += "%d.  %s\n" % [i + 1, _nombre_corto(corredor)]

	# Si quedaste fuera del recorte, igual se muestra tu fila.
	var mi_puesto = orden.find(_enrutador_jugador) + 1
	if mi_puesto > cuantos:
		if mi_puesto > cuantos + 1:
			texto += "...\n"
		texto += "%d.  %s\n" % [mi_puesto, _nombre_corto(_enrutador_jugador)]

	return texto


func _nombre_corto(corredor) -> String:
	if not is_instance_valid(corredor):
		return ""
	var nombre = str(corredor.name).replace("Enrutador_Caballo", "N° ")
	nombre = nombre.replace("Enrutador_", "")
	if corredor == _enrutador_jugador:
		nombre += "   <-- TU"
	return nombre


# Cada vez que otro caballo cruza la raya, la lista se pone al dia.
func _al_cambiar_orden():
	if _lista and is_instance_valid(_lista) and _lista.visible:
		_lista.text = _armar_orden()
