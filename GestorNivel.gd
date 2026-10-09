extends Node
# VERSION: orden de llegada real del 2do en adelante (oct 2026)

# ============================================================
# GESTOR DE NIVEL, PELOTON, RECORRIDO Y VUELTAS
# ============================================================

export var nivel_actual = 1

# --- Progresion de dificultad: sube 1 nivel (de 10) cada vez que el
# jugador gano una carrera. Se queda igual si pierde.
export var nivel_maximo = 10

# Que tan "de golpe" se siente la dificultad cerca del nivel maximo.
# 1.0 = sube parejo del 1 al 10. Mientras mas alto, mas facil se
# sienten los niveles del medio (5-7) y mas fuerte el salto final
# (8-10). Se puede ajustar directo aca en el Inspector.
export var curva_dificultad = 3.0

export var estamina_nivel_1 = 100.0
export var estamina_nivel_10 = 65.0

export var extra_velocidad_rivales_nivel_10 = 4.0

# CORREGIDO - antes esto era en SEGUNDOS de reloj (45 / 15), y por
# eso la agrupacion se apagaba siempre a los 60 segundos sin
# importar cuanto faltara de carrera: en 800-1600m casi no se notaba
# (la carrera terminaba antes), pero en 2000m+ la agrupacion
# desaparecia cuando apenas iba una fraccion chica de la carrera, y
# el resto quedaba sin ningun freno para que se separaran - esa era
# la causa principal de la diferencia enorme entre el puntero y el
# ultimo en carreras largas. Ahora es FRACCION DE LA DISTANCIA
# RECORRIDA (0.0 a 1.0), asi que la forma de la carrera es la misma
# proporcion sin importar si son 800m o 3000m.
export var inicio_relajacion = 0.55
export var duracion_relajacion = 0.20
# NUEVO - antes esta fuerza llegaba a 0 (se apagaba del todo) despues
# de inicio_relajacion + duracion_relajacion. En carreras largas eso
# dejaba un tramo final enorme (en metros reales) sin ningun freno
# para que se separen. Ahora nunca baja de este piso - se van a
# seguir separando hacia el final (como en una carrera real), pero
# nunca del todo sueltos.
export var piso_relajacion = 0.25

# --- Desaceleracion suave al terminar ---
# Los caballos NO se frenan en seco: al cruzar la meta van
# aflojando solos, como en una carrera real. 0.35 = pierde ~35%
# de la velocidad por segundo. Baja el numero para que aflojen
# mas lento, subelo para que aflojen mas rapido.
export var desaceleracion_final = 0.08
export var velocidad_minima_final = 15.0

# --- Photo Finish ---
# Si la diferencia de recorrido entre el 1° y el 2° lugar, en el
# instante justo en que el ganador cruza la meta, es MENOR o IGUAL
# a este numero (en metros, ya que metros_por_unidad = 1.0), se
# considera "llegada de foto" y se activa el modo Photo Finish.
# Subilo si queres que se active mas seguido, bajalo para que sea
# solo en llegadas realmente muy cerradas.
export var margen_photo_finish = 8.0

# --- Control del recorrido (orden de llegada) ---
# Tope de cuanto se acepta como movimiento real de un caballo en un
# solo cuadro. Sirve para que una reposicion del caballo (por ejemplo
# la que hace TrackPath al arrancar) no se cuente como carrera
# corrida. Un caballo normal se mueve menos de 1 unidad por cuadro,
# asi que 20 es un tope MUY holgado. Subilo solo si en carreras con
# tirones se nota que a alguien le falta recorrido.
export var salto_maximo_por_cuadro = 20.0

# Poner en false para que deje de imprimir mensajes en el panel
# Output de Godot una vez que todo funcione.
export var mostrar_diagnostico = true

signal photo_finish_detectado(caballo_ganador, diferencia)
# Avisa cada vez que otro caballo cruza la raya despues del ganador,
# para que los carteles refresquen la lista de puestos.
signal orden_llegada_actualizado

var _corredores = []
var _tiempo_carrera = 0.0
var _longitud_pista = 0.0
var _recorrido = {}
var _offset_anterior_recorrido = {}
var _bloqueado = {}
var _bloqueador_lateral = {}

# --- metas y vueltas ---
var modo_recta = false
var vueltas_totales = 1
var _meta_ovalo = null
var _meta_recta = null
var _offset_anterior_cruce = {}
var _vueltas_completadas = {}

# Solo en modo recta: cuantas unidades tiene que recorrer cada
# caballo desde donde arranco hasta la meta.
var _objetivo_recta = {}
var _aviso_final_hecho = false

# --- estado congelado de la llegada (Photo Finish) ---
var _ganador = null
var _photo_finish_activo = false
var _diferencia_photo_finish = 0.0
var _orden_llegada_congelado = []
var _llegados_en_orden = []    # los que ya cruzaron, en el orden real en que tocaron la raya
var _avance_ultimo = {}
var _fraccion_cruce = {}

# JUEZ POR LA NARIZ - el punto de cada enrutador (donde el juego lleva la
# cuenta del caballo) NO es la punta de la nariz: queda unos metros mas
# atras, mas o menos en el medio del caballo. El juez decidia cuando ese
# punto tocaba la raya, y para entonces un caballo mas rapido que venia
# a una nariz de distancia ya lo habia alcanzado o pasado. Por eso
# ganaban los que venian con mas velocidad aunque no les correspondiera.
# Ahora se mide, en cada caballo, cuanto va la nariz por delante de ese
# punto, y el juez decide cuando la NARIZ toca la raya, como en la vida
# real. Poner en false para volver a como estaba.
var juzgar_por_la_nariz = true
var _adelanto_nariz = {}
var _recorrido_congelado = {}


func _process(delta):
	_tiempo_carrera += delta
	_actualizar_recorridos()
	_aplicar_colision_solida(delta)
	_aplicar_busqueda_baranda(delta)
	_revisar_cruces_meta()
	_revisar_photo_finish()
	_aplicar_desaceleracion_final(delta)


func reiniciar_carrera():
	_tiempo_carrera = 0.0
	_arrancada.clear()
	_objetivo_salida.clear()
	_entrada_recta_final.clear()
	_idea_baranda.clear()
	_apertura.clear()
	_ultima_vez_en_curva.clear()
	_corredores.clear()
	_recorrido.clear()
	_offset_anterior_recorrido.clear()
	_bloqueado.clear()
	_bloqueador_lateral.clear()
	_offset_anterior_cruce.clear()
	_vueltas_completadas.clear()
	_objetivo_recta.clear()
	_aviso_final_hecho = false
	_ganador = null
	_photo_finish_activo = false
	_diferencia_photo_finish = 0.0
	_orden_llegada_congelado.clear()
	_llegados_en_orden.clear()
	_recorrido_congelado.clear()
	_avance_ultimo.clear()
	_fraccion_cruce.clear()
	_adelanto_nariz.clear()
	_grupo_de.clear()
	_grupos_sorteados.clear()


# Sube un nivel (de 10) si el jugador gano (posicion 1), y se
# queda en el mismo nivel si perdio. Se llama desde Jockey_final.gd
# apenas se sabe la posicion de llegada del jugador.
func subir_nivel_si_gano(posicion_llegada):
	if posicion_llegada == 1 and nivel_actual < nivel_maximo:
		nivel_actual += 1
		if mostrar_diagnostico:
			print("[BDG] Subio a nivel ", nivel_actual)


func registrar_longitud_pista(valor):
	_longitud_pista = valor


func configurar_meta(meta_ovalo, meta_recta, es_modo_recta, vueltas):
	_meta_ovalo = meta_ovalo
	_meta_recta = meta_recta
	modo_recta = es_modo_recta
	vueltas_totales = max(1, vueltas)
	if mostrar_diagnostico:
		var offset_meta = -1.0
		if modo_recta and _meta_recta:
			offset_meta = _meta_recta.offset
		elif _meta_ovalo:
			offset_meta = _meta_ovalo.offset
		print("[BDG] Carrera configurada -> modo_recta=", modo_recta,
			" | offset de la meta=", offset_meta,
			" | vueltas_totales=", vueltas_totales,
			" | largo de pista=", _longitud_pista)


func obtener_progreso() -> float:
	var progreso_lineal = clamp(float(nivel_actual - 1) / float(nivel_maximo - 1), 0.0, 1.0)
	return pow(progreso_lineal, curva_dificultad)


func obtener_estamina_maxima() -> float:
	# NUEVO - antes esto escalaba con una formula automatica segun
	# distancia_metros (daba numeros disparatados: 500+ en carreras
	# largas). Ahora usa el numero exacto que pone SelectorDistancias
	# por boton (ConfiguracionCarrera.estamina_base: 800m=100,
	# 1200m=100, 1600m=120, 2000m=150, 2400m=200, 3000m=300), y arriba
	# de esa base se sigue aplicando la misma reduccion por nivel de
	# dificultad que ya habia (65% de la base en el nivel mas dificil).
	var base = estamina_nivel_1
	if ConfiguracionCarrera:
		base = ConfiguracionCarrera.estamina_base
	var proporcion_nivel_10 = 1.0
	if estamina_nivel_1 > 0:
		proporcion_nivel_10 = estamina_nivel_10 / estamina_nivel_1
	return lerp(base, base * proporcion_nivel_10, obtener_progreso())


func obtener_extra_velocidad_rivales() -> float:
	return lerp(0.0, extra_velocidad_rivales_nivel_10, obtener_progreso())


