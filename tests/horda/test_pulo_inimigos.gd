extends TestCase
## D-071: inimigos de chão pulam, sobem atrás do Ryker e nunca ficam presos.


func _criar(cena: String, posicao: Vector2) -> Inimigo:
	var i: Inimigo = (load("res://scenes/inimigos/%s.tscn" % cena) as PackedScene).instantiate()
	i.container_projeteis = self
	add_child(i)
	i.global_position = posicao
	return i


func _antes() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)


func test_padroes_de_pulo_da_dir() -> void:
	var r: Inimigo = (load("res://scenes/inimigos/roedor.tscn") as PackedScene).instantiate()
	var c: Inimigo = (load("res://scenes/inimigos/chacal.tscn") as PackedScene).instantiate()
	var g: Inimigo = (load("res://scenes/inimigos/guerreiro_cla.tscn") as PackedScene).instantiate()
	var z: Inimigo = (load("res://scenes/inimigos/zangao.tscn") as PackedScene).instantiate()
	afirmar(r.pulo_tiles < c.pulo_tiles and r.sobe_plataformas and c.sobe_plataformas, "Roedor pula baixo; Chacal pula alto; os dois sobem")
	afirmar(c.pulo_tiles >= 3.0, "Chacal vence o degrau máximo das salas (3 tiles)")
	afirmar(g.pulo_tiles > 0.0 and g.pulo_tiles <= 2.0 and not g.sobe_plataformas, "pesado: só obstáculos baixos (2 tiles)")
	afirmar(z.voa, "o Zangão voa")
	for i in [r, c, g, z]:
		i.free()


func test_chacal_sobe_na_plataforma_atras_do_ryker() -> void:
	_antes()
	CenarioTeste.criar_bloco(self, Vector2(60, -48), Vector2(120, 8), true)  # 3 tiles acima
	var j := CenarioTeste.criar_jogador(self, Vector2(120, -49))
	j.vida.tornar_invulneravel(99.0)
	var c: Chacal = _criar("chacal", Vector2(-80, -1))
	c._proximo_salto = 99.0  # sem o salto de ataque: só a perseguição
	var subiu: bool = false
	for k in 240:
		await esperar_frames(1)
		c._proximo_salto = 99.0
		if c.is_on_floor() and c.global_position.y < -40.0:
			subiu = true
			break
	afirmar(subiu, "o Chacal subiu na plataforma (y = %.0f)" % c.global_position.y)


func test_roedor_pula_buraco_pequeno() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_bloco(self, Vector2(-200, 0), Vector2(200, 32))
	CenarioTeste.criar_bloco(self, Vector2(24, 0), Vector2(400, 32))  # buraco de 1,5 tile
	var j := CenarioTeste.criar_jogador(self, Vector2(200, -1))
	j.vida.tornar_invulneravel(99.0)
	var r: Inimigo = _criar("roedor", Vector2(-80, -1))
	for k in 120:
		await esperar_frames(1)
		if r.global_position.x > 40.0:
			break
	afirmar(r.global_position.x > 40.0 and r.global_position.y < 20.0, "atravessou o buraco pulando")


func test_pesado_pula_obstaculo_baixo() -> void:
	_antes()
	CenarioTeste.criar_bloco(self, Vector2(0, -16), Vector2(16, 16))  # caixa de 1 tile
	var j := CenarioTeste.criar_jogador(self, Vector2(300, -1))
	j.vida.tornar_invulneravel(99.0)
	var g: Inimigo = _criar("guerreiro_cla", Vector2(-40, -1))
	g.alcance_ataque = Vector2(1, 1)  # só anda
	g.tempo_preso_mudar_rota = 99.0
	for k in 360:
		await esperar_frames(1)
		Combate.reiniciar()  # sem fichas: ele só anda
		if g.global_position.x > 30.0:
			break

	afirmar(g.global_position.x > 30.0, "passou da caixa (x = %.0f)" % g.global_position.x)


func test_pesado_diante_de_obstaculo_alto_nao_fica_parado() -> void:
	_antes()
	CenarioTeste.criar_bloco(self, Vector2(0, -96), Vector2(16, 96))  # parede de 6 tiles
	var j := CenarioTeste.criar_jogador(self, Vector2(300, -1))
	j.vida.tornar_invulneravel(99.0)
	var g: Inimigo = _criar("guerreiro_cla", Vector2(-60, -1))
	g.alcance_ataque = Vector2(1, 1)  # só anda
	var parado: float = 0.0
	var maior: float = 0.0
	var mudou_rota: bool = false
	var x_antes: float = g.global_position.x
	for k in 360:
		await esperar_frames(1)
		Combate.reiniciar()
		if absf(g.global_position.x - x_antes) < 0.2:
			parado += 1.0 / 60.0
		else:
			parado = 0.0
		maior = maxf(maior, parado)
		x_antes = g.global_position.x
		mudou_rota = mudou_rota or g._timer_desvio > 0.0

	afirmar(mudou_rota, "tentou outra rota")
	afirmar(maior < 3.0, "nunca ficou parado 3 s (maior: %.1f s)" % maior)


func test_enxame_preso_fora_da_tela_volta_ao_pool() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self, -2000.0, 4000.0)
	CenarioTeste.criar_bloco(self, Vector2(2000, -200), Vector2(16, 200))  # paredão alto
	var j := CenarioTeste.criar_jogador(self, Vector2(2400, -1))
	j.vida.tornar_invulneravel(99.0)
	var pool := PoolEnxame.new()
	add_child(pool)
	var r: InimigoEnxame = pool.pegar("roedor")
	add_child(r)
	r.global_position = Vector2(1960, -1)  # longe da câmera (fora da tela)
	for k in 300:
		await esperar_frames(1)
		if r.get_parent() == null:
			break
	afirmar(r.get_parent() == null and pool.livres("roedor") == 1, "sumiu e voltou ao pool")
