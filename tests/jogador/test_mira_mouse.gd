extends TestCase
## D-052: mira livre em 360° pelo mouse (ou analógico direito), tiro no ângulo exato,
## pose do tronco na mais próxima das 8 direções, Grilhão no botão direito sem parar o tiro.


func _projeteis() -> Array[Projetil]:
	var lista: Array[Projetil] = []
	for filho in get_children():
		if filho is Projetil and not filho.is_queued_for_deletion():
			lista.append(filho)
	return lista


## Põe o "mouse" num ângulo (graus, 0 = direita, positivo = sentido horário na tela) a 80 px.
func _mirar_mouse(j: Jogador, graus: float) -> void:
	j.entrada.mira_por_ponto = true
	j.entrada.ponto_mira = j.ponto_de_tiro() + Vector2.RIGHT.rotated(deg_to_rad(graus)) * 80.0


func test_tiro_sai_no_angulo_exato_do_mouse() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var ultimo: Array[Projetil] = [null]
	j.atirou.connect(func(p: Projetil) -> void: ultimo[0] = p)
	await esperar_frames(3)
	for graus: float in [-30.0, -100.0, 160.0, 17.0]:
		ultimo[0] = null
		_mirar_mouse(j, graus)
		j.entrada.atirar_segurado = true
		for i in 12:
			await esperar_frames(1)
			if ultimo[0] != null:
				break
		j.entrada.atirar_segurado = false
		afirmar(ultimo[0] != null, "atirou a %.0f°" % graus)
		if ultimo[0] != null:
			var angulo: float = rad_to_deg(ultimo[0].velocidade.angle())
			afirmar(absf(angle_difference(deg_to_rad(angulo), deg_to_rad(graus))) < deg_to_rad(0.5),
					"tiro a %.1f°, mouse a %.0f°" % [angulo, graus])
		await esperar_frames(10)


func test_pose_e_a_mais_proxima_das_8_e_o_ryker_vira_para_o_mouse() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	var casos: Array = [[-10.0, Vector2i(1, 0)], [-55.0, Vector2i(1, -1)], [-80.0, Vector2i(0, -1)],
			[-150.0, Vector2i(-1, -1)], [175.0, Vector2i(-1, 0)]]
	for caso in casos:
		_mirar_mouse(j, caso[0])
		await esperar_frames(1)
		afirmar_igual(j.mira, caso[1], "pose para %.0f°" % caso[0])
		afirmar(j.mira_livre, "mira livre ativa")
	afirmar_igual(j.olhando, -1, "virou para o mouse à esquerda")
	_mirar_mouse(j, -20.0)
	await esperar_frames(1)
	afirmar_igual(j.olhando, 1, "virou de volta para a direita")


func test_no_chao_nao_existe_pose_reta_para_baixo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	_mirar_mouse(j, 90.0)
	await esperar_frames(1)
	afirmar(j.is_on_floor(), "no chão")
	afirmar(j.mira.x != 0 and j.mira.y == 1, "no chão a pose fica na diagonal para baixo")
	afirmar_proximo(j.direcao_mira().angle(), PI * 0.5, 0.01, "mas o tiro sai reto para baixo")


func test_andar_para_tras_mantem_a_mira_no_mouse() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(-1, 0)
	_mirar_mouse(j, 0.0)
	await esperar_frames(10)
	afirmar(j.velocity.x < 0.0, "anda para a esquerda")
	afirmar_igual(j.olhando, 1, "continua virado para o mouse")
	afirmar_proximo(j.direcao_mira().x, 1.0, 0.01, "mira para a direita")


func test_analogico_direito_mira_em_360_e_tem_prioridade() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	_mirar_mouse(j, 0.0)
	j.entrada.mira_analogica = Vector2.RIGHT.rotated(deg_to_rad(-135.0))
	await esperar_frames(1)
	afirmar_proximo(rad_to_deg(j.direcao_mira().angle()), -135.0, 0.1, "analógico manda")
	afirmar_igual(j.mira, Vector2i(-1, -1), "pose diagonal para cima à esquerda")


func test_sem_mouse_nem_analogico_vale_a_mira_de_8_direcoes() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(1, -1)
	await esperar_frames(1)
	afirmar(not j.mira_livre, "sem mira livre")
	afirmar_igual(j.mira, Vector2i(1, -1), "diagonal pelo teclado")
	afirmar_proximo(j.direcao_mira().angle(), -PI * 0.25, 0.01, "tiro na diagonal")


