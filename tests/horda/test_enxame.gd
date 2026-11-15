extends TestCase
## GD-08 §2: inimigos de enxame (Roedor, Chacal, Zangão), contato com recuo e o pool.

const PASTA: String = "res://scenes/inimigos/"


func _antes() -> Jogador:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	return CenarioTeste.criar_jogador(self)


func _criar(cena: String, posicao: Vector2) -> InimigoEnxame:
	var i: InimigoEnxame = (load(PASTA + cena + ".tscn") as PackedScene).instantiate()
	i.container_projeteis = self
	add_child(i)
	i.global_position = posicao
	return i


func test_fichas_do_enxame() -> void:
	var esperado: Dictionary = {
		"roedor": [Vector2(10, 8), 12, 4.5, false, 1],
		"chacal": [Vector2(14, 10), 22, 6.0, false, 2],
		"zangao": [Vector2(12, 12), 8, 5.0, true, 1],
	}
	var prog := ProgressaoPersonagem.new("ryker")
	for nome: String in esperado:
		var i: InimigoEnxame = (load(PASTA + nome + ".tscn") as PackedScene).instantiate()
		afirmar_igual([i.tamanho, i.get_node("Vida").maxima, i.velocidade, i.voa, prog.xp_do_inimigo(i)], esperado[nome], nome)
		afirmar_igual(i.peso, Inimigo.Peso.LEVE, nome + " é Leve")
		afirmar_proximo(i.chance_creditos, 0.1, 0.001, nome + ": 10% de 1 Crédito")
		afirmar_igual(i.creditos, Vector2i(1, 1), nome + ": 1 Crédito")
		i.free()


func test_roedor_morre_com_um_tiro_da_mordida_e_o_chacal_com_dois() -> void:
	_antes()
	var r := _criar("roedor", Vector2(200, -10))
	var c := _criar("chacal", Vector2(300, -10))
	await esperar_frames(2)
	r.receber_ataque(InfoDano.criar(14))
	afirmar(not r.esta_vivo(), "Roedor: 1 tiro")
	c.receber_ataque(InfoDano.criar(14))
	afirmar(c.esta_vivo(), "Chacal aguenta 1")
	c.receber_ataque(InfoDano.criar(14))
	afirmar(not c.esta_vivo(), "Chacal: 2 tiros")


func test_depois_de_tocar_recua_1_tile_e_espera_meio_segundo() -> void:
	var j := _antes()
	var r := _criar("roedor", Vector2(40, -1))
	var vida: int = j.vida.atual
	var tocou: bool = false
	for i in 90:
		await esperar_frames(1)
		if r.esta_recuando():
			tocou = true
			break
	afirmar(tocou, "chegou e tocou")
	afirmar_igual(j.vida.atual, vida - 1, "1 bloco")
	var x0: float = r.global_position.x
	await esperar_frames(12)
	afirmar(r.global_position.x - x0 >= CenarioTeste.tiles(0.7), "recuou ~1 tile (%.0f px)" % (r.global_position.x - x0))
	afirmar(r.esta_recuando(), "ainda parado")
	j.vida._timer_invulneravel = 0.0  # mesmo sem invulnerabilidade, não morde de novo enquanto espera
	await esperar_frames(10)
	afirmar_igual(j.vida.atual, vida - 1, "sem dano em sequência")
	await esperar_frames(30)
	afirmar(not r.esta_recuando(), "voltou a correr depois de ~0,5 s")


func test_roedor_sobe_degrau_e_parede_curta() -> void:
	var j := _antes()
	j.global_position.x = 300
	CenarioTeste.criar_bloco(self, Vector2(100, -24), Vector2(400, 24))  # degrau de 1,5 tile
	var r := _criar("roedor", Vector2(20, -1))
	for i in 120:
		await esperar_frames(1)
		if r.global_position.y < -20.0 and r.global_position.x > 100.0:
			break
	afirmar(r.global_position.x > 100.0 and r.global_position.y < -20.0, "subiu o degrau (%.0f, %.0f)" % [r.global_position.x, r.global_position.y])


func test_chacal_anuncia_0_3_s_e_salta_sem_ficha() -> void:
	var j := _antes()
	var c: Chacal = _criar("chacal", Vector2(90, -1))
	c._proximo_salto = 0.0
	var quadros_aviso: int = 0
	var saltou: bool = false
	for i in 90:
		await esperar_frames(1)
		if c.estado == Chacal.Estado.AVISO:
			quadros_aviso += 1
		if c.estado == Chacal.Estado.SALTO:
			saltou = true
			break
	afirmar(saltou, "saltou")
	afirmar(quadros_aviso >= 16 and quadros_aviso <= 20, "aviso de 0,3 s (%d quadros)" % quadros_aviso)
	afirmar_igual(Combate.fichas_em_uso(), 0, "o salto não usa ficha")
	afirmar(c.velocity.y < 0.0 and signf(c.velocity.x) == signf(j.global_position.x - c.global_position.x), "arco até o jogador")


func test_fuga_vai_para_a_direita() -> void:
	_antes()
	var z := _criar("zangao", Vector2(100, -40))
	z.fugir()
	var x0: float = z.global_position.x
	await esperar_frames(30)
	afirmar(z.global_position.x > x0 + 30.0, "foge pela direita")


func test_pool_reaproveita_quem_morreu() -> void:
	_antes()
	var pool := PoolEnxame.new()
	add_child(pool)
	var r: InimigoEnxame = pool.pegar("roedor")
	add_child(r)
	r.global_position = Vector2(200, -1)
	await esperar_frames(2)
	r.receber_ataque(InfoDano.criar(99))
	await esperar_frames(2)
	afirmar(r.get_parent() == null, "saiu da árvore sem ser apagado")
	afirmar_igual(pool.livres("roedor"), 1, "voltou para o pool")
	var de_novo: InimigoEnxame = pool.pegar("roedor")
	afirmar_igual(de_novo, r, "a mesma instância")
	afirmar(de_novo.esta_vivo() and de_novo.vida.atual == 12, "vida cheia")
	add_child(de_novo)
	await esperar_frames(2)
	afirmar(de_novo.is_in_group("inimigos"), "volta ao grupo de inimigos")
	afirmar_igual([pool.criados, pool.reaproveitados], [1, 1], "1 criado, 1 reaproveitado")
