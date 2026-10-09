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
export var tope_empujon = 1.40          # lo maximo que puede subir la velocidad sumando arreos y latigazos (1.40 = 40% mas)
export var piso_empujon = 0.70          # lo minimo que puede bajar con frenos y castigos
export var suavidad_aceleracion = 1.5   # mas bajo = acelera y frena mas suave; mas alto = mas brusco

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
# Antes de este nivel no hay limite de arreos ni de latigazos, ni castigo:
# manda solo la estamina. (La carrera de 800 m sigue con su modo propio.)
export var limites_desde_nivel = 11

export var frenado_reduccion = 0.10

export var giro_velocidad = 40.0
# Suavidad del cambio de carril: mas bajo = arranca y frena de lado mas
# suave; mas alto = mas brusco. Con 4 tarda como medio segundo en
# tomar toda la velocidad de lado.
export var suavidad_giro = 4.0
var _velocidad_lateral = 0.0
export var h_offset_minimo = 5.0
export var h_offset_maximo = 170.0

# --- Choques entre caballos ------------------------------------
# Deja cambiar de carril tambien en las curvas. Si algun dia el
# caballo vuelve a ladearse al girar en curva, desmarca esta
# casilla y queda como antes (solo se cambia de carril en recta).
export var permitir_carril_en_curva = true

# Impide que un caballo atraviese a otro de costado (el tuyo y los
# rivales). Solo frena el movimiento de lado HACIA el otro caballo;
# alejarse siempre se puede.
export var impedir_atravesarse = true

# Estos cuatro numeros viven en GestorNivel. Desde aqui se los
# escribimos al arrancar, para que tambien queden en el APK y en
# el EXE (lo que se mueve en el panel F1 solo se guarda en esta
# computadora, y en ella manda el panel).
# Ancho del caballo: si dos van mas cerca que esto de costado, se tocan.
export var ancho_del_caballo = 8.0
# Largo del caballo: cuanto puede acercarse el de atras al de adelante.
export var largo_del_caballo = 9.0
# Separacion que buscan los rivales entre ellos cuando corren juntos.
export var separacion_entre_caballos = 10.0
# Que tan rapido el freno echa hacia atras al que se mete encima de
# otro. Mas bajo = mas suave, con menos saltos. No lo bajes de 20.
export var retroceso_maximo_freno = 30.0
# Cuanto puede avanzar un caballo en un solo cuadro para que el juez lo
# cuente. Antes era 20: si el telefono se trababa un momento (un tiron),
# el que iba rapido avanzaba mas de 20 en ese cuadro y el juez le borraba
# ese pedazo de carrera. Por eso al que venia con turbo lo bajaban de
# puesto. 200 solo descarta saltos de verdad imposibles.
export var salto_maximo_juez = 200.0

# --- Largada y lote --------------------------------------------
# Todos salen juntos de la gatera. Marca esta casilla solo si
# quieres volver a la salida por tandas.
export var salida_por_tandas = false
# Al arrancar, corre la gatera para que la casilla 1 quede sobre tu
# caballo y pone a cada rival en su propia casilla, separados por el
# ancho de casilla del Gate. Mientras esperan en la gatera, nadie se
# mueve de su casilla. Si la desmarcas, todo queda como en la escena.
export var cuadrar_gatera = true
# Endereza el punto invisible que sigue cada caballo por la pista (ver
# _enderezar_enrutadores). Hace que el juez de llegada mida lo mismo que
# se ve. Desmarcalo solo para volver a como estaba.
export var enderezar_enrutadores = true
# Pone el dibujo de cada rival en el mismo lugar respecto de su punto
# invisible que el tuyo. Antes cada dibujo estaba corrido distinto (el 10
# casi 7 unidades mas adelante que el tuyo respecto de su punto), asi que
# el juez, los choques y la baranda no coincidian con lo que se ve.
export var igualar_dibujos = true
# Que tan fuerte el juego amarra a los rivales al centro del lote.
# Con 0.6 (lo que traian) los de velocidad media quedaban pegados al
# promedio y se apilaban en el medio. Mas bajo = cada uno corre segun
# su estilo (punteros adelante, rematadores atras) y el lote se
# estira. Mas alto = lote mas apretado. Solo se le baja a los que
# tenian mas que esto; el 9 y el 10 quedan como estaban.
export var fuerza_del_lote = 0.15
# Tope de cuanto puede acelerar o frenar un rival para volver al lote.
export var correccion_maxima_lote = 14.0

# --- Tipo de carrera ------------------------------------------
# En cada carrera se sortea uno de seis tipos. Cada uno arma una formacion
# distinta durante la carrera, y en la parte final se "suelta" para que
# cada caballo corra segun su papel (los punteros se cansan y los
# rematadores atropellan):
#   Amontonada:    el lote va junto, casi todos en dos o tres cuerpos.
#   Estirada:      fila larga, de punta a cola unos 14 cuerpos.
#   Fuga:          uno se escapa como 10 cuerpos; el lote lo persigue.
#   Tres punteros: tres en fila adelante (primero, segundo y tercero),
#                  el lote en el medio y los rematadores bien atras.
#   Mano a mano:   dos cabeza a cabeza en la punta toda la carrera;
#                  a veces uno se cansa y a veces llegan asi.
#   Atropellada:   los rematadores van muy atras (unos 10 cuerpos) y
#                  vienen con todo en la recta final.
# Para probar uno en particular, eligelo aqui ("Al azar" = se sortea).
export(String, "Al azar", "Amontonada", "Estirada", "Fuga", "Tres punteros", "Mano a mano", "Atropellada") var tipo_de_carrera = "Al azar"

# Que cada caballo galope a su propio compas y no todos con la misma
# pata al mismo tiempo.
export var galopes_desfasados = true

# --- Estilos de los rivales ------------------------------------
# Papeles que se reparten los 9 rivales segun el tipo de carrera:
#   - Puntero que se cansa: va adelante y se apaga al final.
#   - Puntero de hierro: va adelante y aguanta (se cansa muy poco).
#   - Parejo: corre igual toda la carrera, en el medio del lote.
#   - Rematador: viene atras y atropella en la recta final.
#   - Rematador de fondo: el ultimo del lote y atropella fuerte.
#   - Fugado: se escapa lejos y despues se cansa (solo en "Fuga").
# Desmarca usar_estilos para volver a como corria cada caballo antes.
export var usar_estilos = true
# Si lo desmarcas, cada caballo tiene siempre el mismo papel.
export var estilos_al_azar = true
# Velocidad de cada papel. "Salida" es al principio, "llegada" en la meta,
# y "cambio" es en que parte de la carrera empieza a cambiar
# (0.6 = cuando va el 60% de la carrera).
export var puntero_salida = 26.5
export var puntero_llegada = 21.5
export var puntero_cambio = 0.6
export var hierro_salida = 25.5
export var hierro_llegada = 24.8
export var hierro_cambio = 0.7
export var parejo_velocidad = 25.0
export var rematador_salida = 24.0
export var rematador_llegada = 29.5
export var rematador_cambio = 0.65
export var fondo_salida = 23.5
export var fondo_llegada = 31.0
export var fondo_cambio = 0.65
export var fuga_salida = 26.0
export var fuga_llegada = 21.5
export var fuga_cambio = 0.6
# Cuanto puede variar cada rival de una carrera a otra (0.06 = 6%).
export var variacion_forma_del_dia = 0.06
# Que tan firme cada rival mantiene su lugar en la formacion.
export var fuerza_de_formacion = 0.25
export var correccion_maxima_formacion = 8.0
# Al largar, todos salen juntos del aparato y van tomando su lugar en la
# formacion poco a poco, en estos metros (antes los que debian ir atras
# se frenaban desde el primer metro y se quedaban en el aparato).
export var metros_para_formarse = 250.0
# En que parte de la carrera se suelta la formacion: empieza a soltarse en
# "liberar_desde" y queda libre del todo en "liberar_hasta" (0.8 = 80%).
export var liberar_desde = 0.65
export var liberar_hasta = 0.8
# Ningun rival puede sacarle al segundo mas de estos cuerpos. Si lo
# intenta, afloja solo. Pon 0 para quitar este tope.
export var ventaja_maxima_cuerpos = 12.0

