extends TestCase
## Grilhão refeito (GD-07 §2): não interrompe o tiro, Marca, elite = gancho, derrubar da
## plataforma, e os nós do ramo do Grilhão na árvore de Combate.


func _g(j: Jogador) -> Grilhao:
	return j.ferramenta as Grilhao


func _lancar_e_esperar(j: Jogador, quadros: int = 40) -> void:
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(1)
	j.entrada.ferramenta_pressionada = false
	for i in quadros:
		await esperar_frames(1)
		if _g(j).estado == Grilhao.Estado.PRONTO:
			return


func test_numeros_base() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var g := _g(j)
	afirmar_igual([g.dano, g.recarga, g.recarga_erro, g.cargas_maximas()], [10, 3.0, 1.0, 1], "10 de dano, 3 s / 1 s, 1 carga")
	afirmar_proximo(Unidades.px(g.alcance_tiles()), 96.0, 0.01, "alcance de 96 px")


func test_acertar_marca_o_alvo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(4), 0))
	await esperar_frames(3)
	await _lancar_e_esperar(j)
	afirmar(j.controle_arma.esta_marcado(b), "Marcado")
	afirmar_proximo(j.controle_arma.bonus_da_marca(b), 0.25, 0.001, "+25%")


func test_atira_durante_a_puxada() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.PESADO, Vector2(40, 64))
	var tiros: Array[int] = [0]
	j.atirou.connect(func(_p: Projetil) -> void: tiros[0] += 1)
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(1)
	j.entrada.ferramenta_pressionada = false
	var durante: int = 0
	for i in 40:
		var antes: int = tiros[0]
		await esperar_frames(1)
		if j.esta_sendo_puxado():
			durante += tiros[0] - antes
	j.entrada.atirar_segurado = false
	afirmar(durante >= 1, "atirou enquanto era puxado (%d tiros)" % durante)


func test_elite_puxa_o_ryker() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0))
	b.categoria = Inimigo.Categoria.ELITE
	await esperar_frames(3)
	j.entrada.ferramenta_pressionada = true
	var puxado: bool = false
	for i in 20:
		await esperar_frames(1)
		j.entrada.ferramenta_pressionada = false
		puxado = puxado or j.esta_sendo_puxado()
	afirmar(puxado, "elite médio também vira gancho")


func test_medio_sem_protecao_numa_plataforma_acima_e_derrubado() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_bloco(self, Vector2(40, -48), Vector2(64, 8))
	var b := CenarioTeste.criar_boneco(self, Vector2(70, -48))
	await esperar_frames(5)
	var x0: float = b.global_position.x
	_g(j)._ao_acertar(b)
	afirmar(b.global_position.x < x0 - 20.0, "puxado na direção do Ryker (%.0f px)" % (x0 - b.global_position.x))
	var c := CenarioTeste.criar_boneco(self, Vector2(70, 0))
	await esperar_frames(3)
	var x1: float = c.global_position.x
	_g(j)._ao_acertar(c)
	afirmar_proximo(c.global_position.x, x1, 0.5, "no mesmo chão só cambaleia")


func test_medio_com_protecao_nao_e_derrubado() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_bloco(self, Vector2(40, -48), Vector2(64, 8))
	var b := CenarioTeste.criar_boneco(self, Vector2(70, -48), Inimigo.Peso.MEDIO, Vector2(20, 32), true)
	await esperar_frames(5)
	var x0: float = b.global_position.x
	_g(j)._ao_acertar(b)
	afirmar(not b.armadura_frontal, "perdeu a proteção")
	afirmar_proximo(b.global_position.x, x0, 0.5, "não é derrubado")


func test_corrente_longa_e_duas_cargas() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.assign([&"grilhao_corrente_longa", &"grilhao_duas_cargas"])
	await esperar_frames(3)
	var g := _g(j)
	afirmar_proximo(Unidades.px(g.alcance_tiles()), 128.0, 0.01, "Corrente Longa: 128 px")
	afirmar_igual(g.cargas_maximas(), 2, "Duas Cargas")
	afirmar_igual(g.cargas, 2, "começa com as 2")
	await _lancar_e_esperar(j)
	afirmar(g.esta_pronto(), "ainda tem a 2ª carga")
	await _lancar_e_esperar(j)
	afirmar(not g.esta_pronto(), "gastou as 2")


func test_arrastao_puxa_leves_perto_do_alvo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.append(&"grilhao_arrastao")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0), Inimigo.Peso.LEVE, Vector2(12, 16))
	var vizinho := CenarioTeste.criar_boneco(self, Vector2(100, 0), Inimigo.Peso.LEVE, Vector2(12, 16))
	var longe := CenarioTeste.criar_boneco(self, Vector2(160, 0), Inimigo.Peso.LEVE, Vector2(12, 16))
	await esperar_frames(3)
	_g(j)._ao_acertar(alvo)
	afirmar(alvo.esta_sendo_puxado(), "alvo puxado")
	afirmar(vizinho.esta_sendo_puxado(), "vizinho a 20 px também")
	afirmar(not longe.esta_sendo_puxado(), "o de 80 px não")


func test_corrente_explosiva_da_dano_em_volta() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.append(&"grilhao_corrente_explosiva")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0))
	var vizinho := CenarioTeste.criar_boneco(self, Vector2(105, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), true)
	await esperar_frames(3)
	_g(j).ponta = alvo.centro()
	_g(j)._ao_acertar(alvo)
	afirmar_igual(vizinho.vida.atual, 460, "vizinho levou 40")
	afirmar(not vizinho.armadura_frontal, "e perdeu a proteção")