func registrar_corredor(nodo):
	_limpiar_corredores()
	if not _corredores.has(nodo):
		_corredores.append(nodo)
		_offset_anterior_recorrido[nodo] = nodo.offset
		_recorrido[nodo] = 0.0
		_offset_anterior_cruce[nodo] = nodo.offset
		_vueltas_completadas[nodo] = 0

		# MODO RECTA: en vez de detectar el cruce de una linea (que
		# es lo que estaba fallando), se calcula aca cuanto tiene que
		# recorrer este caballo, y despues se compara contra el
		# recorrido acumulado - el mismo mecanismo que ya funciona
		# bien en las carreras del ovalo.
		if modo_recta and _meta_recta:
			var objetivo = _meta_recta.offset - nodo.offset
			if objetivo <= 0.0 and _longitud_pista > 0.0:
				objetivo = fposmod(objetivo, _longitud_pista)
			_objetivo_recta[nodo] = objetivo
			if mostrar_diagnostico:
				print("[BDG] ", nodo.name, " arranca en offset=", nodo.offset,
					" y debe recorrer ", objetivo, " unidades")


func _limpiar_corredores():
	for i in range(_corredores.size() - 1, -1, -1):
		if not is_instance_valid(_corredores[i]):
			var caido = _corredores[i]
			_recorrido.erase(caido)
			_offset_anterior_recorrido.erase(caido)
			_avance_ultimo.erase(caido)
			_fraccion_cruce.erase(caido)
			_offset_anterior_cruce.erase(caido)
			_vueltas_completadas.erase(caido)
			_objetivo_recta.erase(caido)
			_bloqueado.erase(caido)
			_bloqueador_lateral.erase(caido)
			_corredores.remove(i)


func _actualizar_recorridos():
	for corredor in _corredores:
		if not is_instance_valid(corredor):
			continue
		if not _offset_anterior_recorrido.has(corredor):
			_offset_anterior_recorrido[corredor] = corredor.offset
			_recorrido[corredor] = 0.0
			continue
		var delta_offset = corredor.offset - _offset_anterior_recorrido[corredor]
		if _longitud_pista > 0 and delta_offset < -_longitud_pista * 0.5:
			delta_offset += _longitud_pista
		# CORREGIDO - CAUSA DEL BUG DEL ORDEN DE LLEGADA.
		# Antes aca decia "if delta_offset > 0", o sea que solo se
		# sumaba lo que el caballo AVANZABA y se tiraba a la basura
		# lo que RETROCEDIA. Pero el sistema de choque sirve sobre
		# la misma variable (mas abajo hace "corredor.offset -=
		# retroceso") para frenar al que se le mete adentro al de
		# adelante. Entonces el caballo que venia trabado en el
		# pelotón perdia terreno de verdad en la pista, pero no lo
		# perdia en la cuenta, y cuando volvia a recuperar ese mismo
		# tramo se lo cobraban DOS VECES. Al que mas choca (el
		# rematador, que viene pasando caballos) se le inflaba el
		# recorrido y salia primero en el cartel aunque llegara cuarto.
		# Ahora el movimiento se suma tal cual, para adelante y para
		# atras, y solo se descartan los saltos imposibles.
		if abs(delta_offset) <= salto_maximo_por_cuadro:
			_recorrido[corredor] += delta_offset
			# Cuanto avanzo ESTE cuadro. Lo necesita el juez de
			# llegada para saber en que momento exacto, dentro del
			# cuadro, cada caballo toco la meta.
			_avance_ultimo[corredor] = delta_offset
		else:
			_avance_ultimo[corredor] = 0.0
		_offset_anterior_recorrido[corredor] = corredor.offset


func obtener_recorrido(nodo) -> float:
	return _recorrido.get(nodo, 0.0)


# ------------------------------------------------------------
# ARRANCADA DE LOS RIVALES
# Al abrirse el aparato, cada rival sale con una parte de su velocidad
# y va acelerando hasta su ritmo de carrera, cada uno en sus propios
# metros (al azar en cada carrera). Asi unos pegan el salto rapido y
# otros tardan en agarrar ritmo. Cada rival multiplica su avance por
# este numero (1 = ya agarro su ritmo).
# ------------------------------------------------------------
export var usar_arrancada = false
export var factor_salida_min = 0.35       # con que parte de su velocidad sale (0.35 = 35%)
export var factor_salida_max = 0.55
export var metros_arrancada_min = 40.0    # en cuantos metros llega a su ritmo
export var metros_arrancada_max = 120.0
export var arrancada_en_800 = false       # la de 800 m no se toca
var _arrancada = {}

func obtener_factor_arranque(corredor) -> float:
	if not usar_arrancada:
		return 1.0
	if modo_recta and not arrancada_en_800:
		return 1.0
	if not _arrancada.has(corredor):
		_arrancada[corredor] = [rand_range(factor_salida_min, factor_salida_max), rand_range(metros_arrancada_min, metros_arrancada_max)]
	var datos = _arrancada[corredor]
	var r = obtener_recorrido(corredor)
	if r >= datos[1]:
		return 1.0
	return lerp(datos[0], 1.0, smoothstep(0.0, datos[1], r))


func obtener_distancia_restante(nodo) -> float:
	if not modo_recta:
		return -1.0
	var objetivo = _objetivo_recta.get(nodo, 0.0)
	if objetivo <= 0.0:
		return -1.0
	return max(0.0, objetivo - obtener_recorrido(nodo))


# Version que funciona en LOS DOS MODOS (antes esto solo existia
# para el modo recta de 800m). Sirve para saber, en cualquier
# carrera, cuanto le falta a un caballo para cruzar la meta - la
# usa GestorCamaras para activar la camara de llegada un poco
# antes de que se cruce, no recien en el instante exacto.
func obtener_distancia_hasta_meta(corredor) -> float:
	if modo_recta:
		return obtener_distancia_restante(corredor)

	if not _meta_ovalo or _longitud_pista <= 0:
		return -1.0

	# Solo tiene sentido en la ultima vuelta - en las vueltas
	# anteriores el caballo pasa cerca de la meta sin que eso sea
	# realmente el final de la carrera.
	var vueltas_del_corredor = _vueltas_completadas.get(corredor, 0)
	if vueltas_del_corredor < vueltas_totales - 1:
		return -1.0

	# CORREGIDO (bug de carreras de 2 o mas vueltas) - la vuelta se
	# cuenta cuando la NARIZ toca la raya, pero esta distancia se medía
	# desde el punto del enrutador (unos metros mas atras). Entonces, al
	# terminar la 1ra vuelta, el puntero ya contaba como "ultima vuelta"
	# y le faltaban 2 o 3 metros: se prendia la camara de llegada, el
	# flash y el audio final en plena carrera. Ahora se mide igual que
	# el juez: hasta donde la nariz toca la raya.
	return fposmod(_meta_ovalo.offset - _nariz(corredor) - corredor.offset, _longitud_pista)


# Distancia hasta la meta del caballo que va MAS ADELANTE de todos
# (no del jugador). La usa GestorCamaras para activar la camara de
# llegada por ESPACIO (cuando el primero entra en la recta final),
# no por tiempo/velocidad.
func obtener_distancia_lider_hasta_meta() -> float:
	_limpiar_corredores()
	var menor = -1.0
	for corredor in _corredores:
		var distancia = obtener_distancia_hasta_meta(corredor)
		if distancia < 0.0:
			continue
		if menor < 0.0 or distancia < menor:
			menor = distancia
	return menor


# El offset del caballo que va MAS ADELANTE de todos (no un
# promedio). La usa la camara de llegada para seguir al puntero
# real, como una camara de TV de verdad.
func obtener_offset_lider() -> float:
	_limpiar_corredores()
	if _corredores.empty():
		return 0.0
	var mejor_recorrido = -1.0
	var mejor_offset = 0.0
	for corredor in _corredores:
		if not is_instance_valid(corredor):
			continue
		var r = obtener_recorrido(corredor)
		if r > mejor_recorrido:
			mejor_recorrido = r
			mejor_offset = corredor.offset
	return mejor_offset


func obtener_offset_promedio() -> float:
	_limpiar_corredores()
	if _corredores.empty():
		return 0.0
	# CORREGIDO (causa de "la carrera entera corre a media velocidad"
	# y de "van todos amuñoñados") - antes esto era un PROMEDIO comun
	# de los 10 caballos. El problema: los caballos usan este numero
	# como referencia de "donde va el peloton", y si van por debajo se
	# apuran, si van por arriba AFLOJAN. Con dos caballos muy
	# rezagados (el 9 y el 10), el promedio se desploma - y entonces
	# los otros 8, que iban bien, quedaban todos "por arriba del
	# promedio" y se frenaban solos para esperarlos. Uno tiraba del
	# otro para atras y la carrera entera corria a ~13 en vez de 20.
	#
	# Ahora se usa la MEDIANA (el valor del medio) en vez del
	# promedio. La mediana no se mueve porque haya dos rezagados muy
	# lejos - sigue marcando donde va de verdad el grueso del grupo.
	# Los rezagados igual reciben su empujon para alcanzar (van por
	# debajo de la mediana), pero ya no arrastran a los demas hacia
	# atras con ellos.
	var lista = []
	for corredor in _corredores:
		lista.append(corredor.offset)
	lista.sort()
	var medio = int(lista.size() / 2)
	if lista.size() % 2 == 1:
		return lista[medio]
	return (lista[medio - 1] + lista[medio]) * 0.5
# --- GRUPOS DEL PELOTON (nuevo) ---
# En cada carrera se sortea en que grupo corre cada rival: 3 adelante
# y despues grupos de 2, cada uno mas atras. Asi no van apilados y
# queda espacio para maniobrar. El jugador no entra en el sorteo.
# Distancia entre un grupo y el siguiente (20 = unos dos cuerpos).
export var separacion_entre_grupos = 20.0
# Cuantos caballos hay en cada grupo, de adelante hacia atras.
export var tamanos_de_grupo = [3, 2, 2, 2]

var _grupo_de = {}
var _grupos_sorteados = []