# --- Como llegan a la meta (cada rival independiente) ----------
# En cada carrera se reparte la "forma del dia" por grupos, al azar:
#   - 3 rivales en punta, parejos entre si (final apretado de 1, 2, 3).
#   - 3 en el medio, a pocos cuerpos.
#   - el resto en la cola, mas atras.
#   - de 0 a 2 "burros" que se quedan lejos.
# Y a veces el final es distinto:
#   Escapada: uno sale adelante y gana de punta a punta por mucho.
#   Remate de lejos: un rematador viene del fondo y gana por mucho.
#   Llegada amontonada: todos llegan juntos (pasa, pero es raro).
# Desmarca reparto_de_llegada para volver a como era antes.
export var reparto_de_llegada = true
export var probabilidad_escapada = 0.1
export var probabilidad_remate_de_lejos = 0.1
export var probabilidad_llegada_amontonada = 0.1
export var forma_punta = 0.01          # 0.01 = los 3 de punta varian solo 1%
export var forma_medio_min = 0.95
export var forma_medio_max = 0.98
export var forma_cola_min = 0.90
export var forma_cola_max = 0.95
export var forma_burro_min = 0.82
export var forma_burro_max = 0.88
export var burros_maximo = 2
export var forma_estrella = 1.07       # el que se escapa o el que remata de lejos
# Que tan rapido afloja el que se quiere escapar (mas alto = mas firme).
export var freno_escapada = 15.0

# --- Paneles de la derecha (puesto y distancia) ------------------
export var mostrar_paneles_derecha = true
# Quita la linea "Puesto" del panel izquierdo, que ya esta lleno.
export var quitar_puesto_de_la_izquierda = true
export var tamano_letra_paneles = 16
# Mismos colores del cartel de llegada: letras amarillas, fondo morado, borde lila.
export var color_texto_paneles = Color(0.992157, 0.941176, 0.2, 1)
export var color_fondo_paneles = Color(0.17, 0.10, 0.42, 0.93)
export var color_borde_paneles = Color(0.60, 0.48, 1.0, 0.95)
# Borde negro alrededor de cada letra (0 = sin borde).
export var contorno_letra_paneles = 2
export var grosor_borde_paneles = 2
export var redondeo_paneles = 8
export var relleno_paneles = Vector2(12, 4)
# Distancia desde el borde derecho y desde arriba (debajo de PAUSAR).
export var margen_derecho_paneles = 16
export var margen_arriba_paneles = 60
export var separacion_paneles = 6

# --- Panel F1 y foto del photo finish -------------------------
# Quita el panel de ajustes (F1): el jugador no lo necesita y confunde.
# Los botones PAUSAR y REINICIAR los pone este script, iguales que antes.
export var quitar_panel_f1 = true
# Pausar y reanudar tambien con el teclado: la letra P o la tecla Pausa.
export var pausar_con_teclado = true
# Quita la franja negra de arriba de la foto. El boton CERRAR queda
# encima de la foto, en la esquina de arriba a la derecha.
export var foto_sin_franja = true
# Alto de la foto (el ancho es 1200; antes era 420). Mas alto = la foto
# crece hacia abajo, sin tocar el cartel de la derecha. El plano se abre
# solo para que se vea mas arriba y mas abajo, no mas de cerca.
export var alto_de_la_foto = 560
# Toma la foto justo cuando la cabeza del primero llega al poste de
# FINISH, midiendo el dibujo del caballo (no un calculo por adelantado).
export var foto_en_la_raya = true
# Corre el momento de la foto, en unidades de pista: positivo = la cabeza
# sale un poco pasada del poste; negativo = un poco antes. 0 = en el poste.
export var ajuste_cabeza_foto = 0.0
# Raya roja de photo finish sobre la foto, en el poste de FINISH.
export var mostrar_raya_foto = true

export var estamina_maxima = 100.0
export var estamina_regen_por_segundo = 3.0

export var color_aviso = Color(0.992157, 0.941176, 0.2, 1)
export var escala_aviso = 3.0

# --- Aspecto del cartel de llegada (panel azul-violeta) ---
export var tamano_aviso = 30
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
export var posicion_aviso = Vector2(1.0, 0.5)

# Empujoncito fino en pixeles, por si querés despegarlo un poco
# del borde. X positivo lo corre a la derecha, Y positivo lo baja.
export var desplazar_aviso = Vector2(-16, 0)

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
# Segundos que espera la tabla de posiciones despues de que cruzas
# la meta, para dejar ver el cruce. 0 = sale al instante, como antes.
export var segundos_antes_de_tabla = 2.0

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

# Donde estaba cada caballo de costado en el cuadro anterior, para
# saber quien se movio hacia quien.
var _h_previo = {}

var _label_puesto = null
var _label_distancia = null
var _caja_paneles = null

onready var enrutador = get_parent()
onready var animador = get_node(animador_path) if animador_path != NodePath("") else null
onready var animador_jinete = get_node(animador_jinete_path) if animador_jinete_path != NodePath("") else null
onready var label_velocidad = get_node(label_velocidad_path) if label_velocidad_path != NodePath("") else null


func _ready():
	# Este script corre DESPUES de que todos los caballos se movieron
	# en el cuadro (y antes que Caballo_final y Jinete_final, que van
	# en 100). Asi el control de choques ve la posicion final de cada
	# uno antes de que se dibuje.
	process_priority = 90

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
	_aplicar_ajustes_de_choque()
	call_deferred("_preparar_largada_y_lote")
	call_deferred("_crear_paneles_derecha")
	call_deferred("_preparar_pantalla")

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


func _aplicar_ajustes_de_choque():
	if GestorNivel == null:
		return
	GestorNivel.distancia_frenado_lateral = ancho_del_caballo
	GestorNivel.distancia_frenado_longitudinal = largo_del_caballo
	GestorNivel.distancia_minima_lateral = separacion_entre_caballos
	GestorNivel.velocidad_maxima_retroceso = retroceso_maximo_freno
	if "salto_maximo_por_cuadro" in GestorNivel:
		GestorNivel.salto_maximo_por_cuadro = salto_maximo_juez


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

	# Retraso de la tabla para que se vea el cruce de la raya.
	if segundos_antes_de_tabla > 0.0:
		yield(get_tree().create_timer(segundos_antes_de_tabla), "timeout")
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
	_cerrar_resultado()

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

	# Si ganas, letras amarillas (color_aviso) aunque haya photo finish.
	# El color de photo finish queda solo para cuando no ganas.
	if hay_photo and posicion_llegada != 1:
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
			marca = "   <-- TÚ"
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
		nombre += "   <-- TÚ"
	return nombre


func _al_terminar_gesto(anim_name):
	animador_jinete.seek(0, true)
	animador_jinete.stop(false)


