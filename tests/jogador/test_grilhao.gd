extends TestCase
## Grilhão, a Ferramenta do Ryker (D-016), com os números do GD-02 1.1 (D-027).
## Inclui o teste 1 da seção 7 do GD-02 (os três pesos).


func _grilhao(j: Jogador) -> Grilhao:
	return j.ferramenta as Grilhao


func test_ryker_tem_o_grilhao_como_ferramenta() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(1)
	afirmar(j.ferramenta is Grilhao, "Ferramenta do Ryker é o Grilhão")


func test_alcance_de_96_px_em_0_12_s() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	var g := _grilhao(j)
	var inicio: Vector2 = j.ponto_de_tiro()
	j.entrada.ferramenta_pressionada = true
	var frames: int = 0
	var mais_longe: float = 0.0
	while frames < 30:
		await esperar_frames(1)
		frames += 1
		mais_longe = maxf(mais_longe, g.ponta.distance_to(inicio))
		if g.estado != Grilhao.Estado.LANCANDO:
			break
	afirmar_proximo(mais_longe, 96.0, 0.5, "alcance")
	afirmar_proximo(frames / 60.0, 0.12, 0.02, "tempo até o alcance máximo")


func test_leve_e_puxado_e_atordoado() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.LEVE, Vector2(12, 24))
	await esperar_frames(3)
	j.entrada.ferramenta_pressionada = true
	var atordoou: bool = false
	for i in 40:
		await esperar_frames(1)
		if b.esta_atordoado():
			atordoou = true
			break
	afirmar(atordoou, "inimigo leve fica atordoado")
	var distancia: float = Unidades.em_tiles(absf(b.global_position.x - j.global_position.x))
	afirmar(distancia <= 2.0, "inimigo puxado para perto (%.2f tiles)" % distancia)
	afirmar_igual(b.vida.atual, 485, "o Grilhão causa 15 de dano")
	await esperar_frames(50)
	afirmar(b.esta_atordoado(), "atordoado por ~1 s")
	await esperar_frames(15)
	afirmar(not b.esta_atordoado(), "o atordoamento acaba")


func test_medio_com_protecao_perde_a_armadura_e_cambaleia() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.MEDIO, Vector2(32, 64), true)
	var x0: float = b.global_position.x
	await esperar_frames(3)
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(10)
	afirmar(not b.armadura_frontal, "armadura arrancada")
	afirmar(b.esta_atordoado(), "cambaleando")
	afirmar_proximo(b.global_position.x, x0, 0.5, "o médio não é puxado")
	afirmar_igual(b.vida.atual, 485, "15 de dano (a corrente não é reduzida pela armadura)")
	await esperar_frames(40)
	afirmar(not b.esta_atordoado(), "cambaleio curto (0,6 s)")


func test_pesado_puxa_o_ryker_com_invulnerabilidade_e_golpe_de_arena() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.PESADO, Vector2(40, 64))
	await esperar_frames(3)
	var x0: float = j.global_position.x
	var xb: float = b.global_position.x
	j.entrada.ferramenta_pressionada = true
	var invulneravel_no_caminho: bool = true
	var chegou: bool = false
	for i in 60:
		await esperar_frames(1)
		if j.esta_sendo_puxado() and not j.vida.esta_invulneravel():
			invulneravel_no_caminho = false
		if _grilhao(j).estado == Grilhao.Estado.PRONTO and i > 3:
			chegou = true
			break
	afirmar(chegou, "o puxão terminou")
	afirmar_proximo(b.global_position.x, xb, 0.5, "o pesado não se mexe")
	afirmar(j.global_position.x - x0 > CenarioTeste.tiles(3), "Ryker foi puxado até o pesado")
	afirmar(invulneravel_no_caminho, "invulnerável durante a puxada")
	afirmar(j.vida.esta_invulneravel(), "invulnerável logo depois de chegar")
	afirmar(j.golpe_de_arena_ativo(), "ganhou o Golpe de Arena")
	await esperar_frames(15)  # 0,25 s
	afirmar(not j.vida.esta_invulneravel(), "a invulnerabilidade extra é curta (0,2 s)")
	await esperar_frames(80)  # ~1,6 s no total
	afirmar(not j.golpe_de_arena_ativo(), "Golpe de Arena dura 1,5 s")


