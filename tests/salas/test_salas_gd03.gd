extends TestCase
## Salas e portas do Ato 1 (GD-03). Os testes 1 a 6 são os requisitos da seção 4 do GD-03.

const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"


func _progresso(flags: Array = []) -> DadosProgresso:
	var p := DadosProgresso.new()
	p.caminho = "user://teste_progresso_salas.cfg"
	for f: String in flags:
		p.definir_flag(f)
	return p


## Planeja uma run inteira (salas 0 a 8).
func _planejar_run(gerador: GeradorAto) -> Array[Dictionary]:
	var planos: Array[Dictionary] = []
	for n in gerador.quantidade_de_salas():
		planos.append(gerador.planejar_sala(n))
	return planos


func _montar(plano: Dictionary, banco: BancoBlocos) -> SalaRun:
	var sala := MontadorSala.montar(plano, banco)
	add_child(sala)
	return sala


# --- 4. Blocos válidos (regras de encaixe) ---

func test_4_todo_bloco_tem_chao_na_linha_14_nas_bordas() -> void:
	var banco := BancoBlocos.new()
	afirmar_igual(banco.carregar(), OK, "blocos carregaram")
	afirmar(banco.blocos.size() >= 30, "banco do VS (%d blocos)" % banco.blocos.size())
	for id: String in banco.blocos:
		var erros := BancoBlocos.validar(banco.bloco(id))
		afirmar(erros.is_empty(), "; ".join(erros))


func test_4_validador_pega_bloco_errado() -> void:
	var linhas: Array = []
	for y in 17:
		linhas.append(".".repeat(15) if y < 14 else "#".repeat(15))
	var bom := {"id": "bom", "tipo": "trecho", "linhas": linhas}
	afirmar(BancoBlocos.validar(bom).is_empty(), "bloco simples é válido")
	var sem_borda: Array = linhas.duplicate()
	sem_borda[14] = "." + "#".repeat(14)
	afirmar(not BancoBlocos.validar({"id": "x", "tipo": "trecho", "linhas": sem_borda}).is_empty(), "sem chão na borda")
	var buraco: Array = linhas.duplicate()
	buraco[14] = "##" + ".".repeat(5) + "#".repeat(8)
	afirmar(not BancoBlocos.validar({"id": "x", "tipo": "trecho", "linhas": buraco}).is_empty(), "buraco de 5 tiles")
	afirmar(not BancoBlocos.validar({"id": "x", "tipo": "arena", "linhas": buraco}).is_empty(), "arena com buraco")
	var largo: Array = []
	for l in linhas:
		largo.append(l + "#")
	afirmar(not BancoBlocos.validar({"id": "x", "tipo": "trecho", "linhas": largo}).is_empty(), "largura fora de meia tela")


func test_banco_tem_o_minimo_do_vs() -> void:
	var banco := BancoBlocos.new()
	banco.carregar()
	var tudo := _progresso(["rotas_varrek_1", "rotas_varrek_2"])
	var inicio := _progresso()
	for bioma in ["carcaca", "linha_kharn", "ninhos_vesh"]:
		afirmar_igual(banco.disponiveis(bioma, "trecho", tudo).size(), 4, "%s: 4 trechos" % bioma)
		afirmar_igual(banco.disponiveis(bioma, "arena", tudo).size(), 2, "%s: 2 arenas" % bioma)
		afirmar_igual(banco.disponiveis(bioma, "trecho", inicio).size(), 2, "%s: começa com 2 trechos" % bioma)
		afirmar_igual(banco.disponiveis(bioma, "arena", inicio).size(), 1, "%s: começa com 1 arena" % bioma)
	afirmar_igual(banco.disponiveis("zona_guerra", "trecho", tudo).size(), 3, "zona de guerra: 3 trechos")
	afirmar_igual(banco.disponiveis("elite", "arena", tudo).size(), 2, "2 arenas de elite")
	afirmar_igual(banco.disponiveis("queda", "trecho", tudo).size(), 7, "sala 0 completa (4) + 3 variantes")
	tudo.free()
	inicio.free()


# --- 2. Orçamento e blocos sem repetir ---