func obtener_offset_objetivo(corredor) -> float:
	var promedio = obtener_offset_promedio()
	if corredor.name == "Enrutador_Caballo1":
		return promedio
	if not _grupo_de.has(corredor):
		if _grupos_sorteados.empty():
			_sortear_grupos()
		_grupo_de[corredor] = _grupos_sorteados.pop_back()
	var centro = (tamanos_de_grupo.size() - 1) * 0.5
	return promedio + (centro - _grupo_de[corredor]) * separacion_entre_grupos

func _sortear_grupos():
	randomize()
	for i in range(tamanos_de_grupo.size()):
		for j in range(tamanos_de_grupo[i]):
			_grupos_sorteados.append(i)
	_grupos_sorteados.shuffle()

# NUEVO - que fraccion de la carrera ya se corrio, medida por
# DISTANCIA (el que va mas adelante de todos), no por tiempo. Se usa
# como base para obtener_factor_relajacion() y la puede usar
# cualquier otro sistema que necesite saber "cuanto va" la carrera
# sin depender del reloj.
#
# SIMPLIFICACION A PROPOSITO: en modo recta (800m) se divide por la
# ETIQUETA (800.0), no por la distancia real de ese modo (724.0) -
# una diferencia chica (~9%) que no importa porque el 800m termina
# en pocos segundos, antes de que la agrupacion llegue a apagarse.
func obtener_progreso_distancia() -> float:
	_limpiar_corredores()
	if _corredores.empty():
		return 0.0
	var distancia_total = 0.0
	if ConfiguracionCarrera:
		distancia_total = ConfiguracionCarrera.distancia_metros
	if distancia_total <= 0.0:
		return 0.0
	var mejor_recorrido = 0.0
	for corredor in _corredores:
		if not is_instance_valid(corredor):
			continue
		mejor_recorrido = max(mejor_recorrido, obtener_recorrido(corredor))
	return clamp(mejor_recorrido / distancia_total, 0.0, 1.0)


func obtener_factor_relajacion() -> float:
	var progreso_carrera = obtener_progreso_distancia()
	if progreso_carrera < inicio_relajacion:
		return 1.0
	var progreso = (progreso_carrera - inicio_relajacion) / duracion_relajacion
	return clamp(1.0 - progreso, piso_relajacion, 1.0)


func obtener_posicion(nodo) -> int:
	# Si la llegada ya quedo congelada (Photo Finish), la posicion
	# se responde desde la foto congelada, no desde el recorrido
	# en vivo (que sigue cambiando porque los caballos no se frenan
	# en seco al cruzar la meta).
	if _ganador != null and _orden_llegada_congelado.has(nodo):
		return _orden_llegada_congelado.find(nodo) + 1

	_limpiar_corredores()
	if not _corredores.has(nodo):
		return 1
	var mi_recorrido = obtener_recorrido(nodo)
	var posicion = 1
	for corredor in _corredores:
		if corredor == nodo:
			continue
		if obtener_recorrido(corredor) > mi_recorrido:
			posicion += 1
	return posicion


func obtener_total_corredores() -> int:
	_limpiar_corredores()
	return _corredores.size()


# ------------------------------------------------------------
# Fin de carrera
# ------------------------------------------------------------
func ha_terminado(corredor) -> bool:
	if modo_recta:
		var objetivo = _objetivo_recta.get(corredor, 0.0)
		if objetivo <= 0.0:
			return false
		return obtener_recorrido(corredor) + _nariz(corredor) >= objetivo
	return _vueltas_completadas.get(corredor, 0) >= vueltas_totales


func obtener_vueltas_completadas(corredor) -> int:
	return _vueltas_completadas.get(corredor, 0)


func _obtener_offset_meta_activa() -> float:
	if modo_recta:
		return -1.0
	if _meta_ovalo:
		return _meta_ovalo.offset
	return -1.0


func _revisar_cruces_meta():
	# En modo recta el final se decide por recorrido (ver ha_terminado),
	# no por cruce, asi que aca no hay nada que hacer.
	if modo_recta:
		if mostrar_diagnostico and not _aviso_final_hecho:
			for corredor in _corredores:
				if is_instance_valid(corredor) and ha_terminado(corredor):
					print("[BDG] LLEGO A LA META: ", corredor.name,
						" | recorrido=", obtener_recorrido(corredor))
					_aviso_final_hecho = true
					break
		return

	var meta_offset = _obtener_offset_meta_activa()
	if meta_offset < 0.0:
		return
	for corredor in _corredores:
		if not is_instance_valid(corredor):
			continue
		if ha_terminado(corredor):
			continue
		if _cruzo_meta(corredor, meta_offset - _nariz(corredor)):
			_vueltas_completadas[corredor] = _vueltas_completadas.get(corredor, 0) + 1
			# DIAGNOSTICO NUEVO - antes esto no se imprimia nunca a mitad
			# de carrera, solo al terminar toda la carrera. Sirve para ver
			# en que momento exacto un caballo suma una vuelta, y confirmar
			# si eso esta pasando antes de tiempo (bug de la camara de
			# llegada en 3000m).
			if mostrar_diagnostico:
				print("[BDG] ", corredor.name, " cruzo la meta -> vuelta ",
					_vueltas_completadas[corredor], " de ", vueltas_totales,
					" | offset=", corredor.offset)
			if mostrar_diagnostico and not _aviso_final_hecho and ha_terminado(corredor):
				print("[BDG] LLEGO A LA META: ", corredor.name,
					" | recorrido=", obtener_recorrido(corredor))
				_aviso_final_hecho = true


func _cruzo_meta(corredor, meta_offset) -> bool:
	if not _offset_anterior_cruce.has(corredor):
		_offset_anterior_cruce[corredor] = corredor.offset
		return false

	var anterior = _offset_anterior_cruce[corredor]
	var actual = corredor.offset

	var avance = actual - anterior
	if _longitud_pista > 0 and avance < -_longitud_pista * 0.5:
		avance += _longitud_pista

	var cruzo = false
	if avance > 0 and _longitud_pista > 0:
		var distancia_a_meta = fposmod(meta_offset - anterior, _longitud_pista)
		if distancia_a_meta <= avance:
			cruzo = true

	_offset_anterior_cruce[corredor] = actual
	return cruzo


# ------------------------------------------------------------
# Photo Finish
# ------------------------------------------------------------
func _revisar_photo_finish():
	if _ganador != null:
		_actualizar_orden_llegada()
	if _ganador != null:
		return
	if _corredores.empty():
		return

	# ----------------------------------------------------------
	# JUEZ DE LLEGADA  (CORREGIDO)
	# ----------------------------------------------------------
	# Antes el puesto se decidia mirando quien estaba mas adelante
	# en la FOTO DE FIN DE CUADRO. Eso esta mal en las llegadas
	# apretadas: el juego revisa la meta 30 o 60 veces por segundo,
	# asi que dos caballos pueden cruzar DENTRO DEL MISMO cuadro.
	# Cuando eso pasaba, ganaba el que estaba mas adelante al
	# terminar el cuadro - o sea EL MAS RAPIDO, no el que toco la
	# linea primero. Por eso el que ganaba por poco margen y era
	# pasado un metro despues de la raya aparecia segundo.
	# Ahora, de los que cruzaron en este cuadro, se calcula que
	# parte del cuadro hace que cada uno cruzo (cuanto se paso de
	# la linea dividido lo que avanzo). El que se paso mas, en
	# proporcion a su propia velocidad, es el que la toco antes.
	var llegados = []
	var todavia_corriendo = []
	for corredor in _corredores:
		if not is_instance_valid(corredor):
			continue
		if ha_terminado(corredor):
			llegados.append(corredor)
		else:
			todavia_corriendo.append(corredor)

	if llegados.empty():
		return

	_recorrido_congelado.clear()
	for corredor in _corredores:
		if is_instance_valid(corredor):
			_recorrido_congelado[corredor] = obtener_recorrido(corredor)

	_fraccion_cruce.clear()
	for corredor in llegados:
		_fraccion_cruce[corredor] = _fraccion_desde_que_cruzo(corredor)
	llegados.sort_custom(self, "_comparar_cruce")

	# Los que todavia no llegaron van despues, por distancia.
	todavia_corriendo.sort_custom(self, "_comparar_recorrido_congelado")

	_orden_llegada_congelado = []
	for corredor in llegados:
		_orden_llegada_congelado.append(corredor)
	for corredor in todavia_corriendo:
		_orden_llegada_congelado.append(corredor)

	_ganador = _orden_llegada_congelado[0]

	_diferencia_photo_finish = 0.0
	if _orden_llegada_congelado.size() >= 2:
		var primero = _orden_llegada_congelado[0]
		var segundo = _orden_llegada_congelado[1]
		_diferencia_photo_finish = abs(_recorrido_congelado[primero] - _recorrido_congelado[segundo])

	_photo_finish_activo = _diferencia_photo_finish <= margen_photo_finish

	if mostrar_diagnostico:
		print("[BDG] PHOTO FINISH -> ganador=", _ganador.name,
			" | diferencia con 2do=", _diferencia_photo_finish,
			" | activado=", _photo_finish_activo)

	emit_signal("photo_finish_detectado", _ganador, _diferencia_photo_finish)


func _comparar_recorrido_congelado(a, b) -> bool:
	return _recorrido_congelado[a] > _recorrido_congelado[b]


func _comparar_cruce(a, b) -> bool:
	# Mas fraccion de cuadro pasada desde que cruzo = toco la linea antes.
	return _fraccion_cruce[a] > _fraccion_cruce[b]


# Que parte de este cuadro (0 a 1) hace que el caballo cruzo la meta.
# 1 = la cruzo justo al empezar el cuadro. 0 = la esta tocando recien
# ahora. Se calcula con lo que se paso de la raya dividido lo que
# avanzo en el cuadro, asi un caballo rapido no gana ventaja por el
# solo hecho de haberse pasado mas lejos.
func _fraccion_desde_que_cruzo(corredor) -> float:
	var avance = _avance_ultimo.get(corredor, 0.0)
	if avance <= 0.0:
		return 0.0
	var sobrante = 0.0
	if modo_recta:
		sobrante = obtener_recorrido(corredor) + _nariz(corredor) - _objetivo_recta.get(corredor, 0.0)
	else:
		var meta_offset = _obtener_offset_meta_activa()
		if meta_offset < 0.0 or _longitud_pista <= 0.0:
			return 0.0
		sobrante = fposmod(corredor.offset + _nariz(corredor) - meta_offset, _longitud_pista)
		if sobrante > _longitud_pista * 0.5:
			sobrante -= _longitud_pista
	return clamp(sobrante / avance, 0.0, 1.0)