func _process(delta):
	if carrera_terminada:
		_foto_en_la_raya()
		_desfasar_galopes()
		_actualizar_ritmo_rivales()
		_limitar_escapada(delta)
		_impedir_atravesarse()
		_actualizar_paneles_derecha()
		return
	_actualizar_efectos_temporales(delta)
	_leer_controles(delta)
	estamina_actual = min(estamina_maxima, estamina_actual + estamina_regen_por_segundo * delta)
	if tiempo_aviso_combo > 0:
		tiempo_aviso_combo -= delta
	_revisar_linea_de_meta()
	_actualizar_pantalla()
	_foto_en_la_raya()
	_desfasar_galopes()
	_actualizar_ritmo_rivales()
	_limitar_escapada(delta)
	_impedir_atravesarse()
	_actualizar_paneles_derecha()


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
	# El puesto y el nivel se cierran con el orden del juez (ver
	# _cerrar_resultado). Si no hay cartel, se cierra ya mismo.
	if not _label_aviso:
		_cerrar_resultado()
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

	if modo_arreo_ritmo and not _sin_limites():
		texto += "Arreos: %d / %d\n" % [conteo_arreos, arreo_limite_ritmo]
	elif not _sin_limites():
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

	total = clamp(total, piso_empujon, tope_empujon)
	enrutador.velocidad_avance = lerp(enrutador.velocidad_avance, _velocidad_base * total, clamp(suavidad_aceleracion * delta, 0.0, 1.0))


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

	# El latigo va siempre en la mano derecha: ya no hay cambio de mano.
	# (En la PC es el clic derecho; el izquierdo no se usa, porque en el
	# telefono cada toque de pantalla cuenta como clic izquierdo.)
	if Input.is_action_just_pressed("latigazo_derecho"):
		_ejecutar_latigazo()

	# Antes la direccion se bloqueaba en curva porque ahi el caballo
	# se ladeaba al girar. En curva, cada cambio de h_offset hace que
	# Godot le sume un poquito de giro al enrutador. Ahora el cambio de
	# carril pasa por _mover_de_lado, que repone el giro, asi que ya
	# no hace falta bloquear la curva (ver permitir_carril_en_curva).
	var puede_girar = true
	if not permitir_carril_en_curva:
		var trackpath = enrutador.get_parent()
		if trackpath and trackpath.has_method("es_zona_recta"):
			puede_girar = trackpath.es_zona_recta(enrutador.offset)

	var direccion_lateral = 0.0
	if puede_girar:
		if Input.is_action_pressed("girar_derecha"):
			direccion_lateral = 1.0
		elif Input.is_action_pressed("girar_izquierda"):
			direccion_lateral = -1.0
	_velocidad_lateral = lerp(_velocidad_lateral, direccion_lateral * giro_velocidad, clamp(suavidad_giro * delta, 0.0, 1.0))
	if abs(_velocidad_lateral) > 0.05:
		_mover_de_lado(enrutador, clamp(
			enrutador.h_offset + _velocidad_lateral * delta, h_offset_minimo, h_offset_maximo
		))

	if Input.is_action_just_pressed("arreo"):
		_ejecutar_arreo()


func _ejecutar_arreo():
	conteo_arreos += 1
	ultima_accion_nombre = "Arreo"
	conteo_acciones_total += 1
	if _sin_limites():
		# Sin limite ni castigo: si queda estamina empuja, si no, nada.
		if estamina_actual >= arreo_costo_estamina:
			estamina_actual -= arreo_costo_estamina
			_aplicar_efecto_temporal(1.0 + arreo_incremento, duracion_efecto)
			_reproducir_si_existe(animacion_arreo)
		return
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

	if estamina_actual >= arreo_costo_estamina and (_sin_limites() or conteo_arreos <= arreo_limite_ritmo):
		estamina_actual -= arreo_costo_estamina
		if en_ritmo:
			_aplicar_efecto_temporal(1.0 + ritmo_boost, duracion_efecto)
		else:
			_aplicar_efecto_temporal(1.0 + ritmo_boost_fuera_de_ritmo, duracion_efecto)
		_reproducir_si_existe(animacion_arreo)
	elif not _sin_limites():
		_aplicar_efecto_temporal(1.0 - ritmo_penalizacion, duracion_efecto * penalizacion_proporcion_duracion)


func _ejecutar_latigazo():
	conteo_racha_actual += 1
	ultima_accion_nombre = "Látigo"
	conteo_acciones_total += 1
	if _sin_limites():
		# Sin limite ni castigo: si queda estamina empuja, si no, nada.
		if estamina_actual >= latigazo_costo_estamina:
			estamina_actual -= latigazo_costo_estamina
			_aplicar_efecto_temporal(1.0 + latigazo_incremento, duracion_efecto)
			_reproducir_si_existe(animacion_latigazo_derecha)
		return
	if conteo_racha_actual <= limite_racha_actual and estamina_actual >= latigazo_costo_estamina:
		estamina_actual -= latigazo_costo_estamina
		_aplicar_efecto_temporal(1.0 + latigazo_incremento, duracion_efecto)
		_reproducir_si_existe(animacion_latigazo_derecha if mano_derecha else animacion_latigazo_izquierda)
	else:
		_aplicar_efecto_temporal(1.0 - latigazo_penalizacion, duracion_efecto * penalizacion_proporcion_duracion)


# Niveles bajos: sin limites de arreo ni de latigo (solo estamina).
func _sin_limites():
	return GestorNivel == null or GestorNivel.nivel_actual < limites_desde_nivel


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


# ------------------------------------------------------------
# CHOQUES DE COSTADO
# ------------------------------------------------------------
# Mueve un caballo de lado sin que se ladee. En curva, cambiar
# h_offset hace que Godot le sume un poquito de giro al enrutador;
# aqui se guarda el giro antes y se repone despues.
func _mover_de_lado(nodo, nuevo_h):
	var giro = nodo.rotation
	nodo.h_offset = nuevo_h
	nodo.rotation = giro


# Revisa a los 10 caballos de a pares. Si dos estan uno al lado del
# otro (a menos de un largo de caballo, adelante o atras) y alguno
# se movio de costado hacia el otro hasta tocarlo, se le devuelve
# solo lo que se metio. Asi nadie atraviesa a nadie de costado, y
# alejarse siempre se puede. De adelante hacia atras se encarga el
# freno de GestorNivel, como hasta ahora.
func _impedir_atravesarse():
	if not impedir_atravesarse or enrutador == null or GestorNivel == null:
		return
	var camino = enrutador.get_parent()
	if camino == null or not ("curve" in camino) or camino.curve == null:
		return
	var largo_pista = camino.curve.get_baked_length()
	if largo_pista <= 0.0:
		return

	var caballos = []
	for hijo in camino.get_children():
		if hijo is PathFollow and hijo.name.begins_with("Enrutador_Caballo"):
			caballos.append(hijo)
			if not _h_previo.has(hijo):
				_h_previo[hijo] = hijo.h_offset

	var ancho = GestorNivel.distancia_frenado_lateral
	var largo = GestorNivel.distancia_frenado_longitudinal
	var h = {}
	for c in caballos:
		h[c] = c.h_offset
		# Mientras espera en la gatera (todavia no largo), se queda
		# quieto en su casilla aunque otro sistema lo quiera correr.
		if cuadrar_gatera and not c.is_processing() and ("separacion_lateral" in c):
			h[c] = c.separacion_lateral

	for _pasada in range(3):
		for i in range(caballos.size()):
			for j in range(i + 1, caballos.size()):
				var a = caballos[i]
				var b = caballos[j]
				var d = fposmod(a.offset - b.offset + largo_pista * 0.5, largo_pista) - largo_pista * 0.5
				if abs(d) >= largo:
					continue
				var antes = _h_previo[a] - _h_previo[b]
				var lado = 1.0
				if antes < 0.0:
					lado = -1.0
				var hueco_minimo = min(ancho, abs(antes))
				var hueco_ahora = (h[a] - h[b]) * lado
				if hueco_ahora >= hueco_minimo:
					continue
				var se_acerco_a = max(0.0, (_h_previo[a] - h[a]) * lado)
				var se_acerco_b = max(0.0, (h[b] - _h_previo[b]) * lado)
				var total = se_acerco_a + se_acerco_b
				if total <= 0.0:
					continue
				var faltante = hueco_minimo - hueco_ahora
				h[a] += lado * faltante * se_acerco_a / total
				h[b] -= lado * faltante * se_acerco_b / total

	for c in caballos:
		if abs(h[c] - c.h_offset) > 0.001:
			_mover_de_lado(c, h[c])
		_h_previo[c] = c.h_offset


