extends TestCase
## D-068: abrir uma recompensa de várias opções não gasta a escolha; voltar mantém tudo na sala.


func _run() -> RunAto:
	Progresso.definir_flag("queda_completa_vista")
	var run: RunAto = instanciar("res://scenes/run/run_ato1.tscn")
	await esperar_frames(3)
	_fechar_falas()
	return run


func _fechar_falas() -> void:
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1


func _esperar_escolha(tela: TelaRecompensa) -> void:
	for i in 60:
		if tela.esta_escolhendo():
			return
		_fechar_falas()
		await esperar_frames(1)


func test_porta_de_oferta_voltar_mantem_as_portas_e_confirmar_segue() -> void:
	var run: RunAto = await _run()
	var sala: SalaRun = run.carregar_sala(1)
	await esperar_frames(2)
	_fechar_falas()
	tree.paused = false
	sala.plano["portas"] = ["kharn", "creditos"]
	sala._abrir_portas()
	await esperar_frames(2)
	var kharn: PortaSaida = sala.portas[0]
	kharn.interagir(run.jogador)
	await _esperar_escolha(run.tela_recompensa)
	afirmar(run.tela_recompensa.esta_escolhendo(), "a Oferta Kharn abriu")
	run.tela_recompensa.cancelar()
	await esperar_frames(2)
	afirmar_igual(run.numero_sala, 1, "continua na mesma sala")
	for p in sala.portas:
		afirmar(is_instance_valid(p) and not p.is_queued_for_deletion() and p.pode_interagir(), "porta %s continua valendo" % p.tipo)
	kharn.interagir(run.jogador)
	await _esperar_escolha(run.tela_recompensa)
	run.tela_recompensa.escolher(0)
	for i in 60:
		_fechar_falas()
		await esperar_frames(1)
		if run.numero_sala == 2:
			break
	afirmar_igual(run.numero_sala, 2, "confirmou: segue para a sala seguinte")
	afirmar_igual(run.jogador.upgrades.todos().size(), 1, "uma Oferta pega")
	tree.paused = false


func test_loja_so_cobra_se_escolher() -> void:
	var run: RunAto = await _run()
	var loja := LojaIlo.new()
	loja.item = &"dadiva_vesh"
	run.add_child(loja)
	run.jogador.creditos = 100
	loja.comprar(run.jogador)
	await _esperar_escolha(run.tela_recompensa)
	run.tela_recompensa.cancelar()
	await esperar_frames(2)
	afirmar_igual([run.jogador.creditos, loja.vendidos], [100, 0], "voltou: nada cobrado")
	loja.comprar(run.jogador)
	await _esperar_escolha(run.tela_recompensa)
	run.tela_recompensa.escolher(0)
	for i in 30:
		_fechar_falas()
		await esperar_frames(1)
	afirmar_igual([run.jogador.creditos, loja.vendidos], [20, 1], "escolheu: 80 Créditos")
	tree.paused = false


func test_reparo_oferta_extra_volta_sem_desligar() -> void:
	var run: RunAto = await _run()
	var par := EstacaoReparo.criar_par(run, Vector2(100, 0), Vector2(140, 0))
	await esperar_frames(1)
	par[1].usar(run.jogador)
	await _esperar_escolha(run.tela_recompensa)
	var faccao: StringName = run.tela_recompensa.catalogo.faccao
	run.tela_recompensa.cancelar()
	await esperar_frames(2)
	afirmar(not par[0].desligada and not par[1].desligada, "voltou: as duas estações continuam")
	par[1].usar(run.jogador)
	await _esperar_escolha(run.tela_recompensa)
	afirmar_igual(run.tela_recompensa.catalogo.faccao, faccao, "a mesma facção de antes")
	run.tela_recompensa.escolher(0)
	for i in 30:
		_fechar_falas()
		await esperar_frames(1)
	afirmar(par[0].desligada and par[1].desligada, "escolheu: o reparo foi usado")
	tree.paused = false
