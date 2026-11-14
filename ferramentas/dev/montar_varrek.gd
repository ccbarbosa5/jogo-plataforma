extends SceneTree
## Ferramenta do DEV (não faz parte do jogo; a pasta ferramentas/ é ignorada pelo Godot).
## 1) Gera scenes/salas/varrek_tileset.tres a partir da folha da ART
##    (assets/sprites/cenarios/varrek/varrek_tileset.png; regras no LEIAME de lá).
## 2) (opcional, com --sala) Monta a sala de teste com TileMapLayer + parallax.
##    Atenção: o Godot grava nas instâncias propriedades repetidas da cena de origem;
##    depois de usar --sala, copie para a sala só os nós Terreno, Decoracao e *Parallax.
## Rodar de novo quando a ART atualizar o tileset:
##   godot --headless --path . -s res://ferramentas/dev/montar_varrek.gd [-- --sala]

const FOLHA: String = "res://assets/sprites/cenarios/varrek/varrek_tileset.png"
const PASTA_PARALLAX: String = "res://assets/sprites/cenarios/varrek/"
const SAIDA_TILESET: String = "res://scenes/salas/varrek_tileset.tres"
const SALA: String = "res://scenes/salas/sala_teste.tscn"
const T: int = 16

## Camadas de física (mesmos bits de scripts/comum/camadas.gd).
const MUNDO: int = 1
const PLATAFORMAS: int = 1 << 5

## Terreno sólido da sala de teste, em tiles: [x0, y0, x1, y1] inclusivos.
const SOLIDOS: Array = [
	[0, 15, 16, 16],    # chão até o buraco
	[20, 15, 89, 16],   # chão depois do buraco (buraco nos tiles 17 a 19)
	[-1, -4, -1, 16],   # parede esquerda
	[90, -4, 90, 16],   # parede direita
	[44, 13, 46, 14],   # caixa de casco
]
## Plataformas de mão única: [x0, x1, y].
const PLATAFORMAS_SALA: Array = [
	[10, 15, 12], [20, 24, 10], [31, 38, 12], [51, 56, 10], [65, 70, 11], [80, 85, 11],
]
## Decoração sem colisão: [x, y, coluna da linha 3].
const DECORACAO: Array = [[5, 14, 3], [27, 14, 3], [60, 14, 3], [76, 14, 3], [42, 14, 1], [88, 14, 2]]


func _initialize() -> void:
	var tileset := _criar_tileset()
	var erro: Error = ResourceSaver.save(tileset, SAIDA_TILESET)
	print("tileset: ", error_string(erro))
	if "--sala" in OS.get_cmdline_user_args():
		_montar_sala(load(SAIDA_TILESET))
	quit()


func _criar_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, MUNDO)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, PLATAFORMAS)
	ts.set_physics_layer_collision_mask(1, 0)
	ts.add_terrain_set()
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, "casco")
	ts.set_terrain_color(0, 0, Color("5a5266"))
	var fonte := TileSetAtlasSource.new()
	fonte.texture = load(FOLHA)
	fonte.texture_region_size = Vector2i(T, T)
	ts.add_source(fonte, 0)
	var quadrado := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	# Linhas 0 e 1: o índice é a soma dos vizinhos sólidos (1 N, 2 L, 4 S, 8 O).
	for i in 16:
		var coords := Vector2i(i % 8, i / 8)
		fonte.create_tile(coords)
		var d: TileData = fonte.get_tile_data(coords, 0)
		_colisao(d, 0, quadrado, false)
		d.terrain_set = 0
		d.terrain = 0
		var lados := {
			TileSet.CELL_NEIGHBOR_TOP_SIDE: 1, TileSet.CELL_NEIGHBOR_RIGHT_SIDE: 2,
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE: 4, TileSet.CELL_NEIGHBOR_LEFT_SIDE: 8,
		}
		for lado: int in lados:
			d.set_terrain_peering_bit(lado, 0 if (i & lados[lado]) != 0 else -1)
	# Linha 2: variantes de miolo (0–2), plataforma fina (3–5), argola do Grilhão (6).
	for c in 7:
		var coords := Vector2i(c, 2)
		fonte.create_tile(coords)
		var d: TileData = fonte.get_tile_data(coords, 0)
		if c <= 2:
			_colisao(d, 0, quadrado, false)
			d.terrain_set = 0
			d.terrain = 0
			for lado: int in [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE]:
				d.set_terrain_peering_bit(lado, 0)
			d.probability = 0.15
		elif c <= 5:
			# Plataforma de mão única: colisão só nos 6 px de cima.
			_colisao(d, 1, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, -2), Vector2(-8, -2)]), true)
	# Linha 3: decoração (sem colisão).
	for c in 4:
		fonte.create_tile(Vector2i(c, 3))
	return ts