func obtener_ganador():
	return _ganador


# Cuanto va la nariz por delante del punto del enrutador, en unidades de
# pista. Se mide una sola vez por caballo (el dibujo no cambia de largo).
func _nariz(corredor) -> float:
	if not juzgar_por_la_nariz or not is_instance_valid(corredor):
		return 0.0
	if _adelanto_nariz.has(corredor):
		return _adelanto_nariz[corredor]
	# Se espera un segundo para que el repartidor ya haya puesto los
	# caballos definitivos.
	if _tiempo_carrera < 1.0:
		return 0.0
	var valor = _medir_nariz(corredor)
	_adelanto_nariz[corredor] = valor
	if mostrar_diagnostico:
		print("[BDG] nariz de ", corredor.name, ": va ", stepify(valor, 0.01), " por delante de su punto")
	return valor


func _medir_nariz(corredor) -> float:
	var modelo = null
	for h in corredor.get_children():
		if h is Spatial and h.name.begins_with("Caballo") and h.is_visible_in_tree():
			modelo = h
			break
	if modelo == null:
		return 0.0
	var adelante = -corredor.global_transform.basis.z
	adelante.y = 0.0
	if adelante.length() < 0.001:
		return 0.0
	adelante = adelante.normalized()
	var origen = corredor.global_transform.origin
	var mejor = -1000000.0
	for mi in _mallas_del_caballo(modelo):
		var caja = mi.get_transformed_aabb()
		for i in range(8):
			var d = (caja.get_endpoint(i) - origen).dot(adelante)
			if d > mejor:
				mejor = d
	if mejor < -999999.0:
		return 0.0
	return clamp(mejor, -50.0, 50.0)


# Mallas del cuerpo del caballo, sin entrar a silla, jinete ni brida
# (van colgadas de BoneAttachment).
func _mallas_del_caballo(n) -> Array:
	var r = []
	for c in n.get_children():
		if c is BoneAttachment:
			continue
		if c is MeshInstance and c.mesh != null and c.is_visible_in_tree():
			r.append(c)
		r += _mallas_del_caballo(c)
	return r


func es_photo_finish() -> bool:
	return _photo_finish_activo


func obtener_diferencia_photo_finish() -> float:
	return _diferencia_photo_finish


func obtener_orden_llegada_congelado() -> Array:
	return _orden_llegada_congelado


# ------------------------------------------------------------
# Desaceleracion suave: los caballos que ya llegaron van aflojando
# solos, sin frenarse en seco. Funciona para todos (jugador y
# rivales) sin tener que tocar los scripts de cada caballo.
# ------------------------------------------------------------
func _aplicar_desaceleracion_final(delta):
	var factor = 1.0 - clamp(desaceleracion_final * delta, 0.0, 1.0)
	for corredor in _corredores:
		if not is_instance_valid(corredor):
			continue
		if not ha_terminado(corredor):
			continue
		if "velocidad_actual" in corredor:
			corredor.velocidad_actual = max(velocidad_minima_final, corredor.velocidad_actual * factor)
		if "velocidad_avance" in corredor:
			corredor.velocidad_avance = max(velocidad_minima_final, corredor.velocidad_avance * factor)


# ------------------------------------------------------------
# REGLA 3 - separacion lateral (hacia la baranda) + freno solido
# ------------------------------------------------------------
# Dos sistemas SEPARADOS, que no se pisan entre si:
#   1) Separacion lateral (mas abajo, obtener_h_offset_hacia_baranda
#      y separar_si_esta_pegado): cada caballo, por su cuenta, va
#      hacia la baranda salvo que alguien REALMENTE adelante suyo
#      (por recorrido real, no por carril de arranque) se lo impida
#      - ahi se corre lo justo y necesario para no montarsele
#      encima. El que va adelante nunca se mueve por culpa de otro.
#      Esta es la logica que ya estaba probada en sesiones
#      anteriores; solo se corrigio para que el orden lo decida el
#      recorrido real (evita que el de adelante "ceda el paso").
#   2) Freno solido (_aplicar_colision_solida, mas abajo): una
#      revision global, aparte, que SOLO frena el avance (offset) -
#      nunca toca el carril de nadie - para que dos caballos jamas
#      lleguen a atravesarse aunque la separacion lateral por algun
#      motivo no alcance a tiempo (por ejemplo, en curva, o cuando
#      el jugador se mete de golpe con las flechas).
# IMPORTANTE: en un intento anterior, el freno solido TAMBIEN
# empujaba el carril de cada caballo. Eso hacia que, cuando todo el
# pelotón iba junto (tipico al arrancar), cada caballo quedara
# pegado exactamente al limite de seguridad del que tenia al lado -
# y el grupo ENTERO quedaba soldado en una formacion de escalera que
# nunca se deshacia, viajando todos al ritmo del mas lento (eso se
# veia como que retrocedian y se alineaban en diagonal). Por eso el
# freno solido ahora NUNCA toca el carril - de eso se encarga solo
# la separacion lateral.

# Cuanto lugar minimo (en metros de recorrido) tiene que haber entre
# dos caballos EN EL MISMO CARRIL para que el de atras no se le
# pegue al de adelante - la distancia de frenado. (Esta variable ya
# existia en el proyecto pero no la usaba ningun codigo; ahora es la
# que gobierna el frenado solido.)
export var distancia_cuerpos_seguridad = 10.0

# Cuanto lugar minimo se dejan dos caballos EN PARALELO (mismo
# tramo de pista) para no quedar pegados/solapados visualmente -
# define que tan ancho es "el mismo carril".
# BAJADO (de 8.0) - este es el numero que se suma UNA VEZ POR CADA
# eslabon de la cadena cuando varios caballos se bloquean en fila
# (A se corre de B, B se corre de C, C se corre de D...) - cuanto
# mas grande sea, mas lejos empuja el efecto dominó a cada uno hacia
# afuera de la baranda cuando se amontonan al arrancar. Bajarlo
# achica ese empuje acumulado.
export var distancia_minima_lateral = 8.0

# Ya no se usa para decidir bloqueos (eso ahora lo hace
# distancia_cuerpos_seguridad, medido en recorrido real), pero se
# deja declarada por si algun script viejo todavia la lee.
export var largo_cuerpo = 5.0

# Que tan rapido corrige el freno solido el avance hacia el limite
# seguro. Mas alto = se siente mas solido/inmediato. Mas bajo = se
# siente mas de goma/gradual.
# BAJADO OTRA VEZ (de 2.5, que ya venia de 3.5, de 5.0 y de 10.0) -
# se seguia notando. A 1.8 tarda un poco mas todavia en corregir del
# todo, pero sigue evitando el atravesamiento igual (se recalcula
# cada cuadro contra la posicion real, nunca es un empujon de una
# sola vez) - solo que ahora bastante mas de a poco.
export var velocidad_correccion_choque = 1.8

# NUEVO - tope de cuanto puede RETROCEDER un caballo por segundo
# cuando el freno lo agarra encima de otro. Tiene que ser bastante
# mas alto que la velocidad a la que corren (20-28), para que nunca
# puedan meterse adentro de nadie; pero al ser un tope y no un
# salto, se ve como que frenan detras del de adelante en vez de
# pegar un tiron hacia atras. Si ves que se atraviesan, subilo. Si
# ves tirones feos hacia atras, bajalo (pero no por debajo de ~35 o
# vuelven los fantasmas).
export var velocidad_maxima_retroceso = 60.0

# NUEVO - cuanto tiene que ir REALMENTE adelante otro caballo para
# que valga frenarse detras de el. Dos caballos parejos (brecha casi
# 0) van lado a lado, no uno tapando al otro - esos NO se frenan
# entre si, se resuelven de costado.
# Este numero es el que evita que todo el peloton se frene a si
# mismo en cadena y la carrera corra a media velocidad. Si lo bajas
# a 0 vuelve ese problema. Subirlo mucho hace que se metan mas
# adentro del de adelante antes de reaccionar.
export var brecha_minima_para_frenar = 1.5

# NUEVO - cuanto mas lejos, ademas de los numeros de aca abajo,
# tiene que estar alguien para que el freno lo SUELTE, si ya lo
# tenia bloqueado. Antes se activaba y se soltaba con el mismo
# numero exacto - si dos caballos quedaban justo en el limite, el
# bloqueo titilaba prendido/apagado varias veces por segundo, y eso
# se sentia como brincoteos hacia atras repetidos. Ahora, una vez
# bloqueado, hace falta abrirse bastante MAS que el numero de
# activacion para soltarlo - asi no titila si se queda rondando
# justo en el limite.
# SUBIDO OTRA VEZ (de 4.0, que ya venia de 2.0) - el titileo seguia
# notandose, asi que se le dio mas margen todavia.
# BAJADO (de 5.0) - se habia ido subiendo (2 -> 4 -> 5) persiguiendo
# el titileo, y termino causando otro problema: una vez que el freno
# te agarraba, el margen se sumaba a los dos topes, asi que el
# jugador tenia que correrse mas de DOS carriles enteros al costado
# antes de que lo soltaran y pudiera pasar. Por eso "hay que estar
# muy lejos para pasarlos". Con 1.5 sigue alcanzando para que no
# titile, pero pasar vuelve a sentirse natural.
export var margen_liberacion_freno = 1.5

