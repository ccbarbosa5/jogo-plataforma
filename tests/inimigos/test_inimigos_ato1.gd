extends TestCase
## Inimigos do Ato 1 (GD-02 §4): Artilheiro, Muralha, Zangão, Cuspidor, Ninho e as elites
## Brutamontes e Ceifadora. Avisos, fichas de ataque, peso para o Grilhão e o banco de ondas.

const PASTA: String = "res://scenes/inimigos/"
const ENTRADA: int = 32  # frames da animação de entrada (0,5 s)


func _antes() -> Jogador:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	return CenarioTeste.criar_jogador(self)


func _criar(cena: String, posicao: Vector2) -> Inimigo:
	var i: Inimigo = (load(PASTA + cena + ".tscn") as PackedScene).instantiate()
	i.container_projeteis = self
	add_child(i)
	i.global_position = posicao
	return i


func _de_tipo(classe: String) -> Array[Node]:
	var lista: Array[Node] = []
	for f in get_children():
		if f.get_script() != null and f.get_script().get_global_name() == classe and not f.is_queued_for_deletion():
			lista.append(f)
	return lista


# --- Fichas da tabela do GD-02 ---

func test_fichas_dos_inimigos_batem_com_o_gd02() -> void:
	var esperado: Dictionary = {
		"artilheiro_kharn": [Vector2(32, 56), 80, Inimigo.Peso.MEDIO, Inimigo.Categoria.COMUM],
		"muralha": [Vector2(40, 64), 150, Inimigo.Peso.MEDIO, Inimigo.Categoria.COMUM],
		"zangao": [Vector2(12, 12), 10, Inimigo.Peso.LEVE, Inimigo.Categoria.COMUM],
		"cuspidor": [Vector2(20, 14), 25, Inimigo.Peso.LEVE, Inimigo.Categoria.COMUM],
		"ninho": [Vector2(48, 48), 200, Inimigo.Peso.PESADO, Inimigo.Categoria.COMUM],
		"brutamontes": [Vector2(48, 72), 400, Inimigo.Peso.PESADO, Inimigo.Categoria.ELITE],
		"ceifadora": [Vector2(32, 40), 250, Inimigo.Peso.MEDIO, Inimigo.Categoria.ELITE],
	}
	for nome: String in esperado:
		var i: Inimigo = (load(PASTA + nome + ".tscn") as PackedScene).instantiate()
		var e: Array = esperado[nome]
		afirmar_igual([i.tamanho, i.get_node("Vida").maxima, i.peso, i.categoria], e, nome)
		i.free()


func test_banco_de_ondas_so_usa_inimigos_que_existem() -> void:
	var banco := BancoOndas.new()
	banco.carregar()
	var tipos: Dictionary = {}
	for o in banco.ondas:
		for item: Dictionary in o["inimigos"]:
			tipos[item["tipo"]] = true
			afirmar(banco.custo_inimigo(item["tipo"]) > 0, "%s tem custo" % item["tipo"])
	for t: String in ["guerreiro", "artilheiro", "muralha", "zangao", "cuspidor", "ninho", "brutamontes", "ceifadora"]:
		afirmar(tipos.has(t), "%s está no banco de ondas" % t)
		afirmar(MontadorSala.CENAS_INIMIGOS.has(t) and ResourceLoader.exists(MontadorSala.CENAS_INIMIGOS[t]), "%s tem cena" % t)
	afirmar(not tipos.has("soldado") and not tipos.has("elite"), "provisórios saíram das ondas")


# --- Artilheiro Kharn ---

