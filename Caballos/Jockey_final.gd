extends Node

export var duracion_efecto = 2.0
export var penalizacion_proporcion_duracion = 0.5

# --- SUAVIDAD DEL EMPUJON (arreo, latigo y combo) ---
# Antes el empujon entraba de golpe seco: apretabas y en el mismo
# instante el caballo ya iba a la velocidad nueva. Con el combo
# (latigo + arreo juntos) eso se sentia como un cohete.
# Ahora el empujon TARDA en entrar y TARDA en irse. La fuerza
# final es la misma - lo unico que cambia es que llega de a poco.
# tiempo_de_entrada: segundos que tarda en llegar a plena fuerza.
# tiempo_de_salida: segundos que tarda en apagarse al final.
# Subilos para que sea mas blando, bajalos para que sea mas seco.
# En 0 los dos, vuelve a ser el golpe de antes.
export var tiempo_de_entrada = 0.45
export var tiempo_de_salida = 0.40

export var arreo_incremento = 0.10
export var arreo_limite_seguro = 30
export var arreo_penalizacion = 0.05
export var arreo_costo_estamina = 2.0

# Limite de arreos para el modo recta (800m). El modo normal usa
# arreo_limite_seguro (30); este es el doble, especifico para 800m.
export var arreo_limite_ritmo = 60

export var latigazo_incremento = 0.20
export var latigazo_limite_inicial = 10
export var latigazo_limite_tras_cambio = 2
export var latigazo_penalizacion = 0.10
export var latigazo_costo_estamina = 4.0

export var frenado_reduccion = 0.10

export var giro_velocidad = 40.0
export var h_offset_minimo = 0.0
export var h_offset_maximo = 170.0

export var estamina_maxima = 100.0
export var estamina_regen_por_segundo = 3.0

export var color_aviso = Color(0.93, 0.93, 1.0)
export var escala_aviso = 3.0

# --- Aspecto del cartel de llegada (panel azul-violeta) ---
export var tamano_aviso = 34
export var grosor_contorno_aviso = 3
export var color_contorno_aviso = Color(0.05, 0.02, 0.15, 1)
export var mostrar_panel_aviso = true
export var color_panel_aviso = Color(0.17, 0.10, 0.42, 0.93)
export var color_borde_panel_aviso = Color(0.60, 0.48, 1.0, 0.95)
export var grosor_borde_panel_aviso = 3
export var redondeo_panel_aviso = 20
export var relleno_panel_aviso = Vector2(54, 38)

# --- DONDE SE PLANTA EL AVISO DE LLEGADA EN LA PANTALLA ---
# Antes estaba clavado en el centro exacto y tapaba la foto finish.
# Ahora se puede mover por Inspector, sin tocar el codigo.
#
# X:  0 = pegado a la izquierda   0.5 = centro   1 = pegado a la derecha
# Y:  0 = pegado arriba           0.5 = centro   1 = pegado abajo
export var posicion_aviso = Vector2(0.0, 0.5)

# Empujoncito fino en pixeles, por si querés despegarlo un poco
# del borde. X positivo lo corre a la derecha, Y positivo lo baja.
export var desplazar_aviso = Vector2(16, 0)

# --- Cartel de llegada: photo finish y orden de llegada ---
# Si la diferencia con el segundo es chica, GestorNivel marca la
# carrera como photo finish. Aca se muestra en pantalla.
# Muestra el puesto en que vas MIENTRAS corres, no solo al llegar.
# Es el dato que decide cuando arrear y cuando guardar stamina.
export var mostrar_puesto_en_vivo = true

export var diagnostico_llegada = true

# Que tan cerrado tiene que ser el final para que cuente como
# photo finish, medido en unidades de recorrido. Cuanto mas alto,
# mas seguido se activa. Este numero vive en GestorNivel, que no
# se toca: desde aca se lo escribimos al arrancar.
# Poner en 0 o menos para dejar el que ya trae GestorNivel.
export var margen_photo_finish = 15.0

# Cuantos cuadros como maximo esperar a que GestorNivel termine
# de calcular el photo finish antes de mostrar el cartel. Solo
# hace falta cuando ganas vos. Si se cuelga algo, bajalo.
export var espera_maxima_cuadros = 30