# CORREGIDO (URGENTE, causa de fondo) - el freno solido usaba
# distancia_cuerpos_seguridad (10) y distancia_minima_lateral (8)
# para decidir cuando frenar a alguien. El problema: esos DOS
# numeros son justamente los que mantienen al pelotón agrupado y
# parejo A PROPOSITO (ajustados en sesiones anteriores para que se
# vea compacto) - o sea que, por diseño, la mayoria de los caballos
# YA estan naturalmente a esa distancia la mayor parte de la
# carrera. Con el freno solido usando esos mismos numeros, quedaba
# activo casi todo el tiempo para casi todos - y como cada uno se
# frena contra el que tiene adelante, la cadena termina atada al
# que va primero (si ese es el jugador, frenar al jugador frenaba a
# toda la carrera).
#
# Ahora el freno solido tiene SUS PROPIOS numeros, mucho mas chicos
# - la distancia justa para evitar que dos modelos se dibujen uno
# encima del otro, no la distancia de "pelotón". Con esto, el
# freno se queda quieto casi todo el tiempo (el pelotón sigue
# yendo agrupado, como esta pensado) y solo actua en el instante
# real en que alguien esta a punto de montarse sobre otro.
export var distancia_frenado_longitudinal = 4.0

# CORREGIDO (la otra mitad de "se quedan frenados apenas arrancan")
# - los carriles de largada estan separados 3.0 entre si (5, 8, 11,
# 14, 17, 20, 23, 26, 29, 32 - uno por caballo). Si este numero es
# 3.0 o mas, entonces en la largada CADA caballo cuenta a su vecino
# de al lado como "en mi mismo carril" - y como ademas arrancan
# todos parejos en avance, quedan todos bloqueando a todos. Por eso
# tiene que quedar por DEBAJO de 3.0.
# (Si algun dia cambias la separacion de los carriles de largada,
# este numero tiene que quedar siempre mas chico que esa separacion.)
export var distancia_frenado_lateral = 2.5

# Separacion lateral: el objetivo de cada caballo es la baranda (0),
# salvo que alguien realmente adelante suyo (por recorrido real,
# suficientemente cerca) le impida llegar - ahi el objetivo pasa a
# ser "justo afuera de ese caballo". Como el criterio es el
# recorrido real (no el carril de arranque), el que va adelante
# nunca se mueve por culpa de otro, y a medida que las diferencias
# de velocidad se acumulan, la restriccion se afloja sola (el
# objetivo vuelve a ser la baranda) - no queda una separacion fija
# para siempre.
# Cuanto tiene que estar REALMENTE adelante otro caballo (en
# recorrido) para contar como que me esta tapando, en vez de ser
# puro empate/ruido. Sin este margen, con el pelotón yendo muy
# parejo, "quien me tapa" podia cambiar de rival de un cuadro a
# otro por una diferencia de milimetros - y cada vez que cambiaba,
# el objetivo lateral saltaba a un valor distinto (a veces mas
# hacia un lado, a veces hacia el otro). Eso era el brinco lateral
# que se notaba sobre todo en curva.
export var margen_empate_recorrido = 0.5

# CORREGIDO (causa real del zigzageo que quedaba despues del ajuste
# de arriba) - el problema no era solo un empate de recorrido.
# Cuando habia MAS DE UN rival genuinamente adelante (sin empate),
# se elegia cada cuadro al que pedia MAS lugar de ese instante
# exacto. Como esos otros rivales tambien se estan moviendo hacia
# la baranda al mismo tiempo, cual de ellos pedia mas lugar podia
# cambiar de un cuadro a otro sin ningun empate de por medio - eso
# era el salto de un lado a otro. Ahora cada caballo se "engancha"
# al rival que lo esta bloqueando (_bloqueador_lateral) y se queda
# con el MISMO mientras siga siendo valido, sin importar que otro
# rival pida apenas un poco mas de lugar. Recien lo cambia si el
# candidato nuevo pide CLARAMENTE mas espacio que el actual - este
# numero es cuanto mas tiene que pedir para que valga la pena el
# cambio. Subilo si todavia se nota algun salto; bajalo si sentis
# que tarda de mas en reaccionar cuando de verdad hace falta.
export var margen_cambio_bloqueo = 2.0


# Que tan lejos de la baranda interior (h_offset) se le permite
# llegar a un rival como MAXIMO, sin importar cuantos rivales tenga
# que esquivar en cadena. Es la "baranda exterior, como limite"
# pedida - un tope fijo que nunca se cruza, en vez de confiar solo
# en que el sistema se porte bien. Un poco mas adentro que el ancho
# real de pista medido en sesiones anteriores (165), para dejar
# colchon de sobra.
export var limite_baranda_exterior = 150.0


# A que carril le llamamos "pegado a la baranda". No es 0: la baranda
# interior esta en el carril 2 y se inclina 0,35 hacia la pista, asi
# que apuntar a 0 los mete adentro de la baranda. 5 = medio cuerpo de
# caballo por dentro. Subilo si todavia la rozan, bajalo si corren
# despegados. GestorNivel es un autoload, asi que este numero se
# cambia aca, no en el Inspector.
export var carril_baranda = 5.0


# ------------------------------------------------------------
# Elegir hacia que carril apuntar (el corazon de "buscar la baranda")
# ------------------------------------------------------------
# CORREGIDO - ERROR DE FONDO, causa de "no buscan la baranda" y de
# buena parte del baile de lado a lado.
#
# Como estaba antes: se miraba a cada caballo que fuera adelante y
# cerca EN RECORRIDO, y se tomaba el que pedia mas lugar - sin fijarse
# NUNCA en donde estaba ese caballo a lo ancho de la pista.
# O sea: un caballo que iba 5 metros adelante pero por la parte de
# AFUERA de todo (carril 140) igual te obligaba a irte al carril 146,
# aunque toda la baranda estuviera libre. Con 9 rivales, casi siempre
# habia alguno adelante y afuera, asi que el objetivo terminaba
# siendo casi siempre "bien afuera". Por eso ninguno llegaba nunca a
# la baranda por mas que subieramos la velocidad de busqueda: el
# objetivo al que corrian ya estaba mal calculado.
#
# Como esta ahora: el objetivo SIEMPRE arranca siendo la baranda (0).
# Se juntan solo los caballos que de verdad te tapan, y se busca el
# lugar MAS PEGADO A LA BARANDA que este libre. Si la baranda esta
# libre, va a la baranda. Si esta ocupada, prueba justo por afuera
# del que la ocupa, y asi. Se va para afuera unicamente lo que haga
# falta, y no un centimetro mas - que es como se corre de verdad.
func _obtener_objetivo_lateral(corredor) -> float:
	var recorrido_propio = obtener_recorrido(corredor)
	var ocupados = []
	for otro in _corredores:
		if otro == corredor or not is_instance_valid(otro):
			continue
		if not ("h_offset" in otro):
			continue
		# CORREGIDO - CAUSA DE "SE TRASPASAN DE COSTADO".
		# Aca antes se salteaba al caballo del jugador, o sea que
		# para los 9 rivales el carril del jugador figuraba SIEMPRE
		# LIBRE y se le metian encima sin enterarse.
		# El comentario viejo decia que el freno solido se ocupaba
		# de eso. No alcanza: el freno solido solo actua cuando uno
		# va genuinamente ADELANTE del otro. Dos caballos a la par
		# no entran nunca en esa cuenta - por eso se traspasaban de
		# costado y nunca de atras.
		# Ahora el jugador ocupa carril como cualquiera. No lo van a
		# seguir: la busqueda arranca siempre en la baranda y toma
		# el primer hueco libre, asi que al jugador lo esquivan, no
		# lo persiguen.
		var diferencia = obtener_recorrido(otro) - recorrido_propio
		if diferencia > distancia_cuerpos_seguridad:
			continue
		if diferencia < -distancia_frenado_longitudinal:
			continue
		if abs(diferencia) <= margen_empate_recorrido:
			# Van parejos, lado a lado. Para que los dos coincidan en
			# quien le hace lugar a quien (y no se crucen), se usa un
			# desempate fijo que no cambia durante la carrera.
			var otro_manda = false
			if ("separacion_lateral" in corredor) and ("separacion_lateral" in otro):
				otro_manda = otro.separacion_lateral < corredor.separacion_lateral
			else:
				otro_manda = otro.get_instance_id() < corredor.get_instance_id()
			if not otro_manda:
				continue
		ocupados.append(otro.h_offset)

	if ocupados.empty():
		return carril_baranda

	# Candidatos: la baranda, y justo por fuera de cada caballo que
	# esta tapando. Se prueban de adentro hacia afuera y se toma el
	# primero que este realmente libre.
	var candidatos = [carril_baranda]
	for h in ocupados:
		candidatos.append(h + distancia_minima_lateral)
	candidatos.sort()
	for candidato in candidatos:
		if candidato > limite_baranda_exterior:
			break
		var libre = true
		for h in ocupados:
			if abs(candidato - h) < distancia_minima_lateral:
				libre = false
				break
		if libre:
			return candidato

	# Caso raro: todo ocupado hasta el limite. Se queda pegado por
	# fuera del ultimo, sin pasarse del limite.
	ocupados.sort()
	return min(ocupados[ocupados.size() - 1] + distancia_minima_lateral, limite_baranda_exterior)


# Le pone freno a los cambios de objetivo para que no baile: si el
# objetivo nuevo es casi igual al de antes, se queda con el de antes.
# Recien cambia cuando la diferencia es de verdad (mas que
# margen_cambio_bloqueo). Irse HACIA la baranda no tiene freno - eso
# siempre se quiere y ya es gradual de por si.
func _obtener_minimo_lateral_estable(corredor) -> float:
	var objetivo = _obtener_objetivo_lateral(corredor)
	if not _bloqueador_lateral.has(corredor):
		_bloqueador_lateral[corredor] = objetivo
		return objetivo
	var anterior = _bloqueador_lateral[corredor]
	if objetivo < anterior or abs(objetivo - anterior) > margen_cambio_bloqueo:
		_bloqueador_lateral[corredor] = objetivo
		return objetivo
	return anterior


