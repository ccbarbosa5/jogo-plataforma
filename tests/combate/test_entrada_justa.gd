extends TestCase
## Entrada justa e buracos (GD-03 2.1, 2.2 e 2.4; D-036). Teste 1 da seção 4 do GD-03.


func test_surgimento_nunca_a_menos_de_6_tiles() -> void:
	var jogadores: Array[Vector2] = [Vector2(100, 240)]
	var limite := Vector2(0, 1000)
	var minimo: float = Unidades.px(6.0)
	for x in [100.0, 130.0, 60.0, 190.0, 300.0]:
		var p: Vector2 = RegrasSurgimento.posicao_justa(Vector2(x, 240), jogadores, limite)
		afirmar(p.distance_to(jogadores[0]) >= minimo - 0.01, "x=%.0f virou %.0f (perto demais)" % [x, p.x])
	var longe := RegrasSurgimento.posicao_justa(Vector2(300, 240), jogadores, limite)
	afirmar_igual(longe, Vector2(300, 240), "posição já justa não muda")


func test_surgimento_respeita_os_limites_da_arena() -> void:
	var jogadores: Array[Vector2] = [Vector2(20, 240)]
	var p := RegrasSurgimento.posicao_justa(Vector2(30, 240), jogadores, Vector2(0, 400))
	afirmar(p.x >= 0.0 and p.x <= 400.0, "dentro da arena")
	afirmar(p.distance_to(jogadores[0]) >= Unidades.px(6.0) - 0.01, "e longe do jogador")


func test_surgimento_com_dois_jogadores() -> void:
	var jogadores: Array[Vector2] = [Vector2(100, 240), Vector2(250, 240)]
	var p := RegrasSurgimento.posicao_justa(Vector2(170, 240), jogadores, Vector2(0, 1000))
	for j in jogadores:
		afirmar(p.distance_to(j) >= Unidades.px(6.0) - 0.01, "longe dos dois")


func test_inimigo_nao_ataca_na_animacao_de_entrada() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(8), 0))
	g.dano_contato = 1
	await esperar_frames(2)
	afirmar(g.esta_entrando(), "está entrando")
	for i in 26:  # até ~0,47 s
		await esperar_frames(1)
		afirmar(not g.esta_anunciando(), "não anuncia ataque durante a entrada")
	await esperar_frames(8)
	afirmar(not g.esta_entrando(), "a entrada dura 0,5 s")
	afirmar(g.esta_anunciando(), "depois ataca normalmente")
	afirmar(j != null)
	Combate.reiniciar()


func test_sem_dano_de_contato_na_entrada() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(4, 0))
	b.dano_contato = 1
	await esperar_frames(20)
	afirmar_igual(j.vida.atual, 4, "encostar no inimigo entrando não machuca")
	await esperar_frames(20)
	afirmar_igual(j.vida.atual, 3, "depois da entrada, o contato machuca")


func test_1_segundo_de_invulnerabilidade_ao_entrar_na_sala() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(1)
	j.entrar_na_sala()
	afirmar(not j.receber_dano(1), "invulnerável ao entrar")
	await esperar_frames(54)  # 0,9 s
	afirmar(not j.receber_dano(1), "ainda no primeiro segundo")
	await esperar_frames(8)
	afirmar(j.receber_dano(1), "depois de 1 s leva dano")


func test_buraco_tira_1_bloco_e_devolve_a_plataforma() -> void:
	CenarioTeste.criar_chao(self, -500.0, 0.0)  # o chão acaba em x = 0
	var j := CenarioTeste.criar_jogador(self, Vector2(-40, 0))
	j.limite_queda_y = 120.0
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(1, 0)
	for i in 120:
		await esperar_frames(1)
		if j.vida.atual < 4:
			break
	j.entrada.direcao = Vector2i.ZERO
	afirmar_igual(j.vida.atual, 3, "caiu e perdeu 1 bloco")
	afirmar(j.global_position.x <= 6.0 and j.global_position.y <= 1.0, "voltou para o último chão (x=%.1f y=%.1f)" % [j.global_position.x, j.global_position.y])
	await esperar_frames(5)
	afirmar(j.is_on_floor(), "em pé no chão")


func test_buraco_tira_vida_mesmo_invulneravel() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(2)
	j.entrar_na_sala()
	j.voltar_do_buraco()
	afirmar_igual(j.vida.atual, 3, "o buraco não é evitado pela invulnerabilidade")
