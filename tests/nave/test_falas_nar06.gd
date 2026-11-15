extends TestCase
## NAR-1 / NAR-06: falas do Vossa (árvore Passiva), do Garrak (árvore de Combate) e das
## Gambiarras, e as condições novas das cenas antigas (§2.7).

const CENA_NAVE: String = "res://scenes/nave/nave_eco.tscn"

var _salvo: Dictionary = {}


func _guardar() -> void:
	_salvo = {"flags": Progresso.flags.duplicate(), "contadores": Progresso.contadores.duplicate(),
			"run": Progresso.estado_run.duplicate(), "resultado": Ciclo.resultado, "ultima": Ciclo.ultima_run.duplicate()}


func _restaurar() -> void:
	Progresso.flags = _salvo["flags"]
	Progresso.contadores = _salvo["contadores"]
	Progresso.estado_run = _salvo["run"]
	Ciclo.resultado = _salvo["resultado"]
	Ciclo.ultima_run = _salvo["ultima"]
	tree.paused = false


func _fechar_falas() -> void:
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1
	tree.paused = false


func _nave() -> NaveEco:
	Progresso.definir_flag("abertura_vista")
	Progresso.contadores["mortes_total"] = 1
	Ciclo.resultado = ""
	var nave: NaveEco = instanciar(CENA_NAVE)
	await esperar_frames(3)
	_fechar_falas()
	return nave


func test_cenas_do_nar06_existem() -> void:
	for id: String in ["vossa_arvore_primeira", "vossa_arvore_abrir", "vossa_arvore_sem_nucleos", "vossa_compra_blindagem",
			"vossa_compra_blindagem_2", "vossa_compra_sinal_emergencia", "vossa_maximo", "vossa_falta_nucleos", "vossa_tudo",
			"vossa_fechar", "arsenal_combate_primeira", "combate_abrir", "combate_abrir_pontos", "combate_ramo_dash",
			"combate_no", "combate_apice_mordida_grande_arena", "combate_segundo_apice", "combate_limite_apices",
			"combate_redistribuir", "combate_nivel_5", "combate_nivel_10", "combate_nivel_25", "combate_nivel_25_kratzu",
			"gambiarra_epica_primeira", "gambiarra_prego", "arsenal_gambiarras_muitas", "arsenal_gambiarra_epica",
			"arsenal_gambiarras"]:
		afirmar(Dialogos.banco.tem_cena(id), id)
	for i in MelhoriasPermanentes.new().do_lugar("vossa"):
		afirmar(Dialogos.banco.tem_cena("vossa_compra_" + String(i["id"])), "fala de compra: " + String(i["id"]))
	afirmar_igual(Dialogos.banco.cena("arsenal_aprimoramento")["condicao"], "1a_gambiarra_pega", "§2.7")
	afirmar_igual(Dialogos.banco.cena("campo_morte_com_arvore")["condicao"], "morreu_com_gambiarra", "§2.7")


func test_vossa_fala_ao_abrir_e_ao_comprar() -> void:
	_guardar()
	Progresso.definir_flag("vossa_conhecido")
	Progresso.definir_flag("vossa_arvore_vista")
	Progresso.definir_flag("vossa_comprou_blindagem", false)
	Progresso.contadores["melhoria_blindagem"] = 0
	Progresso.contadores["nucleos"] = 0
	var nave: NaveEco = await _nave()
	nave._usar_vossa()
	await esperar_frames(2)
	afirmar(nave.tela.esta_aberta(), "árvore Passiva aberta")
	afirmar_igual(nave.tela.fala.get("texto", ""), "Olhar é grátis. Por enquanto.", "sem Núcleos: PASS_A4")
	Progresso.contadores["nucleos"] = 9999
	nave.tela._atualizar()
	var i: int = -1
	for k in nave.tela.opcoes.size():
		if String(nave.tela.opcoes[k]["nome"]).ends_with("Blindagem"):
			i = k
	afirmar(i >= 0, "achou a Blindagem")
	afirmar(nave.tela.confirmar(i), "comprou")
	afirmar(String(nave.tela.fala["texto"]).begins_with("Blindagem!"), "1ª compra: PASS_C_blindagem")
	afirmar_igual(nave.tela.mensagem, "", "a fala do Vossa no lugar do \"comprado\"")
	afirmar(nave.tela.confirmar(i), "comprou de novo")
	afirmar(String(nave.tela.fala["texto"]).begins_with("Mais placa."), "seguintes: PASS_C_blindagem2")
	nave.tela.confirmar(i)
	afirmar(String(nave.tela.fala["texto"]).begins_with("Completo."), "já no máximo: PASS_X1")
	nave.tela.fechar()
	_fechar_falas()
	_restaurar()