func test_artilheiro_morteiro_pesado_com_alvo_marcado() -> void:
	var j := _antes()
	var a: ArtilheiroKharn = _criar("artilheiro_kharn", Vector2(220, 0))
	var vida: int = j.vida.atual
	await esperar_frames(ENTRADA + 4)
	afirmar(a.esta_anunciando(), "anunciou o morteiro")
	afirmar(Combate.tem_ficha(a), "pegou ficha")
	afirmar(is_instance_valid(a.morteiro), "morteiro no ar")
	afirmar_proximo(a.morteiro.destino.x, j.global_position.x, 1.0, "alvo marcado onde o Ryker estava")
	afirmar_proximo(a.morteiro.duracao, 1.0, 0.001, "aviso de 1,0 s")
	await esperar_frames(64)
	afirmar_igual(j.vida.atual, vida - 2, "[PESADO]: 2 blocos")
	afirmar(not Combate.tem_ficha(a), "devolveu a ficha")


func test_artilheiro_mantem_distancia() -> void:
	var j := _antes()
	j.global_position = Vector2(-200, 0)
	var a: ArtilheiroKharn = _criar("artilheiro_kharn", Vector2(-120, 0))
	a.alcance = Vector2.ZERO  # só posicionar, sem atirar
	await esperar_frames(ENTRADA + 40)
	afirmar(a.global_position.x > -110.0, "recuou para longe do Ryker (x=%.0f)" % a.global_position.x)


# --- Muralha ---

func test_muralha_escudo_bloqueia_100_pela_frente() -> void:
	_antes()
	var m: Muralha = _criar("muralha", Vector2(200, 0))
	m.olhando = -1
	await esperar_frames(2)
	m.receber_ataque(InfoDano.criar(30, null, Vector2(1, 0)))  # vindo da esquerda, de frente
	afirmar_igual(m.vida.atual, 150, "escudo segura tudo pela frente")
	m.receber_ataque(InfoDano.criar(30, null, Vector2(-1, 0)))
	afirmar_igual(m.vida.atual, 120, "pelas costas passa")
	var explosao := InfoDano.criar(20, null, Vector2(1, 0))
	explosao.explosao = true
	m.receber_ataque(explosao)
	afirmar_igual(m.vida.atual, 100, "explosão passa (granada)")


func test_muralha_grilhao_arranca_o_escudo_e_derruba() -> void:
	_antes()
	var m: Muralha = _criar("muralha", Vector2(200, 0))
	await esperar_frames(2)
	afirmar(m.arrancar_protecao(), "Grilhão arranca o escudo")
	afirmar(not m.tem_escudo(), "sem escudo")
	afirmar(m.esta_atordoado(), "caiu")
	afirmar_proximo(m._timer_atordoado, 1.5, 0.05, "vulnerável por 1,5 s")
	m.olhando = -1
	m.receber_ataque(InfoDano.criar(30, null, Vector2(1, 0)))
	afirmar(m.vida.atual < 150, "agora a frente leva dano")


func test_muralha_investida_pesada_depois_do_aviso() -> void:
	var j := _antes()
	var m: Muralha = _criar("muralha", Vector2(120, 0))
	var vida: int = j.vida.atual
	await esperar_frames(ENTRADA + 3)
	afirmar(m.esta_anunciando() and not m.esta_investindo(), "aviso (rugido)")
	afirmar(Combate.tem_ficha(m), "ficha")
	await esperar_frames(46)
	afirmar(m.esta_investindo() or j.vida.atual < vida, "investida depois de 0,8 s")
	await esperar_frames(30)
	afirmar_igual(j.vida.atual, vida - 2, "[PESADO]: 2 blocos")


# --- Zangão ---

func test_zangao_voa_e_mergulha_depois_do_aviso() -> void:
	var j := _antes()
	var z: Zangao = _criar("zangao", Vector2(40, -60))
	z._proximo_ataque = 0.1
	var vida: int = j.vida.atual
	await esperar_frames(ENTRADA)
	afirmar(z.global_position.y < -20.0, "voa (não caiu)")
	var viu_aviso: bool = false
	var viu_mergulho: bool = false
	for i in 120:
		await esperar_frames(1)
		viu_aviso = viu_aviso or z.estado == Zangao.Estado.AVISO
		if z.estado == Zangao.Estado.MERGULHO:
			viu_mergulho = true
			afirmar(viu_aviso, "o aviso vem antes do mergulho")
		if j.vida.atual < vida:
			break
	afirmar(viu_mergulho, "mergulhou")
	afirmar(j.vida.atual < vida, "o mergulho acerta quem fica parado")


