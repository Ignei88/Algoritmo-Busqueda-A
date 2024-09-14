extends Node

@onready var map = $TileMapLayer

class Nodo:
	var posicion:Vector2i
	var g_costo:int
	var h_costo:int
	var f_costo:int
	var padre:Nodo = null
	@warning_ignore("shadowed_variable")
	func _init(posicion:Vector2i,g_costo:int,h_costo:int,padre:Nodo = null) -> void:
		self.posicion = posicion 
		self.g_costo = g_costo
		self.h_costo = h_costo
		self.f_costo = g_costo + h_costo
		self.padre = padre



func obtener_vecinos(posicion_celda: Vector2i,pos_final:Vector2i):
	var vecinos = []
	var offsets = [
		Vector2i(0, -1),   # Arriba
		Vector2i(0, 1),    # Abajo
		Vector2i(-1, 0),   # Izquierda
		Vector2i(1, 0),    # Derecha
		Vector2i(-1, -1),  # Arriba-Izquierda
		Vector2i(1, -1),   # Arriba-Derecha
		Vector2i(-1, 1),   # Abajo-Izquierda
		Vector2i(1, 1)     # Abajo-Derecha
	]
	for i in offsets:
		var vecino_pos = posicion_celda + i
		if map.get_cell_atlas_coords(vecino_pos) == Vector2i(-1,-1):
			vecinos.append(vecino_pos)
		elif vecino_pos == pos_final:
			return [pos_final]
	return vecinos

func distancia_Manhattan(d1:Vector2,d2:Vector2):
	var m_dist =  abs(d2.x - d1.x) + abs(d2.y-d1.y)
	return m_dist * 10

func get_neighbor_type(origen: Vector2i, vecino: Vector2i) -> int:
	var delta = origen - vecino
	match delta:
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0):
			return 10  # Direcciones cardinales
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1):
			return 14  # Direcciones diagonales
		_:
			return 0  # No es vecino directo

func _sort_nodos_by_cost(a: Nodo, b: Nodo) -> bool:
	return a.f_costo > b.f_costo


func algoritmo_euristica(p_inicial:Vector2i,p_destino:Vector2i):
#	var repeat_nodos = [null]
	var nodos_open = []
	var nodos_close = []
	var nodo_actual = Nodo.new(p_inicial,0,distancia_Manhattan(p_inicial,p_destino))
#	var nodo_axiliar = nodo_actual
	nodos_open.append(nodo_actual)
#	var z = 0
	while nodos_open.size() > 0:
		nodos_open.sort_custom(Callable(_sort_nodos_by_cost))
		var current_node: Nodo = nodos_open.pop_back()
		map.set_cell(current_node.posicion,0,Vector2i(5,0))
		await get_tree().create_timer(0.0001 * get_process_delta_time()).timeout
		for l in nodos_open:
			map.set_cell(l.posicion,0,Vector2(4,0))
		for i in nodos_close:
			map.set_cell(i.posicion,0,Vector2i(0,0))

		nodos_close.append(current_node)
		var nodos_vecinos = obtener_vecinos(current_node.posicion,p_destino)
#		if nodos_vecinos[0] == p_destino:
#			return reconstruir_camino(current_node)
#			break
		if current_node.posicion == p_destino:
			return reconstruir_camino(current_node)
			#break
		for i in nodos_vecinos:
			if get_nodo_en_lista(i,nodos_close) != null:
				continue
			var g_costo = current_node.g_costo + get_neighbor_type(nodo_actual.posicion,i)
			var h_costo = distancia_Manhattan(i,p_destino)# * 10
			var nodo_vecinos = Nodo.new(i,g_costo,h_costo,current_node)
			var nodo_existe = get_nodo_en_lista(i,nodos_open)
			if nodo_existe != null and g_costo < nodo_existe.g_costo:
				nodos_open.erase(nodo_existe)
			nodos_open.append(nodo_vecinos)
#		z += 1
	return []

func get_nodo_en_lista(cord: Vector2i, lista: Array) -> Nodo:
	for nodo in lista:
		if nodo.posicion == cord:
			return nodo
	return null

func reconstruir_camino(nodo: Nodo) -> Array:
	var camino = []
	while nodo != null:
		camino.append(nodo.posicion)
		nodo = nodo.padre
	camino.reverse()
	return camino

func print_nodo(nodos):
	for i in nodos:
		print("Posicion:",i.posicion)
		print("Costo_G:",i.g_costo)
		print("Costo H:",i.h_costo)
		print("Costo F:",i.f_costo)
		print("PADRE:",i.padre)
		
		
func _ready() -> void:
	pass

func convertir_cords(arr:Array)->Array:
	var arr_aux :Array = []
	var x = 0
	var y = 0
	for i in arr:
		x = i.x * 16 + 8
		y = i.y * 16 + 8
		arr_aux.append(Vector2(x,y))
	return arr_aux

func _on_button_pressed() -> void:
	var pos_inicial = Vector2i(19,11)
	var pos_final = Vector2i(53,15)
	$Label.text = "Buscando..."
	var ruta = await algoritmo_euristica(pos_inicial,pos_final)
	$Label.text = "Trazando ruta"
	for i in ruta:
		await get_tree().create_timer(0.01).timeout
		map.set_cell(i,0,Vector2i(2,0))
	var ruta_converted = convertir_cords(ruta)
	$Label.text = "Play"
	for i in ruta_converted:
		await get_tree().create_timer(0.1).timeout
		$Player.position += i - $Player.position  
