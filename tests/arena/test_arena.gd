extends TestCase
## DEV 33: protótipo da arena (GD-09, D-077/D-078).

const CENA: String = "res://scenes/arena/arena.tscn"


func _arena() -> ArenaJogo:
	var a: ArenaJogo = (load(CENA) as PackedScene).instantiate()
	a.comecar_sozinha = false
	add_child(a)
	a.jogador.ler_entrada = false
	return a


func _limpar(a: Node) -> void:
	tree.paused = false
	if is_instance_valid(a):
		a.queue_free()
	await esperar_frames(2)


func test_inventario_tem_6_slots_e_funde_armas_iguais() -> void:
	var inv := InventarioArmas.new(6)
	for i in 6:
		afirmar(inv.adicionar("mordida" if i < 5 else "grilhao", 1), "slot %d" % (i + 1))
	afirmar(not inv.pode_receber("grilhao", 2), "7ª arma sem par não entra")
	afirmar(not inv.adicionar("grilhao", 2), "não adiciona")
	afirmar(inv.adicionar("grilhao", 1), "igual e do mesmo nível funde")
	afirmar_igual(inv.armas.size(), 6, "continua com 6")
	afirmar_igual(inv.armas[5]["nivel"], 2, "vira nível II")


func test_nivel_da_arma_muda_dano_e_recarga() -> void:
	var a := ArmaArena.new()
	a.configurar("mordida", 2)
	afirmar_igual(a.dano, 9, "6 × 1,5")
	afirmar_proximo(a.recarga, 0.36, 0.001, "0,4 × 0,9")
	a.free()


func test_ondas_duracao_taxa_e_pico() -> void:
	var d := DiretorOndas.new()
	afirmar_igual(d.total_de_ondas(), 3, "protótipo com 3 ondas")
	afirmar_igual([d.duracao(0), d.duracao(1), d.duracao(2)], [30.0, 40.0, 50.0], "30/40/50 s")
	afirmar_proximo(d.taxa(0, 0.0), 0.8, 0.001, "começo da onda 1")
	afirmar_proximo(d.taxa(0, 30.0), 1.2, 0.001, "fim da onda 1")
	afirmar_proximo(d.taxa(2, 39.0), 1.2 + 0.6 * 39.0 / 50.0, 0.001, "onda 3 antes do pico")
	afirmar_proximo(d.taxa(2, 45.0), (1.2 + 0.6 * 0.9) * 2.0, 0.001, "pico dobra nos últimos 10 s")


func test_inimigo_nasce_longe_do_ryker_e_dentro_da_arena() -> void:
	var d := DiretorOndas.new()
	d.rng.seed = 7
	var area: Rect2 = d.area_util()
	var ryker := area.get_center()
	for i in 300:
		var p: Vector2 = d.ponto_de_nascimento(ryker)
		afirmar(p.distance_to(ryker) >= 96.0, "≥ 6 tiles do Ryker")
		afirmar(area.grow(0.01).has_point(p), "dentro da arena")


func test_forca_dos_inimigos_sobe_com_a_onda() -> void:
	var f: Dictionary = ConfigArena.forca(3)
	afirmar_proximo(f["vida"], 1.3, 0.001, "vida +15% por onda")
	afirmar_proximo(f["dano"], 1.12, 0.001, "dano +6% por onda")


func test_marca_antes_de_nascer_e_teto_de_40() -> void:
	var a := _arena()
	await esperar_frames(1)
	a.comecar_onda(0)
	afirmar(a.anunciar_inimigo("roedor"), "anuncia")
	afirmar_igual(a.inimigos_vivos(), 0, "ainda não nasceu")
	for i in 60:
		await esperar_frames(1)
		if a.inimigos_vivos() > 0:
			break
	afirmar(a.inimigos_vivos() >= 1, "nasce depois do aviso")
	for i in 80:
		a.anunciar_inimigo("roedor")
	afirmar(a.inimigos_vivos() + a.marcas.size() <= 40, "teto de 40")
	await _limpar(a)


func test_arma_atira_so_com_inimigo_no_alcance() -> void:
	var a := _arena()
	await esperar_frames(2)
	var arma: ArmaArena = a.jogador.armas()[0]
	afirmar_igual(arma.id, "mordida", "começa com a Mordida")
	afirmar(arma.alvo_mais_perto() == null, "sem inimigo, sem alvo")
	var longe := a.criar_inimigo("roedor", a.jogador.position + Vector2(300, 0))
	longe.velocidade = 0.0
	afirmar(arma.alvo_mais_perto() == null, "fora do alcance não conta")
	var perto := a.criar_inimigo("roedor", a.jogador.position + Vector2(100, 0))
	perto.velocidade = 0.0
	perto.vida = 100
	var mais_perto := a.criar_inimigo("zangao", a.jogador.position + Vector2(-60, 0))
	mais_perto.velocidade = 0.0
	afirmar(arma.alvo_mais_perto() == mais_perto, "mira no mais perto")
	var vida_antes: int = perto.vida
	for i in 40:
		await esperar_frames(1)
		if not is_instance_valid(mais_perto):
			break
	afirmar(not is_instance_valid(mais_perto), "a Mordida matou o mais perto")
	afirmar(is_instance_valid(perto) and perto.vida <= vida_antes, "o outro continua")
	await _limpar(a)


