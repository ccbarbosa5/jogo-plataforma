extends TestCase
## O tileset de Varrek (ART) tem chão sólido e plataforma de mão única.

const TILESET: String = "res://scenes/salas/varrek_tileset.tres"
const CHAO: Vector2i = Vector2i(0, 0)
const PLATAFORMA: Vector2i = Vector2i(3, 2)


## Chão de tiles com o topo em y = 0 e uma plataforma com o topo em y = -48 (3 tiles).
func _montar() -> TileMapLayer:
	var camada := TileMapLayer.new()
	camada.tile_set = load(TILESET)
	add_child(camada)
	for x in range(-20, 20):
		camada.set_cell(Vector2i(x, 0), 0, CHAO)
		camada.set_cell(Vector2i(x, 1), 0, CHAO)
	for x in range(-4, 4):
		camada.set_cell(Vector2i(x, -3), 0, PLATAFORMA)
	camada.update_internals()
	return camada


func test_jogador_fica_em_pe_no_chao_de_tiles() -> void:
	_montar()
	var j := CenarioTeste.criar_jogador(self, Vector2(160, -20))
	await esperar_frames(30)
	afirmar(j.is_on_floor(), "no chão")
	afirmar_proximo(j.global_position.y, 0.0, 1.0, "pés no topo do tile")


func test_plataforma_de_tile_e_mao_unica_e_da_para_descer() -> void:
	_montar()
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(70)
	j.entrada.pular_segurado = false
	afirmar(j.is_on_floor(), "subiu na plataforma por baixo")
	afirmar_proximo(j.global_position.y, -48.0, 1.0, "em cima da plataforma")
	j.entrada.direcao = Vector2i(0, 1)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(40)
	afirmar(j.global_position.y > -1.0, "↓ + pulo desce até o chão, y=%.1f" % j.global_position.y)
