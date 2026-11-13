extends TestCase
## Grilhão, a Ferramenta do Ryker (D-016).


func _grilhao(j: Jogador) -> Grilhao:
	return j.ferramenta as Grilhao


func test_ryker_tem_o_grilhao_como_ferramenta() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(1)
	afirmar(j.ferramenta is Grilhao, "Ferramenta do Ryker é o Grilhão")


func test_puxa_e_atordoa_inimigo_leve() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var s := CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(5), 0))
	await esperar_frames(3)
	j.entrada.ferramenta_pressionada = true
	var atordoou: bool = false
	for i in 40:
		await esperar_frames(1)
		if s.esta_atordoado():
			atordoou = true
			break
	afirmar(atordoou, "inimigo leve fica atordoado")
	var distancia: float = Unidades.em_tiles(absf(s.global_position.x - j.global_position.x))
	afirmar(distancia <= 2.0, "inimigo puxado para perto (%.2f tiles)" % distancia)
	afirmar_igual(s.vida.atual, 2, "o gancho causa 1 de dano")
	afirmar(not s.esta_anunciando(), "atordoado não anuncia ataque")


func test_inimigo_pesado_puxa_o_ryker() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var s := CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(6), 0), true)
	s.tempo_aviso = 99.0  # isola o teste do tiro do soldado
	await esperar_frames(3)
	var x0: float = j.global_position.x
	var xs: float = s.global_position.x
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(40)
	afirmar_proximo(s.global_position.x, xs, 1.0, "o pesado não se mexe")
	afirmar(j.global_position.x - x0 > CenarioTeste.tiles(4), "Ryker foi puxado até o pesado")
	afirmar_igual(j.vida.atual, 4, "chega perto sem encostar (sem dano de contato)")


func test_ponto_de_gancho_puxa_o_ryker() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var gancho := PontoGancho.new()
	add_child(gancho)
	await esperar_frames(3)
	gancho.global_position = j.ponto_de_tiro() + Vector2(64, -64)
	await esperar_frames(1)
	j.entrada.travar_mira_segurado = true
	j.entrada.direcao = Vector2i(1, -1)
	await esperar_frames(1)
	j.entrada.ferramenta_pressionada = true
	var chegou: bool = false
	for i in 40:
		await esperar_frames(1)
		if j.ponto_de_tiro().distance_to(gancho.global_position) < 4.0:
			chegou = true
			break
	afirmar(chegou, "Ryker chegou ao ponto de gancho (dist %.1f)" % j.ponto_de_tiro().distance_to(gancho.global_position))


func test_parede_faz_a_corrente_voltar_e_ha_recarga() -> void:
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_bloco(self, Vector2(CenarioTeste.tiles(3), -100), Vector2(16, 100))
	var j := CenarioTeste.criar_jogador(self)
	var g: Grilhao = null
	await esperar_frames(3)
	g = _grilhao(j)
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(2)
	afirmar(g.estado != Grilhao.Estado.PRONTO, "lançou")
	for i in 30:
		await esperar_frames(1)
		if g.estado == Grilhao.Estado.PRONTO:
			break
	afirmar_igual(g.estado, Grilhao.Estado.PRONTO, "voltou")
	afirmar(not g.esta_pronto(), "em recarga")
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(1)
	afirmar_igual(g.estado, Grilhao.Estado.PRONTO, "não lança durante a recarga")
	await esperar_frames(75)  # 1,25 s
	afirmar(g.esta_pronto(), "recarga terminou")


func test_dash_solta_o_puxao() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_soldado(self, Vector2(CenarioTeste.tiles(6), 0), true)
	await esperar_frames(3)
	j.entrada.ferramenta_pressionada = true
	for i in 10:
		await esperar_frames(1)
		if j.esta_sendo_puxado():
			break
	afirmar(j.esta_sendo_puxado(), "começou a ser puxado")
	j.entrada.direcao = Vector2i(-1, 0)
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	afirmar(not j.esta_sendo_puxado(), "o dash solta o Grilhão")
	afirmar(j.esta_em_dash(), "e o dash acontece")