func test_2_orcamento_nunca_passa_e_blocos_nao_repetem() -> void:
	var banco := BancoOndas.new()
	banco.carregar()
	var rng := RandomNumberGenerator.new()
	for orcamento in [4, 8, 10, 12, 16]:
		for semente in 200:
			rng.seed = semente
			var plano := banco.planejar(orcamento, "carcaca", rng)
			var custo: int = BancoOndas.custo_total(banco, plano)
			afirmar(custo <= orcamento, "orçamento %d: gastou %d" % [orcamento, custo])
			afirmar(not plano.is_empty(), "orçamento %d: tem onda" % orcamento)
			afirmar(plano.size() <= 3, "no máximo 3 ondas")
	for flags in [[], ["rotas_varrek_1", "rotas_varrek_2"]]:
		var p := _progresso(flags)
		for semente in 60:
			var g := GeradorAto.new(p, semente)
			var usados: Array[String] = []
			for plano in _planejar_run(g):
				for id: String in plano["blocos"]:
					var tipo: String = g.blocos.bloco(id)["tipo"]
					if tipo in ["trecho", "arena"]:
						afirmar(not id in usados, "semente %d: %s repetido" % [semente, id])
						usados.append(id)
				if plano["tipo"] in ["combate", "elite", "chefe"]:
					var orc: int = int(g.info_sala(plano["numero"])["orcamento"])
					var comum: int = BancoOndas.custo_total(g.ondas, plano["ondas"].filter(func(o: Dictionary) -> bool: return not o.get("elite", false)))
					afirmar(comum <= orc, "sala %d: %d > %d" % [plano["numero"], comum, orc])
		p.free()


func test_mapa_do_ato_1_segue_o_gd01() -> void:
	var p := _progresso(["queda_completa_vista"])
	var g := GeradorAto.new(p, 5)
	var planos := _planejar_run(g)
	afirmar_igual(planos.size(), 9, "salas 0 a 8")
	var tipos: Array = planos.map(func(pl: Dictionary) -> String: return pl["tipo"])
	afirmar_igual(tipos[0], "queda", "0 Queda")
	afirmar_igual([tipos[1], tipos[2], tipos[5]], ["combate", "combate", "combate"], "1, 2 e 5 Combate")
	afirmar(tipos[3] in ["combate"], "3 Combate (ou Elite sorteada)")
	afirmar(tipos[4] in ["loja", "reparo"], "4 Loja ou Reparo")
	afirmar_igual([tipos[6], tipos[7], tipos[8]], ["elite", "reparo", "chefe"], "6 Elite, 7 Reparo, 8 Chefe")
	afirmar(planos[6]["elite"] and planos[6]["ondas"][0].get("elite", false), "sala 6 começa com a elite")
	afirmar_igual(planos[7]["portas"], ["chefe"], "sala 7 leva ao chefe")
	afirmar(planos[0]["blocos"].size() == 4, "sala 0 curta nas runs seguintes")
	afirmar_igual(planos[0]["ondas"].size(), 1, "1 onda pequena")
	afirmar(BancoOndas.custo_total(g.ondas, planos[0]["ondas"]) <= 4, "orçamento 4")
	p.free()
	var novato := _progresso()
	var g2 := GeradorAto.new(novato, 5)
	var sala0 := g2.planejar_sala(0)
	afirmar(sala0["blocos"].has("queda_tutorial_grilhao"), "1ª run: sala 0 completa (tutorial)")
	afirmar_igual(sala0["portas"], ["kharn", "vesh"], "1ª run: saída Kharn + Vesh")
	novato.free()


# --- 3 e 6. Portas ---

func test_3_portas_sem_repetir_e_garantia_de_faccao() -> void:
	for semente in 300:
		var p := _progresso(["queda_completa_vista"])
		var g := GeradorAto.new(p, semente)
		var sem_faccao: int = 0
		for plano in _planejar_run(g):
			var portas: Array = plano["portas"]
			if portas.is_empty() or portas == ["chefe"]:
				continue
			var n: int = plano["numero"]
			afirmar_igual(portas.size(), 2 if n <= 2 else 3, "sala %d: quantas portas" % n)
			for t in portas:
				afirmar_igual(portas.count(t), 1, "semente %d sala %d: porta %s repetida" % [semente, n, t])
			if "kharn" in portas or "vesh" in portas:
				sem_faccao = 0
			else:
				sem_faccao += 1
			afirmar(sem_faccao <= 2, "semente %d: 3 saídas seguidas sem facção" % semente)
			if "vida_maxima" in portas:
				afirmar(n >= 3, "vida máxima só a partir da sala 3")
		p.free()


