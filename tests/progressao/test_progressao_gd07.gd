extends TestCase
## Progressão permanente (GD-07 §4, D-058): XP e nível, árvore de Combate (ordem, custos,
## no máximo 2 Ápices, redistribuição), efeitos dos nós e a integração na run e na nave.

const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"
const PASTA_INIMIGOS: String = "res://scenes/inimigos/"

var _salvo: Dictionary = {}


func _progresso(xp: int = 0) -> DadosProgresso:
	var p := DadosProgresso.new()
	p.caminho = "user://teste_progressao_gd07.cfg"
	p.contadores["xp_ryker"] = xp
	return p


## XP total para chegar ao nível `n`.
func _xp_do_nivel(prog: ProgressaoPersonagem, n: int) -> int:
	var total: int = 0
	for k in range(1, n):
		total += prog.xp_para_subir(k)
	return total


func _guardar() -> void:
	_salvo = {"flags": Progresso.flags.duplicate(), "contadores": Progresso.contadores.duplicate()}


func _restaurar() -> void:
	Progresso.flags = _salvo["flags"]
	Progresso.contadores = _salvo["contadores"]
	tree.paused = false


func _fechar_falas() -> void:
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1
	tree.paused = false


# --- XP e nível ---

func test_curva_de_xp_60_mais_20n_ate_o_nivel_25() -> void:
	var prog := ProgressaoPersonagem.new("ryker")
	afirmar_igual([prog.xp_para_subir(1), prog.xp_para_subir(9)], [80, 240], "1→2: 80; 9→10: 240")
	afirmar_igual([prog.nivel_de(0), prog.nivel_de(79), prog.nivel_de(80), prog.nivel_de(80 + 99), prog.nivel_de(80 + 100)],
			[1, 1, 2, 2, 3], "níveis pela curva")
	afirmar_igual(prog.nivel_de(_xp_do_nivel(prog, 10)), 10, "nível 10")
	afirmar_igual(prog.nivel_de(999999), 25, "nível máximo 25")
	var p := _progresso(_xp_do_nivel(prog, 25))
	afirmar_igual(prog.pontos_totais(p), 24, "24 pontos no máximo (1 por nível)")
	p.free()


func test_xp_e_nivel_ficam_depois_da_morte() -> void:
	var prog := ProgressaoPersonagem.new("ryker")
	var p := _progresso()
	afirmar_igual(prog.ganhar_xp(p, 100), 1, "subiu 1 nível")
	p.definir_run("xp_ganho", 100)
	p.limpar_run()  # morte: o estado da run zera
	p.salvar()
	p.carregar()
	afirmar_igual(prog.xp_total(p), 100, "XP salvo")
	afirmar_igual(prog.nivel(p), 2, "nível salvo")
	p.apagar()
	p.free()


func test_xp_por_inimigo() -> void:
	var prog := ProgressaoPersonagem.new("ryker")
	var esperado: Dictionary = {"zangao": 2, "cuspidor": 3, "guerreiro_cla": 6, "artilheiro_kharn": 6, "muralha": 8,
			"ninho": 10, "ceifadora": 30, "brutamontes": 30, "ur_kesh": 120}
	for nome: String in esperado:
		var inimigo: Inimigo = (load(PASTA_INIMIGOS + nome + ".tscn") as PackedScene).instantiate()
		afirmar_igual(prog.xp_do_inimigo(inimigo), esperado[nome], nome)
		inimigo.free()


# --- Árvore de Combate ---

func test_ordem_custos_e_pontos() -> void:
	var prog := ProgressaoPersonagem.new("ryker")
	var p := _progresso(_xp_do_nivel(prog, 4))  # 3 pontos
	afirmar_igual(prog.pontos_livres(p), 3, "3 pontos no nível 4")
	afirmar_igual(prog.estado(&"mordida_gatilho_de_mina", p), ProgressaoPersonagem.Estado.TRANCADO, "em ordem")
	afirmar(prog.comprar(&"mordida_rebite_afiado", p), "nó 1 (1)")
	afirmar(prog.comprar(&"mordida_gatilho_de_mina", p), "nó 2 (1)")
	afirmar_igual(prog.estado(&"mordida_perfurante", p), ProgressaoPersonagem.Estado.SEM_PONTOS, "nó 3 custa 2")
	afirmar(prog.comprar(&"granada_cinto", p), "último ponto em outro ramo")
	afirmar_igual(prog.pontos_livres(p), 0, "gastou tudo")
	var custos: Array[int] = []
	for no: Dictionary in prog.ramos[0]["nos"]:
		custos.append(int(no["custo"]))
	afirmar_igual(custos, [1, 1, 2, 2, 3] as Array[int], "custos 1, 1, 2, 2 e Ápice 3")
	p.free()


