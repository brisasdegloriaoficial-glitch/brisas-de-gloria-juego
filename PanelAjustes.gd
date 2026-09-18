extends CanvasLayer

# ============================================================
# PANEL DE AJUSTES EN VIVO - Brisas de Gloria
# ============================================================
# Sirve para graduar vos mismo, mientras la carrera esta
# corriendo, los numeros que controlan como se mueven los
# caballos de lado a lado.
#
# Como se usa:
#   - Apreta F1 (o el boton "AJUSTES") para abrir y cerrar.
#   - Move una barra y el cambio se aplica AL INSTANTE, sin
#     reiniciar la carrera. Podes pausar con el boton de pausa
#     que ya tenias y seguir moviendo las barras igual.
#   - GUARDAR: deja los numeros grabados para la proxima vez.
#   - RESET: vuelve a los numeros originales del codigo.
#   - IMPRIMIR: escribe todos los numeros en el panel Output de
#     Godot, para copiarlos.
#
# Este script NO modifica ningun otro archivo del proyecto: solo
# lee y escribe numeros que ya existen. Si algun dia no lo queres
# mas, borras el nodo del arbol y listo, todo queda como estaba.
#
# ADEMAS incluye los botones de PAUSAR/REANUDAR y REINICIAR
# (arriba a la derecha), restituidos aca porque viven en el
# mismo panel siempre-visible.
# ============================================================

export var mostrar_al_arrancar = false
export var ancho_panel = 380
export var alto_panel = 540

const RUTA_GUARDADO = "user://ajustes_bdg.json"

# Cada linea es: [texto que se ve, donde vive, nombre real, minimo, maximo, paso]
# "gestor"  = el numero vive en GestorNivel (afecta a todos)
# "rivales" = el numero vive en cada Enrutador_CaballoN rival
#             (se cambia en los 9 rivales de una sola vez)
#
# Estan ordenados a proposito: los de arriba son los que mas
# chance tienen de arreglar lo que estas viendo.
const AJUSTES = [
	["1. Suavidad lateral rivales", "rivales", "velocidad_ajuste_lateral", 0.1, 8.0, 0.1],
	["2. Limite baranda exterior", "gestor", "limite_baranda_exterior", 5.0, 170.0, 5.0],
	["3. Separacion entre caballos", "gestor", "distancia_minima_lateral", 0.5, 20.0, 0.5],
	["4. Regreso a baranda en curva", "gestor", "velocidad_regreso_baranda_curva", 0.0, 3.0, 0.05],
	["5. Suavidad del freno", "gestor", "velocidad_correccion_choque", 0.2, 10.0, 0.1],
	["6. Freno: ancho de lado", "gestor", "distancia_frenado_lateral", 0.5, 15.0, 0.5],
	["7. Freno: largo adelante", "gestor", "distancia_frenado_longitudinal", 0.5, 15.0, 0.5],
	["8. Freno: margen para soltar", "gestor", "margen_liberacion_freno", 0.0, 15.0, 0.5],
	["9. Rango de 'me esta tapando'", "gestor", "distancia_cuerpos_seguridad", 1.0, 40.0, 0.5],
	["10. Margen cambio de bloqueo", "gestor", "margen_cambio_bloqueo", 0.0, 10.0, 0.5],
	["11. Margen de empate", "gestor", "margen_empate_recorrido", 0.0, 5.0, 0.1]
]

# QUITADAS A PROPOSITO - antes habia dos barras mas aca:
#   "Agrupacion del peloton"  -> factor_agrupacion
#   "Variacion de velocidad"  -> variacion_maxima
# El problema: este panel le escribe el MISMO numero a los 9 rivales
# de una sola vez (ver _escribir_valor mas abajo). Y factor_agrupacion
# es justamente el numero que le da personalidad a cada caballo - es
# lo que deja que el 10 se vaya a la punta y que el 9 se quede atras
# para rematar. Al ponerselo igual a todos, los 10 volvian a correr
# como clones, y encima el archivo guardado se lo volvia a escribir
# en cada arranque - asi que los cambios hechos en los scripts de
# cada caballo se borraban solos sin que se notara.
# Esos dos numeros ahora se tocan SOLO en el script de cada caballo
# (Enrutador_CaballoN.gd), que es donde cada uno tiene el suyo.

var _panel = null
var _contenedor = null
var _filas = []
var _defectos = {}
var _abierto = false
var _boton_pausa = null