# ------------------------------------------------------------
# LARGADA Y LOTE
# ------------------------------------------------------------
# Corre una sola vez, cuando el resto de la escena ya se armo.
func _preparar_largada_y_lote():
	var camino = enrutador.get_parent()
	if camino == null:
		return
	_elegir_tipo_de_carrera()
	var gate = camino.get_node_or_null("Aparato_Partida/Gate")
	if gate and ("largada_escalonada" in gate):
		gate.largada_escalonada = salida_por_tandas

	for hijo in camino.get_children():
		if hijo == enrutador or not (hijo is PathFollow) or not hijo.name.begins_with("Enrutador_Caballo"):
			continue
		if "factor_agrupacion" in hijo:
			if usar_estilos:
				# La formacion reemplaza a la liga que los amarraba al centro.
				hijo.factor_agrupacion = 0.0
			elif hijo.factor_agrupacion > fuerza_del_lote:
				hijo.factor_agrupacion = fuerza_del_lote
		if ("correccion_maxima" in hijo) and hijo.correccion_maxima > correccion_maxima_lote:
			hijo.correccion_maxima = correccion_maxima_lote

	if enderezar_enrutadores:
		_enderezar_enrutadores(camino)
	if igualar_dibujos:
		_igualar_dibujos(camino)

	# En 800 m, tu meta propia pasa a ser exactamente la misma del juez.
	if _modo_recta_propio and GestorNivel and ("_objetivo_recta" in GestorNivel):
		var objetivo_juez = GestorNivel._objetivo_recta.get(enrutador, 0.0)
		if objetivo_juez > 0.0:
			_distancia_objetivo_propia = objetivo_juez

	if usar_estilos:
		_aplicar_estilos(camino)

	if cuadrar_gatera and gate:
		_cuadrar_gatera(camino, gate)
	# Los carriles cambiaron: el control de choques arranca de cero.
	_h_previo.clear()


# Corre la gatera para que la casilla 1 quede justo sobre tu caballo
# (el 1 va pegado a la baranda) y pone a cada rival en su casilla,
# moviendolo solo de costado. Nadie se adelanta ni se atrasa.
func _cuadrar_gatera(camino, gate):
	if not ("ancho_casilla" in gate) or not ("cantidad_casillas" in gate):
		return
	var caballos = []
	# Todos los caballos que haya (antes se cortaba en el 10).
	for n in range(1, _contar_caballos(camino) + 1):
		caballos.append(camino.get_node_or_null("Enrutador_Caballo%d" % n))
	if caballos[0] == null:
		return

	var cuantas = int(max(gate.cantidad_casillas, 1))
	var ancho = float(gate.ancho_casilla)
	var x_borde = -cuantas * ancho / 2.0
	if "corrimiento_lateral" in gate:
		x_borde += gate.corrimiento_lateral
	var z_casilla = 0.0
	if "corrimiento_adelante" in gate:
		z_casilla = gate.corrimiento_adelante

	# La casilla 1 es la de la punta del aparato mas cercana a tu caballo.
	var centro_1 = _centro_visual(caballos[0])
	var punta_a = gate.global_transform.xform(Vector3(x_borde + ancho * 0.5, 0.0, z_casilla))
	var punta_b = gate.global_transform.xform(Vector3(x_borde + ancho * (cuantas - 0.5), 0.0, z_casilla))
	var primera = 0
	var sentido = 1
	var punta = punta_a
	if _distancia_plana(centro_1, punta_b) < _distancia_plana(centro_1, punta_a):
		primera = cuantas - 1
		sentido = -1
		punta = punta_b
	# El aparato ya no adivina de que lado va el 1: se lo decimos aqui.
	if "_uno_en_menos_x" in gate:
		var uno_en_menos = (primera == 0)
		gate._numeracion_revisada = true
		gate._uno_en_menos_x = uno_en_menos
		if gate._uno_actual != uno_en_menos:
			gate._reconstruir()

	# Se corre el aparato (sin subirlo ni bajarlo) hasta tu caballo.
	var mover = centro_1 - punta
	mover.y = 0.0
	var t = gate.global_transform
	t.origin += mover
	gate.global_transform = t

	# Cada caballo (el jugador tambien) a la casilla que le toco en
	# el sorteo de GestorNivel. La casilla 1 sigue pegada a la baranda.
	for n in range(1, caballos.size() + 1):
		var c = caballos[n - 1]
		if c == null or not ("separacion_lateral" in c):
			continue
		var puesto = n
		if GestorNivel and GestorNivel.has_method("obtener_puesto"):
			puesto = GestorNivel.obtener_puesto(c)
		if puesto < 1 or puesto > cuantas:
			continue
		var k = primera + (puesto - 1) * sentido
		var destino = gate.global_transform.xform(Vector3(x_borde + ancho * (k + 0.5), 0.0, z_casilla))
		var eje = c.global_transform.basis.x
		var escala = eje.length()
		if escala < 0.0001:
			continue
		var diferencia = (destino - _centro_visual(c)).dot(eje / escala) / escala
		c.separacion_lateral = c.h_offset + diferencia


func _distancia_plana(a, b) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# Centro de lo que se ve del caballo (la malla mas grande que cuelga
# del enrutador), no del punto invisible que sigue la pista.
func _centro_visual(nodo) -> Vector3:
	var mejor = null
	var mayor = -1.0
	var pendientes = [nodo]
	while pendientes.size() > 0:
		var actual = pendientes.pop_back()
		for hijo in actual.get_children():
			pendientes.append(hijo)
			if hijo is MeshInstance:
				var caja = hijo.get_transformed_aabb()
				if caja.size.length() > mayor:
					mayor = caja.size.length()
					mejor = caja
	if mejor == null:
		return nodo.global_transform.origin
	return mejor.position + mejor.size * 0.5


# ------------------------------------------------------------
# ESTILOS Y ESCAPADAS
# ------------------------------------------------------------
# Le pone a cada rival la velocidad de su estilo, con una forma del dia
# chica. Pisa la que cada rival se sorteo al arrancar.
# Formacion de cada tipo: [papel, lugar respecto del centro del lote].
# El lugar esta en unidades para una carrera de 1600 (un cuerpo es mas o
# menos 9); en carreras mas cortas o mas largas se achica o se estira.
const FORMACIONES = {
	"Amontonada": [["puntero", 8], ["puntero", 5], ["hierro", 3], ["parejo", 0], ["parejo", -2], ["parejo", -4], ["rematador", -8], ["rematador", -10], ["fondo", -14]],
	"Estirada": [["puntero", 45], ["puntero", 36], ["puntero", 27], ["hierro", 18], ["parejo", 6], ["parejo", -6], ["rematador", -24], ["rematador", -36], ["fondo", -50]],
	"Fuga": [["fuga", 70], ["puntero", 10], ["hierro", 8], ["parejo", 2], ["parejo", 0], ["parejo", -3], ["rematador", -25], ["rematador", -30], ["fondo", -45]],
	"Tres punteros": [["puntero", 32], ["puntero", 23], ["hierro", 14], ["parejo", 0], ["parejo", -4], ["parejo", -8], ["rematador", -40], ["rematador", -45], ["fondo", -60]],
	"Mano a mano": [["duelo", 25], ["duelo", 25], ["parejo", 5], ["parejo", 2], ["parejo", 0], ["hierro", -3], ["rematador", -30], ["rematador", -35], ["fondo", -50]],
	"Atropellada": [["puntero", 15], ["puntero", 12], ["puntero", 9], ["hierro", 6], ["parejo", 0], ["parejo", -3], ["rematador", -60], ["rematador", -70], ["fondo", -80]]
}