func obtener_h_offset_hacia_baranda(corredor) -> float:
	_limpiar_corredores()
	var minimo = _obtener_minimo_lateral_estable(corredor)
	# NUEVO - en la recta final ya no buscan la baranda: se quedan en
	# su carril y algunos se abren un poco, como en la vida real.
	var en_final = _carril_recta_final(corredor, minimo)
	if en_final >= 0.0:
		return en_final
	return _con_rapidez_maxima(corredor, _suavizar_salida(corredor, _decidir_baranda(corredor, minimo)))


# NUEVO - Rapidez maxima hacia los lados (carriles por segundo). Antes,
# mientras mas lejos de la baranda estaba un caballo, mas rapido se
# cruzaba hacia ella, y salian del aparato en diagonal. Mas bajo = mas
# derechos. 0 = apagado (como antes).
export var rapidez_max_lateral = 6.0

func _con_rapidez_maxima(corredor, objetivo) -> float:
	if rapidez_max_lateral <= 0.0:
		return objetivo
	var k = 2.0
	if "velocidad_ajuste_lateral" in corredor:
		k = max(corredor.velocidad_ajuste_lateral, 0.01)
	var margen = rapidez_max_lateral / k
	return clamp(objetivo, corredor.h_offset - margen, corredor.h_offset + margen)


# ------------------------------------------------------------
# AUTONOMIA: CADA RIVAL DECIDE SI BUSCA LA BARANDA
# Cada rival decide al azar si es de los que buscan la baranda o de los
# que se quedan en su carril, y cada uno se mueve con su propia calma.
# Cada cierto rato algunos cambian de idea. Nadie se tira de golpe.
# ------------------------------------------------------------
export var autonomia_baranda = false
export var probabilidad_buscar_baranda = 0.5   # 0.5 = la mitad la busca
export var segundos_cambiar_idea_min = 15.0
export var segundos_cambiar_idea_max = 25.0
export var calma_min = 0.5                     # bajo = se mueve tranquilo
export var calma_max = 1.5
# Por cada rival: [busca la baranda, su carril, hasta cuando, calma, lugar actual]
var _idea_baranda = {}

func _decidir_baranda(corredor, minimo) -> float:
	if not autonomia_baranda:
		return minimo
	var idea = _idea_baranda.get(corredor, null)
	if idea == null or _tiempo_carrera >= idea[2]:
		var calma = rand_range(calma_min, calma_max)
		var lugar = corredor.h_offset
		if idea != null:
			calma = idea[3]
			lugar = idea[4]
		idea = [randf() < probabilidad_buscar_baranda, corredor.h_offset, _tiempo_carrera + rand_range(segundos_cambiar_idea_min, segundos_cambiar_idea_max), calma, lugar]
		_idea_baranda[corredor] = idea
	var destino = minimo
	if not idea[0]:
		destino = max(minimo, idea[1])
	idea[4] = lerp(idea[4], destino, clamp(idea[3] * get_process_delta_time(), 0.0, 1.0))
	return max(minimo, idea[4])


func _busca_baranda(corredor) -> bool:
	if not autonomia_baranda or not _idea_baranda.has(corredor):
		return true
	return _idea_baranda[corredor][0]


# ------------------------------------------------------------
# RECTA FINAL
# Los caballos se pegan a la baranda para ahorrar camino en la curva.
# Saliendo de la ultima curva ya no tiene sentido: cada rival se queda
# en el carril donde salio de la curva, y algunos (al azar) se abren
# unos metros. Solo se corren hacia afuera si alguien los tapa.
# ------------------------------------------------------------
export var no_buscar_baranda_al_final = true
export var metros_recta_final = 400.0    # a cuantos metros de la meta empieza
export var abrirse_final_max = 6.0       # cuanto se puede abrir cada uno, como maximo
var _entrada_recta_final = {}

func _carril_recta_final(corredor, minimo) -> float:
	if not no_buscar_baranda_al_final or modo_recta:
		return -1.0
	var falta = obtener_distancia_hasta_meta(corredor)
	if falta < 0.0 or falta > metros_recta_final:
		return -1.0
	if not _entrada_recta_final.has(corredor):
		_entrada_recta_final[corredor] = corredor.h_offset + rand_range(0.0, abrirse_final_max)
	var destino = min(_entrada_recta_final[corredor], h_offset_maximo_curva)
	return max(minimo, destino)


# ------------------------------------------------------------
# SALIDA SUAVE
# Al largar, con todos juntos, el lugar al que cada rival quiere ir
# cambia a cada rato y se veian brincando de un lado a otro. En los
# primeros metros ese lugar se mueve despacio, y despues vuelve poco a
# poco a lo normal.
# ------------------------------------------------------------
export var suavizar_salida = true
export var metros_salida_suave = 400.0   # en cuantos metros vuelve a lo normal
export var suavidad_salida = 0.15         # al largar: mas bajo = mas suave
export var suavidad_final_salida = 3.0   # al terminar el tramo: rapidez normal
var _objetivo_salida = {}

func _suavizar_salida(corredor, objetivo) -> float:
	if not suavizar_salida or metros_salida_suave <= 0.0:
		return objetivo
	var r = obtener_recorrido(corredor)
	if r >= metros_salida_suave:
		_objetivo_salida.erase(corredor)
		return objetivo
	var antes = _objetivo_salida.get(corredor, corredor.h_offset)
	# Siempre suavizado: arranca muy lento y se va soltando poco a poco.
	var rapidez = lerp(suavidad_salida, suavidad_final_salida, r / metros_salida_suave)
	var suave = lerp(antes, objetivo, clamp(rapidez * get_process_delta_time(), 0.0, 1.0))
	_objetivo_salida[corredor] = suave
	return suave


# NUEVO (causa real de "se quedan pegados a la baranda exterior") -
# esta funcion, tal como estaba, SOLO empujaba hacia afuera (para no
# pisar a alguien) y nunca empujaba de vuelta hacia adentro. Eso
# esta bien mientras hay alguien bloqueando - pero una vez que ese
# alguien ya no bloquea mas (se quedo atras, o el hueco se abrio), 
# el caballo se quedaba CONGELADO en el lugar donde lo habia dejado
# el ultimo empujon, sin ninguna forma de volver el solo hacia la
# baranda durante el resto de la curva - por eso se veian todos
# amontonados lejos de la baranda en curva, aunque ya nadie los
# estuviera tapando.
#
# CUIDADO - este es el mismo tipo de cambio (mover h_offset
# activamente durante la curva) que en sesiones anteriores hizo
# descarrilar caballos (se iban del pastito). Por eso el regreso de
# aca abajo es MUY lento (ver velocidad_regreso_baranda_curva, un
# numero bajo a proposito) - tarda varios segundos en notarse, nunca
# es un salto. Si despues de probar se llegan a ver caballos
# saliendose de la pista en curva, bajar este numero directo en el
# Inspector (0.0 lo apaga del todo) antes que ninguna otra cosa.
export var velocidad_regreso_baranda_curva = 0.4

# VERSION PARA CURVA - sigue siendo conservadora (nunca busca la
# baranda de golpe, solo empuja si de verdad hay alguien pegado, y
# usa el recorrido real para decidir quien va adelante) pero ahora
# SI vuelve de a poquito hacia la baranda cuando nadie la esta
# bloqueando (ver comentario de velocidad_regreso_baranda_curva
# arriba).
func separar_si_esta_pegado(corredor, h_offset_actual, velocidad_ajuste, delta) -> float:
	_limpiar_corredores()
	var minimo = _obtener_minimo_lateral_estable(corredor)
	if h_offset_actual < minimo:
		return lerp(h_offset_actual, minimo, clamp(velocidad_ajuste * delta, 0.0, 1.0))
	# NUEVO - en cada curva, algunos rivales (al azar) se abren hacia
	# afuera y dejan el hueco pegado a la baranda, como en la vida real.
	var apertura = _apertura_en_esta_curva(corredor)
	if apertura > 0.0:
		var destino = min(max(minimo, carril_baranda) + apertura, h_offset_maximo_curva)
		if h_offset_actual < destino:
			return lerp(h_offset_actual, destino, clamp(velocidad_abrirse_curva * delta, 0.0, 1.0))
		return lerp(h_offset_actual, destino, clamp(velocidad_regreso_baranda_curva * delta, 0.0, 1.0))
	if minimo <= carril_baranda and h_offset_actual > carril_baranda and _busca_baranda(corredor):
		return lerp(h_offset_actual, carril_baranda, clamp(velocidad_regreso_baranda_curva * delta, 0.0, 1.0))
	return h_offset_actual


# ------------------------------------------------------------
# ABRIRSE EN LA CURVA
# Al entrar a cada curva, cada rival tira una moneda: si le toca, se
# va abriendo despacio hacia afuera unos metros (al azar) y deja el
# hueco junto a la baranda. Al salir de la curva vuelve a buscar la
# baranda como siempre. Se mueve despacio a proposito (los cambios
# bruscos en curva descarrilaban caballos en sesiones anteriores).
# ------------------------------------------------------------
export var abrirse_en_curva = false
export var probabilidad_abrirse = 0.6     # 0.6 = 6 de cada 10 rivales se abren en cada curva
export var apertura_min = 6.0             # cuanto se abren, como minimo
export var apertura_max = 20.0            # y como maximo
export var velocidad_abrirse_curva = 0.3  # que tan rapido se abren (bajo = suave)
export var h_offset_maximo_curva = 130.0  # nunca mas afuera que esto (la arena llega a 165)
var _apertura = {}
var _ultima_vez_en_curva = {}

