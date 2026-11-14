extends TestCase
## Upgrades de facção do VS (GD-02 §6): os 10 Kharn e os 10 Vesh, cobrindo os 6 slots,
## a raridade, o gerador de ofertas e a tela de escolha com as falas das patronas.

const KHARN: String = "res://scenes/upgrades/kharn.tres"
const VESH: String = "res://scenes/upgrades/vesh.tres"
const CENA_CAIXA: String = "res://scenes/ui/caixa_dialogo.tscn"
const R := DadosUpgrade.Raridade


func _modelo(id: StringName) -> DadosUpgrade:
	for caminho in [KHARN, VESH]:
		for u: DadosUpgrade in (load(caminho) as CatalogoFaccao).upgrades:
			if u.id == id:
				return u
	return null


func _dar(j: Jogador, id: StringName, raridade: DadosUpgrade.Raridade = R.COMUM) -> DadosUpgrade:
	var u: DadosUpgrade = _modelo(id).com_raridade(raridade)
	j.receber_upgrade(u)
	return u


func _jogador() -> Jogador:
	CenarioTeste.criar_chao(self)
	return CenarioTeste.criar_jogador(self)


func _nos(classe: String) -> Array[Node]:
	var lista: Array[Node] = []
	for f in get_children():
		if f.get_script() != null and f.get_script().get_global_name() == classe and not f.is_queued_for_deletion():
			lista.append(f)
	return lista


func _um_disparo(j: Jogador) -> void:
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	j.entrada.atirar_segurado = false


# --- Catálogos e ofertas ---

func test_catalogos_tem_10_upgrades_nos_6_slots() -> void:
	var esperado: Array[int] = [2, 1, 1, 1, 1, 4]  # Tiro, Granada, Dash, Ferramenta, Chamado, Passivo
	for caminho in [KHARN, VESH]:
		var c: CatalogoFaccao = load(caminho)
		afirmar_igual(c.upgrades.size(), 10, "%s: 10 upgrades" % c.nome)
		var por_slot: Array[int] = [0, 0, 0, 0, 0, 0]
		var bloqueados: int = 0
		for u in c.upgrades:
			por_slot[u.slot] += 1
			afirmar_igual(u.faccao, c.faccao, "%s é da facção" % u.nome)
			afirmar_igual(u.valores.size(), 3, "%s: Comum, Raro e Épico" % u.nome)
			if u.bloqueado_no_inicio:
				bloqueados += 1
		afirmar_igual(por_slot, esperado, "%s: slots" % c.nome)
		afirmar_igual(bloqueados, 3, "%s: 3 bloqueados até os Arquivos" % c.nome)


func test_raridade_muda_o_valor_e_o_texto() -> void:
	var m: DadosUpgrade = _modelo(&"honra_do_campeao")
	afirmar_proximo(m.com_raridade(R.COMUM).valor(), 0.15, 0.001, "Comum")
	afirmar_proximo(m.com_raridade(R.EPICO).valor(), 0.35, 0.001, "Épico")
	afirmar(m.com_raridade(R.RARO).texto().contains("+25%"), "texto com o valor da raridade")
	afirmar_igual(m.raridade, R.COMUM, "o modelo do catálogo não muda")
	afirmar(_modelo(&"couro_de_arena").com_raridade(R.RARO).texto().contains("40 s"), "Couro Raro recarrega em 40 s")


func test_textos_dos_upgrades_desenham_com_a_fonte() -> void:
	var faltando: Dictionary = {}
	for caminho in [KHARN, VESH]:
		for u: DadosUpgrade in (load(caminho) as CatalogoFaccao).upgrades:
			for t in [u.nome, u.com_raridade(R.EPICO).texto()]:
				for c in t:
					if c.unicode_at(0) > 32 and not Fontes.texto().has_char(c.unicode_at(0)):
						faltando[c] = true
	afirmar(faltando.is_empty(), "caracteres sem desenho: %s" % "".join(faltando.keys()))


func test_oferta_tem_3_opcoes_liberadas_e_sem_repetir() -> void:
	var cat: CatalogoFaccao = load(KHARN)
	var ups := UpgradesJogador.new()
	var progresso := DadosProgresso.new()
	var rng := RandomNumberGenerator.new()
	ups.adicionar(_modelo(&"honra_do_campeao"))
	for semente in 50:
		rng.seed = semente
		var oferta := GeradorOfertas.gerar(cat, ups, rng, progresso)
		afirmar_igual(oferta.size(), 3, "3 opções")
		var ids: Array[StringName] = []
		for u in oferta:
			afirmar(not u.bloqueado_no_inicio, "%s ainda bloqueado" % u.nome)
			afirmar(u.id != &"honra_do_campeao", "não oferece o que já tem")
			afirmar(not u.id in ids, "sem repetir")
			ids.append(u.id)
	progresso.definir_flag("arquivo_calibre_pesado")
	afirmar(_modelo(&"calibre_pesado").liberado(progresso), "liberado pelos Arquivos")
	progresso.free()