export var mostrar_photo_finish = true
export var mostrar_orden_llegada = true
# Cuantos puestos listar en el cartel. Ojo: con escala_aviso en 3.0
# y muchos puestos, el texto se sale de la pantalla. Si no entra,
# baja escala_aviso a 2.0 o mostra menos puestos.
export var cuantos_puestos_mostrar = 5
export var color_photo_finish = Color(1.0, 0.45, 0.35)

export var modo_arreo_ritmo = false
export var ritmo_intervalo_ideal_min = 0.30
export var ritmo_intervalo_ideal_max = 0.55
export var ritmo_boost = 0.16
export var ritmo_boost_fuera_de_ritmo = 0.05
export var ritmo_penalizacion = 0.05
var _tiempo_ultimo_arreo = -1.0

export(NodePath) var animador_path = NodePath("../Caballo/AnimationPlayer")
export(NodePath) var animador_jinete_path = NodePath("../Caballo/Armature/Skeleton/BoneAttachment/Jinete/AnimationPlayer")
export(NodePath) var label_velocidad_path = NodePath("")
export var animacion_base = "ArmatureAction_Armature"
export var animacion_arreo = "Arreo"
export var animacion_frenado = "Frenar"
export var animacion_cambio_mano = "CambioDeMano"
export var animacion_latigazo_derecha = "Latigo_mano_R"
export var animacion_latigazo_izquierda = "Latigo_Mano_L"

var conteo_arreos = 0
var conteo_racha_actual = 0
var limite_racha_actual = 10
var mano_derecha = true
var estamina_actual = 100.0
var tiempo_aviso_combo = 0.0
var _efectos_temporales = []
var _velocidad_base = 0.0
var carrera_terminada = false

var ultima_accion_nombre = "-"
var conteo_acciones_total = 0

var posicion_llegada = 0
var total_corredores_llegada = 0
var _subio_de_nivel_este_aviso = false

var _capa_aviso = null
var _label_aviso = null
var _panel_aviso = null

# --- REGLA 2 (800m): deteccion de meta PROPIA, sin depender del
# registro de GestorNivel. En modo recta, el jugador cuenta su
# propia distancia recorrida desde el offset donde arranco. Esto
# es a proposito independiente de _objetivo_recta en GestorNivel,
# que dejo de registrar algunos caballos por una causa que todavia
# no encontramos - asi el jugador NUNCA depende de eso.
var _modo_recta_propio = false
var _offset_inicial_propio = 0.0
var _distancia_objetivo_propia = 0.0

onready var enrutador = get_parent()
onready var animador = get_node(animador_path) if animador_path != NodePath("") else null
onready var animador_jinete = get_node(animador_jinete_path) if animador_jinete_path != NodePath("") else null
onready var label_velocidad = get_node(label_velocidad_path) if label_velocidad_path != NodePath("") else null


func _ready():
	# Velocidad de crucero del caballo, sin ningun empujon encima.
	# Es la base sobre la que se calculan arreo, latigo y frenado.
	_velocidad_base = enrutador.velocidad_avance

	if not label_velocidad:
		# Respaldo: si el camino guardado en el Inspector
		# (label_velocidad_path) esta roto o se perdio, lo busca
		# directo desde la raiz de la escena, sin depender de esa
		# ruta relativa fragil.
		var raiz = get_tree().current_scene
		if raiz:
			label_velocidad = raiz.get_node_or_null("CanvasLayer2/Label")

	if GestorNivel:
		print("[BDG-Jockey] label_velocidad_path=", label_velocidad_path,
			" | label_velocidad encontrado=", label_velocidad != null)

	# NUEVO - limite de arreo segun la distancia elegida (lo pone
	# SelectorDistancias en ConfiguracionCarrera.arreo_limite). No se
	# usa en modo recta (800m), que tiene su propio limite fijo
	# aparte (arreo_limite_ritmo), asi que no hace falta filtrarlo.
	if ConfiguracionCarrera:
		arreo_limite_seguro = ConfiguracionCarrera.arreo_limite

	if GestorNivel:
		estamina_maxima = GestorNivel.obtener_estamina_maxima()
		if GestorNivel.modo_recta:
			modo_arreo_ritmo = true
			_modo_recta_propio = true
			_offset_inicial_propio = enrutador.offset
			var pista = enrutador.get_parent()
			if pista and "distancia_recta_800m_real" in pista:
				_distancia_objetivo_propia = pista.distancia_recta_800m_real
			else:
				_distancia_objetivo_propia = 724.0
			print("[BDG-Jockey] Modo recta propio activo. offset_inicial=",
				_offset_inicial_propio, " objetivo_propio=", _distancia_objetivo_propia)

	limite_racha_actual = latigazo_limite_inicial
	estamina_actual = estamina_maxima

	_crear_aviso_final()
	_aplicar_margen_photo_finish()

	if animador and animador.has_animation(animacion_base):
		animador.get_animation(animacion_base).loop = true
		animador.play(animacion_base)

	if label_velocidad and OS.has_touchscreen_ui_hint():
		label_velocidad.rect_scale = Vector2(1.5, 1.5)

	if animador_jinete and animador:
		for nombre in [animacion_arreo, animacion_frenado, animacion_cambio_mano, animacion_latigazo_derecha, animacion_latigazo_izquierda]:
			if animador.has_animation(nombre) and not animador_jinete.has_animation(nombre):
				animador_jinete.add_animation(nombre, animador.get_animation(nombre))
		animador_jinete.connect("animation_finished", self, "_al_terminar_gesto")


