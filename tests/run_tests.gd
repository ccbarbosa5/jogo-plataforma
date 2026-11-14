extends SceneTree
## Executor de testes do estúdio.
## Uso: godot --headless --path . -s res://tests/run_tests.gd
##
## Procura todos os arquivos tests/**/test_*.gd. Cada arquivo deve estender
## res://tests/caso_teste.gd. Todo método que começa com "test_" é executado.
## O processo sai com código 1 se algum teste falhar (o CI usa isso).

const TESTS_DIR: String = "res://tests"

var _total: int = 0
var _falhas: int = 0


func _initialize() -> void:
	var arquivos: Array[String] = []
	_coletar(TESTS_DIR, arquivos)
	arquivos.sort()

	# Nos testes, a run e a nave nunca trocam de cena sozinhas.
	var ciclo: Node = root.get_node_or_null("Ciclo")
	if ciclo != null:
		ciclo.trocar_cena = false
	print("== Testes do Jogo Plataforma ==")
	for caminho in arquivos:
		await _rodar_arquivo(caminho)

	print("")
	print("Resultado: %d testes, %d falha(s)" % [_total, _falhas])
	quit(1 if _falhas > 0 else 0)


func _coletar(dir_path: String, saida: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_coletar(dir_path.path_join(sub), saida)
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			saida.append(dir_path.path_join(f))


func _rodar_arquivo(caminho: String) -> void:
	var script: GDScript = load(caminho)
	if script == null:
		_total += 1
		_falhas += 1
		print("[ERRO] não foi possível carregar %s" % caminho)
		return
	print("\n%s" % caminho)
	for metodo in script.get_script_method_list():
		var nome: String = metodo["name"]
		if not nome.begins_with("test_"):
			continue
		var caso: TestCase = script.new()
		caso.tree = self
		root.add_child(caso)
		await caso.call(nome)
		_total += 1
		if caso.falhas.is_empty():
			print("  [OK]    %s" % nome)
		else:
			_falhas += 1
			print("  [FALHA] %s" % nome)
			for msg in caso.falhas:
				print("          - %s" % msg)
		caso.queue_free()
		await process_frame
