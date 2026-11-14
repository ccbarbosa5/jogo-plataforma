extends TestCase
## Nave-base mínima (GD-01 §9, GD-03 §3): melhorias com Núcleos, desbloqueios com Dados,
## Arsenal (escolha da arma, Bramido liberado), Sinal de Emergência e o ciclo nave → run → nave.

const CENA_NAVE: String = "res://scenes/nave/nave_eco.tscn"
const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"

var _salvo: Dictionary = {}


func _progresso() -> DadosProgresso:
	var p := DadosProgresso.new()
	p.caminho = "user://teste_progresso_nave.cfg"
	return p


## Guarda e restaura o que os testes mexem no Progresso global.
func _guardar() -> void:
	_salvo = {"flags": Progresso.flags.duplicate(), "contadores": Progresso.contadores.duplicate(),
			"arma": Ciclo.arma_escolhida, "resultado": Ciclo.resultado}


func _restaurar() -> void:
	Progresso.flags = _salvo["flags"]
	Progresso.contadores = _salvo["contadores"]
	Ciclo.arma_escolhida = _salvo["arma"]
	Ciclo.resultado = _salvo["resultado"]
	tree.paused = false


func _fechar_falas() -> void:
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1
	tree.paused = false


# --- Melhorias e desbloqueios ---

func test_comprar_melhoria_com_nucleos() -> void:
	var p := _progresso()
	var m := MelhoriasPermanentes.new()
	afirmar(not m.comprar("blindagem", p), "sem Núcleos")
	p.incrementar("nucleos", 200)
	afirmar(m.comprar("blindagem", p), "nível 1 (40)")
	afirmar_igual([MelhoriasPermanentes.nivel("blindagem", p), p.valor("nucleos")], [1, 160], "desconta 40")
	afirmar_igual(m.custo("blindagem", p), 90, "nível 2 custa 90")
	afirmar(m.comprar("blindagem", p), "nível 2")
	afirmar(not m.comprar("blindagem", p), "máximo de 2 níveis")
	afirmar_igual(m.custo("blindagem", p), -1, "completo")
	p.free()


func test_desbloqueios_com_dados_ligam_as_flags() -> void:
	var p := _progresso()
	var m := MelhoriasPermanentes.new()
	p.incrementar("dados", 200)
	afirmar(not m.comprar("rotas_varrek_2", p), "Rotas II precisa de Rotas I")
	afirmar(m.comprar("rotas_varrek_1", p) and p.tem_flag("rotas_varrek_1"), "Rotas I liga a flag do banco de salas")
	afirmar(m.comprar("rotas_varrek_2", p), "agora Rotas II")
	afirmar(m.comprar("arquivo_kharn", p) and p.tem_flag("arquivo_kharn"), "Arquivo Kharn libera os upgrades")
	afirmar(m.comprar("treino_garrak", p) and p.tem_flag("treino_garrak"), "Treino com Garrak")
	afirmar_igual(p.valor("dados"), 200 - 20 - 35 - 25 - 30, "custos do GD-03")
	p.free()


func test_melhorias_valem_no_comeco_da_run() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var p := _progresso()
	for par in [["blindagem", 1], ["cinto_granadas", 2], ["propulsores", 1], ["contato_mercado", 2], ["recalibrar", 1], ["sinal_emergencia", 1]]:
		p.contadores["melhoria_" + par[0]] = par[1]
	var vida: int = j.vida.maxima
	var granadas: int = j.granada.por_sala
	var dash: int = j.parametros.cargas_dash
	MelhoriasPermanentes.aplicar(j, p)
	afirmar_igual(j.vida.maxima, vida + 1, "Blindagem: +1 bloco")
	afirmar_igual([j.granada.por_sala, j.granadas], [granadas + 2, granadas + 2], "Cinto: +2 granadas por sala")
	afirmar_igual(j.parametros.cargas_dash, dash + 1, "Propulsores: +1 dash")
	afirmar_igual(j.creditos, 60, "Contato: 30 Créditos por nível")
	afirmar_igual([j.rerolls, j.retornos], [1, 1], "Recalibrar e Sinal de Emergência")
	afirmar_igual((load("res://scenes/jogador/parametros_ryker.tres") as ParametrosJogador).cargas_dash, dash, "o recurso original não muda")
	p.free()


func test_sinal_de_emergencia_volta_uma_vez() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.retornos = 1
	var voltas: Array[int] = [0]
	j.voltou.connect(func(_j: Jogador) -> void: voltas[0] += 1)
	j.vida.receber_dano(99, true)
	afirmar(not j.esta_morto(), "a ECO puxa de volta")
	afirmar_igual(j.vida.atual, ceili(j.vida.maxima / 2.0), "com metade da vida")
	afirmar_igual(voltas[0], 1, "avisou")
	j.vida.receber_dano(99, true)
	afirmar(j.esta_morto(), "só uma vez por run")


