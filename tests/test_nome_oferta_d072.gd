extends TestCase
## D-072: "Dádiva" passa a se chamar "Oferta" em todo texto que aparece no jogo. Os nomes
## internos (dadiva_kharn, oferecer_dadiva_extra...) podem ficar.

const PASTAS: Array[String] = ["res://scripts", "res://data", "res://scenes"]


func _arquivos(pasta: String, lista: Array[String]) -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for f in dir.get_files():
		if f.ends_with(".gd") or f.ends_with(".json") or f.ends_with(".tres") or f.ends_with(".tscn") or f.ends_with(".txt"):
			lista.append(pasta.path_join(f))
	for d in dir.get_directories():
		_arquivos(pasta.path_join(d), lista)


## Textos entre aspas (fora de comentários) de um arquivo.
func _textos(caminho: String) -> Array[String]:
	var saida: Array[String] = []
	var re := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for linha in FileAccess.get_file_as_string(caminho).split("\n"):
		var codigo: String = linha
		if caminho.ends_with(".gd"):
			var i: int = linha.find("#")
			if i >= 0 and linha.substr(0, i).count("\"") % 2 == 0:
				codigo = linha.substr(0, i)
		for m in re.search_all(codigo):
			saida.append(m.get_string(1))
	return saida


func test_nenhum_texto_visivel_diz_dadiva() -> void:
	var arquivos: Array[String] = []
	for p in PASTAS:
		_arquivos(p, arquivos)
	afirmar(arquivos.size() > 100, "leu os arquivos (%d)" % arquivos.size())
	var achados: Array[String] = []
	for a in arquivos:
		for t in _textos(a):
			if t.to_lower().contains("dádiva"):
				achados.append("%s: %s" % [a.get_file(), t])
	afirmar_igual(achados, [] as Array[String], "\"Dádiva\" ainda aparece")


func test_portas_loja_e_tela_dizem_oferta() -> void:
	afirmar_igual(RegrasRecompensas.NOMES["kharn"], "Oferta Kharn", "porta")
	afirmar_igual(LojaIlo.ITENS[&"dadiva_vesh"][0], "Oferta Vesh", "loja")
	var e := EstacaoReparo.new()
	e.tipo = "dadiva"
	afirmar_igual(e.titulo(), "Oferta extra", "reparo")
	e.free()