func _aplicar_margen_photo_finish():
	if margen_photo_finish <= 0.0:
		return
	if GestorNivel == null:
		return
	GestorNivel.margen_photo_finish = margen_photo_finish
	if diagnostico_llegada:
		print("[BDG-Jockey] margen_photo_finish puesto en ", margen_photo_finish)


func _crear_aviso_final():
	_capa_aviso = CanvasLayer.new()
	_capa_aviso.layer = 10
	add_child(_capa_aviso)

	if mostrar_panel_aviso:
		_panel_aviso = Panel.new()
		_panel_aviso.add_stylebox_override("panel", _estilo_panel_aviso())
		_panel_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel_aviso.visible = false
		_capa_aviso.add_child(_panel_aviso)

	_label_aviso = Label.new()
	_label_aviso.align = Label.ALIGN_CENTER
	_label_aviso.valign = Label.VALIGN_CENTER
	_label_aviso.anchor_left = 0
	_label_aviso.anchor_top = 0
	_label_aviso.anchor_right = 1
	_label_aviso.anchor_bottom = 1
	# CORRECCION: sin esto, el label queda con tamaño minimo aunque
	# las anclas digan "pantalla completa" - en Godot 3.x las anclas
	# solas no alcanzan, hacen falta los margenes en 0 tambien.
	_label_aviso.margin_left = 0
	_label_aviso.margin_top = 0
	_label_aviso.margin_right = 0
	_label_aviso.margin_bottom = 0
	_label_aviso.add_color_override("font_color", color_aviso)
	_capa_aviso.add_child(_label_aviso)

	# CORRECCION: escalar desde la esquina (0,0) empuja el texto
	# grande fuera de la pantalla. Se escala desde el centro de la
	# pantalla para que el agrandado se vea centrado.
	_aplicar_fuente_aviso()
	_label_aviso.visible = false


func _estilo_panel_aviso():
	var e = StyleBoxFlat.new()
	e.bg_color = color_panel_aviso
	e.border_color = color_borde_panel_aviso
	e.set_border_width_all(grosor_borde_panel_aviso)
	e.corner_radius_top_left = redondeo_panel_aviso
	e.corner_radius_top_right = redondeo_panel_aviso
	e.corner_radius_bottom_left = redondeo_panel_aviso
	e.corner_radius_bottom_right = redondeo_panel_aviso
	return e


func _aplicar_fuente_aviso():
	# Si el proyecto tiene fuente propia, se usa tamano real (nitido).
	# Si no, se estira como antes (respaldo).
	var base = _label_aviso.get_font("font")
	if base != null and base is DynamicFont and base.font_data != null:
		var f = DynamicFont.new()
		f.font_data = base.font_data
		f.size = max(10, tamano_aviso)
		if grosor_contorno_aviso > 0:
			f.outline_size = grosor_contorno_aviso
			f.outline_color = color_contorno_aviso
		_label_aviso.add_font_override("font", f)
		_label_aviso.rect_scale = Vector2(1, 1)
	else:
		var tam_pantalla = get_viewport().size
		_label_aviso.rect_pivot_offset = tam_pantalla / 2.0
		_label_aviso.rect_scale = Vector2(escala_aviso, escala_aviso)