func test_raridade_70_25_5_e_elite_raro_ou_melhor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var contagem: Array[int] = [0, 0, 0]
	for i in 4000:
		contagem[GeradorOfertas.sortear_raridade(rng)] += 1
	afirmar_proximo(contagem[0] / 4000.0, 0.70, 0.03, "Comum 70%")
	afirmar_proximo(contagem[1] / 4000.0, 0.25, 0.03, "Raro 25%")
	afirmar_proximo(contagem[2] / 4000.0, 0.05, 0.015, "Épico 5%")
	for i in 300:
		afirmar(GeradorOfertas.sortear_raridade(rng, true) != R.COMUM, "Elite: Raro ou melhor")


func test_slot_substitui_e_passivos_acumulam() -> void:
	var j := _jogador()
	await esperar_frames(1)
	_dar(j, &"municao_de_cla")
	var antigo := j.receber_upgrade(_modelo(&"ferrao_partido").com_raridade(R.COMUM))
	afirmar_igual(antigo.id, &"municao_de_cla", "Tiro novo substitui o antigo")
	_dar(j, &"honra_do_campeao")
	_dar(j, &"carne_mole")
	afirmar_igual(j.upgrades.passivos.size(), 2, "Passivos acumulam")
	afirmar(Progresso.estado_run.get("tem_dadiva_kharn", false) and Progresso.estado_run.get("tem_dadiva_vesh", false), "estado da run")
	j.fim_da_run()
	afirmar(j.upgrades.todos().is_empty(), "zera no fim da run")


# --- TIRO ---

func test_tiro_municao_de_cla_explode_depois_de_5_tiros() -> void:
	var j := _jogador()
	_dar(j, &"municao_de_cla")
	var tiros: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: tiros.append(p))
	await esperar_frames(2)
	j.entrada.atirar_segurado = true
	while tiros.size() < 6:
		await esperar_frames(1)
	j.entrada.atirar_segurado = false
	afirmar_proximo(tiros[4].raio_explosao, 0.0, 0.01, "5º tiro normal")
	afirmar_proximo(tiros[5].raio_explosao, 24.0, 0.01, "6º tiro explode (raio 24)")
	afirmar_igual(tiros[5].dano_explosao, 30, "30 de dano (Comum)")
	afirmar_proximo(tiros[5].abalo_explosao, 25.0, 0.01, "25 de Abalo")


func test_tiro_municao_de_cla_conta_o_peso_do_bramido() -> void:
	var j := _jogador()
	j.equipar(load("res://scenes/armas/bramido.tres"))
	_dar(j, &"municao_de_cla")
	await esperar_frames(2)
	await _um_disparo(j)
	afirmar(not j.efeitos.proximo_disparo_explode(), "1º disparo: 2,5")
	await esperar_frames(45)
	await _um_disparo(j)
	afirmar(j.efeitos.proximo_disparo_explode(), "2º disparo: 5 → o próximo explode")


func test_tiro_calibre_pesado_dano_cadencia_e_abalo() -> void:
	var j := _jogador()
	var cadencia: float = j.controle_arma.cadencia()
	_dar(j, &"calibre_pesado", R.RARO)
	afirmar_proximo(j.controle_arma.cadencia(), cadencia * 0.85, 0.001, "−15% de cadência")
	var tiros: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: tiros.append(p))
	await esperar_frames(2)
	await _um_disparo(j)
	afirmar_proximo(tiros[0].info.multiplicador, 1.45, 0.001, "+45% de dano (Raro)")
	afirmar_proximo(tiros[0].info.abalo, 10.0, 0.001, "10 de Abalo")
	afirmar(tiros[0].info.empurrao.x > 0.0, "empurra")


func test_tiro_ferrao_partido_divide_em_2_fragmentos() -> void:
	var j := _jogador()
	_dar(j, &"ferrao_partido")
	CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(4), 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 9999)
	await esperar_frames(2)
	await _um_disparo(j)
	var fragmentos: Array[Projetil] = []
	for i in 20:
		await esperar_frames(1)
		for f in get_children():
			if f is Projetil and f.fragmento and not f in fragmentos:
				fragmentos.append(f)
	afirmar_igual(fragmentos.size(), 2, "2 fragmentos")
	if fragmentos.size() == 2:
		afirmar_igual(fragmentos[0].info.valor, 4, "35% de 10")


