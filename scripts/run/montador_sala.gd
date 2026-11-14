class_name MontadorSala
extends RefCounted
## Monta os nós de uma sala a partir do plano do GeradorAto (GD-03 §2.1):
## os blocos ASCII viram um TileMapLayer com o tileset de Varrek (autotile pelos vizinhos),
## e os marcadores viram ganchos, inimigos, pontos de surgimento, portas, loja e reparo.

const TILESET: String = "res://scenes/salas/varrek_tileset.tres"
const T: int = 16
const CENAS_INIMIGOS: Dictionary = {
	"guerreiro": "res://scenes/inimigos/guerreiro_cla.tscn",
	"soldado": "res://scenes/inimigos/soldado_kharn.tscn",
	"elite": "res://scenes/inimigos/guerreiro_elite.tscn",
}
## Inimigos do GD-02 que ainda não existem viram Soldado até a tarefa 4.
const SUBSTITUTO: String = "soldado"
const FALAS: Dictionary = {"1": "queda_saida", "2": "queda_inimigo_grande", "4": "reliquia"}


static func cena_inimigo(tipo: String) -> PackedScene:
	return load(CENAS_INIMIGOS.get(tipo, CENAS_INIMIGOS[SUBSTITUTO]))


static func montar(plano: Dictionary, banco: BancoBlocos) -> SalaRun:
	var sala := SalaRun.new()
	sala.name = "Sala%d" % plano["numero"]
	sala.plano = plano
	var terreno := TileMapLayer.new()
	terreno.name = "Terreno"
	terreno.tile_set = load(TILESET)
	sala.add_child(terreno)
	var deco := TileMapLayer.new()
	deco.name = "Decoracao"
	deco.tile_set = terreno.tile_set
	deco.collision_enabled = false
	sala.add_child(deco)
	sala.move_child(deco, 0)
	var solidos: Dictionary = {}
	var plataformas: Array[Vector2i] = []
	var x0: int = 0
	for id: String in plano["blocos"]:
		var b: Dictionary = banco.bloco(id)
		var w: int = BancoBlocos.largura(b)
		var tipo: String = b["tipo"]
		if tipo == "arena":
			sala.arena = Rect2(x0 * T, 0, w * T, BancoBlocos.ALTURA * T)
		for y in BancoBlocos.ALTURA:
			var linha: String = b["linhas"][y]
			for x in w:
				var c: String = linha[x]
				var cel := Vector2i(x0 + x, y)
				var pe := Vector2((x0 + x) * T + T * 0.5, (y + 1) * T)  # pés no fundo da célula
				match c:
					"#":
						solidos[cel] = true
					"=":
						plataformas.append(cel)
					"o":
						var g := PontoGancho.new()
						g.position = Vector2((x0 + x) * T + T * 0.5, y * T + T * 0.5)
						sala.add_child(g)
					"E":
						sala.inicio = pe
					"D":
						sala.pontos_porta.append(pe)
					"G", "S":
						sala.inimigos_fixos.append({"tipo": "guerreiro" if c == "G" else "soldado", "posicao": pe})
					"M":
						var loja := LojaIlo.new()
						loja.position = pe
						sala.add_child(loja)
					"+", "*":
						sala.estacoes_reparo.append({"tipo": "cura" if c == "+" else "dadiva", "posicao": pe})
					"3":
						sala.dicas.append(pe)
					_:
						if c in BancoBlocos.SURGIMENTOS:
							if not sala.surgimentos.has(c):
								sala.surgimentos[c] = []
							sala.surgimentos[c].append(pe)
						elif FALAS.has(c):
							sala.falas.append({"cena": FALAS[c], "x": (x0 + x) * T})
		x0 += w
	sala.largura_px = x0 * T
	_pintar(terreno, solidos, plataformas)
	_decorar(deco, solidos, x0)
	return sala


## Autotile pela soma dos vizinhos sólidos (1 N, 2 L, 4 S, 8 O), como o montar_varrek.gd.
static func _pintar(terreno: TileMapLayer, solidos: Dictionary, plataformas: Array[Vector2i]) -> void:
	for cel: Vector2i in solidos:
		var bits: int = 0
		if solidos.has(cel + Vector2i(0, -1)) or cel.y == 0: bits |= 1
		if solidos.has(cel + Vector2i(1, 0)): bits |= 2
		if solidos.has(cel + Vector2i(0, 1)) or cel.y == BancoBlocos.ALTURA - 1: bits |= 4
		if solidos.has(cel + Vector2i(-1, 0)): bits |= 8
		var coords := Vector2i(bits % 8, bits / 8)
		if bits == 15 and (cel.x * 7 + cel.y * 13) % 6 == 0:
			coords = Vector2i((cel.x + cel.y) % 3, 2)  # variante de miolo
		terreno.set_cell(cel, 0, coords)
	for cel in plataformas:
		var esq: bool = cel + Vector2i(-1, 0) in plataformas
		var dir: bool = cel + Vector2i(1, 0) in plataformas
		var col: int = 4
		if not esq:
			col = 3
		elif not dir:
			col = 5
		terreno.set_cell(cel, 0, Vector2i(col, 2))


## Destroços pequenos no chão, sem colisão (linha 3 do tileset), em posições fixas por x.
static func _decorar(deco: TileMapLayer, solidos: Dictionary, largura: int) -> void:
	for x in largura:
		if (x * 37) % 11 != 0:
			continue
		for y in range(1, BancoBlocos.ALTURA):
			if solidos.has(Vector2i(x, y)) and not solidos.has(Vector2i(x, y - 1)):
				deco.set_cell(Vector2i(x, y - 1), 0, Vector2i((x / 11) % 4, 3))
				break
