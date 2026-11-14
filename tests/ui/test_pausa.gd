extends TestCase
## D-054: menu de pausa (Esc), Controles com teclas trocáveis e salvas, Opções, voltar à nave,
## sem barra de teclas na tela e atalhos de teste só em depuração.

const ARQUIVO_TESTE: String = "user://configuracoes_teste.cfg"


func _pausa() -> Node:
	return tree.root.get_node("Pausa")


func _config() -> Node:
	return tree.root.get_node("Config")


## Um "jogador" mínimo: a pausa só abre com alguém no grupo.
func _com_jogador() -> Node:
	var j := Node.new()
	j.add_to_group("jogadores")
	add_child(j)
	return j


func _limpar() -> void:
	_pausa().fechar()
	tree.paused = false
	_config().redefinir_sem_salvar()
	if FileAccess.file_exists(ARQUIVO_TESTE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_TESTE))


func test_esc_e_start_abrem_a_pausa() -> void:
	var tem_esc := false
	var tem_start := false
	for e in InputMap.action_get_events(&"pausa"):
		tem_esc = tem_esc or (e is InputEventKey and e.physical_keycode == KEY_ESCAPE)
		tem_start = tem_start or (e is InputEventJoypadButton and e.button_index == JOY_BUTTON_START)
	afirmar(tem_esc, "Esc pausa")
	afirmar(tem_start, "Start pausa")


func test_abre_pausa_o_jogo_e_continuar_volta() -> void:
	var p := _pausa()
	afirmar(not p.abrir(), "sem jogador na cena não abre")
	_com_jogador()
	afirmar(p.abrir(), "abre com jogador")
	afirmar(tree.paused, "jogo pausado")
	afirmar(p.visible, "menu visível")
	var textos: Array[String] = p.textos_dos_botoes()
	for esperado in ["Continuar", "Controles", "Opções"]:
		afirmar(textos.has(esperado), "botão %s" % esperado)
	afirmar(textos.has("Sair do jogo"), "Sair do jogo (fora da Web)")
	afirmar(p.ativar("Continuar"), "Continuar")
	afirmar(not p.esta_aberto() and not tree.paused, "Continuar fecha e despausa")
	_limpar()


func test_esc_volta_uma_tela_e_fecha_na_principal() -> void:
	var p := _pausa()
	_com_jogador()
	p.abrir()
	p.ativar("Controles")
	afirmar_igual(p.tela, p.Tela.CONTROLES, "abriu Controles")
	p.voltar()
	afirmar_igual(p.tela, p.Tela.PRINCIPAL, "Esc volta para a principal")
	p.voltar()
	afirmar(not p.esta_aberto() and not tree.paused, "Esc na principal fecha")
	_limpar()


func test_nao_abre_por_cima_de_outra_tela_que_pausou() -> void:
	_com_jogador()
	tree.paused = true  # ex.: diálogo ou oferta de dádiva aberta
	afirmar(not _pausa().abrir(), "não abre por cima")
	tree.paused = false
	_limpar()


func test_controles_mostram_e_trocam_a_tecla_e_salvam() -> void:
	var p := _pausa()
	var c := _config()
	_com_jogador()
	p.abrir()
	p.ativar("Controles")
	for acao: StringName in c.ACOES_TROCAVEIS:
		var b: Button = p.botao_da_acao(acao)
		afirmar(b != null, "linha de %s" % acao)
	afirmar_igual(p.botao_da_acao(&"atirar").text, "Botão esquerdo", "atirar mostra o botão do mouse")
	p.botao_da_acao(&"atirar").pressed.emit()
	afirmar_igual(p.esperando_acao, &"atirar", "esperando a tecla nova")
	afirmar_igual(p.botao_da_acao(&"atirar").text, "Aperte uma tecla…", "pede a tecla")
	var k := InputEventKey.new()
	k.physical_keycode = KEY_K
	k.pressed = true
	p.receber_tecla(k)
	afirmar_igual(p.esperando_acao, &"", "parou de esperar")
	afirmar_igual(c.texto_da_acao(&"atirar"), "K", "atirar agora é K")
	afirmar_igual(p.botao_da_acao(&"atirar").text, "K", "tela atualizada")
	afirmar(FileAccess.file_exists(ARQUIVO_TESTE), "salvou no arquivo")
	# Um Config novo, lendo o mesmo arquivo, volta com a tecla trocada.
	c.redefinir_sem_salvar()
	afirmar_igual(c.texto_da_acao(&"atirar"), "Botão esquerdo", "padrão em memória")
	c.carregar()
	afirmar_igual(c.texto_da_acao(&"atirar"), "K", "tecla salva voltou ao abrir o jogo")
	_limpar()


func test_tecla_ja_usada_troca_com_a_outra_acao_e_esc_e_reservado() -> void:
	var c := _config()
	var q := InputEventKey.new()
	q.physical_keycode = KEY_Q
	afirmar_igual(c.trocar_tecla(&"pular", q), &"granada", "Q era da granada: trocou")
	afirmar_igual(c.texto_da_acao(&"pular"), "Q", "pular = Q")
	afirmar_igual(c.texto_da_acao(&"granada"), "Espaço", "granada ficou com o Espaço")
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	afirmar_igual(c.trocar_tecla(&"dash", esc), &"reservada", "Esc é da pausa")
	afirmar_igual(c.texto_da_acao(&"dash"), "Shift", "dash continua no Shift")
	c.restaurar_teclas()
	afirmar_igual(c.texto_da_acao(&"pular"), "Espaço", "restaurar padrão")
	afirmar_igual(c.texto_da_acao(&"granada"), "Q", "restaurar padrão")
	_limpar()