func test_tiro_ferrao_acido_aplica_acido() -> void:
	var j := _jogador()
	_dar(j, &"ferrao_acido", R.EPICO)
	var alvo := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(4), 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 99999)
	j.efeitos.rng.seed = 3
	await esperar_frames(2)
	j.entrada.atirar_segurado = true
	await esperar_frames(60)
	j.entrada.atirar_segurado = false
	afirmar(alvo.acidos > 0, "Ácido aplicado (%d)" % alvo.acidos)


# --- GRANADA ---

func test_granada_carga_de_cerco() -> void:
	var j := _jogador()
	await esperar_frames(1)
	var base: DadosGranada = j.granada
	afirmar(j.efeitos.dados_da_granada(base) == base, "sem upgrade: granada normal")
	_dar(j, &"carga_de_cerco", R.RARO)
	var d: DadosGranada = j.efeitos.dados_da_granada(base)
	afirmar_proximo(d.raio, base.raio * 1.5, 0.001, "raio +50%")
	afirmar_igual(d.dano, roundi(base.dano * 1.7), "+70% de dano (Raro)")
	afirmar_proximo(d.abalo, 100.0, 0.001, "100 de Abalo (atordoa)")


func test_granada_ovo_de_ninhada_solta_larvas() -> void:
	var j := _jogador()
	var u := _dar(j, &"ovo_de_ninhada")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(60, 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 9999)
	await esperar_frames(2)
	j.efeitos.soltar_larvas(Vector2(20, -2), u)
	afirmar_igual(_nos("AliadoEnxame").size(), 3, "3 larvas (Comum)")
	await esperar_frames(60)
	afirmar(alvo.acidos >= 2, "larvas mordem e passam Ácido")
	afirmar(alvo.vida.atual <= 9999 - 10, "e causam dano")


# --- DASH ---

func _dash_para_a_direita(j: Jogador) -> void:
	j.entrada.direcao = Vector2i(1, 0)
	j.entrada.dash_pressionado = true
	await esperar_frames(20)
	j.entrada.direcao = Vector2i.ZERO


func test_dash_investida_do_cla() -> void:
	var j := _jogador()
	_dar(j, &"investida_do_cla")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(24, 0), Inimigo.Peso.LEVE, Vector2(12, 20), false, 500)
	await esperar_frames(3)
	await _dash_para_a_direita(j)
	afirmar_igual(alvo.vida.atual, 480, "20 de dano, uma vez por dash")
	afirmar(alvo.abalo > 0.0, "Abalo")


func test_dash_rastro_de_enxame() -> void:
	var j := _jogador()
	_dar(j, &"rastro_de_enxame")
	await esperar_frames(3)
	await _dash_para_a_direita(j)
	afirmar(_nos("AreaAcido").size() >= 2, "trilha de ácido")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(16, 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 500)
	await esperar_frames(40)
	afirmar(alvo.acidos >= 1 and alvo.vida.atual < 500, "dano e Ácido em quem pisa")


# --- FERRAMENTA ---

func test_ferramenta_corrente_rubra_explode() -> void:
	var j := _jogador()
	_dar(j, &"corrente_rubra")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 500)
	var vizinho := CenarioTeste.criar_boneco(self, Vector2(104, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 500)
	await esperar_frames(2)
	(j.ferramenta as Grilhao).acertou.emit(alvo)
	afirmar_igual(alvo.vida.atual, 470, "30 de dano no alvo")
	afirmar_igual(vizinho.vida.atual, 470, "e em volta (32 px)")


func test_ferramenta_corrente_infestada_aplica_acido() -> void:
	var j := _jogador()
	_dar(j, &"corrente_infestada", R.EPICO)
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0))
	await esperar_frames(2)
	(j.ferramenta as Grilhao).acertou.emit(alvo)
	afirmar_igual(alvo.acidos, 5, "5 acúmulos (Épico)")


# --- CHAMADO ---

func test_chamado_bombardeio_de_artilharia() -> void:
	var j := _jogador()
	_dar(j, &"bombardeio_de_artilharia")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(100, 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 9999)
	await esperar_frames(2)
	afirmar(not j.efeitos.ativar_chamado(), "barra vazia: nada")
	j.barra_chamado = Combate.regras.chamado_maximo
	afirmar(j.efeitos.ativar_chamado(), "barra cheia: ativa")
	afirmar_proximo(j.barra_chamado, 0.0, 0.001, "gasta a barra")
	afirmar_igual(_nos("QuedaBombardeio").size(), 6, "6 projéteis (Comum)")
	await esperar_frames(120)
	afirmar_igual(alvo.vida.atual, 9999 - 6 * 60, "60 de dano cada")