func test_grilhao_golpeia_e_puxa() -> void:
	var a := _arena()
	await esperar_frames(1)
	a.jogador.inventario.armas.clear()
	a.jogador.adicionar_arma("grilhao", 1)
	var inimigo := a.criar_inimigo("roedor", a.jogador.position + Vector2(50, 0))
	inimigo.velocidade = 0.0
	inimigo.vida = 100
	await esperar_frames(3)
	afirmar_igual(inimigo.vida, 88, "12 de dano")
	afirmar(inimigo.position.x - a.jogador.position.x < 50.0, "puxado para perto")
	await _limpar(a)


func test_contato_fere_o_ryker_com_invencibilidade() -> void:
	var a := _arena()
	await esperar_frames(1)
	var j := a.jogador
	afirmar(j.levar_dano(2), "levou dano")
	afirmar_igual(j.vida, 8, "10 − 2")
	afirmar(not j.levar_dano(2), "invencível por 0,5 s")
	j.dar_dash()
	afirmar(j.esta_em_dash(), "dash")
	await _limpar(a)


func test_fim_da_onda_limpa_e_puxa_a_sucata() -> void:
	var a := _arena()
	await esperar_frames(1)
	a.comecar_onda(0)
	var inimigo := a.criar_inimigo("roedor", a.jogador.position + Vector2(200, 100))
	inimigo.velocidade = 0.0
	inimigo.levar_dano(999)
	await esperar_frames(2)
	afirmar_igual(get_tree_sucata(), 1, "soltou 1 Sucata longe do ímã")
	a.criar_inimigo("roedor", a.jogador.position + Vector2(-280, 0)).velocidade = 0.0
	a.anunciar_inimigo("zangao")
	a.tempo_onda = 29.99
	await esperar_frames(2)
	afirmar_igual(a.estado, ArenaJogo.Estado.INTERVALO, "acabou a onda 1 aos 30 s")
	afirmar_igual(a.inimigos_vivos(), 0, "inimigos somem")
	afirmar(a.marcas.is_empty(), "marcas somem")
	for i in 120:
		await esperar_frames(1)
		if a.estado == ArenaJogo.Estado.LOJA:
			break
	afirmar_igual(a.sucata, 1, "a Sucata voou até o Ryker")
	afirmar_igual(a.estado, ArenaJogo.Estado.LOJA, "abre a loja")
	afirmar(a.loja.visible, "loja na tela")
	await _limpar(a)


func get_tree_sucata() -> int:
	return tree.get_nodes_in_group(SucataArena.GRUPO).size()


func test_loja_precos_reroll_e_compra() -> void:
	var a := _arena()
	await esperar_frames(1)
	afirmar_igual(LojaArena.preco(1, 1), 15, "arma I na onda 1")
	afirmar_igual(LojaArena.preco(2, 3), 42, "arma II na onda 3: 35 × 1,2")
	afirmar_igual(LojaArena.chances(1)[3], 0.0, "sem Lendária antes da onda 8")
	a.estado = ArenaJogo.Estado.LOJA
	a.loja.abrir(2)
	afirmar_igual(a.loja.ofertas.size(), 4, "4 ofertas")
	afirmar_igual(a.loja.custo_reroll(), 3, "1 + onda")
	a.sucata = 10
	afirmar(a.loja.rerolar(), "rerolou")
	afirmar_igual(a.sucata, 7, "gastou 3")
	afirmar_igual(a.loja.custo_reroll(), 4, "+1 por reroll")
	a.loja.ofertas[0] = {"id": "grilhao", "nivel": 1, "preco": 16, "vendida": false}
	afirmar(not a.loja.comprar(0), "sem Sucata, não compra")
	a.sucata = 20
	afirmar(a.loja.comprar(0), "comprou")
	afirmar_igual(a.sucata, 4, "pagou 16")
	afirmar_igual(a.jogador.armas().size(), 2, "Mordida + Grilhão")
	afirmar(not a.loja.comprar(0), "não vende duas vezes")
	a.loja.fechar()
	afirmar_igual(a.estado, ArenaJogo.Estado.ONDA, "Pronto começa a próxima onda")
	afirmar_igual(a.numero_da_onda(), 2, "onda 2")
	await _limpar(a)


func test_morrer_ou_vencer_mostra_o_fim() -> void:
	var a := _arena()
	await esperar_frames(1)
	a.comecar_onda(0)
	a.jogador.vida = 1
	a.jogador.levar_dano(1)
	afirmar_igual(a.estado, ArenaJogo.Estado.FIM, "morreu: fim")
	afirmar(not a.venceu, "não venceu")
	await _limpar(a)
	var b := _arena()
	await esperar_frames(1)
	b.comecar_onda(2)
	b.terminar_onda()
	for i in 120:
		await esperar_frames(1)
		if b.estado == ArenaJogo.Estado.FIM:
			break
	afirmar(b.venceu, "depois da 3ª onda, vitória")
	await _limpar(b)


func test_menu_inicial_abre_a_arena() -> void:
	Ciclo.ultima_cena_pedida = ""
	Ciclo.ir_para_arena()
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_ARENA, "pede a cena da arena")
	Ciclo.ultima_cena_pedida = ""
