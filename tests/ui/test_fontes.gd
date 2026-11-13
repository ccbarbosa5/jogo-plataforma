extends TestCase
## D-046: a fonte da caixa tem acentos do português e desenha todas as falas.

const ARQUIVO_FALAS: String = "res://data/dialogos/vs_varrek.json"


func test_fontes_tem_acentos_do_portugues() -> void:
	for fonte: Font in [Fontes.texto(), Fontes.pequena()]:
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


func test_creditos_registram_as_fontes() -> void:
	var creditos := FileAccess.get_file_as_string("res://assets/CREDITS.md")
	afirmar(creditos.contains("Jersey10-Regular.ttf"), "Jersey 10 em CREDITS")
	afirmar(creditos.contains("Micro5-Regular.ttf"), "Micro 5 em CREDITS")