func test_chamado_pela_entrada_nuvem_de_zangoes() -> void:
	var j := _jogador()
	_dar(j, &"nuvem_de_zangoes", R.RARO)
	await esperar_frames(2)
	j.barra_chamado = Combate.regras.chamado_maximo
	j.entrada.chamado_pressionado = true
	await esperar_frames(2)
	afirmar_igual(_nos("AliadoEnxame").size(), 6, "6 zangões (Raro)")
	afirmar_igual(j.efeitos.aliados_ativos(), 6, "contam como aliados")


# --- PASSIVOS ---

func test_passivo_couro_de_arena() -> void:
	var j := _jogador()
	_dar(j, &"couro_de_arena", R.RARO)
	await esperar_frames(70)  # passa a invulnerabilidade de entrada
	afirmar(not j.receber_dano(1), "1º acerto anulado")
	afirmar_igual(j.vida.atual, j.vida.maxima, "sem perder vida")
	j.vida.tornar_invulneravel(0.0)
	j.vida._timer_invulneravel = 0.0
	afirmar(j.receber_dano(1), "2º acerto pega")
	j.efeitos.processar(41.0)
	afirmar(j.efeitos.couro_carregado(), "Raro recarrega em 40 s")
	j.efeitos.anular_acerto()
	j.entrar_na_sala()
	afirmar(j.efeitos.couro_carregado(), "sala nova: carregado")


func test_passivo_honra_do_campeao() -> void:
	var j := _jogador()
	_dar(j, &"honra_do_campeao")
	var comum := CenarioTeste.criar_boneco(self, Vector2(80, 0))
	var elite := CenarioTeste.criar_boneco(self, Vector2(160, 0))
	elite.categoria = Inimigo.Categoria.ELITE
	await esperar_frames(2)
	comum.receber_ataque(InfoDano.criar(100, j))
	elite.receber_ataque(InfoDano.criar(100, j))
	afirmar_igual(comum.vida.atual, 400, "comum: sem bônus")
	afirmar_igual(elite.vida.atual, 385, "elite: +15%")


func test_passivo_inabalavel_soma_ao_bonus_de_atordoado() -> void:
	var j := _jogador()
	_dar(j, &"inabalavel")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0))
	await esperar_frames(2)
	alvo.adicionar_abalo(100.0)
	afirmar(alvo.esta_atordoado(), "atordoado por Abalo")
	alvo.receber_ataque(InfoDano.criar(100, j))
	afirmar_igual(alvo.vida.atual, 500 - 145, "25% base + 20% = +45%")


func test_passivo_grito_de_guerra() -> void:
	var j := _jogador()
	_dar(j, &"grito_de_guerra", R.RARO)
	await esperar_frames(1)
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0))
	await esperar_frames(2)
	afirmar_proximo(alvo.abalo, 50.0, 1.0, "começa com 50 de Abalo (Raro)")


func test_passivo_corpo_solto_ate_3_zangoes() -> void:
	var j := _jogador()
	var u: DadosUpgrade = _modelo(&"corpo_solto").com_raridade(R.EPICO)
	u.valores = [1.0, 1.0, 1.0]  # sempre, para o teste
	j.receber_upgrade(u)
	await esperar_frames(1)
	for i in 4:
		var b := CenarioTeste.criar_boneco(self, Vector2(80 + i * 30, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 10)
		await esperar_frames(1)
		b.receber_ataque(InfoDano.criar(50, j))
		await esperar_frames(2)
	afirmar_igual(j.efeitos.aliados_ativos(&"corpo_solto"), 3, "no máximo 3")


func test_passivo_carne_mole() -> void:
	var j := _jogador()
	_dar(j, &"carne_mole")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(80, 0))
	await esperar_frames(2)
	afirmar_proximo(j.mult_dano_contra(alvo), 1.0, 0.001, "sem Ácido")
	alvo.adicionar_acido(5, j)
	afirmar_proximo(j.mult_dano_contra(alvo), 1.25, 0.001, "5 acúmulos: +25%")