func _apertura_en_esta_curva(corredor) -> float:
	if not abrirse_en_curva:
		return 0.0
	# Si hace mas de 1 segundo que no estaba en curva, es una curva nueva:
	# se vuelve a tirar la moneda.
	var ultima = _ultima_vez_en_curva.get(corredor, -100.0)
	_ultima_vez_en_curva[corredor] = _tiempo_carrera
	if not _apertura.has(corredor) or _tiempo_carrera - ultima > 1.0:
		var a = 0.0
		if randf() < probabilidad_abrirse:
			a = rand_range(apertura_min, apertura_max)
		_apertura[corredor] = a
	return _apertura[corredor]


# Devuelve true si a "corredor" lo esta bloqueando alguien mas
# adelante, en su mismo carril, mas cerca que distancia_cuerpos_seguridad.
# La calcula _aplicar_colision_solida una vez por cuadro para todos;
# esta funcion solo lee el resultado ya guardado. Sirve tambien para
# preparar la vibracion del control: cuando el jugador este
# bloqueado (esta_bloqueado(jugador) == true), ahi es el momento de
# hacer vibrar el telefono/mando (eso se conecta en Jockey_final.gd
# en un paso aparte).
func esta_bloqueado(corredor) -> bool:
	return _bloqueado.get(corredor, false)


# Busca si hay lugar para meterse en el carril h_offset_intento sin
# quedar pegado a nadie que este cerca en recorrido. La usan los
# rivales (a traves de obtener_h_offset_hacia_baranda) antes de
# intentar salir a adelantar por afuera.
func hay_espacio_en_carril(corredor, h_offset_intento) -> bool:
	_limpiar_corredores()
	for otro in _corredores:
		if otro == corredor or not is_instance_valid(otro):
			continue
		if abs(otro.h_offset - h_offset_intento) >= distancia_minima_lateral:
			continue
		if abs(obtener_recorrido(otro) - obtener_recorrido(corredor)) < distancia_cuerpos_seguridad:
			return false
	return true


# ------------------------------------------------------------
# Colision solida (choque real) - pasada global, frena Y esquiva
# ------------------------------------------------------------
# Se ejecuta una vez por cuadro, para TODOS los caballos a la vez
# (rivales Y jugador). Su trabajo es evitar que uno se atraviese al
# que tiene justo delante - sea de frente (avance) o de costado
# (carril). La separacion lateral "preferida" (que tan lejos de la
# baranda le GUSTARIA estar a cada uno) sigue siendo cosa de cada
# caballo por su cuenta, con obtener_h_offset_hacia_baranda /
# separar_si_esta_pegado - esto de aca es solo el ultimo recurso de
# emergencia, para cuando de verdad estan a punto de superponerse.
#
# (CORREGIDO - esta funcion SI tenia antes un empuje lateral
# tambien, y se sacaba por completo porque usaba distancia_cuerpos_
# seguridad (10) y distancia_minima_lateral (8) - los MISMOS
# numeros con los que el pelotón normal ya viaja todo el tiempo a
# proposito - entonces el empuje quedaba activo para casi todos
# casi siempre, y el grupo ENTERO quedaba soldado en una formacion
# fija que nunca se deshacia (la "escalera" congelada).
# AHORA es distinto: el empuje lateral de aca abajo usa los
# umbrales CHICOS del freno (distancia_frenado_longitudinal /
# distancia_frenado_lateral, mucho mas chicos que los del pelotón) -
# los mismos que ya se usaban SOLO para frenar. Como el pelotón
# normal viaja fuera de ese rango chico la mayor parte del tiempo,
# este empuje se queda quieto para casi todos casi siempre, igual
# que el freno - solo actua en el instante real en que alguien esta
# a punto de montarse sobre otro, que es exactamente cuando hace
# falta poder esquivar y no solo frenar.)
#
# Como funciona: se ordenan los caballos del que va MAS ADELANTE
# (mas recorrido real) al que va mas atras. Cada uno se compara solo
# contra los que van MAS ADELANTE que el (que por regla NUNCA se
# tocan en este cuadro). Si alguno de esos esta demasiado cerca - en
# recorrido Y en carril (h_offset) a la vez - se usa al bloqueador
# MAS exigente entre todos para poner un limite a cuanto puede
# avanzar este cuadro, Y para darle un empujoncito hacia afuera del
# carril de ese bloqueador (nunca se suma mas de lo necesario, sin
# importar cuantos caballos esten alrededor).
func _aplicar_colision_solida(delta):
	_limpiar_corredores()
	var orden = _corredores.duplicate()
	orden.sort_custom(self, "_comparar_recorrido_para_colision")

	# CORREGIDO (causa de "un grupo se queda frenado apenas arrancan")
	# - antes, cada caballo se comparaba contra la posicion EN VIVO de
	# los que tenia adelante... pero esos ya habian sido corregidos en
	# este mismo cuadro, unas lineas antes. Con la correccion chica de
	# antes eso casi no se notaba, pero con la pared dura nueva se
	# volvio una cadena: el 2do se frenaba detras del 1ro, el 3ro
	# detras del 2do YA FRENADO, el 4to detras del 3ro ya frenado...
	# y en la largada, con los 10 juntos, la cadena los empujaba a
	# todos para atras cuadro tras cuadro - se veian clavados.
	# Ahora se saca una FOTO de las posiciones antes de tocar nada, y
	# todos se corrigen contra esa foto. Asi cada uno se corrige una
	# sola vez, contra donde estaban de verdad, sin cadena.
	var foto_offset = {}
	var foto_h_offset = {}
	var foto_recorrido = {}
	for c in orden:
		if is_instance_valid(c) and ("offset" in c) and ("h_offset" in c):
			foto_offset[c] = c.offset
			foto_h_offset[c] = c.h_offset
			foto_recorrido[c] = obtener_recorrido(c)

	for i in range(orden.size()):
		var corredor = orden[i]
		if not is_instance_valid(corredor) or not ("h_offset" in corredor) or not ("offset" in corredor):
			continue
		# NUEVO - si ya estaba bloqueado el cuadro anterior, se le
		# exige abrirse un poco MAS que lo normal antes de soltarlo
		# (ver margen_liberacion_freno mas arriba) - evita el
		# titileo bloqueado/libre cuando alguien se queda rondando
		# justo en el limite.
		var ya_estaba_bloqueado = _bloqueado.get(corredor, false)
		var tope_longitudinal = distancia_frenado_longitudinal
		var tope_lateral = distancia_frenado_lateral
		if ya_estaba_bloqueado:
			tope_longitudinal += margen_liberacion_freno
			tope_lateral += margen_liberacion_freno
		var bloqueo = false
		var mayor_exceso = 0.0
		var objetivo_escape = -1.0
		for j in range(i):
			var otro = orden[j]
			if not is_instance_valid(otro) or not foto_offset.has(otro):
				continue
			var brecha = foto_recorrido[otro] - foto_recorrido[corredor]
			# CORREGIDO (causa de fondo de "se quedan frenados" y de
			# que la carrera vaya a media velocidad) - antes, ALCANZABA
			# con que "otro" estuviera en el mismo carril y no mas de
			# tope_longitudinal adelante. Pero eso incluye brecha = 0,
			# o sea DOS CABALLOS PAREJOS, corriendo lado a lado.
			# Y como el orden de la lista desempata a los parejos por
			# carril, el de mas afuera siempre quedaba contado como "el
			# de atras" y se frenaba detras de su propio vecino - que
			# tambien se frenaba detras del suyo, y asi los 10. Por eso
			# la carrera entera corria a media velocidad de punta a
			# punta, no solo en la largada.
			# Ahora, para frenar a alguien, el otro tiene que ir
			# GENUINAMENTE adelante (ver brecha_minima_para_frenar).
			# Dos caballos parejos ya no se frenan entre si - eso se
			# resuelve de costado, que es como se resuelve en la vida
			# real, no bajando la velocidad.
			if brecha < brecha_minima_para_frenar:
				continue
			if brecha >= tope_longitudinal:
				continue
			if abs(foto_h_offset[otro] - foto_h_offset[corredor]) >= tope_lateral:
				continue
			bloqueo = true
			var offset_maximo = foto_offset[otro] - distancia_frenado_longitudinal
			if _longitud_pista > 0:
				offset_maximo = fposmod(offset_maximo, _longitud_pista)
			var exceso = foto_offset[corredor] - offset_maximo
			if _longitud_pista > 0 and exceso > _longitud_pista * 0.5:
				exceso -= _longitud_pista
			if exceso > mayor_exceso:
				mayor_exceso = exceso
			# NUEVO - ademas de frenar el avance, calcula hacia donde
			# tendria que correrse para salir del carril de "otro" -
			# el mismo tipo de cuenta que ya usa el sistema de
			# baranda (otro.h_offset + distancia_minima_lateral), solo
			# que aca se aplica como ultimo recurso de emergencia.
			var objetivo = min(foto_h_offset[otro] + distancia_minima_lateral, limite_baranda_exterior)
			if objetivo > objetivo_escape:
				objetivo_escape = objetivo
		if mayor_exceso > 0.0:
			# CORREGIDO (causa de "se siguen traspasando como
			# fantasmas") - antes esto corregia solo una FRACCION del
			# excedente por cuadro (mayor_exceso * velocidad * delta).
			# Con la suavidad bajada a 1.8, esa fraccion es como el 3%
			# por cuadro - o sea que el de atras se le metia adentro al
			# de adelante mucho mas rapido de lo que el freno lo sacaba,
			# y visualmente se atravesaban igual.
			#
			# Ahora se corrige TODO el excedente, pero con un tope de
			# cuanto puede retroceder por segundo (ver
			# velocidad_maxima_retroceso). Ese tope es bastante mas
			# rapido de lo que avanza un caballo, asi que ya no puede
			# meterse adentro de nadie - pero al ser un tope y no un
			# salto, el de atras se ve FRENANDO detras del de adelante
			# (haciendo fila), nunca dando un tiron hacia atras.
			var retroceso = min(mayor_exceso, velocidad_maxima_retroceso * delta)
			corredor.offset -= retroceso
		# El esquive de costado SI sigue siendo suave (esa parte era
		# la que se veia fea cuando era brusca).
		# CORREGIDO (causa de "pego el caballo del jugador a la baranda
		# y se vuelve a separar solo") - esto se le estaba aplicando
		# TAMBIEN al jugador, asi que cada vez que tenia a alguien
		# cerca adelante, el juego le movia el caballo hacia afuera sin
		# que el apretara nada, y se despegaba de la baranda solo.
		# El caballo del jugador se maneja UNICAMENTE con las flechas -
		# el juego nunca le toca el carril. Que no se atraviese con
		# nadie ya se lo garantiza el freno de avance de aca arriba,
		# que si le sigue aplicando igual que a todos.
		if bloqueo and corredor.name != "Enrutador_Caballo1" and corredor.h_offset < objetivo_escape:
			corredor.h_offset = lerp(corredor.h_offset, objetivo_escape, clamp(velocidad_correccion_choque * delta, 0.0, 1.0))
		_bloqueado[corredor] = bloqueo


