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


## O Ryker anda para baixo com S e seta para baixo, e para cima com W (ações próprias da arena,
## que não dependem do "Agachar" trocável do jogo antigo).
func test_wasd_e_setas_movem_nas_4_direcoes() -> void:
	var a := _arena()
	a.jogador.ler_entrada = true
	await esperar_frames(1)
	var casos: Dictionary = {KEY_S: Vector2.DOWN, KEY_DOWN: Vector2.DOWN, KEY_W: Vector2.UP, KEY_D: Vector2.RIGHT, KEY_A: Vector2.LEFT}
	for tecla: Key in casos:
		var antes: Vector2 = a.jogador.position
		var e := InputEventKey.new()
		e.physical_keycode = tecla
		e.pressed = true
		Input.parse_input_event(e)
		await esperar_frames(10)
		e.pressed = false
		Input.parse_input_event(e)
		await esperar_frames(2)
		var passo: Vector2 = (a.jogador.position - antes).normalized()
		afirmar(passo.dot(casos[tecla]) > 0.9, "%s move para %s" % [OS.get_keycode_string(tecla), casos[tecla]])
	await _limpar(a)


## DEV 34: destroços longe do centro e uns dos outros; o Ryker não entra neles.
func test_destrocos_sorteados_e_solidos() -> void:
	var a := _arena()
	await esperar_frames(1)
	var o: ObstaculosArena = a.obstaculos
	afirmar_igual(o.pontos.size(), 4, "4 destroços")
	var centro: Vector2 = a.diretor.area_util().get_center()
	for i in o.pontos.size():
		afirmar(o.pontos[i].distance_to(centro) >= 128.0, "centro livre")
		for k in range(i + 1, o.pontos.size()):
			afirmar(o.pontos[i].distance_to(o.pontos[k]) >= 80.0, "separados")
	afirmar(a.mundo.get_node_or_null("Destroco1") is Sprite2D, "desenhados")
	var caixa: Rect2 = o.caixas[0]
	afirmar(o.bloqueia(caixa.get_center(), 6.0), "o meio da caixa bloqueia")
	var fora: Vector2 = o.resolver(caixa.get_center(), 6.0)
	afirmar(not caixa.grow(5.9).has_point(fora), "resolver empurra para fora")
	a.jogador.position = caixa.get_center() + Vector2(0, -30)
	a.jogador.direcao = Vector2.DOWN
	await esperar_frames(30)
	afirmar(not caixa.grow(5.9).has_point(a.jogador.position), "o Ryker para na borda")
	for i in 40:
		a.anunciar_inimigo("roedor")
	for m in a.marcas:
		afirmar(not o.bloqueia(m["pos"], 7.9), "inimigo não nasce dentro de destroço")
	await _limpar(a)


func test_ryker_e_inimigos_usam_os_sprites_de_lado() -> void:
	var a := _arena()
	await esperar_frames(1)
	afirmar(a.mundo.y_sort_enabled, "y_sort no mundo")
	var r := a.criar_inimigo("roedor", a.jogador.position + Vector2(-150, 0))
	await esperar_frames(3)
	afirmar(r.sprite != null and r.sprite.texture != null, "Roedor com sprite")
	afirmar(not r.sprite.flip_h, "indo para a direita não espelha")
	a.jogador.direcao = Vector2.LEFT
	await esperar_frames(3)
	var espelhados: int = 0
	for f in a.jogador.get_children():
		if f is Sprite2D and (f as Sprite2D).flip_h:
			espelhados += 1
	afirmar(espelhados >= 2, "Ryker vira para a esquerda")
	await _limpar(a)


## DEV 35: a Sucata vira experiência; (n + 3)² por nível; +1 de vida por nível.
func test_sucata_da_experiencia_e_nivel() -> void:
	var a := _arena()
	await esperar_frames(1)
	var j := a.jogador
	afirmar_igual(j.xp_para_proximo(), 16, "nível 1 → 2: 16")
	a.coletar_sucata(15)
	afirmar_igual(j.nivel, 1, "15 ainda não sobe")
	a.coletar_sucata(1)
	afirmar_igual(j.nivel, 2, "16 sobe")
	afirmar_igual(j.vida_max, 11, "+1 de vida máx.")
	afirmar_igual(j.niveis_pendentes, 1, "1 escolha pendente")
	afirmar_igual(a.sucata, 16, "a Sucata também é dinheiro")
	a.coletar_sucata(25 + 36)
	afirmar_igual(j.nivel, 4, "subiu mais 2")
	afirmar_igual(j.niveis_pendentes, 3, "3 escolhas")
	await _limpar(a)


