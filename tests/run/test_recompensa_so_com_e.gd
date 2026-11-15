extends TestCase
## D-066: recompensas de escolha só com E (ou clique). Encostar não pega.


func _apertar_e(j: Jogador) -> void:
	j.entrada.interagir_pressionado = true
	await esperar_frames(1)
	j.entrada.interagir_pressionado = false
	await esperar_frames(2)


func _portas(xs: Array, tipos: Array) -> Array[PortaSaida]:
	var portas: Array[PortaSaida] = []
	for k in xs.size():
		var p := PortaSaida.new()
		p.tipo = tipos[k]
		p.position = Vector2(xs[k], 0)
		add_child(p)
		portas.append(p)
	return portas


func test_andar_por_cima_de_todas_nao_pega_nenhuma() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self, Vector2(0, -1))
	var portas := _portas([60, 100, 140], ["kharn", "creditos", "nucleos"])
	var loja := LojaIlo.new()
	loja.position = Vector2(190, 0)
	add_child(loja)
	var reparo := EstacaoReparo.criar_par(self, Vector2(230, 0), Vector2(260, 0))
	j.creditos = 500
	j.vida.receber_dano(1, true)
	var escolhidas: Array[String] = []
	for p in portas:
		p.escolhida.connect(func(porta: PortaSaida) -> void: escolhidas.append(porta.tipo))
	var perto: Array[bool] = [false, false, false]
	j.entrada.direcao = Vector2i(1, 0)
	for i in 120:
		await esperar_frames(1)
		for k in 3:
			perto[k] = perto[k] or portas[k].esta_perto()
		if j.global_position.x > 290.0:
			break
	j.entrada.direcao = Vector2i.ZERO
	afirmar_igual(perto, [true, true, true], "passou por cima de todas")
	afirmar_igual(escolhidas, [] as Array[String], "nenhuma porta escolhida")
	for p in portas:
		afirmar(not p.foi_usada() and not p.is_queued_for_deletion(), p.tipo + " continua lá")
	afirmar_igual([loja.vendidos, j.creditos], [0, 500], "a loja não vendeu")
	afirmar(not reparo[0].desligada and not reparo[1].desligada, "o reparo não foi usado")


func test_e_pega_so_a_mais_proxima() -> void:
	CenarioTeste.criar_chao(self)
	var portas := _portas([90, 112], ["kharn", "vesh"])
	var j := CenarioTeste.criar_jogador(self, Vector2(96, -1))
	var escolhidas: Array[String] = []
	for p in portas:
		p.escolhida.connect(func(porta: PortaSaida) -> void: escolhidas.append(porta.tipo))
	await esperar_frames(3)
	afirmar(portas[0].esta_perto() and portas[1].esta_perto(), "as duas ao alcance")
	afirmar(portas[0].e_a_vez() and not portas[1].e_a_vez(), "a dica aparece só na mais próxima")
	afirmar_igual(portas[0].descricao(), "Escolha 1 de 3 dádivas Kharn", "mostra o que dá")
	await _apertar_e(j)
	afirmar_igual(escolhidas, ["kharn"] as Array[String], "E pegou só a mais próxima")
	await _apertar_e(j)
	afirmar_igual(escolhidas.size(), 1, "não escolhe duas vezes")


func test_loja_e_reparo_com_e() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self, Vector2(100, -1))
	var loja := LojaIlo.new()
	loja.position = Vector2(100, 0)
	add_child(loja)
	j.creditos = 100
	j.vida.receber_dano(1, true)
	await esperar_frames(3)
	afirmar_igual(loja.vendidos, 0, "encostar não compra")
	await _apertar_e(j)
	afirmar_igual([loja.vendidos, j.creditos], [1, 60], "E comprou a Cura")
	j.global_position = Vector2(300, -1)
	var reparo := EstacaoReparo.criar_par(self, Vector2(300, 0), Vector2(360, 0))
	await esperar_frames(3)
	afirmar(not reparo[0].desligada, "encostar não usa o reparo")
	await _apertar_e(j)
	afirmar(reparo[0].desligada and reparo[1].desligada, "E usou o reparo e desligou o outro")


func test_clique_em_cima_pega() -> void:
	CenarioTeste.criar_chao(self)
	var portas := _portas([100], ["dados"])
	var j := CenarioTeste.criar_jogador(self, Vector2(100, -1))
	var escolhidas: Array[String] = []
	portas[0].escolhida.connect(func(porta: PortaSaida) -> void: escolhidas.append(porta.tipo))
	await esperar_frames(3)
	var tela: Vector2 = portas[0].get_global_transform_with_canvas() * Vector2(0, -20)
	var mover := InputEventMouseMotion.new()
	mover.position = tela
	tree.root.push_input(mover)
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	clique.position = tela
	portas[0]._unhandled_input(clique)
	await esperar_frames(2)
	afirmar_igual(escolhidas, ["dados"] as Array[String], "clique na porta, com o jogador perto, escolhe")
	afirmar(is_instance_valid(j), "jogador")
