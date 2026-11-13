extends TestCase
## Regras de combate do GD-02, seção 7 (testes 2, 3, 4, 6 e 7).


func _boneco(armadura: bool = false, vida: int = 1000) -> Boneco:
	CenarioTeste.criar_chao(self)
	var b := CenarioTeste.criar_boneco(self, Vector2.ZERO, Inimigo.Peso.MEDIO, Vector2(32, 64), armadura, vida)
	b.olhando = -1  # olha para a esquerda: a frente dele é o lado esquerdo
	return b


func test_armadura_frontal_reduz_50_por_cento_so_pela_frente() -> void:
	var b := _boneco(true)
	await esperar_frames(2)
	b.receber_ataque(InfoDano.criar(20, null, Vector2.RIGHT))  # vem da esquerda, de frente
	afirmar_igual(b.vida.atual, 990, "pela frente: 50%")
	b.receber_ataque(InfoDano.criar(20, null, Vector2.LEFT))  # vem da direita, pelas costas
	afirmar_igual(b.vida.atual, 970, "pelas costas: dano cheio")
	var explosao := InfoDano.criar(20, null, Vector2.RIGHT)
	explosao.explosao = true
	b.receber_ataque(explosao)
	afirmar_igual(b.vida.atual, 950, "explosão ignora a armadura")
	var golpe := InfoDano.criar(20, null, Vector2.RIGHT)
	golpe.corpo_a_corpo = true
	b.receber_ataque(golpe)
	afirmar_igual(b.vida.atual, 930, "corpo a corpo ignora a armadura")


func test_abalo_100_atordoa_e_zera() -> void:
	var b := _boneco()
	await esperar_frames(2)
	var info := InfoDano.criar(1)
	info.abalo = 60.0
	b.receber_ataque(info)
	afirmar(not b.esta_atordoado(), "60 de Abalo ainda não atordoa")
	b.receber_ataque(info)
	afirmar(b.esta_atordoado(), "passou de 100: atordoado")
	afirmar_proximo(b.abalo, 0.0, 0.001, "Abalo zera depois do atordoamento")
	await esperar_frames(84)  # 1,4 s
	afirmar(b.esta_atordoado(), "comum fica 1,5 s atordoado")
	await esperar_frames(8)
	afirmar(not b.esta_atordoado(), "acabou")


func test_atordoado_pelo_abalo_leva_25_por_cento_a_mais() -> void:
	var b := _boneco()
	await esperar_frames(2)
	b.adicionar_abalo(100.0)
	b.receber_ataque(InfoDano.criar(20))
	afirmar_igual(b.vida.atual, 975, "20 × 1,25 = 25")


func test_abalo_cai_20_por_segundo_sem_golpes() -> void:
	var b := _boneco()
	await esperar_frames(2)
	b.adicionar_abalo(50.0)
	await esperar_frames(30)  # 0,5 s de espera antes de cair
	afirmar(b.abalo > 49.0, "ainda não caiu")
	await esperar_frames(60)
	afirmar_proximo(b.abalo, 30.0, 1.5, "caiu ~20 em 1 s")


func test_abalo_de_elite_e_chefe_atordoa_menos() -> void:
	var b := _boneco()
	b.categoria = Inimigo.Categoria.CHEFE
	await esperar_frames(2)
	b.adicionar_abalo(100.0)
	await esperar_frames(22)  # 0,37 s
	afirmar(b.esta_atordoado(), "chefe atordoado")
	await esperar_frames(4)  # 0,43 s
	afirmar(not b.esta_atordoado(), "chefe: só 0,4 s")


func test_acido_acumula_ate_5_e_renova_a_duracao() -> void:
	var b := _boneco()
	await esperar_frames(2)
	b.adicionar_acido(3)
	afirmar_igual(b.acidos, 3, "3 acúmulos")
	b.adicionar_acido(4)
	afirmar_igual(b.acidos, 5, "máximo de 5")
	await esperar_frames(150)  # 2,5 s
	b.adicionar_acido(1)  # renova
	await esperar_frames(150)  # 5 s desde o primeiro, 2,5 s desde a renovação
	afirmar_igual(b.acidos, 5, "renovou a duração")
	await esperar_frames(100)
	afirmar_igual(b.acidos, 0, "acabou 4 s depois da última renovação")


func test_acido_causa_3_por_segundo_por_acumulo() -> void:
	var b := _boneco()
	await esperar_frames(2)
	b.adicionar_acido(5)
	await esperar_frames(61)
	afirmar_igual(b.vida.atual, 985, "5 acúmulos × 3 = 15 no primeiro segundo")


