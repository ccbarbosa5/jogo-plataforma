extends TestCase
## Tiro, golpe corpo a corpo, vida em blocos e granada (GD-01 3.2; GD-02 1.2, 1.3 e 2).


func _projeteis() -> Array[Projetil]:
	var lista: Array[Projetil] = []
	for filho in get_children():
		if filho is Projetil and not filho.is_queued_for_deletion():
			lista.append(filho)
	return lista


func test_fuzil_atira_8_vezes_por_segundo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var tiros: Array[int] = [0]
	j.atirou.connect(func(_p: Projetil) -> void: tiros[0] += 1)
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(60)
	j.entrada.atirar_segurado = false
	afirmar(tiros[0] >= 7 and tiros[0] <= 9, "esperado ~8 tiros em 1 s, saíram %d" % tiros[0])


func test_tiro_sai_na_direcao_da_mira_a_600_px_por_segundo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var ultimo: Array[Projetil] = [null]
	j.atirou.connect(func(p: Projetil) -> void: ultimo[0] = p)
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(0, -1)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	afirmar(ultimo[0] != null, "atirou")
	if ultimo[0] != null:
		afirmar_proximo(ultimo[0].velocidade.x, 0.0, 0.01, "tiro para cima x")
		afirmar_proximo(ultimo[0].velocidade.y, -600.0, 0.5, "tiro para cima a 600 px/s")


func test_fuzil_causa_10_de_dano() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(6), 0))
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	j.entrada.atirar_segurado = false
	await esperar_frames(15)
	afirmar_igual(b.vida.atual, 490, "vida do boneco depois de 1 tiro")


func test_golpe_corpo_a_corpo_substitui_o_tiro_de_perto() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(22, 0))  # 6 px de folga
	var tiros: Array[int] = [0]
	var golpes: Array[int] = [0]
	j.atirou.connect(func(_p: Projetil) -> void: tiros[0] += 1)
	j.golpeou.connect(func(_a: Array[Inimigo]) -> void: golpes[0] += 1)
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	afirmar_igual(tiros[0], 0, "não atira com inimigo colado")
	afirmar_igual(golpes[0], 1, "golpeou")
	afirmar_igual(b.vida.atual, 475, "golpe de 25")
	await esperar_frames(40)  # ~0,68 s
	afirmar_igual(golpes[0], 3, "1 golpe a cada 0,3 s")


func test_golpe_dobra_em_inimigo_atordoado() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(22, 0))
	await esperar_frames(3)
	b.atordoar(1.0)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	afirmar_igual(b.vida.atual, 450, "golpe de 50 no atordoado")


func test_golpe_ignora_a_armadura_frontal() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(26, 0), Inimigo.Peso.MEDIO, Vector2(28, 32), true)
	b.olhando = -1  # de frente para o Ryker
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	afirmar_igual(b.vida.atual, 475, "corpo a corpo não é reduzido pela armadura")


func test_vida_em_4_blocos_com_invulnerabilidade_de_0_8s() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(2)
	afirmar_igual(j.vida.atual, 4, "começa com 4 blocos")
	afirmar(j.receber_dano(1), "primeiro acerto")
	afirmar_igual(j.vida.atual, 3, "perdeu 1 bloco")
	afirmar(not j.receber_dano(1), "invulnerável logo depois")
	await esperar_frames(42)  # 0,7 s
	afirmar(not j.receber_dano(1), "ainda invulnerável aos 0,7 s")
	await esperar_frames(9)  # 0,85 s
	afirmar(j.receber_dano(1), "volta a levar dano")


func test_ataque_pesado_tira_2_blocos_e_nao_encadeia() -> void:
	# GD-02, seção 7, teste 5.
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(2)
	afirmar(j.receber_ataque(InfoDano.criar(2)), "ataque pesado entra")
	afirmar_igual(j.vida.atual, 2, "pesado tira 2 blocos")
	afirmar(not j.receber_ataque(InfoDano.criar(2)), "invulnerabilidade impede o segundo")
	afirmar_igual(j.vida.atual, 2, "sem dano em sequência")


