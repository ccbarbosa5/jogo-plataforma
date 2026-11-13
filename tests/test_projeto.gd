extends TestCase
## Testes de sanidade do projeto: garantem as configurações decididas pela Diretoria (D-005).


func test_resolucao_interna_pixel_art() -> void:
	afirmar_igual(ProjectSettings.get_setting("display/window/size/viewport_width"), 480, "largura")
	afirmar_igual(ProjectSettings.get_setting("display/window/size/viewport_height"), 270, "altura")


func test_filtro_nearest() -> void:
	afirmar_igual(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0, "filtro de textura")


func test_todas_as_cenas_carregam() -> void:
	var cenas: Array[String] = []
	_coletar_cenas("res://scenes", cenas)
	for c in cenas:
		var pacote: PackedScene = load(c)
		afirmar(pacote != null, "cena não carrega: %s" % c)
		if pacote != null:
			var no := pacote.instantiate()
			afirmar(no != null, "cena não instancia: %s" % c)
			if no != null:
				no.free()


func _coletar_cenas(dir_path: String, saida: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_coletar_cenas(dir_path.path_join(sub), saida)
	for f in dir.get_files():
		if f.ends_with(".tscn"):
			saida.append(dir_path.path_join(f))