func test_zangao_e_leve_para_o_grilhao() -> void:
	_antes()
	var z: Zangao = _criar("zangao", Vector2(60, -40))
	afirmar_igual(z.peso, Inimigo.Peso.LEVE, "Leve: o Grilhão puxa")


# --- Cuspidor ---

func test_cuspidor_cusparada_deixa_poca_que_fere() -> void:
	var j := _antes()
	var c: Cuspidor = _criar("cuspidor", Vector2(130, 0))
	var vida: int = j.vida.atual
	await esperar_frames(ENTRADA + 3)
	afirmar(c.esta_anunciando(), "infla (aviso)")
	await esperar_frames(30)
	afirmar(not c.esta_anunciando(), "cuspiu depois de 0,5 s")
	await esperar_frames(50)
	var pocas := _de_tipo("PocaAcido")
	afirmar_igual(pocas.size(), 1, "poça de ácido no chão")
	afirmar(j.vida.atual < vida, "a poça fere quem está nela")
	j.global_position.x = -300
	await esperar_frames(200)
	afirmar(_de_tipo("PocaAcido").size() <= 1, "a poça some (3 s)")


# --- Ninho ---

func test_ninho_gera_zangoes_ate_6_e_tem_ponto_fraco() -> void:
	_antes()
	var n: Ninho = _criar("ninho", Vector2(200, 0))
	n._timer = 0.2
	await esperar_frames(ENTRADA + 14)
	afirmar(n.vivos() >= 1, "gerou um Zangão")
	for i in 10:
		n.gerar_zangao()
	afirmar_igual(n.vivos(), 6, "até 6 vivos")
	afirmar(n.gerar_zangao() == null, "não passa de 6")
	var pf: PontoFraco = n.get_node("PontoFraco")
	pf.receber_ataque(InfoDano.criar(10, null))
	afirmar_igual(n.vida.atual, 180, "ponto fraco: dobro de dano")
	afirmar_igual(n.peso, Inimigo.Peso.PESADO, "Pesado: o Grilhão puxa o Ryker")


# --- Brutamontes ---

func test_brutamontes_laser_antes_da_metralhadora() -> void:
	var j := _antes()
	var b: Brutamontes = _criar("brutamontes", Vector2(200, 0))
	b._proximo_e_pisao = false
	await esperar_frames(ENTRADA + 3)
	afirmar_igual(b.estado, Brutamontes.Estado.AVISO_METRALHADORA, "laser de mira")
	afirmar(Combate.tem_ficha(b), "ficha")
	await esperar_frames(40)
	afirmar_igual(b.estado, Brutamontes.Estado.AVISO_METRALHADORA, "ainda mirando (0,8 s)")
	await esperar_frames(12)
	afirmar_igual(b.estado, Brutamontes.Estado.METRALHADORA, "atira depois do aviso")
	var altura: float = j.global_position.y - b.ponto_do_cano().y
	afirmar(altura > 18.0 and altura < 28.0, "tiros na altura do peito: acerta em pé, passa agachado")


func test_brutamontes_pisao_pesado_desvia_com_pulo() -> void:
	var j := _antes()
	var vida: int = j.vida.atual
	OndaChoque.criar(self, Vector2(60, 0), -1.0, null)
	await esperar_frames(30)
	afirmar_igual(j.vida.atual, vida - 2, "onda de choque [PESADO] no chão")
	j.vida._timer_invulneravel = 0.0
	j.global_position = Vector2(200, -40)  # no ar
	OndaChoque.criar(self, Vector2(260, 0), -1.0, null)
	await esperar_frames(10)
	afirmar_igual(j.vida.atual, vida - 2, "no ar, a onda passa por baixo")