func test_acido_reduz_a_armadura() -> void:
	var b := _boneco(true)
	await esperar_frames(2)
	b.adicionar_acido(5)
	b.receber_ataque(InfoDano.criar(20, null, Vector2.RIGHT))
	# Armadura: 50% × (1 − 5 × 10%) = 25% de redução → 15 de dano.
	afirmar_igual(b.vida.atual, 985, "armadura enfraquecida pelo Ácido")


func test_teto_de_3_ataques_anunciados() -> void:
	# GD-02, seção 7, teste 6.
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_jogador(self)
	var guerreiros: Array[GuerreiroCla] = []
	for i in 5:
		guerreiros.append(CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(8 + i * 2.5), 0)))
	var maximo: int = 0
	var anunciaram: Dictionary = {}
	for f in 360:  # 6 s
		await esperar_frames(1)
		var em_ataque: int = 0
		for g in guerreiros:
			if is_instance_valid(g) and (g.esta_anunciando() or g.estado == GuerreiroCla.Estado.RAJADA):
				em_ataque += 1
				anunciaram[g] = true
		maximo = maxi(maximo, em_ataque)
		afirmar(Combate.fichas_em_uso() <= 3, "nunca mais de 3 fichas")
	afirmar_igual(maximo, 3, "no máximo 3 ataques ao mesmo tempo")
	afirmar_igual(anunciaram.size(), 5, "os outros esperam e atacam depois")
	Combate.reiniciar()


func test_morte_e_atordoamento_devolvem_a_ficha() -> void:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	CenarioTeste.criar_jogador(self)
	var g := CenarioTeste.criar_guerreiro(self, Vector2(CenarioTeste.tiles(8), 0))
	await esperar_frames(3)
	afirmar(Combate.tem_ficha(g), "pegou ficha para atacar")
	g.atordoar(1.0)
	afirmar(not Combate.tem_ficha(g), "atordoado devolve a ficha")
	afirmar(not g.esta_anunciando(), "aviso cancelado")
	await esperar_frames(170)  # 1 s atordoado + 1,6 s de descanso
	afirmar(Combate.tem_ficha(g), "pegou de novo depois do atordoamento")
	g.receber_ataque(InfoDano.criar(999))
	await esperar_frames(1)
	afirmar_igual(Combate.fichas_em_uso(), 0, "morte devolve a ficha")
	Combate.reiniciar()


func test_upgrade_substitui_no_slot_e_passivos_acumulam() -> void:
	# GD-02, seção 7, teste 7.
	var u := UpgradesJogador.new()
	var municao := DadosUpgrade.criar(&"municao_de_cla", DadosUpgrade.Slot.TIRO, &"kharn")
	var ferrao := DadosUpgrade.criar(&"ferrao_partido", DadosUpgrade.Slot.TIRO, &"vesh")
	afirmar(u.adicionar(municao) == null, "slot vazio")
	afirmar(u.adicionar(ferrao) == municao, "o novo substitui o anterior no mesmo slot")
	afirmar(u.no_slot(DadosUpgrade.Slot.TIRO) == ferrao, "Tiro agora é Ferrão Partido")
	afirmar(not u.tem(&"municao_de_cla"), "o substituído saiu")
	u.adicionar(DadosUpgrade.criar(&"couro_de_arena", DadosUpgrade.Slot.PASSIVO, &"kharn"))
	u.adicionar(DadosUpgrade.criar(&"carne_mole", DadosUpgrade.Slot.PASSIVO, &"vesh"))
	afirmar_igual(u.passivos.size(), 2, "Passivos se acumulam")
	afirmar_igual(u.todos().size(), 3, "1 Tiro + 2 Passivos")


func test_upgrade_de_alianca_exige_pre_requisitos() -> void:
	var u := UpgradesJogador.new()
	var requisitos: Array[StringName] = [&"carga_de_cerco", &"ovo_de_ninhada"]
	var alianca := DadosUpgrade.criar(&"bomba_de_ninhada", DadosUpgrade.Slot.PASSIVO, &"alianca", requisitos)
	afirmar(not u.pode_receber(alianca), "sem os pré-requisitos")
	u.adicionar(alianca)
	afirmar(not u.tem(&"bomba_de_ninhada"), "não entrou")
	u.adicionar(DadosUpgrade.criar(&"carga_de_cerco", DadosUpgrade.Slot.GRANADA, &"kharn"))
	afirmar(not u.pode_receber(alianca), "falta um")
	u.adicionar(DadosUpgrade.criar(&"ovo_de_ninhada", DadosUpgrade.Slot.GRANADA, &"vesh"))
	afirmar(not u.pode_receber(alianca), "Ovo substituiu Carga de Cerco no slot de Granada")
