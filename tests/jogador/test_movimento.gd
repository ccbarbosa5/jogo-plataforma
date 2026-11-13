extends TestCase
## Movimento do Ryker contra os parâmetros do GD-01, seção 3.2.

var p: ParametrosJogador


func _preparar() -> Jogador:
	CenarioTeste.criar_chao(self)
	var jogador := CenarioTeste.criar_jogador(self)
	p = jogador.parametros
	return jogador


func test_corrida_atinge_7_tiles_por_segundo_quase_na_hora() -> void:
	var j := _preparar()
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(1, 0)
	await esperar_frames(5)
	afirmar_proximo(Unidades.em_tiles(j.velocity.x), p.velocidade_corrida, 0.01, "velocidade após 5 frames")
	await esperar_frames(30)
	afirmar_proximo(Unidades.em_tiles(j.velocity.x), 7.0, 0.01, "velocidade de corrida")


func test_pulo_segurado_atinge_3_5_tiles() -> void:
	var j := _preparar()
	await esperar_frames(5)
	var y0: float = j.global_position.y
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	var topo: float = y0
	for i in 70:
		await esperar_frames(1)
		topo = minf(topo, j.global_position.y)
	afirmar_proximo(Unidades.em_tiles(y0 - topo), 3.5, 0.1, "altura do pulo (tiles)")
	afirmar(j.is_on_floor(), "voltou ao chão")


func test_soltar_o_botao_corta_o_pulo() -> void:
	var j := _preparar()
	await esperar_frames(5)
	var y0: float = j.global_position.y
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(4)
	j.entrada.pular_segurado = false
	var topo: float = y0
	for i in 60:
		await esperar_frames(1)
		topo = minf(topo, j.global_position.y)
	var altura: float = Unidades.em_tiles(y0 - topo)
	afirmar(altura < 2.0 and altura > 0.3, "pulo curto deveria ficar entre 0,3 e 2 tiles, ficou %.2f" % altura)


func _sair_da_borda() -> Jogador:
	# Chão termina em x = 0; o jogador corre para a direita até cair.
	CenarioTeste.criar_chao(self, -500.0, 0.0)
	var j := CenarioTeste.criar_jogador(self, Vector2(-30, 0))
	p = j.parametros
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(1, 0)
	for i in 60:
		await esperar_frames(1)
		if not j.is_on_floor():
			break
	return j


func test_coyote_time_permite_pular_logo_depois_da_borda() -> void:
	var j: Jogador = await _sair_da_borda()
	await esperar_frames(3)  # 0,05 s fora do chão (< 0,1 s)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(1)
	afirmar(j.velocity.y < 0.0, "deveria pular dentro do coyote time")


func test_coyote_time_expira() -> void:
	var j: Jogador = await _sair_da_borda()
	await esperar_frames(12)  # 0,2 s fora do chão (> 0,1 s)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(1)
	afirmar(j.velocity.y > 0.0, "não deveria pular depois do coyote time")


func _cair_e_apertar_pulo(segundos_antes_de_tocar: float) -> Jogador:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self, Vector2(0, -CenarioTeste.tiles(4)))
	p = j.parametros
	for i in 120:
		await esperar_frames(1)
		var falta: float = -j.global_position.y
		if j.velocity.y > 0.0 and falta <= j.velocity.y * segundos_antes_de_tocar:
			break
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	return j


func test_buffer_de_pulo_pula_ao_tocar_o_chao() -> void:
	var j: Jogador = await _cair_e_apertar_pulo(0.06)
	var pulou: bool = false
	for i in 15:
		await esperar_frames(1)
		if j.velocity.y < 0.0:
			pulou = true
			break
	afirmar(pulou, "o pulo apertado pouco antes de tocar o chão deveria valer")


func test_pulo_apertado_cedo_demais_nao_vale() -> void:
	var j: Jogador = await _cair_e_apertar_pulo(0.25)
	var pulou: bool = false
	for i in 30:
		await esperar_frames(1)
		if j.velocity.y < 0.0:
			pulou = true
	afirmar(not pulou, "pulo apertado 0,25 s antes não deveria ficar guardado")


