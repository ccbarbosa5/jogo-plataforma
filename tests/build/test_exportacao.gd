extends TestCase
## Exportação para o itch.io (D-028, D-051): Windows (.exe) e Web (HTML5, Compatibility).


func _presets() -> Dictionary:
	var cfg := ConfigFile.new()
	afirmar_igual(cfg.load("res://export_presets.cfg"), OK, "export_presets.cfg existe")
	var por_nome: Dictionary = {}
	for secao in cfg.get_sections():
		if cfg.has_section_key(secao, "platform"):
			por_nome[cfg.get_value(secao, "platform")] = secao
	return {"cfg": cfg, "secoes": por_nome}


func test_tem_windows_e_web() -> void:
	var p: Dictionary = _presets()
	var secoes: Dictionary = p["secoes"]
	afirmar(secoes.has("Windows Desktop"), "preset Windows")
	afirmar(secoes.has("Web"), "preset Web")


func test_web_usa_compatibility_sem_threads() -> void:
	var p: Dictionary = _presets()
	var cfg: ConfigFile = p["cfg"]
	var web: String = p["secoes"].get("Web", "")
	afirmar_igual(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility", "renderizador")
	afirmar_igual(cfg.get_value(web + ".options", "variant/thread_support", true), false, "Web sem threads (roda no itch sem cabeçalhos especiais)")


func test_windows_exe_unico_e_testes_fora_do_jogo() -> void:
	var p: Dictionary = _presets()
	var cfg: ConfigFile = p["cfg"]
	var secoes: Dictionary = p["secoes"]
	var win: String = secoes.get("Windows Desktop", "")
	afirmar_igual(cfg.get_value(win + ".options", "binary_format/embed_pck", false), true, ".exe com os dados embutidos")
	for plataforma in ["Windows Desktop", "Web"]:
		var secao: String = secoes.get(plataforma, "")
		var excluir: String = cfg.get_value(secao, "exclude_filter", "")
		afirmar(excluir.contains("tests/*"), "testes fora do jogo (%s)" % plataforma)
		var incluir: String = cfg.get_value(secao, "include_filter", "")
		afirmar(incluir.contains("data/*.json"), "dados JSON no jogo (%s)" % plataforma)
		afirmar(incluir.contains("data/*.txt"), "textos (créditos) no jogo (%s)" % plataforma)
