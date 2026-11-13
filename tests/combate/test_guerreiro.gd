extends TestCase
## Guerreiro de Clã (GD-02, 4.1): avisa 0,6 s antes, rajada de 3 tiros lentos, armadura frontal.


func _projeteis_inimigos() -> Array[Projetil]:
	var lista: Array[Projetil] = []
	for filho in get_children():
		if filho is Projetil and not filho.is_queued_for_deletion() and filho.collision_layer == Camadas.PROJETEIS_INIMIGO:
			lista.append(filho)
	return lista


func test_guerreiro_tem_os_numeros_do_gd02() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(30), 0))
	await esperar_frames(1)
	afirmar_igual(g.vida.maxima, 120, "vida")
	afirmar_igual(g.tamanho, Vector2(32, 64), "tamanho ~2× Ryker")
	afirmar_igual(g.peso, Inimigo.Peso.MEDIO, "peso médio")
	afirmar(g.armadura_frontal, "armadura frontal")


func test_avisa_0_6s_antes_e_atira_rajada_de_3() -> void:
	# Pilar 1: nenhum tiro sem aviso.
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_jogador(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(9), 0))
	await esperar_frames(33)  # 0,5 s de entrada (D-036)
	afirmar(g.esta_anunciando(), "entra em aviso ao ver o jogador")
	await esperar_frames(30)  # ~0,55 s
	afirmar(_projeteis_inimigos().is_empty(), "nenhum tiro durante o aviso")
	await esperar_frames(30)  # ~1,05 s
	afirmar_igual(_projeteis_inimigos().size(), 3, "rajada de 3 tiros")
	var tiro: Projetil = _projeteis_inimigos()[0]
	afirmar_proximo(tiro.velocidade.length(), 180.0, 0.5, "tiros lentos a 180 px/s")
	Combate.reiniciar()


func test_rajada_acerta_o_jogador_parado() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(9), 0))
	await esperar_frames(180)
	afirmar(j.vida.atual < 4, "a rajada acerta quem fica parado")
	afirmar(j.vida.atual >= 3, "a invulnerabilidade impede levar os 3 tiros seguidos")
	Combate.reiniciar()


func test_avanca_devagar_ate_a_distancia_preferida() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(24), 0))
	var x0: float = g.global_position.x
	await esperar_frames(60)
	afirmar(g.global_position.x < x0, "avança em direção ao jogador")
	afirmar(x0 - g.global_position.x < CenarioTeste.tiles(2), "devagar")
	afirmar(j != null)
	Combate.reiniciar()


func test_fuzil_pela_frente_causa_metade() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(10), 0))
	await esperar_frames(33)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	j.entrada.atirar_segurado = false
	await esperar_frames(20)
	afirmar_igual(g.vida.atual, 115, "10 de dano pela frente vira 5")
	Combate.reiniciar()


func test_ataca_faccao_rival_na_zona_de_guerra() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(0, 0))
	g.ataca_faccao_rival = true
	var vesh := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(8), 0))
	vesh.faccao = &"vesh"
	var kharn := CenarioTeste.criar_boneco(self, Vector2(-CenarioTeste.tiles(5), 0))
	kharn.faccao = &"kharn"
	await esperar_frames(2)
	afirmar(g.escolher_alvo(Vector2(500, 200)) == vesh, "mira na facção rival, não no aliado")
	var j := CenarioTeste.criar_jogador(self, Vector2(CenarioTeste.tiles(12), 0))
	await esperar_frames(1)
	afirmar(g.escolher_alvo(Vector2(500, 200)) == j, "jogador com peso 2× continua sendo o alvo principal")
	Combate.reiniciar()


func test_aviso_final_0_2s_antes_do_tiro() -> void:
	# Pedido de ART: gancho para o flash na cor AVISO nos últimos 0,2 s.
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_jogador(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(9), 0))
	var quadro_aviso: Array[int] = [-1]
	var quadro: Array[int] = [0]
	g.aviso_final.connect(func(_i: Inimigo) -> void: quadro_aviso[0] = quadro[0])
	var quadro_tiro: int = -1
	for i in 120:
		await esperar_frames(1)
		quadro[0] += 1
		if g.estado == GuerreiroCla.Estado.RAJADA and quadro_tiro < 0:
			quadro_tiro = quadro[0]
	afirmar(quadro_aviso[0] > 0, "emitiu aviso_final")
	afirmar_proximo((quadro_tiro - quadro_aviso[0]) / 60.0, 0.2, 0.04, "0,2 s antes do tiro")
	afirmar_igual(Inimigo.COR_AVISO, Color("fff3a0"), "cor AVISO reservada (D-033)")
	Combate.reiniciar()