func test_passivo_colmeia_faminta_vira_poca() -> void:
	var j := _jogador()
	_dar(j, &"colmeia_faminta")
	var morto := CenarioTeste.criar_boneco(self, Vector2(80, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 10)
	var vizinho := CenarioTeste.criar_boneco(self, Vector2(96, 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 9999)
	await esperar_frames(2)
	morto.adicionar_acido(1, j)
	morto.receber_ataque(InfoDano.criar(50, j))
	await esperar_frames(3)
	afirmar(_nos("AreaAcido").size() == 1, "poça no lugar do morto")
	afirmar_igual(vizinho.acidos, 2, "passa 2 acúmulos (Comum)")


func test_passivo_nos_somos_muitos() -> void:
	var j := _jogador()
	_dar(j, &"nos_somos_muitos")
	var alvo := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(2)
	for i in 2:
		AliadoEnxame.criar(self, Vector2(0, -40), AliadoEnxame.Tipo.ZANGAO, j, 0, 5.0)
	afirmar_proximo(j.mult_dano_contra(alvo), 1.08, 0.001, "+4% por aliado")


# --- Tela de oferta e falas das patronas ---

func _limpar_falas() -> void:
	for flag in ["1a_oferta_kharn", "1a_oferta_vesh", "1a_dual"]:
		Progresso.definir_flag(flag, false)


func test_tela_oferta_kharn_com_falas_antes_e_depois() -> void:
	_limpar_falas()
	var j := _jogador()
	var caixa: CaixaDialogo = instanciar(CENA_CAIXA)
	var tela := TelaRecompensa.new()
	add_child(tela)
	await esperar_frames(2)
	afirmar(tela.abrir(j, load(KHARN)), "abriu")
	afirmar(tree.paused, "jogo pausado")
	afirmar(caixa.esta_ativa() and caixa.fala_atual()["id"] == "KHAR_01", "Tor-Ama fala primeiro")
	afirmar(not tela.esta_escolhendo(), "opções esperam a fala")
	while caixa.esta_ativa():
		caixa.avancar()
	await tree.process_frame
	afirmar(tela.esta_escolhendo(), "3 opções na tela")
	afirmar_igual(tela.ofertas.size(), 3, "3 opções")
	var u := tela.escolher(1)
	afirmar(j.upgrades.tem(u.id), "pegou a dádiva")
	afirmar(caixa.esta_ativa() and caixa.fala_atual()["id"] == "KHAR_06", "fala de depois da escolha")
	caixa.avancar()
	await tree.process_frame
	afirmar(not tela.esta_aberta() and not tree.paused, "fechou e despausou")
	afirmar(Progresso.tem_flag("1a_oferta_kharn"), "a 1ª oferta toca uma vez")
	afirmar(tela.abrir(j, load(KHARN)), "2ª oferta")
	afirmar(caixa.fala_atual()["id"].begins_with("KHAR_R"), "fala de repetição")
	caixa.avancar()
	await tree.process_frame
	tela.escolher(0)
	await tree.process_frame
	afirmar(not tree.paused, "fechou")


func test_tela_avisa_substituicao_e_conta_ofertas_vesh() -> void:
	_limpar_falas()
	var j := _jogador()
	var tela := TelaRecompensa.new()
	add_child(tela)
	await esperar_frames(2)
	_dar(j, &"municao_de_cla")
	var antes: int = Progresso.valor("ofertas_vesh_total")
	afirmar(tela.abrir(j, load(VESH)), "abriu sem caixa de diálogo")
	afirmar_igual(Progresso.valor("ofertas_vesh_total"), antes + 1, "conta ofertas Vesh (pistas VESH_P)")
	afirmar(tela.esta_escolhendo(), "sem caixa: opções direto")
	afirmar_igual(tela.substituiria(_modelo(&"ferrao_partido")).id, &"municao_de_cla", "avisa que substitui o Tiro")
	afirmar(tela.substituiria(_modelo(&"carne_mole")) == null, "Passivo não substitui")
	tela.escolher(0)
	await tree.process_frame
	afirmar(not tree.paused, "fechou")


func test_porta_de_faccao_abre_a_oferta_e_fecha_as_outras() -> void:
	_limpar_falas()
	var j := _jogador()
	var tela := TelaRecompensa.new()
	add_child(tela)
	var porta := PortaFaccao.new()
	porta.catalogo = load(VESH)
	porta.position = Vector2(40, 0)
	add_child(porta)
	var outra := PortaAprimoramento.new()
	outra.position = Vector2(-200, 0)
	add_child(outra)
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(1, 0)
	for i in 30:
		await esperar_frames(1)
		if tela.esta_aberta():
			break
	j.entrada.direcao = Vector2i.ZERO
	afirmar(porta.foi_usada(), "pegou a porta")
	afirmar(tela.esta_aberta(), "oferta Vesh aberta")
	afirmar(not is_instance_valid(outra) or outra.is_queued_for_deletion(), "as outras saídas somem")
	tela.escolher(0)
	await tree.process_frame
