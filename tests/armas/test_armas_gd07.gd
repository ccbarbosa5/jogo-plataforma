extends TestCase
## Armas do GD-07 (D-058): base sem assinatura e os efeitos que a árvore de Combate e as
## Gambiarras ligam (marcadores do ControleArma). A Marca do Grilhão só vale para a arma.

const MORDIDA: String = "res://scenes/armas/mordida.tres"
const BRAMIDO: String = "res://scenes/armas/bramido.tres"


func _mod(marcadores: Array[StringName] = [], id: StringName = &"teste") -> ModificadorArma:
	var m := ModificadorArma.new()
	m.id = id
	m.marcadores = marcadores
	return m


func _jogador(arma: String = MORDIDA) -> Jogador:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.equipar(load(arma))
	return j


## Atira por `frames` quadros e devolve os projéteis criados.
func _atirar(j: Jogador, frames: int) -> Array[Projetil]:
	var lista: Array[Projetil] = []
	var guardar := func(p: Projetil) -> void: lista.append(p)
	j.atirou.connect(guardar)
	j.entrada.atirar_segurado = true
	await esperar_frames(frames)
	j.entrada.atirar_segurado = false
	j.atirou.disconnect(guardar)
	return lista


## Projétil parado no lugar, só para chamar os ganchos de acerto.
func _projetil(j: Jogador, posicao: Vector2) -> Projetil:
	var p: Projetil = (load(MORDIDA) as DadosArma).cena_projetil.instantiate()
	add_child(p)
	p.configurar(posicao, Vector2.RIGHT, 0.0, InfoDano.criar(10, j), 5.0, 0, 0)
	p.disparo = Disparo.new()
	return p


func test_numeros_base_do_gd07() -> void:
	var m: DadosArma = load(MORDIDA)
	var b: DadosArma = load(BRAMIDO)
	afirmar_igual([m.cadencia, m.dano, m.projeteis_por_tiro, m.velocidade_projetil, m.duracao_projetil, m.espalhamento_graus],
			[3.5, 14, 1, 37.5, 1.0, 0.0], "Mordida (GD-08 §1)")
	afirmar_igual([b.cadencia, b.dano, b.projeteis_por_tiro, b.velocidade_projetil, b.duracao_projetil, b.espalhamento_graus],
			[1.0, 10, 6, 25.0, 0.2, 15.0], "Bramido (GD-08 §1)")
	afirmar_igual([b.queda_dano_px, b.mult_queda_dano], [48.0, 0.5], "queda de dano do Bramido")
	afirmar_igual([m.peso_disparo, m.fator_efeito, b.peso_disparo, b.fator_efeito], [1.0, 1.0, 2.5, 0.35],
			"peso e fator continuam (facções)")


func test_sem_assinatura_a_cadencia_nao_muda_atirando() -> void:
	afirmar(not "assinatura" in DadosArma.new(), "sem campo de assinatura")
	afirmar(not "arvore" in DadosArma.new(), "sem árvore por arma")
	var j := _jogador()
	await esperar_frames(2)
	var tiros: Array[Projetil] = await _atirar(j, 120)  # 2 s
	afirmar(tiros.size() >= 6 and tiros.size() <= 8, "3,5 tiros/s sem Embalo (%d em 2 s)" % tiros.size())


func test_numeros_dos_modificadores_somam() -> void:
	var j := _jogador()
	var m := _mod()
	m.soma_perfuracoes = 1
	m.soma_ricochetes = 2
	m.mult_tamanho_projetil = 1.25
	m.mult_dano = 1.1
	j.arma_equipada.adicionar(m)
	await esperar_frames(2)
	var tiros: Array[Projetil] = await _atirar(j, 2)
	afirmar(not tiros.is_empty(), "atirou")
	var p: Projetil = tiros[0]
	afirmar_igual(p.perfuracoes, 1, "atravessa 1")
	afirmar_igual(p.ricochetes, 2, "quica 2")
	afirmar_proximo(p.scale.x, 1.25, 0.001, "projétil 25% maior")
	afirmar_igual(p.info.valor, 15, "14 × 1,1")


