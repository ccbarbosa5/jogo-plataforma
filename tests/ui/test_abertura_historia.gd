extends TestCase
## D-073B: abertura da história (NAR-07, ART-5) no primeiro Novo jogo; pular; "Ver abertura".

const CENA: String = "res://scenes/ui/abertura_historia.tscn"
const ARQUIVO_PROGRESSO: String = "user://progresso_teste_abertura.cfg"


func _abertura(rever: bool = false) -> AberturaHistoria:
	Ciclo.ultima_cena_pedida = ""
	Ciclo.abertura_rever = rever
	var a: AberturaHistoria = (load(CENA) as PackedScene).instantiate()
	add_child(a)
	return a


func _limpar(a: Node = null) -> void:
	if a != null and is_instance_valid(a):
		a.queue_free()
	Config.abertura_vista = false
	Ciclo.abertura_rever = false
	Ciclo.ultima_cena_pedida = ""
	tree.paused = false


func test_falas_do_roteiro_em_modo_narracao() -> void:
	var cena: Dictionary = Dialogos.banco.cena("abertura_historia")
	afirmar_igual(cena.get("modo"), "narracao", "modo narração")
	var ids: Array[String] = []
	for f: Dictionary in cena.get("falas", []):
		ids.append(String(f["id"]))
		afirmar_igual(f.get("falante"), "RYKER", "%s: fala do Ryker" % f["id"])
		afirmar(String(f["texto"]).length() <= 120, "%s: até 120 caracteres (D-063)" % f["id"])
	afirmar_igual(ids, ["AB_01", "AB_02", "AB_03", "AB_04", "AB_05", "AB_06"], "as 6 falas do NAR-07")
	afirmar(Dialogos.banco.validar().is_empty(), "banco de diálogos válido")
	afirmar_igual(AberturaHistoria.DURACOES.size(), 9, "9 quadros")
	var total := AberturaHistoria.duracao_total()
	afirmar(total >= 30.0 and total <= 60.0, "30–60 s (D-073B): %.0f" % total)


func test_primeiro_novo_jogo_toca_a_abertura_e_os_seguintes_nao() -> void:
	var p := DadosProgresso.new()
	p.caminho = ARQUIVO_PROGRESSO
	add_child(p)
	p.apagar()
	var t: TelaTitulo = (load("res://scenes/ui/tela_titulo.tscn") as PackedScene).instantiate()
	t.progresso = p
	add_child(t)
	await esperar_frames(1)
	Config.abertura_vista = false
	t.ativar("Novo jogo")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_ABERTURA, "1º Novo jogo: abertura")
	afirmar(not Ciclo.abertura_rever, "não é o \"Ver abertura\"")
	Config.abertura_vista = true
	Ciclo.ultima_cena_pedida = ""
	t.ativar("Novo jogo")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_NAVE, "já viu: direto para a nave")
	t.queue_free()
	p.queue_free()
	_limpar()


func test_toca_os_9_quadros_com_as_falas_e_vai_para_a_nave() -> void:
	var a := _abertura()
	await esperar_frames(1)
	afirmar(not a.rever, "primeira vez")
	for i in AberturaHistoria.DURACOES.size():
		a.tempo = AberturaHistoria.inicio_do_quadro(i) + 0.05
		await esperar_frames(2)
		afirmar_igual(a.indice, i, "quadro %d" % (i + 1))
		afirmar(a.palco.get_node_or_null("Quadro%d" % (i + 1)) != null, "quadro %d montado" % (i + 1))
		# Passa pelo meio de cada quadro (animações sem erro) e pelas falas agendadas.
		a.tempo = AberturaHistoria.inicio_do_quadro(i) + AberturaHistoria.DURACOES[i] * 0.6
		await esperar_frames(2)
		if i == 0:
			afirmar(a.legenda.visible or a.falas_mostradas.has("AB_01"), "legenda da arena ou fala")
	afirmar_igual(a.falas_mostradas.size(), 6, "as 6 falas apareceram")
	a.tempo = AberturaHistoria.duracao_total() + 0.1
	await esperar_frames(2)
	afirmar(a.acabou and not a.pulou, "terminou sozinha")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_NAVE, "segue para a nave (ABER)")
	afirmar(Config.abertura_vista, "o save marca que já viu")
	_limpar(a)


func test_narracao_nao_pausa_e_some_sozinha() -> void:
	var a := _abertura()
	await esperar_frames(1)
	a.tempo = 2.65
	await esperar_frames(2)
	afirmar(a.caixa.esta_ativa(), "AB_01 na caixa")
	afirmar_igual(a.caixa.fala_atual().get("id"), "AB_01", "AB_01")
	afirmar(a.caixa.retrato_esquerda.visible, "com o retrato do Ryker")
	afirmar(not a.caixa.escurecer.visible, "sem escurecer a cena")
	afirmar(not tree.paused, "não pausa")
	var limite := 400
	while a.caixa.esta_ativa() and limite > 0:
		await esperar_frames(5)
		limite -= 5
	afirmar(not a.caixa.esta_ativa(), "some sozinha, sem apertar nada")
	_limpar(a)


func test_pular_pelo_botao_ou_segurando_esc() -> void:
	var a := _abertura()
	await esperar_frames(2)
	a.botao_pular.pressed.emit()
	afirmar(a.pulou and a.acabou, "clicou em Pular")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_NAVE, "foi para a nave")
	afirmar(Config.abertura_vista, "pular também marca como vista")
	_limpar(a)
	var b := _abertura()
	await esperar_frames(2)
	Input.action_press("pausa")
	var limite := 200
	while not b.acabou and limite > 0:
		await esperar_frames(1)
		limite -= 1
	Input.action_release("pausa")
	afirmar(b.pulou, "segurar Esc/Pausa pula")
	_limpar(b)


func test_ver_abertura_pelo_menu_termina_no_logo_e_volta_ao_menu() -> void:
	var pausa: Node = tree.root.get_node("Pausa")
	pausa.abrir_opcoes_do_titulo()
	afirmar(pausa.textos_dos_botoes().has("Ver abertura"), "botão nas Opções do menu inicial")
	pausa.ativar("Ver abertura")
	afirmar(not pausa.esta_aberto(), "fecha as Opções")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_ABERTURA, "toca a abertura")
	afirmar(Ciclo.abertura_rever, "modo rever")
	var a := _abertura(true)
	await esperar_frames(1)
	a.tempo = AberturaHistoria.duracao_total() + 0.1
	await esperar_frames(2)
	afirmar(not a.acabou, "segura a tela preta com o logo")
	var limite := 400
	while not a.acabou and limite > 0:
		await esperar_frames(5)
		limite -= 5
	afirmar(a.acabou, "terminou")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_TITULO, "volta ao menu")
	afirmar(not Config.abertura_vista, "rever não muda o save")
	_limpar(a)