func test_dash_anda_3_tiles_com_invulnerabilidade() -> void:
	var j := _preparar()
	await esperar_frames(3)
	var x0: float = j.global_position.x
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	afirmar(j.esta_em_dash(), "dash começou")
	afirmar(j.vida.esta_invulneravel(), "invulnerável no começo do dash")
	afirmar(not j.receber_dano(1), "dano ignorado durante o dash")
	var frames: int = 1
	while j.esta_em_dash() and frames < 60:
		await esperar_frames(1)
		frames += 1
	afirmar_proximo(Unidades.em_tiles(j.global_position.x - x0), 3.0, 0.05, "distância do dash (tiles)")
	afirmar_proximo(frames / 60.0, 0.18, 0.02, "duração do dash (s)")
	await esperar_frames(3)
	afirmar(not j.vida.esta_invulneravel(), "invulnerabilidade do dash acaba (0,15 s)")
	afirmar_igual(j.vida.atual, 4, "vida intacta")


func test_dash_tem_1_carga_e_recarga_de_0_7s() -> void:
	var j := _preparar()
	await esperar_frames(3)
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	while j.esta_em_dash():
		await esperar_frames(1)
	# A recarga de 0,7 s conta a partir do fim do dash.
	afirmar_igual(j.cargas_dash, 0, "carga gasta")
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	afirmar(not j.esta_em_dash(), "sem carga, sem dash")
	await esperar_frames(36)  # ~0,62 s
	afirmar_igual(j.cargas_dash, 0, "ainda recarregando")
	await esperar_frames(8)  # ~0,75 s
	afirmar_igual(j.cargas_dash, 1, "carga recarregada")


func test_mira_em_8_direcoes() -> void:
	var j := _preparar()
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(0, -1)
	await esperar_frames(1)
	afirmar_igual(j.mira, Vector2i(0, -1), "cima")
	j.entrada.direcao = Vector2i(1, -1)
	await esperar_frames(1)
	afirmar_igual(j.mira, Vector2i(1, -1), "diagonal cima")
	j.entrada.direcao = Vector2i(0, 1)
	await esperar_frames(2)
	afirmar(j.agachado, "baixo no chão agacha")
	afirmar_igual(j.mira, Vector2i(1, 0), "agachado atira reto")
	j.entrada.direcao = Vector2i.ZERO
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(5)
	j.entrada.direcao = Vector2i(0, 1)
	await esperar_frames(1)
	afirmar(not j.is_on_floor(), "está no ar")
	afirmar_igual(j.mira, Vector2i(0, 1), "baixo no ar atira para baixo")
	j.entrada.direcao = Vector2i(-1, 1)
	await esperar_frames(1)
	afirmar_igual(j.mira, Vector2i(-1, 1), "diagonal baixo no ar")


func test_agachar_reduz_a_hitbox() -> void:
	var j := _preparar()
	await esperar_frames(3)
	var forma := j.forma.shape as RectangleShape2D
	var em_pe: float = forma.size.y
	j.entrada.direcao = Vector2i(0, 1)
	await esperar_frames(1)
	afirmar(forma.size.y < em_pe, "hitbox menor agachado")


func test_travar_mira_para_e_mira_livre() -> void:
	var j := _preparar()
	await esperar_frames(3)
	j.entrada.travar_mira_segurado = true
	j.entrada.direcao = Vector2i(1, -1)
	var x0: float = j.global_position.x
	await esperar_frames(10)
	afirmar_proximo(j.global_position.x, x0, 0.01, "não anda com a mira travada")
	afirmar_igual(j.mira, Vector2i(1, -1), "mira diagonal travada")
	j.entrada.direcao = Vector2i(-1, 1)
	await esperar_frames(1)
	afirmar_igual(j.mira, Vector2i(-1, 1), "diagonal para baixo travado no chão")
	afirmar(not j.agachado, "travado não agacha")


func test_baixo_e_pulo_desce_da_plataforma() -> void:
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_bloco(self, Vector2(-100, -CenarioTeste.tiles(3)), Vector2(200, 8), true)
	var j := CenarioTeste.criar_jogador(self, Vector2(0, -CenarioTeste.tiles(3) - 1.0))
	await esperar_frames(5)
	afirmar(j.is_on_floor(), "em pé na plataforma")
	j.entrada.direcao = Vector2i(0, 1)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(40)
	afirmar(j.global_position.y > -1.0, "caiu até o chão, y=%.1f" % j.global_position.y)


func test_sobe_na_plataforma_por_baixo() -> void:
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_bloco(self, Vector2(-100, -CenarioTeste.tiles(2.5)), Vector2(200, 8), true)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	j.entrada.pular_pressionado = true
	j.entrada.pular_segurado = true
	await esperar_frames(70)
	afirmar_proximo(j.global_position.y, -CenarioTeste.tiles(2.5), 1.0, "parou em cima da plataforma")
