extends TestCase
## D-064 (caixa de diálogo) e D-065 (menus com mouse; Esc sempre volta ou fecha).


func _tecla_esc() -> InputEventAction:
	var e := InputEventAction.new()
	e.action = &"ui_cancel"
	e.pressed = true
	return e


func _mover(pos: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = pos
	return e


func _clique(pos: Vector2, botao: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.button_index = botao
	e.pressed = true
	return e


func _depois() -> void:
	tree.paused = false


# --- D-064 ---

func test_caixa_margem_de_cima_igual_aos_lados_e_sem_colchetes() -> void:
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	afirmar_igual(caixa.texto.position.y, caixa.texto.position.x, "margem de cima = margem dos lados")
	afirmar(caixa.texto.position.y >= 12.0, "o texto não encosta na borda de cima")
	var banco := BancoDialogos.new()
	banco.falantes = {"ECO": {"nome": "ECO"}}
	var falas: Array[Dictionary] = [{"id": "X", "falante": "ECO", "texto": "Olá.", "direcao": "chiado, voz humana falhando"}]
	caixa.mostrar("x", falas, "conversa", banco)
	afirmar(not caixa.direcao.is_visible_in_tree() or caixa.direcao.text.is_empty(), "sem texto entre colchetes na tela")
	afirmar(not caixa.texto.text.contains("["), "a fala não traz colchetes")
	afirmar_igual(caixa.fala_atual()["direcao"], "chiado, voz humana falhando", "a nota continua nos dados (AUD)")
	caixa.avancar()
	_depois()
	caixa.queue_free()


# --- D-065: listas da nave ---

func _lista(n: int) -> TelaLista:
	var t := TelaLista.new()
	add_child(t)
	var usados: Array[int] = []
	t.set_meta("usados", usados)
	t.abrir("Teste", "eco", func() -> Array[Dictionary]:
		var o: Array[Dictionary] = []
		for i in n:
			o.append({"nome": "Opção %d" % i, "pode": true, "acao": func() -> bool:
				usados.append(i)
				return true})
		return o)
	return t


func test_lista_da_nave_com_mouse_e_esc() -> void:
	var t := _lista(9)
	await esperar_frames(15)  # passa a trava de abertura
	var r: Rect2 = t.retangulo_da_linha(2)
	t._input(_mover(r.get_center()))
	afirmar_igual(t.selecionada, 2, "passar o mouse destaca")
	t._input(_clique(r.get_center()))
	afirmar_igual(t.get_meta("usados"), [2] as Array[int], "clique confirma a linha sob o cursor")
	afirmar(t.retangulo_da_linha(8).size == Vector2.ZERO, "a 9ª opção fica fora da tela")
	for k in 3:
		t._input(_clique(Vector2.ZERO, MOUSE_BUTTON_WHEEL_DOWN))
	afirmar_igual(t.primeira, 3, "a roda rola a lista")
	afirmar(t.retangulo_da_linha(8).size != Vector2.ZERO, "agora a 9ª aparece")
	t._input(_tecla_esc())
	afirmar(not t.esta_aberta(), "Esc fecha")
	afirmar(not tree.paused, "despausou")
	t.queue_free()


# --- D-065: pausa, título, árvore ---

func test_pausa_esc_volta_um_nivel() -> void:
	var pausa: Node = tree.root.get_node("Pausa")
	var j := Node.new()
	j.add_to_group("jogadores")
	add_child(j)
	afirmar(pausa.abrir(), "abriu")
	pausa.ativar("Opções")
	afirmar_igual(pausa.tela, pausa.Tela.OPCOES, "nas Opções")
	pausa._unhandled_input(_tecla_esc())
	afirmar_igual(pausa.tela, pausa.Tela.PRINCIPAL, "Esc volta para a pausa")
	pausa.ativar("Controles")
	pausa._unhandled_input(_tecla_esc())
	afirmar_igual(pausa.tela, pausa.Tela.PRINCIPAL, "Esc volta dos Controles")
	pausa._unhandled_input(_tecla_esc())
	afirmar(not pausa.esta_aberto(), "Esc na pausa volta ao jogo")
	afirmar(not tree.paused, "jogo continua")
	j.queue_free()


func test_arvore_de_combate_fecha_com_esc() -> void:
	var tela := TelaArvoreCombate.new()
	add_child(tela)
	var p := DadosProgresso.new()
	tela.abrir(ProgressaoPersonagem.new("ryker"), p, "mordida")
	await esperar_frames(1)
	afirmar(tela.esta_aberta(), "aberta")
	tela._unhandled_input(_tecla_esc())
	afirmar(not tela.esta_aberta(), "Esc fecha")
	_depois()
	tela.queue_free()
	p.free()


# --- D-065: escolhas obrigatórias ---

func test_gambiarra_esc_nao_fecha_nem_abre_a_pausa() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var tela := TelaGambiarras.new()
	add_child(tela)
	var banco := BancoGambiarras.new()
	var rng := RandomNumberGenerator.new()
	tela.abrir(j, banco.sortear(j.arma_equipada, rng, false, false))
	await esperar_frames(1)
	tela._input(_tecla_esc())
	afirmar(tela.esta_aberta(), "Esc não fecha sem escolher")
	afirmar(not tree.root.get_node("Pausa").esta_aberto(), "e não abre a pausa")
	tela.escolher(0)
	afirmar(not tela.esta_aberta(), "escolheu e fechou")
	_depois()
	tela.queue_free()


func test_dadiva_com_mouse_e_esc_sem_efeito() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.rerolls = 1
	var tela := TelaRecompensa.new()
	add_child(tela)
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	tela.abrir(j, load("res://scenes/upgrades/vesh.tres"))
	for i in 40:
		if tela.esta_escolhendo():
			break
		if caixa.esta_ativa():
			caixa.avancar()
		await esperar_frames(1)
	afirmar(tela.esta_escolhendo(), "as 3 opções na tela")
	await esperar_frames(15)
	tela._input(_tecla_esc())
	afirmar(tela.esta_escolhendo(), "Esc não fecha a escolha")
	var centro := Rect2(TelaRecompensa.CARTA_X, TelaRecompensa.CARTA_Y + 2 * TelaRecompensa.CARTA_PASSO,
			TelaRecompensa.CARTA_LARGURA, TelaRecompensa.CARTA_ALTURA).get_center()
	tela._input(_mover(centro))
	afirmar_igual(tela.selecionada, 2, "passar o mouse destaca a 3ª")
	tela._input(_clique(TelaRecompensa.RECALIBRAR.get_center()))
	afirmar_igual(j.rerolls, 0, "Recalibrar é clicável")
	tela._input(_clique(centro))
	afirmar(not tela.esta_escolhendo(), "clique pegou a dádiva")
	for i in 40:
		if not tela.esta_aberta():
			break
		if caixa.esta_ativa():
			caixa.avancar()
		await esperar_frames(1)
	_depois()
	tela.queue_free()
	caixa.queue_free()


func test_tela_de_gambiarra_cala_a_faixa_de_fala() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	var banco := BancoDialogos.new()
	banco.falantes = {"RYKER": {"nome": "Ryker"}}
	var falas: Array[Dictionary] = [{"id": "R", "falante": "RYKER", "texto": "Varrek."}]
	caixa.mostrar("r", falas, "rapida", banco)
	afirmar(caixa.rapida.visible, "faixa no topo")
	var tela := TelaGambiarras.new()
	add_child(tela)
	tela.abrir(j, BancoGambiarras.new().sortear(j.arma_equipada, RandomNumberGenerator.new(), false, false))
	afirmar(not caixa.rapida.visible, "a faixa some quando a tela de Gambiarra abre")
	tela.escolher(0)
	_depois()
	tela.queue_free()
	caixa.queue_free()
