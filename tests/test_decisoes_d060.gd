extends TestCase
## D-060: propostas padrão do DEV aprovadas pela DIR (conferência de que o jogo segue cada uma).


func test_soldado_kharn_provisorio_foi_apagado() -> void:
	afirmar(not ResourceLoader.exists("res://scenes/inimigos/soldado_kharn.tscn"), "cena apagada")
	afirmar(not MontadorSala.CENAS_INIMIGOS.has("soldado"), "fora do montador")
	afirmar(not MontadorSala.MARCADORES_INIMIGOS.has("S"), "sem marcador nos blocos")


func test_loja_cura_40_ate_2_e_dadivas_80() -> void:
	afirmar_igual(LojaIlo.ITENS[&"cura"], ["Cura (1 bloco)", 40, 2], "Cura: 40, até 2")
	afirmar_igual(LojaIlo.ITENS[&"dadiva_kharn"][1], 80, "Dádiva Kharn: 80")
	afirmar_igual(LojaIlo.ITENS[&"dadiva_vesh"][1], 80, "Dádiva Vesh: 80")
	afirmar(not LojaIlo.ITENS.has(&"aprimoramento_de_arma"), "sem Aprimoramento")


func test_abandonar_a_run_nao_conta_como_morte() -> void:
	var pausa: Node = tree.root.get_node("Pausa")
	var mortes: int = Progresso.valor("mortes_total")
	var cena := Node.new()
	tree.root.add_child(cena)
	tree.current_scene = cena
	var j := Node.new()
	j.add_to_group("jogadores")
	add_child(j)
	pausa.abrir()
	pausa.ativar("Voltar à nave")
	pausa.ativar("Abandonar")
	afirmar_igual(Progresso.valor("mortes_total"), mortes, "mortes_total não muda")
	afirmar_igual(Ciclo.resultado, "desistiu", "volta como desistência")
	tree.current_scene = null
	cena.queue_free()
	Ciclo.resultado = ""
	tree.paused = false


func test_esquiva_vale_para_qualquer_golpe_no_dash_e_recarga_conta_tiro_e_granada() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.nos_combate.assign([&"dash_esquiva_de_arena", &"granada_recarga_de_campo"])
	await esperar_frames(3)
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	j.entrada.dash_pressionado = false
	var golpe := InfoDano.criar(1)
	golpe.corpo_a_corpo = true  # um golpe, não um projétil
	afirmar(not j.receber_ataque(golpe), "atravessou o golpe")
	afirmar_proximo(j.controle_arma._bonus_proximo, 0.5, 0.001, "Esquiva armada por golpe corpo a corpo")
	j.granadas = 0
	var b := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(1)
	j.controle_arma.acertou.emit(b, InfoDano.criar(10, j), true)  # morte por tiro
	j.controle_arma.acertou.emit(b, InfoDano.criar(10, j), true)
	j.efeitos_arvore.contar_morte()  # morte por granada (via explosão)
	afirmar_igual(j.granadas, 1, "3 mortes (tiro + granada) = +1 granada")


func test_saves_antigos_perdem_o_cinto_de_granadas() -> void:
	var m := MelhoriasPermanentes.new()
	afirmar(m.item("cinto_granadas").is_empty(), "o Cinto não existe mais na árvore Passiva")
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var p := DadosProgresso.new()
	p.contadores["melhoria_cinto_granadas"] = 2
	var antes: int = j.granada.por_sala
	MelhoriasPermanentes.aplicar(j, p)
	afirmar_igual(j.granada.por_sala, antes, "nível antigo ignorado")
	p.free()