func test_trocar_tecla_mantem_o_gamepad() -> void:
	var c := _config()
	var antes: int = 0
	for e in InputMap.action_get_events(&"pular"):
		antes += 1 if e is InputEventJoypadButton else 0
	var w := InputEventKey.new()
	w.physical_keycode = KEY_W
	c.trocar_tecla(&"pular", w)
	var depois: int = 0
	for e in InputMap.action_get_events(&"pular"):
		depois += 1 if e is InputEventJoypadButton else 0
	afirmar_igual(depois, antes, "o botão do gamepad continua")
	_limpar()


func test_opcoes_mudam_volume_e_acessibilidade_e_salvam() -> void:
	var p := _pausa()
	var c := _config()
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(1)
	p.abrir()
	p.ativar("Opções")
	afirmar_igual(p.tela, p.Tela.OPCOES, "abriu Opções")
	afirmar(p.textos_dos_botoes().has("Volume: 80%"), "volume começa em 80%")
	p.ativar("Volume")
	afirmar_proximo(c.volume, 0.9, 0.001, "volume subiu 10%")
	afirmar_proximo(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.9, 0.01, "aplicado no áudio")
	p.ativar("Mira automática")
	afirmar_igual(j.assistencias.modo_mira, Assistencias.ModoMira.ASSISTIDA, "mira assistida no jogador")
	p.ativar("Tiro automático")
	afirmar(j.assistencias.tiro_automatico, "tiro automático no jogador")
	afirmar(p.textos_dos_botoes().has("Tiro automático: Ligado"), "texto atualizado")
	var cfg := ConfigFile.new()
	afirmar_igual(cfg.load(ARQUIVO_TESTE), OK, "salvou")
	afirmar_igual(cfg.get_value("opcoes", "modo_mira", -1), 1, "mira salva")
	afirmar_igual(cfg.get_value("opcoes", "tiro_automatico", false), true, "tiro salvo")
	_limpar()


func test_voltar_a_nave_pede_confirmacao_e_abandona_a_run() -> void:
	var p := _pausa()
	var cena := Node.new()
	tree.root.add_child(cena)
	tree.current_scene = cena  # uma cena que não é a nave
	_com_jogador()
	p.abrir()
	afirmar(p.textos_dos_botoes().has("Voltar à nave"), "na run aparece Voltar à nave")
	p.ativar("Voltar à nave")
	afirmar_igual(p.tela, p.Tela.CONFIRMAR_SAIDA, "pede confirmação")
	p.ativar("Cancelar")
	afirmar_igual(p.tela, p.Tela.PRINCIPAL, "cancelar volta")
	p.ativar("Voltar à nave")
	p.ativar("Abandonar")
	afirmar(not p.esta_aberto() and not tree.paused, "fechou e despausou")
	afirmar_igual(Ciclo.resultado, "desistiu", "voltou para a nave")
	tree.current_scene = null
	cena.queue_free()
	Ciclo.resultado = ""
	_limpar()


func test_sem_barra_de_teclas_e_dica_so_no_tutorial() -> void:
	var hud: Node = instanciar("res://scenes/ui/hud.tscn")
	await esperar_frames(1)
	afirmar(hud.get_node_or_null("Ajuda") == null, "sem barra de teclas no HUD")
	afirmar(not hud.dica.visible, "dica escondida fora do tutorial")
	var dica: String = RunAto.dica_do_tutorial()
	for trecho in ["A D andar", "Espaço pular", "Botão esquerdo atirar", "Botão direito Grilhão", "Shift dash", "Q granada", "Esc pausa"]:
		afirmar(dica.contains(trecho), "dica tem \"%s\" (%s)" % [trecho, dica])
	var q := InputEventKey.new()
	q.physical_keycode = KEY_J
	_config().trocar_tecla(&"atirar", q)
	afirmar(RunAto.dica_do_tutorial().contains("J atirar"), "a dica usa a tecla escolhida")
	_limpar()


func test_atalhos_de_teste_so_em_depuracao() -> void:
	afirmar_igual(Depuracao.ativa(), OS.is_debug_build(), "segue o tipo de build")
	var workflow := FileAccess.get_file_as_string("res://.github/workflows/publicar.yml")
	afirmar(workflow.contains("--export-release") and not workflow.contains("--export-debug"),
			"a versão publicada é release (sem atalhos)")
	for arquivo in ["res://scripts/run/run_ato.gd", "res://scripts/salas/sala.gd"]:
		var codigo := FileAccess.get_file_as_string(arquivo)
		var antes_do_guarda: String = codigo.substr(0, codigo.find("func _atalhos_de_teste"))
		afirmar(not antes_do_guarda.contains("\"debug_"), "%s: atalhos só dentro de _atalhos_de_teste" % arquivo)
		afirmar(codigo.contains("if Depuracao.ativa():"), "%s: guarda de depuração" % arquivo)