# El panel se acomoda solo al tamano que ocupe el texto, y despues
# se planta donde diga "Posicion Aviso".
#
# CAMBIO DE ESTA SESION: antes el panel se anclaba al centro de la
# pantalla (anclas en 0.5 y margenes a mitad de ancho), y el texto
# iba en un label del tamano de TODA la pantalla, centrado. Por eso
# el aviso quedaba siempre en el medio y se comia la foto finish.
# Ahora el label se recorta al mismo rectangulo que el panel, y los
# dos se mueven juntos al lugar que se elija por Inspector.
func _ajustar_panel_aviso():
	if not _label_aviso:
		return
	var medida = _label_aviso.get_combined_minimum_size()
	var ancho = medida.x + relleno_panel_aviso.x * 2.0
	var alto = medida.y + relleno_panel_aviso.y * 2.0

	var pantalla = get_viewport().get_visible_rect().size
	# Espacio que sobra en la pantalla despues de poner el cartel.
	# Repartirlo segun posicion_aviso hace que 0 quede pegado al
	# borde y 1 pegado al otro, sin que se salga nunca de cuadro.
	var libre_x = max(0.0, pantalla.x - ancho)
	var libre_y = max(0.0, pantalla.y - alto)

	var esquina = Vector2(
		libre_x * clamp(posicion_aviso.x, 0.0, 1.0) + desplazar_aviso.x,
		libre_y * clamp(posicion_aviso.y, 0.0, 1.0) + desplazar_aviso.y)

	_colocar_control(_panel_aviso, esquina, Vector2(ancho, alto))
	_colocar_control(_label_aviso, esquina, Vector2(ancho, alto))

	if _panel_aviso:
		_panel_aviso.visible = true


# Planta un control en un lugar y tamano exactos, sin anclas.
func _colocar_control(control, esquina, tamano):
	if not control:
		return
	control.anchor_left = 0
	control.anchor_top = 0
	control.anchor_right = 0
	control.anchor_bottom = 0
	control.margin_left = esquina.x
	control.margin_top = esquina.y
	control.margin_right = esquina.x + tamano.x
	control.margin_bottom = esquina.y + tamano.y


func _mostrar_aviso_final():
	if not _label_aviso:
		return

	# ESPERA AL CALCULO DE GESTORNIVEL.
	# GestorNivel es autoload, asi que corre ANTES que los caballos
	# en cada cuadro. Cuando gana un rival, el calculo ya esta hecho
	# cuando vos cruzas. Pero cuando ganas VOS, el cartel se dispara
	# en el mismo instante y el calculo todavia no existe.
	#
	# Antes aca habia un solo "esperar un cuadro", y no alcanzaba:
	# por eso el photo finish no se activaba nunca cuando el jugador
	# llegaba primero. Ahora se espera hasta que el dato este.
	var cuadros_esperados = 0
	while cuadros_esperados < espera_maxima_cuadros:
		yield(get_tree(), "idle_frame")
		cuadros_esperados += 1
		if not _label_aviso:
			return
		if GestorNivel == null:
			break
		if GestorNivel.obtener_ganador() != null:
			break

	if not _label_aviso:
		return

	if diagnostico_llegada:
		print("[BDG-Jockey] espere ", cuadros_esperados,
			" cuadros al calculo de llegada.")

	var hay_photo = false
	var diferencia = 0.0
	if GestorNivel and mostrar_photo_finish:
		hay_photo = GestorNivel.es_photo_finish()
		diferencia = GestorNivel.obtener_diferencia_photo_finish()

	var texto = ""
	if hay_photo:
		texto += "¡PHOTO FINISH!\n"
	else:
		texto += "META\n"

	if posicion_llegada > 0:
		texto += "Puesto %d de %d" % [posicion_llegada, total_corredores_llegada]

	if hay_photo:
		texto += "\nDefinido por %.2f" % diferencia

	if mostrar_orden_llegada and GestorNivel:
		var orden = GestorNivel.obtener_orden_llegada_congelado()
		if orden.size() > 0:
			texto += "\n"
			var cuantos = int(min(cuantos_puestos_mostrar, orden.size()))
			for i in range(cuantos):
				var corredor = orden[i]
				if not is_instance_valid(corredor):
					continue
				texto += "\n%d.  %s" % [i + 1, _nombre_para_el_cartel(corredor)]

			# Si quedaste fuera de la lista, igual se muestra TU fila
			# al final, con puntos suspensivos si hay un salto. Sin
			# esto, el que llega septimo no se ve en ninguna parte.
			var mi_puesto = orden.find(enrutador) + 1
			if mi_puesto > cuantos:
				if mi_puesto > cuantos + 1:
					texto += "\n..."
				texto += "\n%d.  %s" % [mi_puesto, _nombre_para_el_cartel(enrutador)]

	if _subio_de_nivel_este_aviso and GestorNivel:
		texto += "\n\n¡SUBISTE A NIVEL %d!" % GestorNivel.nivel_actual

	if hay_photo:
		_label_aviso.add_color_override("font_color", color_photo_finish)
	else:
		_label_aviso.add_color_override("font_color", color_aviso)

	_label_aviso.text = texto
	_label_aviso.visible = true
	call_deferred("_ajustar_panel_aviso")

	if diagnostico_llegada:
		_imprimir_diagnostico_llegada(hay_photo, diferencia)