# Cuenta los Enrutador_Caballo1, 2, 3... seguidos que haya en la pista.
func _contar_caballos(camino):
	var n = 0
	while camino.get_node_or_null("Enrutador_Caballo%d" % (n + 1)) != null:
		n += 1
	return n


func _aplicar_estilos(camino):
	var rivales = []
	# Todos los rivales que haya (antes se cortaba en el 10).
	for n in range(2, _contar_caballos(camino) + 1):
		var c = camino.get_node_or_null("Enrutador_Caballo%d" % n)
		if c and (("velocidad_inicial" in c) or ("velocidad_base" in c)):
			rivales.append(c)
	var lugares = FORMACIONES.get(_tipo_elegido, FORMACIONES["Amontonada"]).duplicate(true)
	# Si hay mas rivales que lugares en la formacion (11 y 12), se les
	# agrega un papel del medio del lote, para que nadie quede sin plan.
	var extras = [["parejo", -5], ["rematador", -18], ["parejo", 3], ["hierro", 1]]
	var k_extra = 0
	while lugares.size() < rivales.size():
		lugares.append(extras[k_extra % extras.size()].duplicate())
		k_extra += 1
	if estilos_al_azar:
		lugares.shuffle()
	# Mano a mano: uno de los dos aguanta siempre; el otro a veces se cansa
	# (y a veces aguanta tambien y llegan cabeza a cabeza).
	var los_dos_aguantan = randf() < 0.35
	var duelistas = 0
	_papeles.clear()
	var formas = _repartir_formas(min(rivales.size(), lugares.size()))
	for i in range(min(rivales.size(), lugares.size())):
		var papel = lugares[i][0]
		var lugar = float(lugares[i][1])
		var forma = formas[i] if i < formas.size() else 1.0
		var firmeza = 1.0
		if papel == "duelo":
			papel = "hierro" if (duelistas == 0 or los_dos_aguantan) else "puntero"
			duelistas += 1
			# Los dos duelistas iguales y bien pegados, cabeza a cabeza.
			forma = 1.0
			firmeza = 2.0
		_papeles[rivales[i]] = [papel, forma, lugar, firmeza]
		if diagnostico_llegada:
			print("[BDG-Jockey] ", rivales[i].name, ": ", papel, " en ", lugar, " forma ", stepify(forma, 0.01))
	_sortear_final()
	_actualizar_ritmo_rivales()
	for c in _papeles.keys():
		var arranque = c.velocidad_inicial if ("velocidad_inicial" in c) else c.velocidad_base
		if "velocidad_actual" in c:
			c.velocidad_actual = arranque
		if "velocidad_objetivo" in c:
			c.velocidad_objetivo = arranque


# Reparte la forma del dia por grupos (punta, medio, cola, burros) y la
# mezcla al azar entre los rivales.
func _repartir_formas(cantidad) -> Array:
	var formas = []
	# La de 800 m no se toca: queda como era.
	if not reparto_de_llegada or _modo_recta_propio:
		for i in range(cantidad):
			formas.append(rand_range(1.0 - variacion_forma_del_dia, 1.0 + variacion_forma_del_dia))
		return formas
	var burros = randi() % (int(burros_maximo) + 1)
	for i in range(cantidad):
		var f = 1.0
		if i < 3:
			f = rand_range(1.0 - forma_punta, 1.0 + forma_punta)
		elif i >= cantidad - burros:
			f = rand_range(forma_burro_min, forma_burro_max)
		elif i < 6:
			f = rand_range(forma_medio_min, forma_medio_max)
		else:
			f = rand_range(forma_cola_min, forma_cola_max)
		formas.append(f)
	formas.shuffle()
	return formas


# A veces el final no es el normal: uno se escapa, uno remata de lejos,
# o llegan todos juntos.
func _sortear_final():
	if not reparto_de_llegada or _modo_recta_propio or _papeles.empty():
		return
	var tiro = randf()
	var final = "Normal"
	if tiro < probabilidad_escapada:
		final = "Escapada"
		_hacer_estrella(["fuga", "puntero", "hierro"], "hierro")
	elif tiro < probabilidad_escapada + probabilidad_remate_de_lejos:
		final = "Remate de lejos"
		_hacer_estrella(["rematador", "fondo"], "rematador")
	elif tiro < probabilidad_escapada + probabilidad_remate_de_lejos + probabilidad_llegada_amontonada:
		final = "Llegada amontonada"
		for c in _papeles.keys():
			_papeles[c][1] = rand_range(1.0 - forma_punta, 1.0 + forma_punta)
	if diagnostico_llegada:
		print("[BDG-Jockey] Final: ", final)


func _hacer_estrella(papeles_validos, nuevo_papel):
	var candidatos = []
	for c in _papeles.keys():
		if _papeles[c][0] in papeles_validos:
			candidatos.append(c)
	if candidatos.empty():
		return
	var c = candidatos[randi() % candidatos.size()]
	_papeles[c][0] = nuevo_papel
	_papeles[c][1] = forma_estrella
	if diagnostico_llegada:
		print("[BDG-Jockey] Estrella: ", c.name, " (", nuevo_papel, ")")


# Papel de cada rival: [papel, forma del dia, lugar en la formacion, firmeza].
var _papeles = {}
var _escala_formacion = 1.0

# Cada rival corre a la velocidad de su papel, mas una correccion que lo
# lleva a su lugar en la formacion. En la parte final esa correccion se
# va apagando y queda solo su papel. Corre en cada cuadro.
func _actualizar_ritmo_rivales():
	if not usar_estilos or _papeles.empty() or GestorNivel == null:
		return
	var p = _progreso_carrera()
	var extra = 0.0
	if GestorNivel.has_method("obtener_extra_velocidad_rivales"):
		extra = GestorNivel.obtener_extra_velocidad_rivales()
	# Centro del lote: el recorrido del caballo del medio (contandote a ti).
	var recorridos = [GestorNivel.obtener_recorrido(enrutador)]
	for c in _papeles.keys():
		if is_instance_valid(c):
			recorridos.append(GestorNivel.obtener_recorrido(c))
	recorridos.sort()
	var mitad = recorridos.size() / 2
	var centro = recorridos[mitad]
	if recorridos.size() % 2 == 0:
		centro = (recorridos[mitad - 1] + recorridos[mitad]) / 2.0
	# Cuanto manda la formacion: toda hasta liberar_desde, nada desde liberar_hasta.
	var peso = 1.0
	if p >= liberar_hasta:
		peso = 0.0
	elif p > liberar_desde and liberar_hasta > liberar_desde:
		peso = 1.0 - (p - liberar_desde) / (liberar_hasta - liberar_desde)
	# Salida: la formacion entra de a poco en los primeros metros.
	var entrada = 1.0
	if metros_para_formarse > 0.0 and not GestorNivel.modo_recta:
		entrada = clamp(centro / metros_para_formarse, 0.0, 1.0)
	for c in _papeles.keys():
		if not is_instance_valid(c):
			continue
		var papel = _papeles[c][0]
		var forma = _papeles[c][1]
		var lugar = _papeles[c][2] * _escala_formacion
		var firmeza = _papeles[c][3]
		var correccion = (centro + lugar - GestorNivel.obtener_recorrido(c)) * fuerza_de_formacion * firmeza
		correccion = clamp(correccion, -correccion_maxima_formacion, correccion_maxima_formacion) * peso * entrada
		var ahora = _velocidad_de_papel(papel, p) * forma + extra + correccion
		var al_final = _velocidad_de_papel(papel, 1.0) * forma + extra
		if ("velocidad_inicial" in c) and ("velocidad_final" in c):
			c.velocidad_inicial = ahora
			c.velocidad_final = al_final
		elif "velocidad_base" in c:
			c.velocidad_base = ahora
			# Estos caballos cambian de velocidad cada tantos segundos; aqui se
			# les pone ya, para que la formacion no se les atrase.
			if peso > 0.0 and ("velocidad_objetivo" in c):
				c.velocidad_objetivo = ahora