func test_grilhao_sai_na_direcao_do_mouse_sem_parar_o_tiro() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var tiros: Array[int] = [0]
	j.atirou.connect(func(_p: Projetil) -> void: tiros[0] += 1)
	await esperar_frames(3)
	var g := j.ferramenta as Grilhao
	_mirar_mouse(j, -40.0)
	j.entrada.atirar_segurado = true
	await esperar_frames(6)
	var antes: int = tiros[0]
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(2)
	afirmar(g.estado != Grilhao.Estado.PRONTO, "Grilhão lançado")
	var direcao_corrente: Vector2 = (g.ponta - j.ponto_de_tiro()).normalized()
	afirmar_proximo(rad_to_deg(direcao_corrente.angle()), -40.0, 1.0, "corrente no ângulo do mouse")
	await esperar_frames(38)
	j.entrada.atirar_segurado = false
	afirmar(tiros[0] - antes >= 2, "continuou atirando com o Grilhão no ar (%d tiros)" % (tiros[0] - antes))


func _tem_evento(acao: StringName, teste: Callable) -> bool:
	for e in InputMap.action_get_events(acao):
		if teste.call(e):
			return true
	return false


func _tecla(codigo: Key) -> Callable:
	return func(e: InputEvent) -> bool: return e is InputEventKey and e.physical_keycode == codigo


func _botao_mouse(botao: MouseButton) -> Callable:
	return func(e: InputEvent) -> bool: return e is InputEventMouseButton and e.button_index == botao


func test_teclas_padrao_da_d052() -> void:
	afirmar(_tem_evento(&"mover_esquerda", _tecla(KEY_A)), "A anda para a esquerda")
	afirmar(_tem_evento(&"mover_direita", _tecla(KEY_D)), "D anda para a direita")
	afirmar(_tem_evento(&"mirar_baixo", _tecla(KEY_S)), "S agacha")
	afirmar(_tem_evento(&"pular", _tecla(KEY_SPACE)), "Espaço pula")
	afirmar(not _tem_evento(&"pular", _tecla(KEY_W)), "W não pula")
	afirmar(_tem_evento(&"atirar", _botao_mouse(MOUSE_BUTTON_LEFT)), "botão esquerdo atira")
	afirmar(_tem_evento(&"ferramenta", _botao_mouse(MOUSE_BUTTON_RIGHT)), "botão direito = Grilhão")
	afirmar(_tem_evento(&"dash", _tecla(KEY_SHIFT)), "Shift = dash")
	afirmar(_tem_evento(&"granada", _tecla(KEY_Q)), "Q = granada")
	afirmar(_tem_evento(&"interagir", _tecla(KEY_E)), "E = interagir")
	var eixo := func(eixo_esperado: int) -> Callable:
		return func(e: InputEvent) -> bool: return e is InputEventJoypadMotion and e.axis == eixo_esperado
	for acao: StringName in [&"mira_esquerda", &"mira_direita"]:
		afirmar(_tem_evento(acao, eixo.call(JOY_AXIS_RIGHT_X)), "%s no analógico direito" % acao)
	for acao: StringName in [&"mira_cima", &"mira_baixo"]:
		afirmar(_tem_evento(acao, eixo.call(JOY_AXIS_RIGHT_Y)), "%s no analógico direito" % acao)
	afirmar(_tem_evento(&"atirar", eixo.call(JOY_AXIS_TRIGGER_RIGHT)), "RT atira (dá para mirar com o polegar)")


func test_entrada_local_troca_para_o_gamepad_e_guarda_a_ultima_direcao() -> void:
	var e := EntradaLocal.new()
	e.atualizar()
	afirmar_igual(e.dispositivo, EntradaLocal.Dispositivo.NENHUM, "começa na mira de 8 direções")
	afirmar(not e.mira_por_ponto and e.mira_analogica == Vector2.ZERO, "sem mira livre")
	Input.action_press(&"mira_cima", 1.0)
	e.atualizar()
	Input.action_release(&"mira_cima")
	afirmar_igual(e.dispositivo, EntradaLocal.Dispositivo.GAMEPAD, "analógico direito liga o gamepad")
	afirmar_proximo(e.mira_analogica.y, -1.0, 0.01, "mira para cima")
	e.atualizar()
	afirmar_proximo(e.mira_analogica.y, -1.0, 0.01, "ao soltar, continua na última direção")
	afirmar(not e.mira_por_ponto, "mouse parado não rouba a mira")