func test_6_aprimoramento_maximo_3_nunca_na_sala_1_e_garantia_da_sala_5() -> void:
	var viu_garantia: bool = false
	for semente in 400:
		var p := _progresso(["queda_completa_vista"])
		var g := GeradorAto.new(p, semente)
		var total: int = 0
		var ate_5: int = 0
		var vidas: int = 0
		for plano in _planejar_run(g):
			var n: int = plano["numero"]
			if "aprimoramento" in plano["portas"]:
				afirmar(n != 1, "nunca na sala 1")
				total += 1
				if n <= 5:
					ate_5 += 1
			if "vida_maxima" in plano["portas"]:
				vidas += 1
			if n == 5:
				afirmar(ate_5 >= 1, "semente %d: garantia até a sala 5" % semente)
		afirmar(total <= 3, "semente %d: %d portas de Aprimoramento" % [semente, total])
		afirmar(vidas <= 1, "no máximo 1 vida máxima por ato")
		viu_garantia = viu_garantia or ate_5 >= 1
		p.free()
	var estado := EstadoAto.new()
	var rng := RandomNumberGenerator.new()
	var portas := RegrasRecompensas.sortear(5, estado, rng, {"kharn": 1, "vesh": 1, "creditos": 100})
	afirmar("aprimoramento" in portas, "sala 5 sem nenhuma antes: mostra Aprimoramento")


# --- 1. Surgimento justo na arena ---

func test_1_ninguem_surge_perto_nem_ataca_na_entrada() -> void:
	var p := _progresso(["queda_completa_vista"])
	var g := GeradorAto.new(p, 3)
	var plano := {"numero": 1, "nome": "teste", "bioma": "carcaca", "tipo": "combate", "elite": false,
			"blocos": ["entrada_varrek", "carcaca_a1", "saida_varrek"],
			"ondas": [g.ondas.ondas[0], g.ondas.ondas[5]], "portas": ["kharn", "dados"]}
	var sala := _montar(plano, g.blocos)
	var j := CenarioTeste.criar_jogador(self, Vector2(sala.arena.position.x + 52.0, 224.0))
	var camera := CameraJogo.new()
	add_child(camera)
	sala.iniciar(j, camera, self, g.ondas)
	await esperar_frames(3)
	afirmar(sala.arena_ativa, "entrou na arena")
	afirmar(not sala.vivos_da_onda.is_empty(), "1ª onda surgiu")
	for i in sala.vivos_da_onda:
		afirmar(i.global_position.distance_to(j.global_position) >= Unidades.px(6.0) - 0.5, "longe do jogador (%.0f px)" % i.global_position.distance_to(j.global_position))
		afirmar(i.esta_entrando(), "animação de entrada")
		afirmar(not i.esta_anunciando(), "não ataca na entrada")
	p.free()


# --- Sala montada ---

func test_sala_montada_tem_chao_portas_e_ondas() -> void:
	var p := _progresso(["queda_completa_vista"])
	var g := GeradorAto.new(p, 9)
	var plano := {"numero": 2, "nome": "teste", "bioma": "linha_kharn", "tipo": "combate", "elite": false,
			"blocos": ["entrada_varrek", "linha_a1", "saida_varrek"],
			"ondas": [g.ondas.ondas[0]], "portas": ["kharn", "creditos"]}
	var sala := _montar(plano, g.blocos)
	afirmar_igual(sala.largura_px, 960.0, "15 + 30 + 15 tiles")
	afirmar_igual(sala.pontos_porta.size(), 3, "3 lugares de porta na saída")
	var j := CenarioTeste.criar_jogador(self, sala.inicio + Vector2(0, -20))
	var camera := CameraJogo.new()
	add_child(camera)
	sala.iniciar(j, camera, self, g.ondas)
	await esperar_frames(30)
	afirmar(j.is_on_floor(), "em pé no chão de tiles")
	afirmar_proximo(j.global_position.y, 224.0, 1.0, "chão na linha 14 (y = 224)")
	sala.comecar_arena()
	for i in sala.inimigos.get_children():
		i.vida.receber_dano(9999, true)
	await esperar_frames(3)
	afirmar(sala.arena_concluida, "arena limpa")
	await esperar_frames(2)
	afirmar_igual(sala.portas.size(), 2, "2 portas")
	var escolhida: Array = []
	sala.porta_escolhida.connect(func(porta: PortaSaida) -> void: escolhida.append(porta.tipo))
	sala.portas[1].escolhida.emit(sala.portas[1])
	await esperar_frames(2)
	afirmar_igual(escolhida, ["creditos"], "escolheu a porta de Créditos")
	afirmar(not is_instance_valid(sala.portas[0]) or sala.portas[0].is_queued_for_deletion(), "a outra some")
	p.free()