func test_tela_de_nivel_no_fim_da_onda_e_depois_a_loja() -> void:
	var a := _arena()
	await esperar_frames(1)
	a.comecar_onda(0)
	a.coletar_sucata(16 + 25)
	afirmar_igual(a.jogador.niveis_pendentes, 2, "2 níveis")
	a.terminar_onda()
	for i in 120:
		await esperar_frames(1)
		if a.estado != ArenaJogo.Estado.INTERVALO:
			break
	afirmar_igual(a.estado, ArenaJogo.Estado.NIVEL, "abre a tela de nível")
	afirmar_igual(a.tela_nivel.cartas.size(), 4, "4 cartas")
	var ids: Array = a.tela_nivel.cartas.map(func(c: Dictionary) -> String: return c["id"])
	afirmar_igual(ids.size(), ids.filter(func(x: String) -> bool: return ids.count(x) == 1).size(), "4 atributos diferentes")
	afirmar_igual(a.tela_nivel.custo_reroll(), 2, "trocar custa 2")
	afirmar(a.tela_nivel.rerolar(), "trocou")
	afirmar_igual(a.tela_nivel.custo_reroll(), 4, "+2 a cada vez")
	var c: Dictionary = a.tela_nivel.cartas[0]
	var antes: float = a.jogador.atributos.valor(c["id"])
	a.tela_nivel.escolher(0)
	afirmar_proximo(a.jogador.atributos.valor(c["id"]), antes + float(c["valor"]), 0.001, "somou o atributo")
	afirmar_igual(a.estado, ArenaJogo.Estado.NIVEL, "ainda falta 1")
	a.tela_nivel.escolher(1)
	afirmar_igual(a.estado, ArenaJogo.Estado.LOJA, "depois, a loja")
	afirmar_igual(a.jogador.niveis_pendentes, 0, "nada pendente")
	await _limpar(a)


func test_atributos_mudam_dano_recarga_alcance_e_dano_recebido() -> void:
	var at := AtributosArena.new()
	afirmar_igual(at.dano(6, "distancia", false), 6, "sem bônus")
	at.somar("dano_distancia", 2)
	at.somar("dano_pct", 50)
	afirmar_igual(at.dano(6, "distancia", false), 12, "(6 + 2) × 1,5")
	afirmar_igual(at.dano(6, "distancia", true), 24, "crítico dobra")
	afirmar_igual(at.dano(12, "corpo", false), 18, "o bônus à distância não vale no corpo a corpo")
	at.somar("cadencia_pct", 20)
	afirmar_proximo(at.recarga(1.0), 0.8, 0.001, "20% menos recarga")
	at.somar("alcance", 20)
	afirmar_proximo(at.alcance(200.0, "distancia"), 220.0, 0.001, "alcance +20")
	afirmar_proximo(at.alcance(64.0, "corpo"), 74.0, 0.001, "corpo a corpo ganha metade")
	at.somar("armadura", 3)
	afirmar_proximo(at.fator_armadura(), 0.79, 0.001, "3 de armadura: ×0,79 (GD-09 teste 12)")
	at.somar("armadura", 20)
	afirmar_proximo(at.fator_armadura(), 0.40, 0.001, "nunca abaixo de ×0,40")
	at.somar("regeneracao", 2)
	afirmar_proximo(at.intervalo_regeneracao(), 2.5, 0.001, "cura 1 a cada 5/2 s")