func test_morte_emite_sinal_e_para_o_jogador() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var morreu: Array[bool] = [false]
	j.morreu.connect(func(_j: Jogador) -> void: morreu[0] = true)
	await esperar_frames(2)
	j.receber_dano(4)
	afirmar(morreu[0], "sinal morreu")
	afirmar(j.esta_morto(), "estado morto")
	j.entrada.atirar_segurado = true
	await esperar_frames(10)
	afirmar(_projeteis().is_empty(), "morto não atira")


func test_dash_atravessa_tiro_inimigo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	var cena: PackedScene = load("res://scenes/armas/projetil_inimigo.tscn")
	var tiro: Projetil = cena.instantiate()
	add_child(tiro)
	tiro.configurar(j.ponto_de_tiro() + Vector2(20, 0), Vector2.LEFT, 180.0, InfoDano.criar(1), 4.0,
			Camadas.PROJETEIS_INIMIGO, Camadas.MUNDO | Camadas.JOGADOR)
	j.entrada.dash_pressionado = true
	await esperar_frames(8)
	afirmar_igual(j.vida.atual, 4, "dash desviou do tiro")
	afirmar(is_instance_valid(tiro) and not tiro.is_queued_for_deletion(), "o tiro passa direto")


func test_arma_pesada_volta_para_a_principal_sem_municao() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(2)
	var pesada: DadosArma = j.arma.duplicate()
	pesada.nome = "Teste pesada"
	pesada.municao = 3
	pesada.cadencia = 30.0
	var principal: DadosArma = j.arma
	j.equipar(pesada)
	j.entrada.atirar_segurado = true
	await esperar_frames(20)
	afirmar(j.arma == principal, "voltou para a arma principal")


func test_granadas_3_por_sala() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(2)
	afirmar_igual(j.granadas, 3, "começa a sala com 3")
	for i in 3:
		afirmar(j.lancar_granada() != null, "granada %d" % (i + 1))
	afirmar(j.lancar_granada() == null, "a 4ª não sai")
	j.reabastecer_granadas()
	afirmar_igual(j.granadas, 3, "sala nova reabastece")


func test_granada_explode_com_50_de_dano_em_32_px_e_empurra() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var perto := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.MEDIO, Vector2(20, 32), true)
	perto.olhando = -1
	var longe := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(12), 0))
	await esperar_frames(3)
	var g: Granada = j.lancar_granada()
	g.global_position = perto.centro() + Vector2(-20, 0)
	g.velocidade = Vector2.ZERO
	var atingidos: Array = g.explodir()
	afirmar(perto in atingidos, "o boneco a 20 px foi atingido")
	afirmar(not longe in atingidos, "o boneco longe não foi atingido")
	afirmar_igual(perto.vida.atual, 450, "explosão ignora a armadura frontal (50 de dano)")
	await esperar_frames(2)
	afirmar(perto.global_position.x > CenarioTeste.tiles(5), "explosão empurra")


func test_granada_explode_sozinha_em_1_2_s() -> void:
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_bloco(self, Vector2(-2000, -400), Vector2(4000, 16))  # teto: a granada não cai no chão tão cedo
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	var g: Granada = j.lancar_granada()
	g.velocidade = Vector2.ZERO
	g.dados = g.dados.duplicate()
	g.dados.gravidade = 0.0
	var explodiu: Array[bool] = [false]
	g.explodiu.connect(func(_a: Array[Node]) -> void: explodiu[0] = true)
	await esperar_frames(66)  # 1,1 s
	afirmar(not explodiu[0], "ainda não explodiu")
	await esperar_frames(8)
	afirmar(explodiu[0], "explodiu pelo tempo")


func test_chamado_enche_1_ponto_a_cada_10_de_dano() -> void:
	# GD-02, seção 7, teste 8.
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(6), 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 5000)
	await esperar_frames(2)
	b.receber_ataque(InfoDano.criar(10, j))
	afirmar_proximo(j.barra_chamado, 1.0, 0.001, "10 de dano = 1 ponto")
	b.receber_ataque(InfoDano.criar(250, j))
	afirmar_proximo(j.barra_chamado, 26.0, 0.001, "260 de dano = 26 pontos")
	for i in 10:
		b.receber_ataque(InfoDano.criar(100, j))
	afirmar_proximo(j.barra_chamado, 100.0, 0.001, "para em 100")
	afirmar(j.chamado_pronto(), "Chamado pronto")
