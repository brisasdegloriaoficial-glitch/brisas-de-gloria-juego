tool
extends EditorScript
# AsignarTexturas.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Script de UN SOLO USO. Cambia las texturas gigantes que venian guardadas
# DENTRO de los materiales de caballos y jinetes (sin comprimir, por eso en
# Android salian negras y el APK pesaba tanto) por las texturas livianas de
# la carpeta Caballos/Texturas. No toca nada mas del material.
#
# Como usarlo:
#   1. Abre este script en el editor de scripts de Godot.
#   2. Menu Archivo > Ejecutar (o Ctrl + Shift + X).
#   3. Mira el panel Salida: debe decir "Listo: 14 de 14".
# Despues de usarlo lo puedes borrar.

const CARPETA = "res://Caballos/Texturas/"

# [material, casilla del material, textura nueva]
const CAMBIOS = [
	["res://Caballos/ab73fc39_325f_4f7f_93af_d11076175a67.material", "albedo_texture", "Americano_color.jpg"],
	["res://Caballos/tripo_1a7c3b4e_7c32_4d49_833c_d07e4bab6614.material", "albedo_texture", "Arabe_color.jpg"],
	["res://Caballos/tripo_86a61581_cf2c_408b_a89a_6ca6651d7480.material", "albedo_texture", "Silla_Arabe_color.jpg"],
	["res://Caballos/tripo_node_c4303750-eb8e-459f-a3a5-7d295333db8d_material_001.material", "albedo_texture", "CuartoMilla_color.jpg"],
	["res://Caballos/tripo_node_c4303750-eb8e-459f-a3a5-7d295333db8d_material_001.material", "normal_texture", "CuartoMilla_normal.png"],
	["res://Caballos/tripo_node_40740f63-094e-4e2b-8b6c-e18ec21e795b_material_001.material", "albedo_texture", "Ingles_color.jpg"],
	["res://Caballos/tripo_node_40740f63-094e-4e2b-8b6c-e18ec21e795b_material_001.material", "normal_texture", "Ingles_normal.png"],
	["res://Caballos/tripo_mat_5ed2ce11-b23d-4a7d-a743-6f536ea58903.material", "albedo_texture", "Jinete_color.jpg"],
	["res://Caballos/Cara.material", "albedo_texture", "Jinete_color.jpg"],
	["res://Caballos/Cara.material", "emission_texture", "Jinete_color.jpg"],
	["res://Caballos/tripo_mat_24d7b5ee-686d-49f8-970c-480cbf98637e.material", "albedo_texture", "Modelos_viejos_color.jpg"],
	["res://Caballos/tripo_mat_24d7b5ee-686d-49f8-970c-480cbf98637e_001.material", "albedo_texture", "Modelos_viejos_color.jpg"],
	["res://Caballos/tripo_mat_32674431-df6d-4d95-999e-3dad4a45b903.material", "albedo_texture", "Modelos_viejos_color.jpg"],
	["res://tripo_mat_24d7b5ee-686d-49f8-970c-480cbf98637e.material", "albedo_texture", "Modelos_viejos_color.jpg"],
]


func _run():
	var materiales = {}
	var listos = 0
	for c in CAMBIOS:
		if not ResourceLoader.exists(c[0]):
			print("[Texturas] No encontre el material: ", c[0])
			continue
		var m = load(c[0])
		var t = load(CARPETA + c[2])
		if m == null or t == null:
			print("[Texturas] No pude abrir: ", c[0], " o ", c[2])
			continue
		m.set(c[1], t)
		materiales[c[0]] = m
		listos += 1
	for ruta in materiales:
		var e = ResourceSaver.save(ruta, materiales[ruta])
		if e == OK:
			print("[Texturas] Guardado: ", ruta.get_file())
		else:
			print("[Texturas] ERROR al guardar ", ruta.get_file(), " (", e, ")")
	print("[Texturas] Listo: ", listos, " de ", CAMBIOS.size(), " texturas cambiadas.")