# --- Arsenal e ciclo ---

func test_arsenal_so_libera_o_bramido_depois_da_vitoria() -> void:
	_guardar()
	Progresso.definir_flag("bramido_liberado", false)
	afirmar(not Ciclo.escolher_arma(&"bramido"), "Bramido bloqueado")
	afirmar_igual(Ciclo.dados_da_arma().id, &"mordida", "Mordida")
	Progresso.definir_flag("bramido_liberado")
	afirmar(Ciclo.escolher_arma(&"bramido"), "liberado na 1ª vitória")
	var run: RunAto = instanciar(CENA_RUN)
	await esperar_frames(2)
	afirmar_igual(run.jogador.arma.id, &"bramido", "a run começa com a arma do Arsenal")
	afirmar_igual(Progresso.estado_run.get("arma_atual"), "bramido", "e as falas sabem (UREK_BR)")
	_fechar_falas()
	_restaurar()


func test_fim_da_run_guarda_o_sete_e_volta_para_a_nave() -> void:
	_guardar()
	Progresso.definir_flag("pegou_vesh_na_run", false)
	Progresso.limpar_run()
	Progresso.definir_run("pegou_vesh_na_run")
	Progresso.definir_run("usou_arvore")
	Ciclo.voltar_para_nave("morte")
	afirmar_igual(Ciclo.resultado, "morte", "resultado")
	afirmar(Progresso.flags.get("pegou_vesh_na_run", false), "pegou Vesh vira flag salva (Sete chega na Ponte)")
	afirmar(Ciclo.ultima_run.get("usou_arvore", false), "a nave sabe que usou a árvore (CAMP_A3)")
	Progresso.limpar_run()
	_restaurar()


func test_nave_presencas_reconstrucao_e_menus() -> void:
	_guardar()
	Progresso.contadores["mortes_total"] = 0
	for f in ["garrak_conhecido", "vossa_conhecido", "sete_chegou", "abertura_vista", "morte_primeira_vista", "bramido_liberado"]:
		Progresso.definir_flag(f, false)
	Progresso.definir_flag("abertura_vista")
	Ciclo.resultado = ""
	var nave: NaveEco = instanciar(CENA_NAVE)
	await esperar_frames(3)
	_fechar_falas()
	afirmar(not nave.garrak.visible and not nave.vossa.visible, "antes da 1ª morte: sem Garrak e sem Vossa")
	Progresso.contadores["mortes_total"] = 1
	nave.atualizar_presencas()
	afirmar(nave.garrak.visible and nave.vossa.visible, "depois da 1ª morte, eles chegam")
	var armas := nave.opcoes_arsenal()
	afirmar_igual(armas.size(), 3, "Mordida, Bramido e Treino")
	afirmar(not armas[1]["pode"], "Bramido ainda não")
	Progresso.definir_flag("bramido_liberado")
	nave.tela.abrir("Arsenal", "kharn", nave.opcoes_arsenal)
	afirmar(nave.tela.confirmar(1), "escolheu o Bramido")
	afirmar_igual(Ciclo.arma_escolhida, &"bramido", "Ciclo guarda a arma")
	nave.tela.fechar()
	_fechar_falas()
	_restaurar()


func test_chegada_depois_da_morte_toca_a_reconstrucao() -> void:
	_guardar()
	Progresso.contadores["mortes_total"] = 1
	Progresso.definir_flag("morte_primeira_vista", false)
	Ciclo.resultado = "morte"
	instanciar(CENA_NAVE)
	await esperar_frames(3)
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	afirmar(caixa.esta_ativa() and String(caixa.fala_atual().get("id", "")).begins_with("MORT_"), "a ECO fala na reconstrução")
	_fechar_falas()
	await esperar_frames(2)
	_fechar_falas()
	_restaurar()


func test_recalibrar_sorteia_de_novo_a_oferta() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var tela := TelaRecompensa.new()
	add_child(tela)
	await esperar_frames(1)
	j.rerolls = 1
	for f in ["1a_oferta_kharn"]:
		Progresso.definir_flag(f)
	tela.abrir(j, load("res://scenes/upgrades/kharn.tres"))
	_fechar_falas()
	await tree.process_frame
	if not tela.esta_escolhendo():
		_fechar_falas()
		await tree.process_frame
	afirmar(tela.recalibrar(), "recalibrou")
	afirmar_igual(j.rerolls, 0, "gastou o reroll")
	afirmar(not tela.recalibrar(), "sem rerolls")
	tela.escolher(0)
	_fechar_falas()
	tree.paused = false