func _velocidad_de_papel(papel, p) -> float:
	if papel == "puntero":
		return _tramo(puntero_salida, puntero_llegada, puntero_cambio, p)
	if papel == "hierro":
		return _tramo(hierro_salida, hierro_llegada, hierro_cambio, p)
	if papel == "rematador":
		return _tramo(rematador_salida, rematador_llegada, rematador_cambio, p)
	if papel == "fondo":
		return _tramo(fondo_salida, fondo_llegada, fondo_cambio, p)
	if papel == "fuga":
		return _tramo(fuga_salida, fuga_llegada, fuga_cambio, p)
	return parejo_velocidad


func _tramo(salida, llegada, cambio, p) -> float:
	if p <= cambio or cambio >= 1.0:
		return salida
	return lerp(salida, llegada, (p - cambio) / (1.0 - cambio))


# Que parte de la carrera lleva el que va adelante (0 = largada, 1 = meta).
func _progreso_carrera() -> float:
	var total = 0.0
	if GestorNivel.modo_recta and ("_objetivo_recta" in GestorNivel):
		total = GestorNivel._objetivo_recta.get(enrutador, 0.0)
	if total <= 0.0 and ConfiguracionCarrera:
		total = float(ConfiguracionCarrera.distancia_metros)
	if total <= 0.0:
		return 0.0
	var mejor = GestorNivel.obtener_recorrido(enrutador)
	for c in _papeles.keys():
		if is_instance_valid(c):
			mejor = max(mejor, GestorNivel.obtener_recorrido(c))
	return clamp(mejor / total, 0.0, 1.0)


# Si un rival le saca al segundo mas de ventaja_maxima_cuerpos, se le
# frena un poco cada cuadro hasta que vuelva al tope. A ti no.
func _limitar_escapada(delta):
	if ventaja_maxima_cuerpos <= 0.0 or GestorNivel == null or enrutador == null:
		return
	var camino = enrutador.get_parent()
	if camino == null:
		return
	var primero = null
	var rec_primero = -INF
	var rec_segundo = -INF
	for hijo in camino.get_children():
		if not (hijo is PathFollow) or not hijo.name.begins_with("Enrutador_Caballo"):
			continue
		var r = GestorNivel.obtener_recorrido(hijo)
		if r > rec_primero:
			rec_segundo = rec_primero
			rec_primero = r
			primero = hijo
		elif r > rec_segundo:
			rec_segundo = r
	if primero == null or primero == enrutador or rec_segundo == -INF:
		return
	if GestorNivel.ha_terminado(primero):
		return
	var tope = ventaja_maxima_cuerpos * GestorNivel.distancia_frenado_longitudinal
	var sobra = rec_primero - rec_segundo - tope
	if sobra <= 0.0:
		return
	primero.offset -= min(sobra, freno_escapada * delta)


# ------------------------------------------------------------
# PANELES DE LA DERECHA
# ------------------------------------------------------------
func _crear_paneles_derecha():
	if not mostrar_paneles_derecha:
		return
	if quitar_puesto_de_la_izquierda:
		mostrar_puesto_en_vivo = false
	var capa = CanvasLayer.new()
	capa.layer = 5
	add_child(capa)
	var caja = VBoxContainer.new()
	caja.anchor_left = 1.0
	caja.anchor_right = 1.0
	caja.anchor_top = 0.0
	caja.anchor_bottom = 0.0
	caja.margin_left = -margen_derecho_paneles
	caja.margin_right = -margen_derecho_paneles
	caja.margin_top = margen_arriba_paneles
	caja.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_constant_override("separation", int(separacion_paneles))
	capa.add_child(caja)
	# Escondidos hasta que larguen, para no tapar la pantalla de inicio.
	caja.visible = false
	_caja_paneles = caja
	_label_distancia = _crear_panel(caja)
	_label_puesto = _crear_panel(caja)
	_label_distancia.text = "DISTANCIA: " + _texto_distancia()
	_actualizar_paneles_derecha()


func _crear_panel(caja):
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = color_fondo_paneles
	estilo.border_color = color_borde_paneles
	estilo.set_border_width_all(int(grosor_borde_paneles))
	estilo.set_corner_radius_all(int(redondeo_paneles))
	estilo.content_margin_left = relleno_paneles.x
	estilo.content_margin_right = relleno_paneles.x
	estilo.content_margin_top = relleno_paneles.y
	estilo.content_margin_bottom = relleno_paneles.y
	panel.add_stylebox_override("panel", estilo)
	caja.add_child(panel)
	var etiqueta = Label.new()
	etiqueta.align = Label.ALIGN_CENTER
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_color_override("font_color", color_texto_paneles)
	panel.add_child(etiqueta)
	var fuente = etiqueta.get_font("font")
	if fuente and fuente is DynamicFont:
		var chica = DynamicFont.new()
		chica.font_data = fuente.font_data
		chica.size = int(tamano_letra_paneles)
		chica.outline_size = int(contorno_letra_paneles)
		chica.outline_color = fuente.outline_color
		etiqueta.add_font_override("font", chica)
	return etiqueta


func _actualizar_paneles_derecha():
	if _label_puesto == null or GestorNivel == null:
		return
	# Se muestran recien cuando la gatera suelta a tu caballo, y ya no
	# se esconden hasta el final.
	if not _caja_paneles.visible:
		if enrutador.is_processing() and GestorNivel.obtener_tiempo_carrera() > 0.0:
			_caja_paneles.visible = true
		else:
			return
	var puesto = GestorNivel.obtener_posicion(enrutador)
	if carrera_terminada and posicion_llegada > 0:
		puesto = posicion_llegada
	_label_puesto.text = "PUESTO: %d / %d" % [puesto, GestorNivel.obtener_total_corredores()]


# El nombre de la distancia tal como aparece en los botones (1200m,
# 1600m...), buscandolo en el selector de distancias.
func _texto_distancia() -> String:
	if ConfiguracionCarrera == null:
		return ""
	var valor = float(ConfiguracionCarrera.distancia_metros)
	var raiz = get_tree().current_scene
	if raiz:
		var selector = raiz.get_node_or_null("SelectorDistancias")
		if selector and ("distancias" in selector):
			for d in selector.distancias:
				if abs(float(d["valor"]) - valor) < 0.5:
					return str(d["etiqueta"])
	return "%dm" % int(round(valor))


# ------------------------------------------------------------
# ENDEREZAR LOS ENRUTADORES
# ------------------------------------------------------------
# Cada enrutador (el punto invisible que sigue la pista y que el juez usa
# para decidir la llegada) venia girado unos 25 grados respecto de la
# pista, y el dibujo del caballo estaba girado al reves para que se viera
# derecho. Por eso, al correrse de costado, el caballo tambien se iba un
# poco hacia atras (mas afuera = mas atras), y lo que se veia no coincidia
# con lo que media el juez. Aqui se endereza cada enrutador y se gira el
# dibujo lo contrario: el caballo se ve igual, pero de costado se mueve
# solo de costado, y el juez mide lo mismo que se ve.
func _enderezar_enrutadores(camino):
	if not ("curve" in camino) or camino.curve == null:
		return
	var largo = camino.curve.get_baked_length()
	if largo <= 0.0:
		return
	for hijo in camino.get_children():
		if not (hijo is PathFollow) or not hijo.name.begins_with("Enrutador_Caballo"):
			continue
		var o = fposmod(hijo.offset, largo)
		var p1 = camino.curve.interpolate_baked(o)
		var p2 = camino.curve.interpolate_baked(fposmod(o + 1.0, largo))
		var dir = p2 - p1
		if dir.length_squared() < 0.000001:
			continue
		var rumbo = rad2deg(atan2(dir.x, dir.z))
		var actual = _normalizar_angulo(hijo.rotation_degrees.y - rumbo)
		var destino = 0.0
		if abs(actual) > 90.0:
			destino = 180.0
		var giro = _normalizar_angulo(destino - actual)
		if abs(giro) < 0.01:
			continue
		# Todo lo que cuelga del enrutador gira al reves: queda igual en el mundo.
		var compensa = Transform(Basis(Vector3.UP, deg2rad(-giro)), Vector3.ZERO)
		for nieto in hijo.get_children():
			if nieto is Spatial:
				nieto.transform = compensa * nieto.transform
		var r = hijo.rotation_degrees
		r.y += giro
		hijo.rotation_degrees = r
		# Que su propio script siga usando el giro nuevo en cada cuadro.
		if "_calibracion_rotacion" in hijo:
			hijo._calibracion_rotacion = destino
		if "_rotacion_calibrada" in hijo:
			hijo._rotacion_calibrada = true
		# Recalcula su lugar en la pista con el eje ya derecho.
		_mover_de_lado(hijo, hijo.h_offset)
		if diagnostico_llegada:
			print("[BDG-Jockey] ", hijo.name, " enderezado ", stepify(giro, 0.1), " grados")