func test_no_maximo_2_apices_e_redistribuir_devolve_tudo() -> void:
	var prog := ProgressaoPersonagem.new("ryker")
	var p := _progresso(_xp_do_nivel(prog, 25))  # 24 pontos
	for ramo in ["mordida", "granada"]:
		for no: Dictionary in prog.ramos.filter(func(r: Dictionary) -> bool: return r["id"] == ramo)[0]["nos"]:
			afirmar(prog.comprar(StringName(no["id"]), p), "comprou %s" % no["id"])
	afirmar_igual(prog.apices(p), 2, "2 Ápices")
	for id: StringName in [&"grilhao_corrente_longa", &"grilhao_marca_funda", &"grilhao_duas_cargas", &"grilhao_arrastao"]:
		afirmar(prog.comprar(id, p), "comprou %s" % id)
	afirmar_igual(prog.pontos_livres(p), 0, "24 pontos usados")
	p.contadores["xp_ryker"] = 999999  # mesmo com pontos sobrando...
	afirmar_igual(prog.estado(&"grilhao_corrente_explosiva", p), ProgressaoPersonagem.Estado.LIMITE_APICES, "...o 3º Ápice não entra")
	prog.redistribuir(p)
	afirmar(prog.comprados(p).is_empty(), "nada comprado")
	afirmar_igual(prog.pontos_livres(p), prog.pontos_totais(p), "todos os pontos de volta")
	p.apagar()
	p.free()


func test_aplicar_na_run_so_o_ramo_da_arma_levada() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.equipar(load("res://scenes/armas/mordida.tres"))
	var prog := ProgressaoPersonagem.new("ryker")
	var p := _progresso(_xp_do_nivel(prog, 25))
	for id: StringName in [&"mordida_rebite_afiado", &"bramido_balins_pesados", &"grilhao_corrente_longa",
			&"granada_cinto", &"granada_pavio_curto", &"dash_passo_leve", &"dash_duplo"]:
		afirmar(prog.comprar(id, p), "comprou %s" % id)
	var granadas: int = j.granada.por_sala
	var raio: float = j.granada.raio
	var recarga: float = j.parametros.recarga_dash
	var cargas: int = j.parametros.cargas_dash
	prog.aplicar(j, p)
	afirmar_igual(j.arma_equipada.dano(), 12, "Rebite Afiado: 10 × 1,15 ≈ 12")
	afirmar(not j.arma_equipada.permanentes.has(&"bramido_balins_pesados"), "ramo do Bramido inativo com a Mordida")
	afirmar(j.tem_no(&"grilhao_corrente_longa"), "nó do Grilhão ativo")
	afirmar_igual([j.granada.por_sala, j.granadas], [granadas + 1, granadas + 1], "Cinto: +1 granada")
	afirmar_proximo(j.granada.raio, raio * 1.25, 0.001, "Pavio Curto: +25% de raio")
	afirmar_proximo(j.parametros.recarga_dash, recarga - 0.15, 0.001, "Passo Leve")
	afirmar_igual(j.parametros.cargas_dash, cargas + 1, "Dash Duplo")
	j.fim_da_run()
	afirmar(j.arma_equipada.permanentes.has(&"mordida_rebite_afiado"), "o nó continua depois do fim da run")
	p.apagar()
	p.free()


# --- Efeitos da Granada e do Dash ---

