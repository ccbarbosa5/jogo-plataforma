extends TestCase
## D-063: falas maiores, limite por página e divisão automática.

const LONGA: String = "Eu já vi gente melhor que você morrer nessa areia, gladiador, e todos achavam que iam sair daqui. Ninguém saiu. Os portões só abrem para a carroça dos corpos, e a carroça nunca volta vazia para a cidade de cima."


func _falas_do_jogo() -> Array[Dictionary]:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogos/vs_varrek.json"))
	var saida: Array[Dictionary] = []
	var pilha: Array = [d["cenas"]]
	while not pilha.is_empty():
		var o: Variant = pilha.pop_back()
		if o is Dictionary:
			if o.has("texto") or o.has("direcao"):
				saida.append(o)
			for v in o.values():
				if v is Dictionary or v is Array:
					pilha.append(v)
		elif o is Array:
			pilha.append_array(o)
	return saida


func test_tamanho_igual_em_todas_as_caixas() -> void:
	afirmar_igual(Fontes.TAMANHO_FALA, 8, "32 px em 1080p (escala 4×)")
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	afirmar_igual(caixa.texto.get_theme_font_size("font_size"), Fontes.TAMANHO_FALA, "conversa")
	afirmar_igual(caixa.rapida_texto.get_theme_font_size("font_size"), Fontes.TAMANHO_FALA, "rápida")
	caixa.queue_free()


func test_fala_longa_vira_paginas_cortadas_no_fim_da_frase() -> void:
	var paginas: PackedStringArray = PaginasFala.dividir(LONGA)
	afirmar(paginas.size() >= 2, "dividiu em %d páginas" % paginas.size())
	for p in paginas:
		afirmar(p.length() <= PaginasFala.LIMITE and PaginasFala.linhas(p) <= PaginasFala.LINHAS, "cabe: " + p)
		afirmar(".!?…".contains(p[p.length() - 1]), "termina em fim de frase: " + p)
	afirmar_igual(" ".join(paginas), LONGA, "nenhuma palavra perdida ou cortada")


func test_sem_ponto_corta_na_virgula_e_nunca_no_meio_da_palavra() -> void:
	var t: String = "Eu corro, eu pulo, eu atiro, eu caio, eu levanto, eu corro de novo, eu pulo mais alto, eu atiro melhor, eu caio de outro jeito, eu levanto mais devagar, e ainda assim eu volto para a areia"
	var paginas: PackedStringArray = PaginasFala.dividir(t)
	afirmar(paginas.size() >= 2, "dividiu")
	afirmar(paginas[0].ends_with(","), "primeira página termina na vírgula")
	afirmar_igual(" ".join(paginas), t, "texto inteiro")
	var sem_pausa: String = "palavra ".repeat(40).strip_edges()
	for p in PaginasFala.dividir(sem_pausa):
		for w in p.split(" "):
			afirmar_igual(w, "palavra", "palavra inteira")


func test_fala_curta_fica_igual() -> void:
	var falas: Array[Dictionary] = [{"id": "X", "falante": "RYKER", "texto": "Curta."}]
	afirmar_igual(PaginasFala.paginar(falas), falas, "uma página só")


func test_nenhuma_pagina_do_jogo_passa_do_limite_nem_sai_da_caixa() -> void:
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	var paginas: Array[Dictionary] = PaginasFala.paginar(_falas_do_jogo())
	afirmar(paginas.size() > 200, "leu as falas do jogo")
	var ruins: int = 0
	for f in paginas:
		var campo: String = "texto" if not String(f.get("falante", "")).is_empty() else "direcao"
		var t: String = f.get(campo, "")
		caixa.texto.text = t
		caixa.rapida_texto.text = t
		var altura: float = caixa.texto.get_line_count() * Fontes.texto().get_height(Fontes.TAMANHO_FALA)
		if t.length() > PaginasFala.LIMITE or caixa.texto.get_line_count() > PaginasFala.LINHAS \
				or caixa.rapida_texto.get_line_count() > PaginasFala.LINHAS \
				or caixa.texto.position.y + altura > caixa.direcao.position.y + 2.0:
			ruins += 1
			print("    não cabe: ", f.get("id", "?"), " ", t)
	afirmar_igual(ruins, 0, "todas as páginas cabem nas caixas")
	afirmar(caixa.texto.position.x + PaginasFala.LARGURA <= caixa.caixa.size.x, "texto dentro da caixa")
	afirmar(caixa.rapida.position.y + caixa.rapida.size.y < caixa.caixa.position.y, "faixa rápida não cobre a caixa")
	caixa.queue_free()


func test_caixa_mostra_as_paginas_em_sequencia() -> void:
	var caixa := CaixaDialogo.new()
	add_child(caixa)
	await esperar_frames(1)
	var banco := BancoDialogos.new()
	banco.falantes = {"RYKER": {"nome": "Ryker"}}
	var falas: Array[Dictionary] = [{"id": "L1", "falante": "RYKER", "texto": LONGA, "direcao": "cansado"}]
	caixa.mostrar("teste", falas, "conversa", banco)
	var n: int = PaginasFala.dividir(LONGA).size()
	afirmar_igual(caixa.fala_atual()["paginas"], n, "páginas")
	afirmar(caixa.direcao.text != "", "direção na primeira página")
	for i in n - 1:
		caixa.avancar()
	afirmar(caixa.esta_ativa() and caixa.direcao.text == "", "última página, sem repetir a direção")
	caixa.avancar()
	afirmar(not caixa.esta_ativa(), "terminou depois da última página")
	tree.paused = false
	caixa.queue_free()