func test_garrak_fala_na_arvore_de_combate() -> void:
	_guardar()
	Progresso.contadores["xp_ryker"] = 0
	Progresso.contadores.erase("combate_ryker")
	for f in ["combate_ramo_mordida_visto", "combate_ramo_dash_visto"]:
		Progresso.definir_flag(f, false)
	var p := DadosProgresso.new()
	p.contadores["xp_ryker"] = 200 + 250 + 300  # nível 4: 3 pontos
	var tela := TelaArvoreCombate.new()
	add_child(tela)
	var prog := ProgressaoPersonagem.new("ryker")
	tela.abrir(prog, p, "mordida")
	await esperar_frames(1)
	afirmar(tela.fala.get("texto", "") in ["Você subiu. Dá para ver no jeito que segura a arma.",
			"Pontos parados não matam ninguém. Gaste."], "pontos livres: COMB_A3 ou A2")
	tela.comprar(&"mordida_rebite_afiado")
	afirmar(String(tela.fala["texto"]).begins_with("A Mordida de sempre"), "1º nó do ramo: COMB_R_mordida")
	tela.comprar(&"mordida_gatilho_de_mina")
	afirmar(String(tela.fala["texto"]) in ["Bom.", "Isso.", "Mais um.", "Hm. Aceitável."], "outros nós: comentário curto")
	tela.redistribuir()
	afirmar(String(tela.fala["texto"]) in ["Desfazer não é vergonha. Morrer igual duas vezes é.", "Começa de novo. Igual cada descida."],
			"redistribuir: COMB_D")
	tela.fechar()
	p.free()
	tela.queue_free()
	_restaurar()


func test_gambiarra_conta_na_run_e_ryker_comenta() -> void:
	_guardar()
	Progresso.estado_run.clear()
	Progresso.definir_flag("1a_gambiarra_pega", false)
	Progresso.definir_flag("visto_CAMP_A1", false)
	Progresso.definir_flag("visto_GAMB_P", false)
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	var run := RunAto.new()
	var banco := BancoGambiarras.new()
	var comum: ModificadorArma = null
	var prego: ModificadorArma = null
	for m in banco.todas(&"mordida"):
		if m.raridade == ModificadorArma.Raridade.COMUM and comum == null:
			comum = m
		if m.id == &"prego_do_rato":
			prego = m
	run.registrar_gambiarra(comum)
	afirmar_igual(caixa.fala_atual().get("id", ""), "CAMP_A1", "1ª Gambiarra: CAMP_A1")
	afirmar(Progresso.tem_flag("1a_gambiarra_pega"), "destrava arsenal_aprimoramento")
	caixa.calar_rapida()
	run.registrar_gambiarra(prego)
	afirmar_igual(caixa.fala_atual().get("id", ""), "GAMB_P", "Prego do Rato: GAMB_P")
	afirmar_igual([Progresso.estado_run.get("gambiarras_pegas", 0), Progresso.estado_run.get("gambiarra_epica", false)],
			[2, true], "a run conta as Gambiarras")
	caixa.calar_rapida()
	run.free()
	caixa.queue_free()
	_restaurar()


func test_garrak_comenta_as_gambiarras_uma_vez_na_volta() -> void:
	_guardar()
	Ciclo.ultima_run = {"gambiarras_pegas": 6}
	var nave: NaveEco = await _nave()
	afirmar(nave.comentar_gambiarras(), "comentou")
	afirmar_igual(nave.caixa.fala_atual().get("id", ""), "GAMB_G1", "5 ou mais: GAMB_G1")
	afirmar(not nave.comentar_gambiarras(), "só 1 vez por volta")
	_fechar_falas()
	_restaurar()