# Diagnostico: vuelca los numeros con los que el juego decidio
# el orden. Se apaga poniendo "Diagnostico Llegada" en false.
func _imprimir_diagnostico_llegada(hay_photo, diferencia):
	if not GestorNivel:
		return
	print("========== ORDEN DE LLEGADA (diagnostico) ==========")
	print("  photo finish activado = ", hay_photo, "  | diferencia = ", diferencia)
	var orden = GestorNivel.obtener_orden_llegada_congelado()
	for i in range(orden.size()):
		var c = orden[i]
		if not is_instance_valid(c):
			continue
		var marca = ""
		if c == enrutador:
			marca = "   <-- VOS"
		print("  ", i + 1, ". ", c.name,
			"  | recorrido = ", GestorNivel.obtener_recorrido(c),
			"  | le faltaba = ", GestorNivel.obtener_distancia_restante(c),
			"  | offset = ", c.offset, marca)
	print("====================================================")


# "Enrutador_Caballo7" queda feo en pantalla. Se le saca el prefijo
# y se marca cual sos vos.
func _nombre_para_el_cartel(corredor) -> String:
	var nombre = str(corredor.name).replace("Enrutador_", "")
	if corredor == enrutador:
		nombre += "   <-- VOS"
	return nombre


func _al_terminar_gesto(anim_name):
	animador_jinete.seek(0, true)
	animador_jinete.stop(false)


func _process(delta):
	if carrera_terminada:
		return
	_actualizar_efectos_temporales(delta)
	_leer_controles(delta)
	estamina_actual = min(estamina_maxima, estamina_actual + estamina_regen_por_segundo * delta)
	if tiempo_aviso_combo > 0:
		tiempo_aviso_combo -= delta
	_revisar_linea_de_meta()
	_actualizar_pantalla()


func _revisar_linea_de_meta():
	if carrera_terminada:
		return

	var termino = false

	if _modo_recta_propio:
		var recorrido_propio = enrutador.offset - _offset_inicial_propio
		termino = recorrido_propio >= _distancia_objetivo_propia
	elif GestorNivel:
		termino = GestorNivel.ha_terminado(enrutador)

	if not termino:
		return

	carrera_terminada = true
	if GestorNivel:
		posicion_llegada = GestorNivel.obtener_posicion(enrutador)
		total_corredores_llegada = GestorNivel.obtener_total_corredores()
	if posicion_llegada <= 0:
		posicion_llegada = 1
	if total_corredores_llegada <= 0:
		total_corredores_llegada = 1
	if GestorNivel:
		var nivel_antes = GestorNivel.nivel_actual
		GestorNivel.subir_nivel_si_gano(posicion_llegada)
		_subio_de_nivel_este_aviso = GestorNivel.nivel_actual > nivel_antes
	print("[BDG-Jockey] META propia alcanzada. Puesto=", posicion_llegada, "/", total_corredores_llegada)
	_mostrar_aviso_final()


