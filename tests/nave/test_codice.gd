extends TestCase
## Códice na nave (D-060, NAR-05 §5): entradas destravam por encontros; mouse e Esc (D-065).

const CENA_NAVE: String = "res://scenes/nave/nave_eco.tscn"

var _salvo: Dictionary = {}


func _progresso() -> DadosProgresso:
	var p := DadosProgresso.new()
	p.caminho = "user://teste_progresso_codice.cfg"
	return p


func _entrada(lista: Array[Dictionary], id: String) -> Dictionary:
	for e in lista:
		if e["id"] == id:
			return e
	return {}


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


func test_dados_do_codice_tem_as_entradas_do_vs() -> void:
	var dados := Codice.carregar()
	var ids: Array[String] = []
	for e in dados:
		ids.append(String(e["id"]))
		for campo in ["grupo", "nome", "titulo", "condicao", "texto"]:
			afirmar(e.has(campo), "%s tem %s" % [e["id"], campo])
		afirmar(not String(e["texto"]).is_empty(), "%s tem texto" % e["id"])
	for id in ["ryker", "eco", "garrak", "sete", "vossa", "mercador", "tor_ama", "colmeia", "urkesh", "mordida", "bramido"]:
		afirmar(ids.has(id), "entrada %s (NAR-05 §5)" % id)
	afirmar_igual(ids.size(), 11, "9 personagens + 2 armas do VS")


func test_entradas_destravam_por_encontros() -> void:
	var p := _progresso()
	var lista := Codice.entradas(p)
	afirmar(_entrada(lista, "ryker")["liberada"] and _entrada(lista, "eco")["liberada"] and _entrada(lista, "mordida")["liberada"],
			"Ryker, ECO e Mordida desde o começo")
	for id in ["garrak", "sete", "vossa", "mercador", "tor_ama", "colmeia", "urkesh", "bramido"]:
		afirmar(not _entrada(lista, id)["liberada"], "%s ainda travada" % id)
	afirmar_igual(Codice.liberadas(p), 3, "3 liberadas no começo")
	var encontros: Dictionary = {"garrak": "garrak_conhecido", "sete": "sete_chegou", "vossa": "vossa_conhecido",
			"mercador": "1a_loja", "tor_ama": "1a_oferta_kharn", "colmeia": "1a_oferta_vesh", "bramido": "bramido_liberado"}
	for id: String in encontros:
		p.flags[encontros[id]] = true
		afirmar(_entrada(Codice.entradas(p), id)["liberada"], "%s destrava com %s" % [id, encontros[id]])
	p.contadores["urkesh_encontros"] = 1
	afirmar(_entrada(Codice.entradas(p), "urkesh")["liberada"], "Ur-Kesh destrava no 1º encontro")
	afirmar_igual(Codice.liberadas(p), 11, "tudo liberado")


func test_paragrafo_extra_da_arma_depois_de_10_runs() -> void:
	var p := _progresso()
	var m := _entrada(Codice.entradas(p), "mordida")
	afirmar(String(m["extra"]).is_empty() and not String(m["aviso"]).is_empty(), "sem o extra, com o aviso de como destravar")
	p.contadores["runs_mordida"] = 10
	m = _entrada(Codice.entradas(p), "mordida")
	afirmar(String(m["extra"]).contains("prego do rato") and String(m["aviso"]).is_empty(), "10 runs: parágrafo extra")
	p.contadores["runs_bramido"] = 10
	afirmar(String(_entrada(Codice.entradas(p), "bramido")["extra"]).is_empty(), "arma travada não mostra o extra")


func test_tela_mostra_interrogacoes_e_aceita_mouse_e_esc() -> void:
	var p := _progresso()
	p.flags["garrak_conhecido"] = true
	var t := TelaCodice.new()
	add_child(t)
	t.abrir(p)
	await esperar_frames(15)  # passa a trava de abertura
	afirmar(t.esta_aberta() and tree.paused, "aberta, jogo pausado")
	afirmar_igual(t.nome_na_lista(0), "Ryker", "liberada: mostra o nome")
	afirmar_igual(t.nome_na_lista(3), "???", "Sete ainda não encontrado: ???")
	t._input(_mover(t.retangulo_da_linha(2).get_center()))
	afirmar_igual(t.selecionada, 2, "passar o mouse escolhe")
	afirmar(t.texto_da_selecionada().contains("mestre de armas"), "texto do Garrak à direita")
	t._input(_clique(t.retangulo_da_linha(3).get_center()))
	afirmar_igual(t.texto_da_selecionada(), TelaCodice.TEXTO_OCULTO, "travada: sem texto")
	t.selecionar(10)
	afirmar(t.retangulo_da_linha(10).size != Vector2.ZERO, "a seleção fica visível")
	t._input(_clique(Vector2.ZERO, MOUSE_BUTTON_WHEEL_UP))
	afirmar(t.selecionada >= t.primeira, "a roda rola sem perder a seleção")
	t._input(_tecla_esc())
	afirmar(not t.esta_aberta() and not tree.paused, "Esc volta")
	t.abrir(p)
	await esperar_frames(15)
	t._input(_clique(Vector2(5, 5)))
	afirmar(not t.esta_aberta(), "clique fora do painel volta")
	t.queue_free()
	tree.paused = false


func test_codice_abre_pelo_arquivo_da_nave() -> void:
	_salvo = {"flags": Progresso.flags.duplicate(), "contadores": Progresso.contadores.duplicate(), "resultado": Ciclo.resultado}
	Progresso.definir_flag("abertura_vista")
	Ciclo.resultado = ""
	var nave: NaveEco = instanciar(CENA_NAVE)
	await esperar_frames(3)
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 60
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1
	tree.paused = false
	var opcoes := nave.opcoes_arquivo()
	afirmar_igual(opcoes[0]["nome"], "Códice", "o Códice é a 1ª opção do Arquivo da Ponte")
	afirmar(opcoes.size() > 1, "os desbloqueios com Dados continuam na lista")
	nave._usar_terminal()
	afirmar(nave.tela.esta_aberta(), "Arquivo aberto")
	nave.tela.confirmar(0)
	await esperar_frames(2)
	afirmar(not nave.tela.esta_aberta() and nave.tela_codice.esta_aberta(), "abre o Códice")
	afirmar_igual(nave.tela_codice.entradas.size(), 11, "com as 11 entradas")
	nave.tela_codice.fechar()
	Progresso.flags = _salvo["flags"]
	Progresso.contadores = _salvo["contadores"]
	Ciclo.resultado = _salvo["resultado"]
	tree.paused = false