func _ready():
	# Para que el panel siga funcionando aunque el juego este en
	# pausa (asi podes pausar en plena curva y ajustar tranquilo).
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 100
	# Se arma un cuadro despues, cuando el resto del arbol
	# (los caballos incluidos) ya termino de cargar.
	call_deferred("_iniciar")


func _iniciar():
	# Se anotan los numeros originales ANTES de cargar lo guardado,
	# para que el boton RESET tenga a donde volver.
	for ajuste in AJUSTES:
		_defectos[ajuste[2]] = _leer_valor(ajuste[1], ajuste[2])
	_cargar()
	_construir()
	_abrir_o_cerrar(mostrar_al_arrancar)


func _input(evento):
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.scancode == KEY_F1:
			_abrir_o_cerrar(not _abierto)


# ------------------------------------------------------------
# Armado del panel
# ------------------------------------------------------------
func _construir():
	var tam = get_viewport().get_visible_rect().size

	var boton_abrir = Button.new()
	boton_abrir.text = "AJUSTES (F1)"
	boton_abrir.focus_mode = Control.FOCUS_NONE
	boton_abrir.rect_size = Vector2(130, 30)
	boton_abrir.rect_position = Vector2(tam.x / 2.0 - 65, 8)
	boton_abrir.connect("pressed", self, "_alternar")
	add_child(boton_abrir)

	# --- Pausar/Reanudar + Reiniciar (arriba a la derecha) ---
	var fila_superior = HBoxContainer.new()
	fila_superior.rect_position = Vector2(tam.x - 220, 8)
	fila_superior.rect_size = Vector2(210, 30)
	add_child(fila_superior)

	_boton_pausa = Button.new()
	_boton_pausa.text = "PAUSAR"
	_boton_pausa.focus_mode = Control.FOCUS_NONE
	_boton_pausa.rect_min_size = Vector2(95, 30)
	_boton_pausa.connect("pressed", self, "_alternar_pausa")
	fila_superior.add_child(_boton_pausa)

	var boton_reiniciar = Button.new()
	boton_reiniciar.text = "REINICIAR"
	boton_reiniciar.focus_mode = Control.FOCUS_NONE
	boton_reiniciar.rect_min_size = Vector2(105, 30)
	boton_reiniciar.connect("pressed", self, "_reiniciar")
	fila_superior.add_child(boton_reiniciar)

	_panel = Panel.new()
	_panel.rect_size = Vector2(ancho_panel, alto_panel)
	_panel.rect_position = Vector2(tam.x - ancho_panel - 10, 80)
	add_child(_panel)

	var titulo = Label.new()
	titulo.text = "AJUSTES EN VIVO"
	titulo.rect_position = Vector2(12, 8)
	_panel.add_child(titulo)

	var scroll = ScrollContainer.new()
	scroll.rect_position = Vector2(10, 34)
	scroll.rect_size = Vector2(ancho_panel - 20, alto_panel - 80)
	_panel.add_child(scroll)

	_contenedor = VBoxContainer.new()
	_contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenedor.rect_min_size = Vector2(ancho_panel - 40, 0)
	scroll.add_child(_contenedor)

	for ajuste in AJUSTES:
		_crear_fila(ajuste)

	var fila_botones = HBoxContainer.new()
	fila_botones.rect_position = Vector2(10, alto_panel - 40)
	fila_botones.rect_size = Vector2(ancho_panel - 20, 30)
	_panel.add_child(fila_botones)

	_crear_boton(fila_botones, "GUARDAR", "_guardar")
	_crear_boton(fila_botones, "RESET", "_resetear")
	_crear_boton(fila_botones, "IMPRIMIR", "_imprimir")


func _crear_boton(padre, texto, metodo):
	var boton = Button.new()
	boton.text = texto
	boton.focus_mode = Control.FOCUS_NONE
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.connect("pressed", self, metodo)
	padre.add_child(boton)


func _crear_fila(ajuste):
	var texto = ajuste[0]
	var donde = ajuste[1]
	var propiedad = ajuste[2]
	var valor = _leer_valor(donde, propiedad)

	var etiqueta = Label.new()
	etiqueta.text = texto + ":  " + str(valor)
	_contenedor.add_child(etiqueta)

	var barra = HSlider.new()
	barra.min_value = ajuste[3]
	barra.max_value = ajuste[4]
	barra.step = ajuste[5]
	barra.value = valor
	# IMPORTANTE - sin esto, las barras se roban las flechas del
	# teclado y dejarias de poder mover tu caballo mientras el
	# panel esta abierto.
	barra.focus_mode = Control.FOCUS_NONE
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.rect_min_size = Vector2(0, 20)
	barra.connect("value_changed", self, "_al_mover_barra", [donde, propiedad, etiqueta, texto])
	_contenedor.add_child(barra)

	_filas.append([donde, propiedad, texto, barra, etiqueta])


