extends TestCase
## D-070: toda plataforma de todo bloco de sala é alcançável com o pulo base do Ryker (sem dash,
## sem melhoria), a partir do chão das bordas. Degrau máximo = altura do pulo − 8 px; distância
## horizontal com folga (85% do alcance do pulo). Exceção: bloco marcado "excecao_alcance" com
## um gancho do Grilhão perto (o tutorial do Grilhão).

const TILE: float = 16.0
const FOLGA: float = 0.85


func _parametros() -> ParametrosJogador:
	return ParametrosJogador.new()


## Maior subida (em tiles) que o pulo base vence com a margem de 8 px.
func _subida_maxima(p: ParametrosJogador) -> int:
	return floori((p.altura_pulo * TILE - 8.0) / TILE)


## Distância horizontal (px) que o pulo cobre subindo `subida_px`, com folga.
func _alcance_px(p: ParametrosJogador, subida_px: float) -> float:
	var h: float = p.altura_pulo * TILE
	var g_queda: float = p.gravidade_px() * p.multiplicador_gravidade_queda
	var tempo: float = p.tempo_ate_topo + sqrt(maxf(2.0 * (h - subida_px), 0.0) / g_queda)
	return p.velocidade_corrida_px() * tempo * FOLGA


func _celula(linhas: Array, x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= String(linhas[0]).length():
		return "."
	if y >= linhas.size():
		return "#"
	return String(linhas[y])[x]


## Células onde o Ryker fica em pé (chão ou plataforma embaixo, livre em cima).
func _pes(linhas: Array) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for y in linhas.size() - 1:
		for x in String(linhas[0]).length():
			var embaixo: String = _celula(linhas, x, y + 1)
			if (embaixo == "#" or embaixo == "=") and not _celula(linhas, x, y) in ["#", "="] \
					and _celula(linhas, x, y - 1) != "#":
				lista.append(Vector2i(x, y))
	return lista


func _inalcancaveis(bloco: Dictionary, p: ParametrosJogador) -> Array[Vector2i]:
	var linhas: Array = bloco["linhas"]
	var largura: int = String(linhas[0]).length()
	var pes: Array[Vector2i] = _pes(linhas)
	var visto: Dictionary = {}
	var fila: Array[Vector2i] = []
	for c in pes:
		if c.x == 0 or c.x == largura - 1:
			visto[c] = true
			fila.append(c)
	var subida_max: int = _subida_maxima(p)
	while not fila.is_empty():
		var a: Vector2i = fila.pop_front()
		for b in pes:
			if visto.has(b):
				continue
			var dx: int = absi(b.x - a.x)
			var subida: int = a.y - b.y
			var ok: bool = false
			if subida == 0 and dx == 1:
				ok = true
			elif subida < 0:
				ok = dx <= 6  # cair
			elif subida <= subida_max:
				ok = (dx - 1) * TILE <= _alcance_px(p, subida * TILE) \
						and not (subida > 0 and dx == 0 and _celula(linhas, b.x, b.y + 1) == "#")
			if ok:
				visto[b] = true
				fila.append(b)
	var fora: Array[Vector2i] = []
	for c in pes:
		if not visto.has(c):
			fora.append(c)
	return fora


func _tem_gancho_perto(bloco: Dictionary, c: Vector2i) -> bool:
	var linhas: Array = bloco["linhas"]
	for y in linhas.size():
		for x in String(linhas[y]).length():
			if String(linhas[y])[x] == "o" and absi(x - c.x) <= 12 and absi(y - c.y) <= 8:
				return true
	return false


func test_pulo_base_vence_3_tiles_de_degrau() -> void:
	var p := _parametros()
	afirmar_igual(_subida_maxima(p), 3, "altura do pulo 3,5 tiles − 8 px = 3 tiles de degrau")
	afirmar(_alcance_px(p, 48.0) >= 32.0, "no degrau máximo ainda cobre 2 tiles de vão")


func test_toda_plataforma_de_todo_bloco_e_alcancavel() -> void:
	var p := _parametros()
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/salas/blocos_varrek.json"))
	var ruins: Array[String] = []
	var blocos: int = 0
	for bloco: Dictionary in dados["blocos"]:
		blocos += 1
		var excecao: bool = "excecao_alcance" in bloco.get("tags", [])
		for c in _inalcancaveis(bloco, p):
			if excecao and _tem_gancho_perto(bloco, c):
				continue
			ruins.append("%s (%d, %d)" % [bloco["id"], c.x, c.y])
	afirmar(blocos > 20, "leu os blocos")
	afirmar_igual(ruins, [] as Array[String], "plataformas fora do alcance do pulo base")


func test_pulo_de_verdade_sobe_o_degrau_maximo() -> void:
	CenarioTeste.criar_chao(self)
	# Plataforma de mão única com o topo 3 tiles acima do chão, começando 2 tiles à frente.
	CenarioTeste.criar_bloco(self, Vector2(48, -48), Vector2(64, 8), true)
	var j := CenarioTeste.criar_jogador(self, Vector2(0, 0))
	await esperar_frames(5)
	j.entrada.direcao = Vector2i(1, 0)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(1)
	j.entrada.pular_pressionado = false
	await esperar_frames(50)
	j.entrada.direcao = Vector2i.ZERO
	j.entrada.pular_segurado = false
	await esperar_frames(10)
	afirmar(j.is_on_floor() and j.global_position.y < -40.0, "em pé na plataforma (y = %.0f)" % j.global_position.y)


## D-071: todo inimigo pesado de bloco tem caminho a pé (degraus até o pulo de um pesado) até
## uma das bordas do bloco, por onde o Ryker passa.
func test_pesados_tem_caminho_ate_a_area_do_jogador() -> void:
	var pulo_pesado: int = floori((load("res://scenes/inimigos/guerreiro_cla.tscn") as PackedScene).instantiate().pulo_tiles)
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/salas/blocos_varrek.json"))
	var presos: Array[String] = []
	for bloco: Dictionary in dados["blocos"]:
		var linhas: Array = bloco["linhas"]
		var largura: int = String(linhas[0]).length()
		var pes: Array[Vector2i] = _pes(linhas)
		for y in linhas.size():
			for x in largura:
				if not String(linhas[y])[x] in ["G", "T", "W", "C", "N"]:
					continue
				var inicio := Vector2i(x, y)
				while not pes.has(inicio) and inicio.y < linhas.size():
					inicio.y += 1
				var visto: Dictionary = {inicio: true}
				var fila: Array[Vector2i] = [inicio]
				var chegou: bool = false
				while not fila.is_empty() and not chegou:
					var a: Vector2i = fila.pop_front()
					chegou = a.x == 0 or a.x == largura - 1
					for b in pes:
						if visto.has(b):
							continue
						var dx: int = absi(b.x - a.x)
						var subida: int = a.y - b.y
						if (subida == 0 and dx == 1) or (subida < 0 and dx <= 2) or (subida > 0 and subida <= pulo_pesado and dx <= 2):
							visto[b] = true
							fila.append(b)
				if not chegou:
					presos.append("%s %s (%d, %d)" % [bloco["id"], String(linhas[y])[x], x, y])
	afirmar_igual(presos, [] as Array[String], "pesados sem caminho")