func _normalizar_angulo(a) -> float:
	return fposmod(a + 180.0, 360.0) - 180.0


# ------------------------------------------------------------
# RESULTADO FINAL
# ------------------------------------------------------------
# Antes el puesto del cartel se calculaba en el instante en que cruzabas,
# con un estimado, y el orden de abajo salia del juez un momento despues.
# Por eso podian no coincidir, y hasta se subia de nivel con el estimado.
# Ahora el puesto sale del mismo orden del juez, y recien ahi se decide
# si subes de nivel. Se hace una sola vez.
var _resultado_cerrado = false

func _cerrar_resultado():
	if _resultado_cerrado:
		return
	_resultado_cerrado = true
	if GestorNivel == null:
		return
	var orden = GestorNivel.obtener_orden_llegada_congelado()
	var mi_puesto = orden.find(enrutador) + 1
	if mi_puesto > 0:
		posicion_llegada = mi_puesto
	var nivel_antes = GestorNivel.nivel_actual
	GestorNivel.subir_nivel_si_gano(posicion_llegada)
	_subio_de_nivel_este_aviso = GestorNivel.nivel_actual > nivel_antes
	if diagnostico_llegada:
		print("[BDG-Jockey] Resultado del juez: puesto ", posicion_llegada)


# ------------------------------------------------------------
# IGUALAR LOS DIBUJOS
# ------------------------------------------------------------
# Cada rival tenia su dibujo corrido distinto respecto de su punto
# invisible. Aqui todos quedan corridos igual que el tuyo, asi que el
# mismo carril y el mismo avance se ven igual en todos los caballos.
func _igualar_dibujos(camino):
	var mio = _modelo_de(enrutador)
	if mio == null:
		return
	var ref = mio.translation
	for hijo in camino.get_children():
		if hijo == enrutador or not (hijo is PathFollow) or not hijo.name.begins_with("Enrutador_Caballo"):
			continue
		var modelo = _modelo_de(hijo)
		if modelo == null:
			continue
		var t = modelo.translation
		t.x = ref.x
		t.z = ref.z
		modelo.translation = t


func _modelo_de(nodo):
	for hijo in nodo.get_children():
		if hijo is Spatial and hijo.name.begins_with("Caballo"):
			return hijo
	return null


# ------------------------------------------------------------
# PANEL F1, BOTONES Y FOTO
# ------------------------------------------------------------
var _boton_pausa = null

func _preparar_pantalla():
	var raiz = get_tree().current_scene
	if raiz == null:
		return
	if quitar_panel_f1:
		# Se sacan los dos paneles de ajustes antes de que se armen, asi
		# no aparece AJUSTES (F1) ni se aplican numeros guardados en
		# esta computadora. Tu computadora y el APK quedan iguales.
		for nombre in ["PanelJuego", "PanelAjustes"]:
			var nodo = raiz.get_node_or_null(nombre)
			if nodo:
				raiz.remove_child(nodo)
				nodo.free()
		_crear_botones_pausa()
	var foto = raiz.get_node_or_null("FotoFinish")
	if foto:
		_ajustar_foto(foto)


# PAUSAR/REANUDAR y REINICIAR, iguales a los que tenia el panel viejo:
# arriba a la derecha, mismo tamano y mismo funcionamiento.
func _crear_botones_pausa():
	var capa = CanvasLayer.new()
	capa.layer = 100
	# Siguen funcionando con el juego en pausa, para poder reanudar.
	capa.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(capa)
	var tam = get_viewport().get_visible_rect().size
	var fila = HBoxContainer.new()
	fila.rect_position = Vector2(tam.x - 220, 8)
	fila.rect_size = Vector2(210, 30)
	capa.add_child(fila)
	_boton_pausa = Button.new()
	_boton_pausa.text = "PAUSAR"
	_boton_pausa.focus_mode = Control.FOCUS_NONE
	_boton_pausa.rect_min_size = Vector2(95, 30)
	_boton_pausa.connect("pressed", self, "_alternar_pausa")
	fila.add_child(_boton_pausa)
	var boton_reiniciar = Button.new()
	boton_reiniciar.text = "REINICIAR"
	boton_reiniciar.focus_mode = Control.FOCUS_NONE
	boton_reiniciar.rect_min_size = Vector2(105, 30)
	boton_reiniciar.connect("pressed", self, "_reiniciar_carrera")
	fila.add_child(boton_reiniciar)
	if pausar_con_teclado:
		# La P va directo en el boton PAUSAR.
		_boton_pausa.shortcut = _atajo(KEY_P)
		_boton_pausa.shortcut_in_tooltip = false
		# La tecla Pausa usa un boton invisible que hace lo mismo.
		var oculto = Button.new()
		oculto.flat = true
		oculto.modulate = Color(1, 1, 1, 0)
		oculto.rect_min_size = Vector2(1, 1)
		oculto.focus_mode = Control.FOCUS_NONE
		oculto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		oculto.shortcut = _atajo(KEY_PAUSE)
		oculto.shortcut_in_tooltip = false
		oculto.connect("pressed", self, "_alternar_pausa")
		capa.add_child(oculto)


func _atajo(tecla):
	var evento = InputEventKey.new()
	evento.scancode = tecla
	var atajo = ShortCut.new()
	atajo.shortcut = evento
	return atajo


func _alternar_pausa():
	# En la pantalla de inicio no se pausa: ahi el juego ya esta detenido
	# esperando PARTIDA, y quitarle la pausa arrancaria la carrera detras.
	var raiz = get_tree().current_scene
	if raiz and raiz.find_node("PantallaInicio", true, false):
		return
	get_tree().paused = not get_tree().paused
	_boton_pausa.text = "REANUDAR" if get_tree().paused else "PAUSAR"


func _reiniciar_carrera():
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")


