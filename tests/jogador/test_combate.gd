extends TestCase
## Tiro, vida em blocos, dano e o inimigo básico (GD-01, seções 3.2 e 4).


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


func test_tiro_sai_na_direcao_da_mira() -> void:
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
		var dir: Vector2 = ultimo[0].velocidade.normalized()
		afirmar_proximo(dir.x, 0.0, 0.01, "tiro para cima x")
		afirmar_proximo(dir.y, -1.0, 0.01, "tiro para cima y")


func test_projetil_do_fuzil_tira_1_de_vida_do_soldado() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var s := CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(5), 0))
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	j.entrada.atirar_segurado = false
	await esperar_frames(15)
	afirmar_igual(s.vida.atual, 2, "vida do soldado depois de 1 tiro")


func test_soldado_morre_com_3_tiros() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var s := CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(5), 0))
	var morreu: Array[bool] = [false]
	s.morreu.connect(func(_s: Soldado) -> void: morreu[0] = true)
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(40)
	afirmar(morreu[0], "soldado deveria morrer")


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
	afirmar(j.receber_dano(2), "ataque pesado depois da invulnerabilidade")
	afirmar_igual(j.vida.atual, 1, "ataque pesado tira 2 blocos")


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


func test_soldado_avisa_antes_de_atirar() -> void:
	# Pilar 1: nenhum tiro inimigo sem aviso.
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var s := CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(8), 0))
	await esperar_frames(3)
	afirmar(s.esta_anunciando(), "entra em aviso ao ver o jogador")
	afirmar(_projeteis().is_empty(), "nenhum tiro no começo do aviso")
	await esperar_frames(20)  # ~0,38 s < tempo_aviso (0,5 s)
	afirmar(_projeteis().is_empty(), "nenhum tiro durante o aviso")
	await esperar_frames(15)  # ~0,63 s
	afirmar_igual(_projeteis().size(), 1, "atira depois do aviso")
	afirmar(j != null)


func test_tiro_inimigo_acerta_o_jogador() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(6), 0))
	await esperar_frames(90)
	afirmar_igual(j.vida.atual, 3, "levou 1 bloco do tiro")


func test_dash_atravessa_tiro_inimigo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	var cena: PackedScene = load("res://scenes/armas/projetil_inimigo.tscn")
	var tiro: Projetil = cena.instantiate()
	add_child(tiro)
	tiro.configurar(j.ponto_de_tiro() + Vector2(20, 0), Vector2.LEFT, Unidades.px(8.0), 1, 4.0,
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
