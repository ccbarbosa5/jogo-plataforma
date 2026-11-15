extends TestCase
## GD-08 §1, §2 e §4: números da horda (armas mais lentas, vidas, XP) e a mira "à frente".


func test_cadencia_das_outras_fontes_sobe() -> void:
	var banco := BancoGambiarras.new()
	var cadencias: Dictionary = {}
	for arma: StringName in [&"mordida", &"bramido"]:
		for m in banco.todas(arma):
			cadencias[m.id] = m.mult_cadencia
	afirmar_proximo(cadencias[&"gatilho_leve"], 1.12, 0.001, "Gatilho Leve +12%")
	afirmar_proximo(cadencias[&"engatilho_rapido"], 1.15, 0.001, "Engatilho Rápido +15%")
	var prog := ProgressaoPersonagem.new("ryker")
	afirmar_proximo(prog.no(&"mordida_gatilho_de_mina")["modificador"]["mult_cadencia"], 1.2, 0.001, "Gatilho de Mina +20%")


func test_mira_prefere_o_mais_proximo_a_frente() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var atras := CenarioTeste.criar_boneco(self, Vector2(-CenarioTeste.tiles(2), 0))
	var frente := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0))
	await esperar_frames(2)
	var mira := MiraAutomatica.new()
	var origem: Vector2 = j.ponto_de_tiro()
	afirmar_igual(mira.escolher_alvo(origem, j.assistencias, tree), atras, "sem direção: o mais próximo (atrás)")
	afirmar_igual(mira.escolher_alvo(origem, j.assistencias, tree, 1), frente, "olhando para a direita: o da frente")
	frente.global_position.x = j.global_position.x + CenarioTeste.tiles(9)
	mira.alvo_atual = null
	afirmar_igual(mira.escolher_alvo(origem, j.assistencias, tree, 1), atras, "a frente vale só até 6 tiles")