func _actualizar_pantalla():
	if not label_velocidad:
		return
	var texto = ""

	# El puesto va PRIMERO: es lo que mas se mira de reojo mientras
	# se corre. Al terminar la carrera se deja de actualizar en vivo,
	# porque abajo ya se muestra la posicion final congelada.
	if mostrar_puesto_en_vivo and GestorNivel and not carrera_terminada:
		texto += "Puesto: %d / %d\n" % [GestorNivel.obtener_posicion(enrutador), GestorNivel.obtener_total_corredores()]

	texto += "Velocidad: %.1f\n" % enrutador.velocidad_avance
	texto += "Stamina: %d / %d\n" % [int(estamina_actual), int(estamina_maxima)]

	# NUEVO - contador de distancia recorrida y tiempo, para poder
	# leer en vivo (sin depender de la consola ni de donde quedo la
	# camara al final) exactamente cuanta distancia/tiempo llevaba la
	# carrera en el instante en que pasa algo (por ejemplo, cuando
	# cambia la camara de llegada).
	if GestorNivel:
		texto += "Distancia recorrida: %.1f m\n" % GestorNivel.obtener_recorrido(enrutador)
		texto += "Tiempo: %.1f s\n" % GestorNivel.obtener_tiempo_carrera()

	if GestorNivel:
		texto += "Nivel: %d / %d\n" % [GestorNivel.nivel_actual, GestorNivel.nivel_maximo]

	if modo_arreo_ritmo:
		texto += "Arreos: %d / %d\n" % [conteo_arreos, arreo_limite_ritmo]
	else:
		var arreos_usados = min(conteo_arreos, arreo_limite_seguro)
		var latigazos_usados = min(conteo_racha_actual, limite_racha_actual)
		texto += "Arreo: %d / %d\n" % [arreos_usados, arreo_limite_seguro]
		texto += "Látigo: %d / %d\n" % [latigazos_usados, limite_racha_actual]
		if tiempo_aviso_combo > 0:
			texto += "¡CAMBIO DE MANO!\n"

	if GestorNivel and GestorNivel.vueltas_totales > 1 and not GestorNivel.modo_recta:
		var vuelta_actual = min(GestorNivel.obtener_vueltas_completadas(enrutador) + 1, GestorNivel.vueltas_totales)
		texto += "Vuelta: %d / %d\n" % [vuelta_actual, GestorNivel.vueltas_totales]

	if carrera_terminada:
		texto += "CARRERA TERMINADA!\n"
		if posicion_llegada > 0:
			texto += "Posicion: %d de %d\n" % [posicion_llegada, total_corredores_llegada]
	label_velocidad.text = texto


func _actualizar_efectos_temporales(delta):
	# CAMBIADO - antes esto multiplicaba la velocidad de una sola
	# vez al apretar y la dividia de una sola vez al terminar. De
	# ahi el golpe seco. Ahora cada efecto tiene un PESO que sube
	# de 0 a 1 mientras entra y baja de 1 a 0 mientras se va, y en
	# cada cuadro se recalcula la velocidad desde la base.
	var total = 1.0

	for i in range(_efectos_temporales.size() - 1, -1, -1):
		var efecto = _efectos_temporales[i]
		efecto["tiempo_restante"] -= delta
		if efecto["tiempo_restante"] <= 0.0:
			_efectos_temporales.remove(i)
			continue

		var duracion = efecto["duracion"]
		var transcurrido = duracion - efecto["tiempo_restante"]

		# Ni la entrada ni la salida pueden comerse mas de la mitad
		# del efecto, asi siempre llega a dar toda su fuerza.
		var entrada = min(tiempo_de_entrada, duracion * 0.5)
		var salida = min(tiempo_de_salida, duracion * 0.5)

		var peso = 1.0
		if entrada > 0.0:
			peso = min(peso, transcurrido / entrada)
		if salida > 0.0:
			peso = min(peso, efecto["tiempo_restante"] / salida)
		peso = clamp(peso, 0.0, 1.0)

		total *= 1.0 + (efecto["factor"] - 1.0) * peso

	enrutador.velocidad_avance = _velocidad_base * total


func _aplicar_efecto_temporal(factor, duracion):
	# Ya no toca la velocidad aca. Solo anota el efecto; el empujon
	# lo va metiendo de a poco _actualizar_efectos_temporales.
	_efectos_temporales.append({
		"factor": factor,
		"tiempo_restante": duracion,
		"duracion": duracion
	})


