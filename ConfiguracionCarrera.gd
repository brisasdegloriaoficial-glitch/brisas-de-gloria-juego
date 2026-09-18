extends Node

# Distancia de carrera elegida, en metros REALES (1 unidad de Godot
# = 1 metro de carrera, la pista ya esta a escala real). Para 800m
# este valor es solo la ETIQUETA que ve el jugador: la distancia
# real de ese modo la maneja TrackPath.distancia_recta_800m_real,
# porque 800m es un modo aparte (ver modo_recta).
export var distancia_metros = 1600.0

export var metros_por_unidad = 1.0

# REGLA 2 - true cuando la carrera elegida es el modo recta
# independiente (800m). Lo pone SelectorDistancias al elegir 800m.
export var modo_recta = false

# REGLA 2b - true cuando la carrera elegida es "vuelta completa"
# (2000m). Lo pone SelectorDistancias al elegir esa distancia.
export var modo_vuelta_completa = false

# true recien despues de que el jugador aprieta un boton en el
# selector. Mientras sea false, el juego arranca en pausa mostrando
# solo la lista de distancias - no arranca ninguna por defecto.
export var distancia_elegida = false

# NUEVO - limite de arreos (arreo_limite_seguro en Jockey_final.gd)
# para el modo ovalo normal. NO se usa en 800m, que tiene su propio
# limite aparte (arreo_limite_ritmo = 60, fijo). Lo pone
# SelectorDistancias por boton: 1200m=40, 1600m=50, 2000m=60,
# 2400m=70, 3000m=80.
export var arreo_limite = 30

# NUEVO - stamina base para la distancia elegida (a nivel de
# dificultad 1; en niveles mas altos GestorNivel la reduce
# proporcionalmente, igual que hacia antes). La pone SelectorDistancias
# por boton: 800m=100, 1200m=100, 1600m=120, 2000m=150, 2400m=200,
# 3000m=300. Reemplaza al intento anterior (formula automatica segun
# distancia_metros), que daba numeros disparatados en las carreras
# largas.
export var estamina_base = 100.0