func test_ryker_usa_armadura_velocidade_e_vida_dos_atributos() -> void:
	var a := _arena()
	await esperar_frames(1)
	var j := a.jogador
	j.aplicar_efeitos({"vida_max": 6, "armadura": 5, "velocidade_pct": 10})
	afirmar_igual(j.vida_max, 16, "vida máx. +6")
	afirmar_igual(j.vida, 16, "e cura o que ganhou")
	afirmar_proximo(j.velocidade_atual(), 121.0, 0.01, "110 × 1,1")
	j.levar_dano(4)
	afirmar_igual(j.vida, 13, "4 × 0,65 = 2,6 → 3")
	await _limpar(a)


func test_loja_tem_itens_cadeado_e_item_soma_atributos() -> void:
	var a := _arena()
	await esperar_frames(1)
	afirmar_igual(LojaArena.preco_item(1, 1), 12, "item comum na onda 1")
	afirmar_igual(LojaArena.preco_item(2, 3), 36, "item raro na onda 3: 30 × 1,2")
	a.estado = ArenaJogo.Estado.LOJA
	a.loja.rng.seed = 3
	var tipos: Dictionary = {}
	for i in 30:
		a.loja.abrir(1)
		for o in a.loja.ofertas:
			tipos[o["tipo"]] = true
	afirmar(tipos.has("arma") and tipos.has("item"), "vende armas e itens")
	a.loja.abrir(1)
	var travada: Dictionary = a.loja.ofertas[2]
	a.loja.travar(2)
	a.loja.abrir(2)
	afirmar_igual(a.loja.ofertas[2]["id"], travada["id"], "a oferta travada continua na loja seguinte")
	afirmar(a.loja.ofertas[2]["travada"], "continua travada")
	a.loja.ofertas[0] = {"tipo": "item", "id": "botas_de_mineiro", "nivel": 1, "preco": 12, "vendida": false, "travada": false}
	a.sucata = 12
	afirmar(a.loja.comprar(0), "comprou o item")
	afirmar_proximo(a.jogador.atributos.valor("velocidade_pct"), 5.0, 0.001, "Botas: +5% de velocidade")
	afirmar_igual(a.jogador.inventario.armas.size(), 1, "item não ocupa slot de arma")
	await _limpar(a)


# --- DEV 36: as outras 6 armas e o bônus de família (GD-09 §5) ---

func _so_com(a: ArenaJogo, id: String) -> ArmaArena:
	a.jogador.inventario.armas.clear()
	a.jogador.adicionar_arma(id, 1)
	return a.jogador.armas()[0]


func _parado(a: ArenaJogo, tipo: String, deslocamento: Vector2, vida: int = 100) -> InimigoArena:
	var i := a.criar_inimigo(tipo, a.jogador.position + deslocamento)
	i.velocidade = 0.0
	i.vida = vida
	return i


func test_as_8_armas_existem_com_familia() -> void:
	var armas: Dictionary = ConfigArena.secao("armas")
	afirmar_igual(armas.size(), 8, "8 armas do VS")
	for id in armas:
		afirmar(ConfigArena.secao("familias").has(armas[id]["familia"]), "%s com família válida" % id)
		var arma := ArmaArena.new()
		arma.configurar(id, 1)
		afirmar(arma.dano > 0 and arma.recarga > 0.0 and arma.alcance > 0.0, "%s com números" % id)
		arma.free()


func test_bramido_solta_5_balins_e_empurra_uma_vez() -> void:
	var a := _arena()
	await esperar_frames(1)
	_so_com(a, "bramido")
	var alvo := _parado(a, "roedor", Vector2(40, 0))
	var p0: Vector2 = alvo.position
	await esperar_frames(2)
	var balins: int = a.mundo.get_children().filter(func(n: Node) -> bool: return n is ProjetilArena).size()
	afirmar_igual(balins, 5, "5 balins")
	await esperar_frames(10)
	afirmar(alvo.vida < 100, "acertou")
	afirmar_proximo((alvo.position - p0).length(), 16.0, 0.5, "empurrou 16 px uma vez só (não 16 por balim)")
	await _limpar(a)


func test_granada_explode_em_area() -> void:
	var a := _arena()
	await esperar_frames(1)
	_so_com(a, "granada")
	var i1 := _parado(a, "roedor", Vector2(100, 0))
	var i2 := _parado(a, "roedor", Vector2(110, 15))
	var longe := _parado(a, "roedor", Vector2(100, 120))
	for k in 60:
		await esperar_frames(1)
		if i1.vida < 100:
			break
	afirmar_igual(i1.vida, 85, "15 de dano no alvo")
	afirmar_igual(i2.vida, 85, "e no vizinho dentro do raio")
	afirmar_igual(longe.vida, 100, "fora do raio não leva")
	await _limpar(a)