func _leer_controles(delta):
	if modo_arreo_ritmo:
		if Input.is_action_just_pressed("arreo"):
			_ejecutar_arreo_ritmo()
		return

	if Input.is_action_just_pressed("frenar"):
		_ejecutar_frenado()

	if Input.is_action_just_pressed("latigazo_derecho") and mano_derecha:
		_ejecutar_latigazo()

	if Input.is_action_just_pressed("latigazo_izquierdo") and not mano_derecha:
		_ejecutar_latigazo()

	if Input.is_action_just_pressed("cambiar_mano"):
		_cambiar_mano()

	# SOLUCION TEMPORAL: la direccion se bloquea en curva, porque es
	# ahi (y solo ahi) donde el caballo se ladea al usarla. Se
	# permite de nuevo apenas vuelve a la recta. No toca latigo,
	# freno ni arreo - solo izquierda/derecha.
	var puede_girar = true
	var trackpath = enrutador.get_parent()
	if trackpath and trackpath.has_method("es_zona_recta"):
		puede_girar = trackpath.es_zona_recta(enrutador.offset)

	if puede_girar:
		if Input.is_action_pressed("girar_derecha"):
			enrutador.h_offset = clamp(
				enrutador.h_offset + giro_velocidad * delta, h_offset_minimo, h_offset_maximo
			)
		elif Input.is_action_pressed("girar_izquierda"):
			enrutador.h_offset = clamp(
				enrutador.h_offset - giro_velocidad * delta, h_offset_minimo, h_offset_maximo
			)

	if Input.is_action_just_pressed("arreo"):
		_ejecutar_arreo()


func _ejecutar_arreo():
	conteo_arreos += 1
	ultima_accion_nombre = "Arreo"
	conteo_acciones_total += 1
	if conteo_arreos <= arreo_limite_seguro and estamina_actual >= arreo_costo_estamina:
		estamina_actual -= arreo_costo_estamina
		_aplicar_efecto_temporal(1.0 + arreo_incremento, duracion_efecto)
		_reproducir_si_existe(animacion_arreo)
	else:
		_aplicar_efecto_temporal(1.0 - arreo_penalizacion, duracion_efecto * penalizacion_proporcion_duracion)


func _ejecutar_arreo_ritmo():
	conteo_arreos += 1
	ultima_accion_nombre = "Arreo"
	conteo_acciones_total += 1

	var ahora = OS.get_ticks_msec() / 1000.0
	var en_ritmo = false
	if _tiempo_ultimo_arreo >= 0.0:
		var intervalo = ahora - _tiempo_ultimo_arreo
		en_ritmo = intervalo >= ritmo_intervalo_ideal_min and intervalo <= ritmo_intervalo_ideal_max
	_tiempo_ultimo_arreo = ahora

	if estamina_actual >= arreo_costo_estamina and conteo_arreos <= arreo_limite_ritmo:
		estamina_actual -= arreo_costo_estamina
		if en_ritmo:
			_aplicar_efecto_temporal(1.0 + ritmo_boost, duracion_efecto)
		else:
			_aplicar_efecto_temporal(1.0 + ritmo_boost_fuera_de_ritmo, duracion_efecto)
		_reproducir_si_existe(animacion_arreo)
	else:
		_aplicar_efecto_temporal(1.0 - ritmo_penalizacion, duracion_efecto * penalizacion_proporcion_duracion)


func _ejecutar_latigazo():
	conteo_racha_actual += 1
	ultima_accion_nombre = "Látigo"
	conteo_acciones_total += 1
	if conteo_racha_actual <= limite_racha_actual and estamina_actual >= latigazo_costo_estamina:
		estamina_actual -= latigazo_costo_estamina
		_aplicar_efecto_temporal(1.0 + latigazo_incremento, duracion_efecto)
		_reproducir_si_existe(animacion_latigazo_derecha if mano_derecha else animacion_latigazo_izquierda)
	else:
		_aplicar_efecto_temporal(1.0 - latigazo_penalizacion, duracion_efecto * penalizacion_proporcion_duracion)


func _cambiar_mano():
	mano_derecha = not mano_derecha
	conteo_racha_actual = 0
	limite_racha_actual = latigazo_limite_tras_cambio
	tiempo_aviso_combo = 1.5
	_reproducir_si_existe(animacion_cambio_mano)


func _ejecutar_frenado():
	_aplicar_efecto_temporal(1.0 - frenado_reduccion, duracion_efecto)
	_reproducir_si_existe(animacion_frenado)


func _reproducir_si_existe(nombre_animacion):
	if animador_jinete and nombre_animacion != "" and animador_jinete.has_animation(nombre_animacion):
		animador_jinete.play(nombre_animacion)