func test_brutamontes_pesado_com_tanque_nas_costas() -> void:
	_antes()
	var b: Brutamontes = _criar("brutamontes", Vector2(200, 0))
	await esperar_frames(2)
	b.olhando = -1
	b._posicionar_tanque()
	afirmar(b.ponto_fraco.position.x > 0.0, "olhando para a esquerda, o tanque fica à direita (costas)")
	afirmar_igual(b.peso, Inimigo.Peso.PESADO, "Pesado: o Grilhão puxa o Ryker")
	b.ponto_fraco.receber_ataque(InfoDano.criar(10, null, Vector2(-1, 0)))
	afirmar_igual(b.vida.atual, 380, "ponto fraco: dobro")


# --- Ceifadora ---

func test_ceifadora_tres_cortes_depois_do_aviso() -> void:
	var j := _antes()
	var c: Ceifadora = _criar("ceifadora", Vector2(56, 0))
	c.chance_sumir = 0.0
	var vida: int = j.vida.atual
	await esperar_frames(ENTRADA + 3)
	afirmar_igual(c.estado, Ceifadora.Estado.AVISO_CORTES, "lâminas brilham")
	await esperar_frames(28)
	afirmar(c.estado == Ceifadora.Estado.CORTES, "corta depois de 0,5 s")
	await esperar_frames(40)
	afirmar(j.vida.atual < vida, "os cortes acertam")


func test_ceifadora_some_e_reaparece_do_outro_lado() -> void:
	var j := _antes()
	var c: Ceifadora = _criar("ceifadora", Vector2(200, 0))
	await esperar_frames(ENTRADA)
	c.sumir(j)
	afirmar(c.esta_sumida(), "sumiu na parede")
	afirmar(c.ponto_reaparecer.x < j.global_position.x, "o sinal fica do outro lado do Ryker")
	afirmar(not c.receber_ataque(InfoDano.criar(10, null)), "sumida não leva dano")
	await esperar_frames(30)
	afirmar(c.esta_sumida(), "o sinal dura 0,6 s")
	await esperar_frames(10)
	afirmar(not c.esta_sumida(), "reapareceu")
	afirmar_proximo(c.global_position.x, c.ponto_reaparecer.x, 2.0, "no lugar do sinal")


func test_ceifadora_grilhao_atordoa_1_segundo() -> void:
	var j := _antes()
	var c: Ceifadora = _criar("ceifadora", Vector2(60, 0))
	await esperar_frames(2)
	(j.ferramenta as Grilhao)._ao_acertar(c)
	afirmar_proximo(c._timer_atordoado, 1.0, 0.05, "atordoada por 1,0 s")


# --- Fichas e zona de guerra ---

func test_sem_ficha_nao_anuncia() -> void:
	_antes()
	for i in 3:
		var portador := Node.new()
		add_child(portador)
		Combate.pedir_ficha(portador)
	var c: Cuspidor = _criar("cuspidor", Vector2(130, 0))
	await esperar_frames(ENTRADA + 30)
	afirmar(not c.esta_anunciando(), "teto de 3 ataques anunciados")
	Combate.reiniciar()


func test_zona_de_guerra_kharn_e_vesh_brigam() -> void:
	_antes()
	var g := CenarioTeste.criar_guerreiro(self, Vector2(-300, 0))
	g.ataca_faccao_rival = true
	var z: Zangao = _criar("zangao", Vector2(-200, -20))
	await esperar_frames(2)
	afirmar(g.pode_ferir(z), "Kharn pode ferir Vesh na zona de guerra")
	afirmar(not g.pode_ferir(g), "não fere a si mesmo")
	var morteiro_hit := ExplosaoInimiga.causar(self, z.centro(), 24.0, 2, g)
	afirmar(z in morteiro_hit or not z.esta_vivo(), "explosão Kharn fere Vesh")