func _al_mover_barra(valor, donde, propiedad, etiqueta, texto):
	_escribir_valor(donde, propiedad, valor)
	etiqueta.text = texto + ":  " + str(valor)


func _alternar():
	_abrir_o_cerrar(not _abierto)


func _abrir_o_cerrar(abierto):
	_abierto = abierto
	if _panel:
		_panel.visible = abierto


# ------------------------------------------------------------
# Pausar / Reanudar / Reiniciar
# ------------------------------------------------------------
func _alternar_pausa():
	get_tree().paused = not get_tree().paused
	_boton_pausa.text = "REANUDAR" if get_tree().paused else "PAUSAR"


func _reiniciar():
	get_tree().paused = false
	if _boton_pausa:
		_boton_pausa.text = "PAUSAR"
	get_tree().call_deferred("reload_current_scene")


# ------------------------------------------------------------
# Leer y escribir los numeros
# ------------------------------------------------------------
func _leer_valor(donde, propiedad):
	if donde == "gestor":
		if GestorNivel and propiedad in GestorNivel:
			return GestorNivel.get(propiedad)
		return 0.0
	for rival in _obtener_rivales():
		if propiedad in rival:
			return rival.get(propiedad)
	return 0.0


func _escribir_valor(donde, propiedad, valor):
	if donde == "gestor":
		if GestorNivel and propiedad in GestorNivel:
			GestorNivel.set(propiedad, valor)
		return
	for rival in _obtener_rivales():
		if propiedad in rival:
			rival.set(propiedad, valor)


# Busca los 9 rivales (todos los Enrutador_CaballoN menos el 1,
# que es el tuyo). Se busca por nombre recorriendo el arbol, asi
# no depende de en que rama exacta esten colgados.
func _obtener_rivales() -> Array:
	var lista = []
	var raiz = get_tree().get_current_scene()
	if raiz:
		_buscar_rivales(raiz, lista)
	return lista


func _buscar_rivales(nodo, lista):
	for hijo in nodo.get_children():
		if hijo.name.begins_with("Enrutador_Caballo") and hijo.name != "Enrutador_Caballo1":
			lista.append(hijo)
		_buscar_rivales(hijo, lista)


# ------------------------------------------------------------
# Botones
# ------------------------------------------------------------
func _guardar():
	var datos = {}
	for fila in _filas:
		datos[fila[1]] = _leer_valor(fila[0], fila[1])
	var archivo = File.new()
	if archivo.open(RUTA_GUARDADO, File.WRITE) == OK:
		archivo.store_string(to_json(datos))
		archivo.close()
		print("[BDG-Ajustes] Numeros guardados.")
	else:
		print("[BDG-Ajustes] No se pudo guardar.")


func _cargar():
	var archivo = File.new()
	if not archivo.file_exists(RUTA_GUARDADO):
		return
	if archivo.open(RUTA_GUARDADO, File.READ) != OK:
		return
	var texto = archivo.get_as_text()
	archivo.close()
	var datos = parse_json(texto)
	if typeof(datos) != TYPE_DICTIONARY:
		return
	for ajuste in AJUSTES:
		var propiedad = ajuste[2]
		if datos.has(propiedad):
			_escribir_valor(ajuste[1], propiedad, float(datos[propiedad]))
	print("[BDG-Ajustes] Numeros guardados cargados.")


func _resetear():
	for fila in _filas:
		var donde = fila[0]
		var propiedad = fila[1]
		if not _defectos.has(propiedad):
			continue
		var valor = _defectos[propiedad]
		_escribir_valor(donde, propiedad, valor)
		fila[3].value = valor
		fila[4].text = fila[2] + ":  " + str(valor)
	print("[BDG-Ajustes] Volvio a los numeros originales.")


func _imprimir():
	print("=== AJUSTES BDG - valores actuales ===")
	for fila in _filas:
		print(fila[1], " = ", _leer_valor(fila[0], fila[1]))
	print("======================================")