func _colisao(d: TileData, camada: int, poligono: PackedVector2Array, uma_via: bool) -> void:
	d.add_collision_polygon(camada)
	d.set_collision_polygon_points(camada, 0, poligono)
	d.set_collision_polygon_one_way(camada, 0, uma_via)


func _montar_sala(tileset: TileSet) -> void:
	var sala: Node = (load(SALA) as PackedScene).instantiate()
	var mundo: Node = sala.get_node("Mundo")
	for filho in mundo.get_children():
		if filho is StaticBody2D or filho is TileMapLayer:
			mundo.remove_child(filho)
			filho.free()
	for nome in ["FundoParallax", "FrenteParallax"]:
		var velho: Node = sala.get_node_or_null(nome)
		if velho != null:
			sala.remove_child(velho)
			velho.free()
	# Terreno
	var terreno := TileMapLayer.new()
	terreno.name = "Terreno"
	terreno.tile_set = tileset
	mundo.add_child(terreno)
	mundo.move_child(terreno, 0)
	var solidos := {}
	for r: Array in SOLIDOS:
		for x in range(r[0], r[2] + 1):
			for y in range(r[1], r[3] + 1):
				solidos[Vector2i(x, y)] = true
	for celula: Vector2i in solidos:
		var bits: int = 0
		if solidos.has(celula + Vector2i(0, -1)): bits |= 1
		if solidos.has(celula + Vector2i(1, 0)): bits |= 2
		if solidos.has(celula + Vector2i(0, 1)): bits |= 4
		if solidos.has(celula + Vector2i(-1, 0)): bits |= 8
		var coords := Vector2i(bits % 8, bits / 8)
		if bits == 15 and (celula.x * 7 + celula.y * 13) % 6 == 0:
			coords = Vector2i((celula.x + celula.y) % 3, 2)  # variante de miolo
		terreno.set_cell(celula, 0, coords)
	for p: Array in PLATAFORMAS_SALA:
		for x in range(p[0], p[1] + 1):
			var col: int = 4
			if x == p[0]: col = 3
			elif x == p[1]: col = 5
			terreno.set_cell(Vector2i(x, p[2]), 0, Vector2i(col, 2))
	var deco := TileMapLayer.new()
	deco.name = "Decoracao"
	deco.tile_set = tileset
	deco.collision_enabled = false
	mundo.add_child(deco)
	mundo.move_child(deco, 0)
	for d: Array in DECORACAO:
		deco.set_cell(Vector2i(d[0], d[1]), 0, Vector2i(d[2], 3))
	# Parallax (LEIAME: fatores 0, 0,2, 0,5 atrás e 1,3 na frente)
	var fundo := Node2D.new()
	fundo.name = "FundoParallax"
	fundo.z_index = -10
	sala.add_child(fundo)
	sala.move_child(fundo, 0)
	_camada(fundo, "varrek_parallax_0_ceu_anel.png", 0.0, false)
	_camada(fundo, "varrek_parallax_1_cascos_longe.png", 0.2, true)
	_camada(fundo, "varrek_parallax_2_cascos_meio.png", 0.5, true)
	var frente := Node2D.new()
	frente.name = "FrenteParallax"
	frente.z_index = 20
	sala.add_child(frente)
	_camada(frente, "varrek_parallax_3_primeiro_plano.png", 1.3, true)
	_definir_dono(sala, sala)
	var cena := PackedScene.new()
	print("pack: ", error_string(cena.pack(sala)))
	print("sala: ", error_string(ResourceSaver.save(cena, SALA)))
	sala.free()


func _camada(pai: Node, arquivo: String, fator: float, repetir: bool) -> void:
	var p := Parallax2D.new()
	p.name = arquivo.get_basename().replace("varrek_parallax_", "Camada")
	p.scroll_scale = Vector2(fator, 0.0) if fator > 0.0 else Vector2.ZERO
	if repetir:
		p.repeat_size = Vector2(480, 0)
		p.repeat_times = 4
	pai.add_child(p)
	var s := Sprite2D.new()
	s.name = "Imagem"
	s.texture = load(PASTA_PARALLAX + arquivo)
	s.centered = false
	p.add_child(s)


func _definir_dono(no: Node, dono: Node) -> void:
	for filho in no.get_children():
		if filho.scene_file_path.is_empty() or filho.owner == null:
			filho.owner = dono
		if filho.scene_file_path.is_empty():
			_definir_dono(filho, dono)
