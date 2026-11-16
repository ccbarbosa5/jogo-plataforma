extends TestCase
## D-073A: logo animado ao abrir o jogo, antes do menu; qualquer tecla/clique pula.

const CENA: String = "res://scenes/ui/logo_animado.tscn"


func _logo() -> LogoAnimado:
	Ciclo.ultima_cena_pedida = ""
	var l: LogoAnimado = (load(CENA) as PackedScene).instantiate()
	add_child(l)
	return l


func test_e_a_cena_que_abre_o_jogo() -> void:
	afirmar_igual(ProjectSettings.get_setting("application/run/main_scene"), CENA, "abre no logo")


func test_folha_da_art_com_56_quadros_e_duracao_de_6_a_7_segundos() -> void:
	var l := _logo()
	await esperar_frames(1)
	var s := l.get_node("Logo") as Sprite2D
	afirmar(s.texture != null, "folha carregada")
	afirmar_igual(s.hframes * s.vframes, LogoAnimado.QUADROS, "8 × 7 = 56 quadros")
	afirmar_igual(s.texture.get_size(), Vector2(279 * 8, 86 * 7), "quadros de 279×86")
	afirmar(l.duracao_total() >= 4.0 and l.duracao_total() <= 8.0, "entre 4 e 8 s (D-073A)")
	# Mesmo lugar do logo do menu: x do logo = (480 − 259) / 2, topo em 22.
	afirmar_igual(s.position + Vector2(LogoAnimado.FOLGA, LogoAnimado.FOLGA), Vector2(111, 22), "mesma posição do menu")
	l.queue_free()


func test_toca_ate_o_fim_e_vai_para_o_menu() -> void:
	var l := _logo()
	l.qps = 240.0  # acelera: o caminho é o mesmo
	l.segurar_no_fim = 0.05
	l.duracao_fade = 0.05
	await esperar_frames(3)
	afirmar(l.quadro_atual() > 0, "a animação anda")
	afirmar(l.get_node("Brasas").emitting or l.quadro_atual() < LogoAnimado.QUADRO_QUEBRA, "brasas a partir da quebra")
	var limite := 120
	while not l.acabou and limite > 0:
		await esperar_frames(1)
		limite -= 1
	afirmar(l.acabou and not l.pulou, "terminou sozinho")
	afirmar_igual(l.quadro_atual(), LogoAnimado.QUADROS - 1, "parou no logo limpo")
	afirmar(l.get_node("Brasas").emitting, "brasas acesas depois da quebra")
	afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_TITULO, "foi para o menu")
	l.queue_free()


func test_qualquer_tecla_ou_clique_pula() -> void:
	var eventos: Array[InputEvent] = []
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_A
	tecla.pressed = true
	eventos.append(tecla)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	eventos.append(esc)
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	eventos.append(clique)
	var botao := InputEventJoypadButton.new()
	botao.button_index = JOY_BUTTON_A
	botao.pressed = true
	eventos.append(botao)
	for e in eventos:
		var l := _logo()
		await esperar_frames(2)
		l._input(e)
		afirmar(l.pulou, "pulou com %s" % e.as_text())
		afirmar_igual(Ciclo.ultima_cena_pedida, Ciclo.CENA_TITULO, "foi para o menu")
		l.queue_free()
	# Movimento do mouse não pula.
	var l2 := _logo()
	await esperar_frames(2)
	l2._input(InputEventMouseMotion.new())
	afirmar(not l2.pulou, "mexer o mouse não pula")
	l2.queue_free()
	Ciclo.ultima_cena_pedida = ""