func test_reparo_cura_ou_dadiva() -> void:
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_chao(self)
	var par := EstacaoReparo.criar_par(self, Vector2(200, 0), Vector2(260, 0))
	await esperar_frames(2)
	j.vida.receber_dano(2, true)
	var antes: int = j.vida.atual
	par[0].usar(j)
	afirmar_igual(j.vida.atual, mini(antes + 2, j.vida.maxima), "cura 2 blocos")
	afirmar(par[1].desligada, "a dádiva extra fica desligada")


# --- 5. Dados persistem; desbloqueios mudam os sorteios ---

func test_5_dados_persistem_e_desbloqueios_mudam_o_sorteio() -> void:
	var p := _progresso()
	p.incrementar("dados", 10)
	p.estado_run["tem_dadiva_kharn"] = true
	afirmar_igual(p.salvar(), OK, "salvou")
	p.limpar_run()  # morte: a run zera
	var depois := DadosProgresso.new()
	depois.caminho = p.caminho
	depois.carregar()
	afirmar_igual(depois.valor("dados"), 10, "Dados ficam depois da morte")
	afirmar(not depois.tem_flag("tem_dadiva_kharn"), "o estado da run não fica")
	# Arquivo Kharn libera os 3 upgrades bloqueados no sorteio.
	var cat: CatalogoFaccao = load("res://scenes/upgrades/kharn.tres")
	var bloqueados: int = 0
	for u in cat.upgrades:
		if not u.liberado(depois):
			bloqueados += 1
	afirmar_igual(bloqueados, 3, "começa com 3 bloqueados")
	depois.definir_flag("arquivo_kharn")
	for u in cat.upgrades:
		afirmar(u.liberado(depois), "%s liberado pelo Arquivo Kharn" % u.nome)
	# Rotas de Varrek I aumenta o banco de blocos.
	var banco := BancoBlocos.new()
	banco.carregar()
	var antes: int = banco.disponiveis("carcaca", "trecho", depois).size()
	depois.definir_flag("rotas_varrek_1")
	afirmar(banco.disponiveis("carcaca", "trecho", depois).size() > antes, "Rotas I: +1 trecho")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.caminho))
	p.free()
	depois.free()


# --- Run ---

func test_run_aplica_recompensa_e_passa_de_sala() -> void:
	var run: RunAto = instanciar(CENA_RUN)
	await esperar_frames(3)
	afirmar_igual(run.numero_sala, 0, "começa na sala 0")
	afirmar(run.sala != null and run.sala.tem_arena(), "sala 0 com mini-arena")
	var creditos: int = run.jogador.creditos
	await run.aplicar_recompensa("creditos")
	afirmar(run.jogador.creditos >= creditos + 40, "Créditos (40 a 60)")
	var maxima: int = run.jogador.vida.maxima
	await run.aplicar_recompensa("vida_maxima")
	afirmar_igual(run.jogador.vida.maxima, maxima + 1, "+1 bloco de vida máximo")
	run.carregar_sala(1)
	await esperar_frames(2)
	afirmar_igual(run.numero_sala, 1, "sala 1")
	afirmar_proximo(run.jogador.global_position.x, run.sala.inicio.x, 1.0, "Ryker no início da sala nova")