func test_ponto_de_ancoragem_puxa_o_ryker() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var gancho := PontoGancho.new()
	add_child(gancho)
	await esperar_frames(3)
	gancho.global_position = j.ponto_de_tiro() + Vector2(56, -56)
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
	afirmar(chegou, "Ryker chegou ao ponto de ancoragem (dist %.1f)" % j.ponto_de_tiro().distance_to(gancho.global_position))


func test_recarga_de_3s_ao_acertar_e_1s_ao_errar() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	await esperar_frames(3)
	var g := _grilhao(j)
	# Erro: nada no alcance.
	j.entrada.ferramenta_pressionada = true
	for i in 30:
		await esperar_frames(1)
		if g.estado == Grilhao.Estado.PRONTO:
			break
	afirmar_proximo(g.recarga_restante(), 1.0, 0.05, "recarga ao errar")
	await esperar_frames(62)
	afirmar(g.esta_pronto(), "pronto depois de 1 s")
	# Acerto num boneco médio.
	CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(4), 0))
	await esperar_frames(1)
	j.entrada.ferramenta_pressionada = true
	for i in 30:
		await esperar_frames(1)
		if g.estado == Grilhao.Estado.PRONTO:
			break
	afirmar_proximo(g.recarga_restante(), 3.0, 0.05, "recarga ao acertar começa quando a corrente volta")
	j.entrada.ferramenta_pressionada = true
	await esperar_frames(1)
	afirmar_igual(g.estado, Grilhao.Estado.PRONTO, "não lança durante a recarga")


func test_dash_solta_o_puxao() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.PESADO, Vector2(40, 64))
	await esperar_frames(3)
	j.entrada.ferramenta_pressionada = true
	for i in 12:
		await esperar_frames(1)
		if j.esta_sendo_puxado():
			break
	afirmar(j.esta_sendo_puxado(), "começou a ser puxado")
	j.entrada.direcao = Vector2i(-1, 0)
	j.entrada.dash_pressionado = true
	await esperar_frames(1)
	afirmar(not j.esta_sendo_puxado(), "o dash solta o Grilhão")
	afirmar(j.esta_em_dash(), "e o dash acontece")


func test_ponto_fraco_dobra_e_golpe_de_arena_dobra_de_novo() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(8), 0), Inimigo.Peso.PESADO, Vector2(40, 64))
	var pf := PontoFraco.new()
	b.add_child(pf)
	await esperar_frames(2)
	pf.receber_ataque(InfoDano.criar(10, j))
	afirmar_igual(b.vida.atual, 480, "ponto fraco: 2× (20)")
	j.ativar_golpe_de_arena(1.5)
	pf.receber_ataque(InfoDano.criar(10, j))
	afirmar_igual(b.vida.atual, 440, "com Golpe de Arena: 4× (40)")
	b.receber_ataque(InfoDano.criar(10, j))
	afirmar_igual(b.vida.atual, 430, "fora do ponto fraco, Golpe de Arena não muda nada")


func test_tiro_acerta_o_ponto_fraco() -> void:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	var b := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(8), 0), Inimigo.Peso.PESADO, Vector2(40, 64))
	await esperar_frames(3)
	var pf := PontoFraco.new()
	pf.tamanho = Vector2(16, 16)
	b.add_child(pf)
	pf.global_position = j.ponto_de_tiro() + Vector2(CenarioTeste.tiles(8) - 20.0, 0)
	await esperar_frames(2)
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	j.entrada.atirar_segurado = false
	await esperar_frames(20)
	afirmar_igual(b.vida.atual, 480, "o tiro no ponto fraco causa 20")