func test_ferrao_aplica_acido_que_fere_com_o_tempo() -> void:
	var a := _arena()
	await esperar_frames(1)
	var arma := _so_com(a, "ferrao")
	arma.dados = arma.dados.duplicate()
	arma.dados["chance_acido"] = 100.0
	var alvo := _parado(a, "roedor", Vector2(60, 0))
	for k in 30:
		await esperar_frames(1)
		if alvo.acido > 0:
			break
	afirmar(alvo.acido >= 1, "pegou Ácido")
	var vida: int = alvo.vida
	a.jogador.inventario.armas.clear()
	a.jogador.adicionar_arma("mordida", 1)
	for arma_m in a.jogador.armas():
		arma_m.alcance = 1.0  # para de atirar: só o Ácido fere
	await esperar_frames(40)
	afirmar(alvo.vida < vida, "o Ácido continua ferindo")
	await _limpar(a)


func test_ninhada_solta_larvas_que_perseguem() -> void:
	var a := _arena()
	await esperar_frames(1)
	_so_com(a, "ninhada")
	var alvo := _parado(a, "roedor", Vector2(120, 0))
	await esperar_frames(2)
	var larvas: int = a.mundo.get_children().filter(func(n: Node) -> bool: return n is LarvaArena).size()
	afirmar_igual(larvas, 2, "2 larvas")
	for k in 90:
		await esperar_frames(1)
		if alvo.vida <= 90:
			break
	afirmar_igual(alvo.vida, 90, "as 2 larvas morderam (5 + 5)")
	await _limpar(a)


func test_liquidacao_ricocheteia() -> void:
	var a := _arena()
	await esperar_frames(1)
	_so_com(a, "liquidacao")
	var i1 := _parado(a, "roedor", Vector2(80, 0))
	var i2 := _parado(a, "roedor", Vector2(80, 60))
	for k in 20:
		await esperar_frames(1)
		if i2.vida < 100:
			break
	afirmar(i1.vida < 100, "acertou o primeiro")
	afirmar(i2.vida < 100, "ricocheteou no segundo")
	await _limpar(a)


func test_lanterna_gira_e_fere_quem_toca() -> void:
	var a := _arena()
	await esperar_frames(1)
	var arma := _so_com(a, "lanterna")
	afirmar_igual(arma.quantidade_de_esferas(), 2, "2 esferas")
	var alvo := _parado(a, "roedor", Vector2(40, -10))
	await esperar_frames(60)
	afirmar(alvo.vida < 100, "a esfera feriu ao passar")
	afirmar(alvo.vida >= 100 - 6 * 2 * 2 - 6, "no máximo 2 toques por segundo por esfera")
	await _limpar(a)


func test_bonus_de_familia_conta_armas_diferentes() -> void:
	afirmar(AtributosArena.bonus_de_familias(["mordida"]).is_empty(), "1 arma: sem bônus")
	afirmar(AtributosArena.bonus_de_familias(["mordida", "mordida"]).is_empty(), "2 Mordidas contam como 1")
	afirmar_igual(AtributosArena.bonus_de_familias(["mordida", "grilhao"]), {"cadencia_pct": 5.0}, "Arena 2: +5% de cadência")
	afirmar_igual(AtributosArena.bonus_de_familias(["ferrao", "ninhada", "mordida"]), {"acido_chance_pct": 10.0}, "Vesh 2: +10% de Ácido")
	var a := _arena()
	await esperar_frames(1)
	a.jogador.adicionar_arma("grilhao", 1)
	afirmar_proximo(a.jogador.atributos.valor("cadencia_pct"), 5.0, 0.001, "o Ryker recebe o bônus ao ter as 2")
	afirmar_proximo(a.jogador.armas()[0].recarga_atual(), 0.38, 0.001, "Mordida 0,4 s × 0,95")
	await _limpar(a)