func test_gambiarras_somem_no_fim_da_run_e_a_arvore_fica() -> void:
	var j := _jogador()
	j.arma_equipada.adicionar_permanente(_mod([&"tres_golpes"], &"mordida_tres_golpes"))
	j.arma_equipada.adicionar(_mod([&"leque"], &"leque"))
	j.arma_equipada.adicionar(_mod([&"rebite_duplo"], &"rebite_duplo"))
	j.arma_equipada.adicionar(_mod([&"rebite_duplo"], &"rebite_duplo"))
	afirmar_igual(j.arma_equipada.acumulos(&"rebite_duplo"), 2, "acumulou 2")
	j.fim_da_run()
	afirmar(j.controle_arma.tem(&"tres_golpes"), "nó da árvore fica")
	afirmar(not j.controle_arma.tem(&"leque"), "Gambiarra some")
	afirmar_igual(j.arma_equipada.acumulos(&"rebite_duplo"), 0, "acumuláveis somem")


func test_tres_golpes_o_terceiro_acerto_seguido_e_critico() -> void:
	var j := _jogador()
	j.arma_equipada.adicionar(_mod([&"tres_golpes"]))
	var b := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(2)
	var c: ControleArma = j.controle_arma
	var mults: Array[float] = []
	for i in 3:
		var p := _projetil(j, b.centro())
		var golpe := InfoDano.criar(10, j)
		c.antes_do_acerto(p, b, golpe)
		c.depois_do_acerto(p, b, golpe, false)
		mults.append(golpe.multiplicador)
	afirmar_igual(mults, [1.0, 1.0, 2.0] as Array[float], "só o 3º é ×2")


func test_grande_arena_cada_10o_tiro_e_um_rebite_de_40() -> void:
	var j := _jogador()
	j.arma_equipada.adicionar(_mod([&"grande_arena"]))
	await esperar_frames(2)
	var tiros: Array[Projetil] = await _atirar(j, 175)
	afirmar(tiros.size() >= 10, "deu 10 tiros")
	afirmar_igual(tiros[9].especial, &"arena", "o 10º é especial")
	afirmar_igual(tiros[9].info.valor, 40, "40 de dano")
	afirmar(tiros[9].perfuracoes >= 999, "atravessa tudo")
	afirmar_igual(tiros[8].especial, &"", "o 9º é normal")


func test_rebite_duplo_a_cada_5_e_a_cada_4_com_2_acumulos() -> void:
	var j := _jogador()
	j.arma_equipada.adicionar(_mod([&"rebite_duplo"], &"rebite_duplo"))
	await esperar_frames(2)
	var tiros: Array[Projetil] = await _atirar(j, 80)  # ~5 disparos
	afirmar(tiros.size() >= 6, "o 5º disparo saiu duplo (%d projéteis)" % tiros.size())
	afirmar_igual(j.controle_arma.tiros >= 5, true, "5 disparos")
	afirmar_igual(tiros.size(), j.controle_arma.tiros + j.controle_arma.tiros / 5, "um extra a cada 5")
	j.arma_equipada.adicionar(_mod([&"rebite_duplo"], &"rebite_duplo"))
	j.controle_arma.reiniciar()
	var mais: Array[Projetil] = await _atirar(j, 75)
	afirmar_igual(mais.size(), j.controle_arma.tiros + j.controle_arma.tiros / 4, "um extra a cada 4")