# Foto del photo finish: sin franja negra y mas alta. Al hacerla mas
# alta se abre el plano en la misma proporcion, asi se ve lo mismo a
# lo ancho y mas arriba y mas abajo (no quedan caballos cortados).
func _ajustar_foto(foto):
	if foto_sin_franja and ("mostrar_boton_cerrar" in foto):
		foto.mostrar_boton_cerrar = false
	if "mostrar_raya" in foto:
		foto.mostrar_raya = mostrar_raya_foto
	# La foto ya no filma todo el final (eso era dibujar la pista dos veces
	# por cuadro y trababa el telefono justo antes de la meta). Solo saca
	# la foto en el momento exacto (ver _foto_en_la_raya).
	if foto_en_la_raya and ("distancia_para_encender" in foto):
		foto.distancia_para_encender = 0.0
	# Y se "calienta" una vez ahora, en la gatera, para que la primera
	# foto no cause un tiron en plena llegada.
	if foto.has_method("_ubicar_camara") and ("_viewport" in foto) and foto._viewport:
		foto._ubicar_camara()
		foto._viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	if alto_de_la_foto <= 0 or not ("alto_foto" in foto) or not ("ancho_foto" in foto):
		return
	var alto_viejo = float(foto.alto_foto)
	var alto_nuevo = float(alto_de_la_foto)
	if alto_viejo <= 0.0 or abs(alto_nuevo - alto_viejo) < 0.5:
		return
	if "campo_vision" in foto:
		var mitad = deg2rad(foto.campo_vision / 2.0)
		foto.campo_vision = rad2deg(2.0 * atan(tan(mitad) * alto_nuevo / alto_viejo))
	foto.alto_foto = int(alto_nuevo)
	if ("_viewport" in foto) and foto._viewport:
		foto._viewport.size = Vector2(foto.ancho_foto, foto.alto_foto)


# ------------------------------------------------------------
# FOTO EN LA RAYA
# ------------------------------------------------------------
# La foto se sacaba cuando el calculo decia que el primero iba a 12.5
# de la raya, un numero graduado a ojo con los dibujos viejos (los de
# afuera se veian atrasados). Con los dibujos ya en su lugar, la foto
# salia tarde. Ahora se mide la cabeza de cada caballo tal como se ve y
# se saca la foto en el cuadro en que la del primero llega al poste de
# FINISH. Este script corre despues de que todos se movieron, asi que
# la foto muestra exactamente ese momento.
var _foto_disparada = false
var _foto_armada = false
var _foto_punto = Vector3.ZERO
var _foto_dir = Vector3.ZERO
var _foto_mallas = []
var _foto_anterior = -INF

func _foto_en_la_raya():
	if not foto_en_la_raya or _foto_disparada or GestorNivel == null or enrutador == null:
		return
	var raiz = get_tree().current_scene
	if raiz == null:
		return
	var foto = raiz.get_node_or_null("FotoFinish")
	if foto == null or not foto.has_method("_congelar_imagen") or not foto.has_method("_obtener_datos_meta"):
		return
	if not _foto_armada:
		# Se prepara recien en la recta final, cuando al primero le faltan
		# menos de 80 unidades.
		var falta = GestorNivel.obtener_distancia_lider_hasta_meta()
		if falta < 0.0 or falta > 80.0:
			return
		var datos = foto._obtener_datos_meta()
		if datos == null:
			return
		_foto_punto = datos["punto"]
		_foto_dir = datos["avance"]
		# Si el poste de FINISH esta en esta meta, la raya pasa por el poste.
		var poste = raiz.get_node_or_null("TrackPath/Meta_LLegada/PosteMeta")
		if poste and poste is Spatial:
			var p = poste.global_transform.origin
			if abs((p - _foto_punto).dot(_foto_dir)) < 40.0:
				_foto_punto = p
		_foto_mallas = []
		for hijo in enrutador.get_parent().get_children():
			if hijo is PathFollow and hijo.name.begins_with("Enrutador_Caballo"):
				var malla = _malla_mayor(hijo)
				if malla:
					_foto_mallas.append(malla)
		_foto_armada = true

	# Cuanto le falta (negativo) o cuanto paso (positivo) la cabeza del
	# que va mas adelante.
	var cabeza = -INF
	for malla in _foto_mallas:
		if not is_instance_valid(malla):
			continue
		var caja = malla.get_transformed_aabb()
		var mitad = caja.size * 0.5
		var centro = caja.position + mitad
		var d = (centro - _foto_punto).dot(_foto_dir)
		d += abs(mitad.x * _foto_dir.x) + abs(mitad.y * _foto_dir.y) + abs(mitad.z * _foto_dir.z)
		cabeza = max(cabeza, d)
	if cabeza == -INF:
		return
	# Lo que avanzo en este cuadro, para sacar la foto en el cuadro mas
	# cercano al poste (ni medio cuadro antes ni medio despues).
	var paso = 0.0
	if _foto_anterior != -INF and cabeza > _foto_anterior:
		paso = cabeza - _foto_anterior
	_foto_anterior = cabeza
	if cabeza + paso * 0.5 >= ajuste_cabeza_foto:
		foto._congelar_imagen(-cabeza)
		_foto_disparada = true
		# La raya roja se dibuja justo donde se midio la cabeza (el poste).
		if ("_punto_meta" in foto) and ("_hay_punto_meta" in foto):
			foto._punto_meta = _foto_punto
			foto._hay_punto_meta = true
		if diagnostico_llegada:
			print("[BDG-Jockey] Foto tomada con la cabeza a ", stepify(cabeza, 0.01), " del poste")


func _malla_mayor(nodo):
	var mejor = null
	var mayor = -1.0
	var pendientes = [nodo]
	while pendientes.size() > 0:
		var actual = pendientes.pop_back()
		for hijo in actual.get_children():
			pendientes.append(hijo)
			if hijo is MeshInstance:
				var tam = hijo.get_transformed_aabb().size.length()
				if tam > mayor:
					mayor = tam
					mejor = hijo
	return mejor


# ------------------------------------------------------------
# TIPO DE CARRERA
# ------------------------------------------------------------
# Los numeros de "Amontonada" son los del Inspector. Los otros dos tipos
# los cambian solo para esta carrera (al reiniciar vuelven solos).
var _tipo_elegido = ""

func _elegir_tipo_de_carrera():
	var tipo = tipo_de_carrera
	if tipo == "Al azar" or not FORMACIONES.has(tipo):
		var tipos = FORMACIONES.keys()
		tipo = tipos[randi() % tipos.size()]
	_tipo_elegido = tipo
	# En la Atropellada, los de atras vienen con mas fuerza.
	if tipo == "Atropellada":
		rematador_llegada = max(rematador_llegada, 31.0)
		rematador_cambio = min(rematador_cambio, 0.62)
		fondo_llegada = max(fondo_llegada, 32.5)
		fondo_cambio = min(fondo_cambio, 0.62)
	# La formacion se achica en carreras cortas y se estira en las largas.
	var total = 0.0
	if GestorNivel and GestorNivel.modo_recta and ("_objetivo_recta" in GestorNivel):
		total = GestorNivel._objetivo_recta.get(enrutador, 0.0)
	if total <= 0.0 and ConfiguracionCarrera:
		total = float(ConfiguracionCarrera.distancia_metros)
	_escala_formacion = clamp(total / 1600.0, 0.45, 1.3)
	if diagnostico_llegada:
		print("[BDG-Jockey] Tipo de carrera: ", tipo)


# ------------------------------------------------------------
# GALOPES DESFASADOS
# ------------------------------------------------------------
# En la gatera, cada caballo se queda quieto en la misma pose, y al
# largar todos arrancaban el galope desde ese mismo punto: por eso
# movian la misma pata al mismo tiempo. Apenas cada uno arranca, aqui se
# lo pone en un punto distinto de su galope, una sola vez.
var _galope_desfasado = {}

func _desfasar_galopes():
	if not galopes_desfasados or GestorNivel == null or enrutador == null:
		return
	for hijo in enrutador.get_parent().get_children():
		if not (hijo is PathFollow) or not hijo.name.begins_with("Enrutador_Caballo"):
			continue
		if _galope_desfasado.has(hijo):
			continue
		# Solo despues de salir de la gatera y ya corriendo.
		if not hijo.is_processing() or GestorNivel.obtener_recorrido(hijo) < 1.0:
			continue
		var modelo = _modelo_de(hijo)
		if modelo == null:
			continue
		var anim = modelo.get_node_or_null("AnimationPlayer")
		if anim == null or not anim.is_playing():
			continue
		var largo = anim.current_animation_length
		if largo > 0.0:
			anim.seek(randf() * largo, true)
		_galope_desfasado[hijo] = true