# ------------------------------------------------------------
# Busqueda de la baranda (pasada global, para los 9 rivales)
# ------------------------------------------------------------
# NUEVO - motivo: los caballos escapados seguian corriendo por el
# medio de la pista en vez de pegarse a la baranda.
#
# Por que pasaba: la busqueda de la baranda la hacia cada caballo por
# su cuenta, en su propio script, y la velocidad con que lo hacia era
# el MISMO numero que usa para esquivar a otro caballo
# (velocidad_ajuste_lateral - la barra 1 del panel). Son dos cosas
# distintas que no deberian compartir numero: esquivar tiene que ser
# LENTO para que no se vea el brincoteo, pero irse a la baranda tiene
# que ser NORMAL o no llega nunca. Al bajar esa barra para matar el
# brincoteo (que funciono), se apago tambien la busqueda de la
# baranda para los 9 rivales a la vez.
#
# Ahora la busqueda vive aca, con su propio numero, y no la puede
# pisar ninguna barra del panel. Ojo con el detalle importante: esta
# pasada SOLO mueve hacia ADENTRO (hacia la baranda), nunca hacia
# afuera. Empujar hacia afuera sigue siendo tarea de cada caballo.
# Por eso esto no puede sacar a nadie de la pista: el destino es la
# baranda interior, que es el borde de adentro, no el pasto.
export var velocidad_busqueda_baranda = 1.5


func _aplicar_busqueda_baranda(delta):
	# En el modo "800m" (recta suelta) nadie busca la baranda - esa
	# carrera es corta y derecha, no hay curva que cortar.
	if ConfiguracionCarrera and ConfiguracionCarrera.modo_recta:
		return
	_limpiar_corredores()
	for corredor in _corredores:
		if not is_instance_valid(corredor) or not ("h_offset" in corredor):
			continue
		# El jugador queda afuera: su carril lo maneja el con las
		# flechas y nada mas.
		if corredor.name == "Enrutador_Caballo1":
			continue
		var objetivo = _obtener_minimo_lateral_estable(corredor)
		if corredor.h_offset > objetivo:
			var paso = (corredor.h_offset - objetivo) * clamp(velocidad_busqueda_baranda * delta, 0.0, 1.0)
			if rapidez_max_lateral > 0.0:
				paso = min(paso, rapidez_max_lateral * delta)
			corredor.h_offset -= paso


func _comparar_recorrido_para_colision(a, b) -> bool:
	var recorrido_a = obtener_recorrido(a)
	var recorrido_b = obtener_recorrido(b)
	# CORREGIDO - justo al arrancar la carrera, todos los caballos
	# tienen practicamente el mismo recorrido (una diferencia de
	# centimetros). Decidir "quien va adelante" con un empate asi es
	# puro ruido numerico, y ese ruido puede invertirse de un cuadro
	# a otro - eso hacia que dos caballos parecidos se turnaran el
	# rol de "el que va atras" varias veces por segundo, y se veia
	# como saltos hacia atras seguidos justo al principio de la
	# carrera (una vez que se abrian diferencias de velocidad
	# reales, pasados los primeros metros, el empate desaparecia y
	# dejaba de pasar). Ahora, si estan practicamente empatados
	# (menos de 0.5 de diferencia), el orden se decide por el carril
	# de arranque (separacion_lateral) - fijo desde el arranque,
	# nunca cambia - en vez del recorrido. Esto es SOLO para
	# desempatar casos de empate real; el recorrido sigue siendo el
	# criterio principal en cuanto hay una diferencia real.
	if abs(recorrido_a - recorrido_b) < 0.5:
		if ("separacion_lateral" in a) and ("separacion_lateral" in b):
			return a.separacion_lateral < b.separacion_lateral
		return a.get_instance_id() < b.get_instance_id()
	return recorrido_a > recorrido_b


# ------------------------------------------------------------
# Separacion lateral segura (buscar la baranda sin solaparse)
# ------------------------------------------------------------
func obtener_h_offset_seguro(corredor, h_offset_deseado, distancia_minima, ventana_offset = 6.0) -> float:
	_limpiar_corredores()
	var resultado = h_offset_deseado
	for otro in _corredores:
		if otro == corredor or not is_instance_valid(otro):
			continue
		var separacion_offset = abs(otro.offset - corredor.offset)
		if _longitud_pista > 0:
			separacion_offset = min(separacion_offset, _longitud_pista - separacion_offset)
		if separacion_offset > ventana_offset:
			continue
		if abs(resultado - otro.h_offset) < distancia_minima:
			if resultado >= otro.h_offset:
				resultado = otro.h_offset + distancia_minima
			else:
				resultado = otro.h_offset - distancia_minima
	return resultado


# ------------------------------------------------------------
# Tiempo de carrera (para mostrar en el HUD y para diagnostico)
# ------------------------------------------------------------
func obtener_tiempo_carrera() -> float:
	return _tiempo_carrera


# ------------------------------------------------------------
# Devuelve true recien cuando TODOS los corredores (no solo el
# jugador) ya cruzaron la meta la cantidad de vueltas necesaria.
# La usa GestorCamaras para saber cuando apagar la camara de
# llegada (se queda prendida viendo pasar a todos, y se apaga
# recien cuando ya paso el ultimo).
# ------------------------------------------------------------
func todos_terminaron() -> bool:
	_limpiar_corredores()
	if _corredores.empty():
		return false
	for corredor in _corredores:
		if not ha_terminado(corredor):
			return false
	return true


# ------------------------------------------------------------
# SORTEO DE PUESTOS
# En cada carrera se sortea en que casilla sale cada caballo (el
# jugador tambien), y ese mismo es su numero de mandil.
# ------------------------------------------------------------
export var sortear_puestos = true
var _puesto_de = {}
var _escena_del_sorteo = 0

func obtener_puesto(enrutador) -> int:
	var propio = int(enrutador.name.substr(17))
	if not sortear_puestos:
		return propio
	var escena = get_tree().current_scene
	var id_escena = 0
	if escena:
		id_escena = escena.get_instance_id()
	if id_escena != _escena_del_sorteo or _puesto_de.empty():
		_hacer_sorteo(enrutador.get_parent())
		_escena_del_sorteo = id_escena
	return _puesto_de.get(enrutador.name, propio)

func _hacer_sorteo(camino):
	_puesto_de.clear()
	if camino == null:
		return
	var nombres = []
	for hijo in camino.get_children():
		if hijo is PathFollow and hijo.name.begins_with("Enrutador_Caballo"):
			nombres.append(hijo.name)
	var puestos = []
	for i in range(nombres.size()):
		puestos.append(i + 1)
	randomize()
	puestos.shuffle()
	for i in range(nombres.size()):
		_puesto_de[nombres[i]] = puestos[i]
	print("[BDG-Sorteo] ", _puesto_de)


# ------------------------------------------------------------
# ORDEN DE LLEGADA REAL (del 2do en adelante)
# ------------------------------------------------------------
# Antes el orden completo quedaba congelado en el instante en que
# cruzaba el GANADOR: del 2do para atras se ordenaba por la distancia
# que llevaba cada uno en ese momento. Si un caballo pasaba a otro en
# los ultimos metros (remate con latigo y arreo), igual quedaba detras.
# Ahora, despues del ganador, cada caballo entra en su puesto en el
# cuadro exacto en que su nariz toca la raya. Si dos cruzan en el mismo
# cuadro, va primero el que la toco antes (misma regla del ganador).
# Los que todavia no llegan van al final, por distancia.
func _actualizar_orden_llegada():
	if _llegados_en_orden.empty():
		for corredor in _orden_llegada_congelado:
			if is_instance_valid(corredor) and ha_terminado(corredor):
				_llegados_en_orden.append(corredor)
	var nuevos = []
	var faltan = []
	for corredor in _corredores:
		if not is_instance_valid(corredor) or _llegados_en_orden.has(corredor):
			continue
		if ha_terminado(corredor):
			nuevos.append(corredor)
		else:
			faltan.append(corredor)
	if nuevos.empty():
		return
	_fraccion_cruce.clear()
	for corredor in nuevos:
		_fraccion_cruce[corredor] = _fraccion_desde_que_cruzo(corredor)
	nuevos.sort_custom(self, "_comparar_cruce")
	for corredor in nuevos:
		_llegados_en_orden.append(corredor)
	faltan.sort_custom(self, "_comparar_recorrido_vivo")
	_orden_llegada_congelado = _llegados_en_orden + faltan
	if mostrar_diagnostico:
		for corredor in nuevos:
			print("[BDG] PUESTO ", _llegados_en_orden.find(corredor) + 1, ": ", corredor.name)
	emit_signal("orden_llegada_actualizado")


func _comparar_recorrido_vivo(a, b) -> bool:
	return obtener_recorrido(a) > obtener_recorrido(b)