func test_carregador_de_2_e_de_3_com_os_dois() -> void:
	var j := _jogador(BRAMIDO)
	afirmar_igual(j.controle_arma.tamanho_carregador(), 1, "sem carregador")
	j.arma_equipada.adicionar(_mod([&"cano_duplo"]))
	afirmar_igual(j.controle_arma.tamanho_carregador(), 2, "Cano Duplo")
	j.arma_equipada.adicionar(_mod([&"carregador_arena"]))
	afirmar_igual(j.controle_arma.tamanho_carregador(), 3, "Cano Duplo + Carregador de Arena")
	j.controle_arma.reiniciar()
	await esperar_frames(2)
	var tiros: Array[Projetil] = await _atirar(j, 30)  # 0,5 s: 3 disparos rápidos
	afirmar_igual(tiros.size(), 18, "3 disparos de 6 balins em 0,5 s")


func test_bala_central_e_leque() -> void:
	var j := _jogador(BRAMIDO)
	j.arma_equipada.adicionar(_mod([&"bala_central"]))
	await esperar_frames(2)
	var tiros: Array[Projetil] = await _atirar(j, 2)
	var centrais: Array[Projetil] = tiros.filter(func(p: Projetil) -> bool: return p.especial == &"central")
	afirmar_igual(centrais.size(), 1, "1 projétil central")
	afirmar_igual(centrais[0].info.valor, 30, "30 de dano")
	var alcance: float = centrais[0].tempo_restante * centrais[0].velocidade.length()
	afirmar(alcance >= 470.0, "alcança a tela inteira (%.0f px)" % alcance)
	var m := _jogador()
	m.arma_equipada.adicionar(_mod([&"leque"]))
	await esperar_frames(2)
	var leque: Array[Projetil] = await _atirar(m, 2)
	afirmar_igual(leque.size(), 3, "1 + 2 do leque")
	afirmar_igual(leque[1].info.valor, 7, "50% do dano")


func test_marca_do_grilhao_da_25_por_cento_so_na_arma() -> void:
	var j := _jogador()
	var b := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(2)
	var c: ControleArma = j.controle_arma
	c.marcar(b)
	afirmar(c.esta_marcado(b), "marcado")
	var golpe := InfoDano.criar(10, j)
	c.antes_do_acerto(_projetil(j, b.centro()), b, golpe)
	afirmar_proximo(golpe.multiplicador, 1.25, 0.001, "+25% no tiro")
	var vida: int = b.vida.atual
	b.receber_ataque(InfoDano.criar(10, j))  # dano que não é da arma (granada, corrente...)
	afirmar_igual(vida - b.vida.atual, 10, "fora da arma: sem bônus")
	await esperar_frames(250)  # ~4,2 s
	afirmar(not c.esta_marcado(b), "a Marca dura 4 s")


func test_marca_funda_40_por_cento_por_6_s() -> void:
	var j := _jogador()
	j.nos_combate.append(&"grilhao_marca_funda")
	var b := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	await esperar_frames(2)
	j.controle_arma.marcar(b)
	afirmar_proximo(j.controle_arma.bonus_da_marca(b), 0.40, 0.001, "+40%")
	afirmar_proximo(j.controle_arma.marcas[b]["tempo"], 6.0, 0.05, "6 s")


func test_queima_roupa_e_abre_couraca_a_24_px() -> void:
	var j := _jogador(BRAMIDO)
	j.arma_equipada.adicionar(_mod([&"queima_roupa", &"abre_couraca"]))
	var b := CenarioTeste.criar_boneco(self, Vector2(200, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), true)
	await esperar_frames(2)
	var perto := InfoDano.criar(10, j)
	j.controle_arma.antes_do_acerto(_projetil(j, j.ponto_de_tiro() + Vector2(20, 0)), b, perto)
	afirmar_proximo(perto.multiplicador, 1.4, 0.001, "+40% a 20 px")
	afirmar(b.armadura_quebrada(), "armadura quebrada")
	var longe := InfoDano.criar(10, j)
	j.controle_arma.antes_do_acerto(_projetil(j, j.ponto_de_tiro() + Vector2(60, 0)), b, longe)
	afirmar_proximo(longe.multiplicador, 1.0, 0.001, "nada a 60 px")