func test_estilhacos_e_bomba_de_fragmentacao() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.assign([&"granada_estilhacos", &"granada_bomba_de_fragmentacao"])
	await esperar_frames(2)
	var g: Granada = j.lancar_granada()
	afirmar(g != null, "lançou")
	g.explodir()
	await esperar_frames(2)
	var estilhacos: int = 0
	var menores: int = 0
	for filho in get_children():
		if filho is Projetil and (filho as Projetil).fragmento:
			estilhacos += 1
		if filho is Granada and filho.has_meta("menor"):
			menores += 1
	afirmar_igual(estilhacos, 4, "4 estilhaços")
	afirmar_igual(menores, 3, "3 granadas menores")


func test_recarga_de_campo_a_cada_3_mortes() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.append(&"granada_recarga_de_campo")
	await esperar_frames(1)
	j.granadas = 0
	for i in 3:
		j.efeitos_arvore.contar_morte()
	afirmar_igual(j.granadas, 1, "+1 granada a cada 3 mortes")
	j.granadas = j.granada.por_sala
	for i in 3:
		j.efeitos_arvore.contar_morte()
	afirmar_igual(j.granadas, j.granada.por_sala, "não passa do limite da sala")


func test_esquiva_de_arena_da_50_por_cento_no_proximo_tiro() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.append(&"dash_esquiva_de_arena")
	var tiros: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: tiros.append(p))
	await esperar_frames(3)
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	j.entrada.dash_pressionado = false
	afirmar(j.esta_em_dash(), "em dash")
	afirmar(not j.receber_ataque(InfoDano.criar(1)), "atravessou o golpe")
	j.entrada.atirar_segurado = true
	await esperar_frames(2)
	j.entrada.atirar_segurado = false
	afirmar(not tiros.is_empty(), "atirou")
	afirmar_proximo(tiros[0].info.multiplicador, 1.5, 0.001, "+50% no próximo tiro")


# --- Run e nave ---

func test_run_da_xp_por_inimigo_com_a_memoria_e_nucleos_com_a_coleta() -> void:
	_guardar()
	Progresso.contadores["melhoria_memoria_da_ancora"] = 1
	Progresso.contadores["melhoria_coleta_fina"] = 2
	var run: RunAto = instanciar(CENA_RUN)
	await esperar_frames(2)
	_fechar_falas()
	var xp0: int = run.progressao.xp_total(Progresso)
	var guerreiro: Inimigo = (load(PASTA_INIMIGOS + "guerreiro_cla.tscn") as PackedScene).instantiate()
	run._ao_inimigo_morrer(guerreiro, false)
	guerreiro.free()
	afirmar_igual(run.progressao.xp_total(Progresso) - xp0, 7, "6 XP + 10% = 7")
	afirmar_igual(Progresso.valor("xp_ganho"), 7, "a run conta o XP ganho")
	var n0: int = Progresso.valor("nucleos")
	afirmar_igual(run.ganhar_nucleos(50), 60, "Coleta Fina 2: +20%")
	afirmar_igual(Progresso.valor("nucleos") - n0, 60, "somou 60")
	_restaurar()


func test_nave_mostra_o_xp_da_run_e_abre_a_arvore_no_arsenal() -> void:
	_guardar()
	var nave: NaveEco = instanciar("res://scenes/nave/nave_eco.tscn")
	await esperar_frames(3)
	_fechar_falas()
	Ciclo.ultima_run = {"xp_ganho": 150, "nivel_inicial": 1}
	Progresso.contadores["xp_ryker"] = 150
	afirmar_igual(nave.texto_xp_da_run(), "\n+150 XP · Nível 2 — novos pontos no Arsenal!", "XP na reconstrução")
	nave.abrir_arvore_combate()
	afirmar(nave.tela_arvore.esta_aberta(), "a árvore abre no Arsenal")
	var b: Button = nave.tela_arvore.botao_do_no(&"mordida_rebite_afiado")
	afirmar(b != null, "botão do nó")
	b.pressed.emit()
	afirmar(nave.progressao.comprado(&"mordida_rebite_afiado", Progresso), "comprou pelo botão")
	nave.tela_arvore.redistribuir()
	afirmar(not nave.progressao.comprado(&"mordida_rebite_afiado", Progresso), "redistribuiu")
	nave.tela_arvore.fechar()
	afirmar(not tree.paused, "fechou")
	Ciclo.ultima_run = {}
	_restaurar()
