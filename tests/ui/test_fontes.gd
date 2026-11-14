extends TestCase
## D-046: a fonte tem os acentos do português e desenha todas as falas.
## D-056: texto nítido na resolução da tela. D-057: placa de nome legível.

const ARQUIVO_FALAS: String = "res://data/dialogos/vs_varrek.json"


func test_fontes_tem_acentos_do_portugues() -> void:
	for fonte: Font in [Fontes.texto(), Fontes.pequena(), Fontes.placa()]:
		afirmar(fonte != null, "fonte carregou")
		for c in Fontes.CARACTERES_OBRIGATORIOS:
			afirmar(fonte.has_char(c.unicode_at(0)), "%s sem o caractere %s" % [fonte.get_font_name(), c])


func test_todas_as_falas_desenham_sem_faltar_caractere() -> void:
	var banco := BancoDialogos.new()
	afirmar_igual(banco.carregar(ARQUIVO_FALAS), OK, "falas carregaram")
	var fonte := Fontes.texto()
	var pequena := Fontes.pequena()
	var faltando: Dictionary = {}
	var textos: Array[String] = []
	for codigo: String in banco.falantes:
		textos.append(banco.nome_do_falante(codigo))
	for id_cena: String in banco.cenas:
		for fala in banco.todas_as_falas(id_cena):
			textos.append(fala.get("texto", ""))
			textos.append(fala.get("direcao", ""))
	for t in textos:
		for c in t:
			var u := c.unicode_at(0)
			if u > 32 and (not fonte.has_char(u) or not pequena.has_char(u)):
				faltando[c] = true
	afirmar(faltando.is_empty(), "caracteres sem desenho: %s" % "".join(faltando.keys()))


func test_fonte_padrao_do_jogo_e_a_das_falas() -> void:
	afirmar(ThemeDB.fallback_font == Fontes.texto(), "Label sem fonte própria usa a fonte das falas")
	afirmar_igual(ThemeDB.fallback_font_size, Fontes.TAMANHO_TEXTO, "tamanho padrão")


# --- D-056: texto nítido na resolução nativa da tela ---

func test_texto_e_desenhado_na_resolucao_da_tela() -> void:
	# "canvas_items": o texto é rasterizado no tamanho real da janela; o mundo segue em 480×270.
	afirmar_igual(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "modo de escala")
	afirmar_igual(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer", "escala inteira (pixel art)")
	var fonte: FontFile = Fontes.texto() as FontFile
	afirmar(fonte != null, "fonte vetorial (FontFile)")
	if fonte != null:
		afirmar_igual(fonte.fixed_size, 0, "fonte escalável, não de pixel")


func test_tamanho_confortavel_em_1080p() -> void:
	# 1080p = escala 4× da tela de 480×270. D-056: letra de ~20–24 px.
	var escala: int = 1080 / 270
	afirmar(Fontes.TAMANHO_TEXTO * escala >= 20 and Fontes.TAMANHO_TEXTO * escala <= 24, "falas entre 20 e 24 px")
	afirmar(Fontes.TAMANHO_PEQUENA * escala >= 18, "texto pequeno ainda legível")
	afirmar(Fontes.TAMANHO_PLACA > Fontes.TAMANHO_TEXTO, "placa maior que o texto")


# --- D-057: placa de nome legível ---

func _luminancia(c: Color) -> float:
	var canais: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		canais.append(v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * canais[0] + 0.7152 * canais[1] + 0.0722 * canais[2]


func test_placa_tem_contraste_alto() -> void:
	var claro: float = _luminancia(CaixaDialogo.COR_TEXTO_PLACA)
	var escuro: float = _luminancia(CaixaDialogo.COR_FUNDO_PLACA)
	var contraste: float = (claro + 0.05) / (escuro + 0.05)
	afirmar(contraste >= 7.0, "contraste da placa %.1f:1 (mínimo 7:1)" % contraste)


func test_placa_usa_texto_claro_negrito_sobre_fundo_liso() -> void:
	var banco := BancoDialogos.new()
	afirmar_igual(banco.carregar(ARQUIVO_FALAS), OK, "falas carregaram")
	var caixa: CaixaDialogo = instanciar("res://scenes/ui/caixa_dialogo.tscn")
	var falas: Array[Dictionary] = [{"falante": "VOSSA", "texto": "Ação, coração."}]
	caixa.mostrar("teste", falas, "conversa", banco)
	afirmar(caixa.placa.visible, "placa aparece")
	afirmar_igual(caixa.nome.text, "VOSSA MARGEM", "só o nome, em maiúsculas")
	afirmar_igual(caixa.nome.get_theme_color("font_color"), CaixaDialogo.COR_TEXTO_PLACA, "texto claro, não a cor do falante")
	afirmar_igual(caixa.nome.get_theme_font_size("font_size"), Fontes.TAMANHO_PLACA, "letra maior")
	afirmar(caixa.nome.get_theme_font("font") == Fontes.placa(), "fonte negrito da placa")
	var estilo: StyleBoxFlat = caixa.placa.get_theme_stylebox("panel") as StyleBoxFlat
	afirmar(estilo != null and estilo.bg_color == CaixaDialogo.COR_FUNDO_PLACA, "fundo escuro e liso")
	afirmar(estilo != null and estilo.bg_color.a >= 1.0, "fundo opaco")
	afirmar(estilo != null and estilo.border_color == banco.cor_do_falante("VOSSA"), "cor do falante só na faixa")
	var largura_nome: float = Fontes.placa().get_string_size(caixa.nome.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PLACA).x
	afirmar(caixa.placa.size.x >= largura_nome, "o nome cabe na placa")
	afirmar(caixa.placa.position.y + caixa.placa.size.y <= caixa.caixa.position.y + 4.0, "placa em cima da caixa")
	while caixa.esta_ativa():
		caixa.avancar()


func test_textos_das_armas_desenham_sem_faltar_caractere() -> void:
	var fonte := Fontes.texto()
	var faltando: Dictionary = {}
	for caminho: String in ["res://scenes/armas/mordida.tres", "res://scenes/armas/bramido.tres"]:
		var arma: DadosArma = load(caminho)
		var textos: Array[String] = [arma.nome, arma.assinatura_descricao]
		textos.append_array(arma.arvore.ramos)
		for no in arma.arvore.nos:
			textos.append(no.nome)
			textos.append(no.descricao)
		for t in textos:
			for c in t:
				if c.unicode_at(0) > 32 and not fonte.has_char(c.unicode_at(0)):
					faltando[c] = true
	afirmar(faltando.is_empty(), "caracteres sem desenho: %s" % "".join(faltando.keys()))