func test_empurrao_uma_vez_por_disparo() -> void:
	var j := _jogador(BRAMIDO)
	j.arma_equipada.adicionar(_mod([&"empurrao"]))
	var b := CenarioTeste.criar_boneco(self, Vector2(100, 0))
	await esperar_frames(3)
	var x0: float = b.global_position.x
	var p := _projetil(j, b.centro())
	p.velocidade = Vector2.RIGHT * 100.0
	for i in 4:  # 4 balins do mesmo disparo
		j.controle_arma.depois_do_acerto(p, b, InfoDano.criar(9, j), false)
	afirmar_proximo(b.global_position.x - x0, 16.0, 0.5, "empurrou 16 px uma vez só")


func test_tiro_para_no_chao_e_na_parede() -> void:
	# Correção: com monitorable desligado, a área do projétil não via corpos parados (paredes).
	var j := _jogador()
	await esperar_frames(2)
	for cena: String in ["res://scenes/armas/projetil_jogador.tscn", "res://scenes/armas/projetil_inimigo.tscn"]:
		var p: Projetil = (load(cena) as PackedScene).instantiate()
		add_child(p)
		p.configurar(Vector2(100, -30), Vector2.DOWN, 300.0, InfoDano.criar(10, j), 1.0,
				Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO)
		await esperar_frames(15)
		afirmar(not is_instance_valid(p) or p.is_queued_for_deletion(), "%s some no chão" % cena.get_file())


func test_ricochete_quica_no_chao() -> void:
	var j := _jogador()
	await esperar_frames(2)
	var p: Projetil = (load(MORDIDA) as DadosArma).cena_projetil.instantiate()
	add_child(p)
	p.configurar(Vector2(100, -30), Vector2.DOWN, 300.0, InfoDano.criar(10, j), 1.0,
			Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO)
	p.ricochetes = 1
	await esperar_frames(15)
	afirmar(is_instance_valid(p) and not p.is_queued_for_deletion(), "não sumiu no chão")
	if is_instance_valid(p):
		afirmar(p.velocidade.y < 0.0, "voltou para cima")
		afirmar_igual(p.ricochetes, 0, "gastou o ricochete")
		p.queue_free()


func test_artilharia_segurar_1_s_dispara_explosivo() -> void:
	var j := _jogador(BRAMIDO)
	j.arma_equipada.adicionar(_mod([&"artilharia"]))
	await esperar_frames(2)
	var lista: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: lista.append(p))
	j.entrada.atirar_segurado = true
	await esperar_frames(66)
	afirmar(lista.is_empty(), "segurando, só carrega")
	afirmar(j.controle_arma.fracao_carga() >= 1.0, "carga cheia")
	j.entrada.atirar_segurado = false
	await esperar_frames(2)
	afirmar_igual(lista.size(), 1, "1 disparo carregado")
	afirmar_igual(lista[0].especial, &"carregado", "explosivo")
	afirmar_proximo(lista[0].raio_explosao, 40.0, 0.01, "raio de 40 px")


func test_estilhaco_vivo_solta_estilhacos_ao_matar() -> void:
	var j := _jogador(BRAMIDO)
	j.arma_equipada.adicionar(_mod([&"estilhaco_vivo"]))
	var b := CenarioTeste.criar_boneco(self, Vector2(100, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 5)
	await esperar_frames(2)
	var p := _projetil(j, b.centro())
	b.receber_ataque(InfoDano.criar(10, j))
	j.controle_arma.depois_do_acerto(p, b, InfoDano.criar(10, j), true)
	await esperar_frames(1)
	var depois: int = 0
	for filho in get_children():
		depois += 1 if filho is Projetil and (filho as Projetil).fragmento else 0
	afirmar_igual(depois, 2, "2 estilhaços")
