extends TestCase
## Armas do VS (GD-05): Mordida, Bramido, mini árvore, porta e loja de Aprimoramento.
## Os testes 1 a 8 são os requisitos da seção 6 do GD-05.

const MORDIDA: String = "res://scenes/armas/mordida.tres"
const BRAMIDO: String = "res://scenes/armas/bramido.tres"
const A: int = 0
const B: int = 1
const C: int = 2


func _jogador(arma: String = MORDIDA) -> Jogador:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	if arma != MORDIDA:
		j.equipar(load(arma))
	return j


func _arvore(arma: String) -> ArvoreRun:
	return ArvoreRun.new(ArmaEquipada.new(load(arma)))


func _projeteis() -> Array[Projetil]:
	var lista: Array[Projetil] = []
	for filho in get_children():
		if filho is Projetil and not filho.is_queued_for_deletion():
			lista.append(filho)
	return lista


func _um_disparo(j: Jogador) -> void:
	j.entrada.atirar_segurado = true
	await esperar_frames(1)
	j.entrada.atirar_segurado = false


# --- Dados-base (GD-05 §7) ---

func test_dados_base_da_mordida_e_do_bramido() -> void:
	var m: DadosArma = load(MORDIDA)
	afirmar_igual([m.cadencia, m.dano, m.velocidade_projetil, m.duracao_projetil, m.projeteis_por_tiro], [8.0, 10, 37.5, 1.0, 1], "Mordida")
	afirmar_igual([m.peso_disparo, m.fator_efeito, m.assinatura], [1.0, 1.0, &"embalo"], "Mordida: campos novos")
	var b: DadosArma = load(BRAMIDO)
	afirmar_igual([b.cadencia, b.dano, b.velocidade_projetil, b.duracao_projetil, b.espalhamento_graus, b.projeteis_por_tiro],
			[1.5, 9, 25.0, 0.2, 15.0, 6], "Bramido")
	afirmar_igual([b.peso_disparo, b.fator_efeito, b.assinatura], [2.5, 0.35, &"coice"], "Bramido: campos novos")
	for dados: DadosArma in [m, b]:
		afirmar_igual(dados.arvore.nos.size(), 9, "%s: 3 ramos × 3 nós" % dados.nome)
		var marcadores: Array[StringName] = []
		for no in dados.arvore.nos:
			afirmar(not no.marcadores.is_empty(), "%s: todo nó tem marcador" % no.nome)
			marcadores.append_array(no.marcadores)
		afirmar_igual(marcadores.size(), 9, "%s: 9 marcadores" % dados.nome)


# --- 1. Ordem e custo ---

func test_1_nos_em_ordem_com_custo_1_2_3() -> void:
	var arvore := _arvore(MORDIDA)
	arvore.ganhar_pontos(6)
	afirmar(not arvore.comprar(A, 1), "nó 2 antes do 1: não")
	afirmar(not arvore.comprar(A, 2), "Ápice antes do 1: não")
	afirmar(arvore.comprar(A, 0), "nó 1")
	afirmar_igual(arvore.pontos, 5, "custou 1")
	afirmar(arvore.comprar(A, 1), "nó 2")
	afirmar_igual(arvore.pontos, 3, "custou 2")
	afirmar(arvore.comprar(A, 2), "Ápice")
	afirmar_igual(arvore.pontos, 0, "custou 3")
	afirmar(arvore.arma.tem_marcador(&"golpe_do_campeao"), "nó vira modificador na arma")
	var pobre := _arvore(MORDIDA)
	pobre.ganhar_pontos(2)
	pobre.comprar(B, 0)
	afirmar(not pobre.comprar(B, 1), "sem pontos suficientes")


# --- 2. Um Ápice por run ---

func test_2_apice_tranca_os_outros_dois() -> void:
	var arvore := _arvore(BRAMIDO)
	arvore.ganhar_pontos(18)
	for n in 3:
		arvore.comprar(A, n)
	afirmar_igual(arvore.estado(B, 2), ArvoreRun.Estado.BLOQUEADO, "Ápice B trancado")
	afirmar_igual(arvore.estado(C, 2), ArvoreRun.Estado.BLOQUEADO, "Ápice C trancado")
	arvore.comprar(B, 0)
	arvore.comprar(B, 1)
	afirmar(not arvore.comprar(B, 2), "não compra o 2º Ápice")
	afirmar_igual(arvore.pontos, 18 - 6 - 3, "só gastou os nós comuns")


# --- 3. Zera na morte e no fim da run ---

func test_3_arvore_e_pontos_zeram_na_morte_e_no_fim_da_run() -> void:
	var j := _jogador()
	await esperar_frames(2)
	j.arvore.ganhar_pontos(4)
	j.arvore.comprar(A, 0)
	j.arvore.comprar(B, 0)
	afirmar(j.arma_equipada.modificadores.size() == 2, "dois nós ativos")
	j.fim_da_run()
	afirmar_igual([j.arvore.pontos, j.arvore.comprados(), j.arma_equipada.modificadores.size()], [0, 0, 0], "fim da run zera")
	j.arvore.ganhar_pontos(3)
	j.arvore.comprar(C, 0)
	j.vida.receber_dano(99, true)
	afirmar(j.esta_morto(), "morreu")
	afirmar_igual([j.arvore.pontos, j.arvore.comprados(), j.arma_equipada.modificadores.size()], [0, 0, 0], "morte zera")


# --- 4. Pontos guardados ---

func test_4_pontos_nao_gastos_ficam_guardados() -> void:
	var j := _jogador()
	var tela := TelaArvore.new()
	add_child(tela)
	tela.entrada = EntradaJogador.new()
	await esperar_frames(2)
	j.ganhar_aprimoramento(1)
	tela.abrir(j)
	afirmar(tree.paused, "a tela pausa o jogo")
	tela.fechar()
	afirmar(not tree.paused, "fechar despausa")
	afirmar_igual(j.arvore.pontos, 1, "ponto guardado")
	j.ganhar_aprimoramento(2)
	tela.abrir(j)
	afirmar_igual(j.arvore.pontos, 3, "1 guardado + 2 novos")
	tela.selecionar(A, 0)
	afirmar(tela.comprar_selecionado(), "comprou A1")
	tela.selecionar(A, 1)
	afirmar(tela.comprar_selecionado(), "comprou A2 com o ponto guardado + o novo")
	afirmar_igual(j.arvore.pontos, 0, "gastou tudo")
	tela.fechar()


# --- 5. peso_disparo e fator_efeito ---

func test_5_peso_disparo_e_fator_efeito() -> void:
	var j := _jogador(BRAMIDO)
	var municao_de_cla := GatilhoTiros.new(5.0)  # "a cada 5 tiros"
	var disparou_efeito: Array[int] = []
	var disparos: Array[int] = [0]
	j.controle_arma.disparou.connect(func(peso: float) -> void:
		disparos[0] += 1
		if municao_de_cla.alimentar(peso):
			disparou_efeito.append(disparos[0]))
	var fatores: Array[float] = []
	j.atirou.connect(func(p: Projetil) -> void: fatores.append(p.info.fator_efeito))
	await esperar_frames(2)
	await _um_disparo(j)
	await esperar_frames(45)
	await _um_disparo(j)
	afirmar_igual(disparos[0], 2, "dois disparos")
	afirmar_igual(disparou_efeito, [2] as Array[int], "Munição de Clã no 2º disparo do Bramido (2 × 2,5 ≥ 5)")
	afirmar_proximo(fatores[0], 0.35, 0.001, "fator_efeito por balim")
	var boneco := CenarioTeste.criar_boneco(self, Vector2(200, 0))
	var golpe := InfoDano.criar(1, j)
	golpe.abalo = 10.0
	golpe.fator_efeito = 0.35
	boneco.receber_ataque(golpe)
	afirmar_proximo(boneco.abalo, 3.5, 0.01, "abalo multiplicado pelo fator_efeito")


# --- 6. Embalo ---

func test_6_embalo_sobe_zera_e_cai() -> void:
	var j := _jogador()
	CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(5), 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 99999)
	await esperar_frames(3)
	j.entrada.atirar_segurado = true
	await esperar_frames(60)
	j.entrada.atirar_segurado = false
	var c: ControleArma = j.controle_arma
	afirmar(c.embalo >= 5.0, "subiu com os acertos (%.1f)" % c.embalo)
	var cadencia_base: float = j.arma_equipada.cadencia()
	afirmar(c.cadencia() > cadencia_base, "Embalo acelera a cadência")
	await esperar_frames(20)  # últimos tiros chegam
	var depois_do_ultimo: float = c.embalo
	await esperar_frames(60)
	afirmar_proximo(c.embalo, depois_do_ultimo, 0.01, "não cai antes de 1,5 s sem acertar")
	await esperar_frames(60)
	afirmar(c.embalo < depois_do_ultimo - 1.0, "caiu depois de 1,5 s sem acertar (%.1f)" % c.embalo)
	c.embalo = 20.0
	afirmar_proximo(c.cadencia(), cadencia_base * 1.25, 0.001, "20 pontos = +25%")
	j.receber_dano(1)
	afirmar_igual(c.embalo, 0.0, "levar dano zera")
	j.arvore.ganhar_pontos(1)
	j.arvore.comprar(A, 0)  # Plateia Fiel
	c.embalo = 30.0
	afirmar(c.embalo_cheio(), "máximo 30 com A1")
	await esperar_frames(80)  # passa a invulnerabilidade do dano anterior
	c.embalo = 30.0
	j.receber_dano(1)
	afirmar_igual(c.embalo, 15.0, "com A1, levar dano tira metade")


# --- 7. Bala de Cerco e Recuo de Gladiador ---

func test_7_bala_de_cerco_troca_os_balins_por_1_projetil() -> void:
	var j := _jogador(BRAMIDO)
	await esperar_frames(2)
	await _um_disparo(j)
	afirmar_igual(_projeteis().size(), 6, "6 balins sem a árvore")
	await esperar_frames(45)
	j.arvore.ganhar_pontos(1)
	j.arvore.comprar(A, 0)
	await _um_disparo(j)
	var lista := _projeteis()
	afirmar_igual(lista.size(), 1, "1 projétil com a Bala de Cerco")
	afirmar_igual(lista[0].info.valor, 50, "50 de dano")
	afirmar_proximo(lista[0].info.fator_efeito, 1.0, 0.001, "fator_efeito volta a 1,0")
	afirmar_proximo(lista[0].velocidade.length(), 600.0, 0.5, "600 px/s")
	afirmar_proximo(lista[0].queda_dano_px, 0.0, 0.001, "sem queda de dano")


func test_7_recuo_de_gladiador_empurra_o_jogador() -> void:
	var j := _jogador(BRAMIDO)
	j.arvore.ganhar_pontos(6)
	for n in 3:
		afirmar(j.arvore.comprar(B, n), "Brecha %d" % (n + 1))
	await esperar_frames(5)
	var x0: float = j.global_position.x
	await _um_disparo(j)
	afirmar_proximo(j.global_position.x, x0 - 24.0, 1.0, "recuou 24 px para trás")


# --- 8. Tiro automático e nós de carga ---

func test_8_tiro_automatico_dispara_a_carga_sozinho() -> void:
	var j := _jogador(BRAMIDO)
	j.arvore.ganhar_pontos(6)
	for n in 3:
		j.arvore.comprar(A, n)  # Artilharia
	j.assistencias.tiro_automatico = true
	CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(8), 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 99999)
	var tiros: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: tiros.append(p))
	await esperar_frames(30)
	afirmar(tiros.is_empty(), "carregando, ainda sem disparo")
	afirmar(j.controle_arma.carregando(), "carga em andamento")
	await esperar_frames(40)
	afirmar_igual(tiros.size(), 1, "disparou sozinho com a carga completa")
	if not tiros.is_empty():
		afirmar_igual(tiros[0].especial, &"carregado", "disparo carregado")
		afirmar_proximo(tiros[0].raio_explosao, 40.0, 0.01, "explode em 40 px")


func test_8_soltar_antes_da_carga_dispara_a_bala_normal() -> void:
	var j := _jogador(BRAMIDO)
	j.arvore.ganhar_pontos(6)
	for n in 3:
		j.arvore.comprar(A, n)
	var tiros: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: tiros.append(p))
	await esperar_frames(2)
	j.entrada.atirar_segurado = true
	await esperar_frames(20)
	afirmar(tiros.is_empty(), "segurando: carrega sem atirar")
	j.entrada.atirar_segurado = false
	await esperar_frames(1)
	afirmar_igual(tiros.size(), 1, "soltou: atirou")
	if not tiros.is_empty():
		afirmar_igual(tiros[0].especial, &"", "bala normal (Bala de Cerco)")


# --- Assinaturas e nós ---

func test_coice_empurra_leves_e_medios_uma_vez_por_disparo() -> void:
	var j := _jogador(BRAMIDO)
	var medio := CenarioTeste.criar_boneco(self, Vector2(40, 0), Inimigo.Peso.MEDIO, Vector2(20, 32), false, 9999)
	await esperar_frames(3)
	var x0: float = medio.global_position.x
	await _um_disparo(j)
	await esperar_frames(10)
	afirmar_proximo(medio.global_position.x, x0 + 16.0, 1.5, "médio empurrado 16 px (os balins não somam)")


func test_coice_nao_move_pesados() -> void:
	var j := _jogador(BRAMIDO)
	var pesado := CenarioTeste.criar_boneco(self, Vector2(44, 0), Inimigo.Peso.PESADO, Vector2(40, 64), false, 9999)
	await esperar_frames(3)
	var x0: float = pesado.global_position.x
	await _um_disparo(j)
	await esperar_frames(10)
	afirmar_proximo(pesado.global_position.x, x0, 0.5, "pesado não se mexe")


func test_rajada_dispara_3_balas() -> void:
	var j := _jogador()
	j.arvore.ganhar_pontos(1)
	j.arvore.comprar(B, 0)  # Disciplina
	var tiros: Array[Projetil] = []
	j.atirou.connect(func(p: Projetil) -> void: tiros.append(p))
	await esperar_frames(2)
	await _um_disparo(j)
	await esperar_frames(12)
	afirmar_igual(tiros.size(), 3, "rajada de 3")
	afirmar_igual(tiros[0].info.valor, 12, "+20% de dano por bala")


func test_marca_do_grilhao_aumenta_o_dano() -> void:
	var j := _jogador()
	j.arvore.ganhar_pontos(1)
	j.arvore.comprar(C, 0)
	var alvo := CenarioTeste.criar_boneco(self, Vector2(CenarioTeste.tiles(6), 0), Inimigo.Peso.PESADO, Vector2(20, 32), false, 500)
	await esperar_frames(2)
	j.controle_arma.marcar(alvo)
	afirmar(j.controle_arma.esta_marcado(alvo), "marcado")
	await _um_disparo(j)
	await esperar_frames(15)
	afirmar_igual(alvo.vida.atual, 500 - 13, "10 × 1,25 = 13 de dano")


# --- Porta, loja e regras ---

func test_porta_de_aprimoramento_da_1_ponto_e_abre_a_arvore() -> void:
	var j := _jogador()
	var abriu: Array[bool] = [false]
	j.ganhou_aprimoramento.connect(func(_j: Jogador) -> void: abriu[0] = true)
	var porta := PortaAprimoramento.new()
	porta.position = Vector2(40, 0)
	add_child(porta)
	await esperar_frames(3)
	j.entrada.direcao = Vector2i(1, 0)
	await esperar_frames(20)
	j.entrada.direcao = Vector2i.ZERO
	await esperar_frames(2)
	afirmar(porta.foi_usada(), "pegou a porta")
	afirmar_igual(j.arvore.pontos, 1, "+1 ponto")
	afirmar(abriu[0], "pede para abrir a árvore")


func test_loja_vende_1_aprimoramento_por_90_creditos() -> void:
	var j := _jogador()
	var loja := LojaIlo.new()
	add_child(loja)
	await esperar_frames(2)
	j.creditos = 80
	afirmar(not loja.comprar(j), "80 Créditos não bastam")
	afirmar_igual(j.creditos, 80, "não descontou")
	j.creditos = 200
	afirmar(loja.comprar(j), "comprou")
	afirmar_igual([j.creditos, j.arvore.pontos], [110, 1], "−90 Créditos, +1 ponto")
	afirmar(not loja.comprar(j), "no máximo 1 por loja")
	afirmar_igual(j.creditos, 110, "a 2ª tentativa não cobra")


func test_regras_das_portas_de_aprimoramento() -> void:
	afirmar(not RegrasPortas.aprimoramento_permitido(1, 0), "nunca na sala 1")
	afirmar(RegrasPortas.aprimoramento_permitido(2, 2), "pode na sala 2")
	afirmar(not RegrasPortas.aprimoramento_permitido(6, 3), "no máximo 3 por ato")
	afirmar(RegrasPortas.aprimoramento_obrigatorio(5, 0), "garantida até a sala 5")
	afirmar(not RegrasPortas.aprimoramento_obrigatorio(4, 0), "antes da 5 é sorteio")
	afirmar(not RegrasPortas.aprimoramento_obrigatorio(5, 1), "já ofereceu: não precisa")


func test_trocar_de_arma_vai_para_o_estado_da_run() -> void:
	var j := _jogador(BRAMIDO)
	await esperar_frames(1)
	afirmar_igual(Progresso.estado_run.get("arma_atual"), "bramido", "falas sabem que é o Bramido")
	j.equipar(load(MORDIDA))
	afirmar_igual(Progresso.estado_run.get("arma_atual"), "mordida", "e a Mordida")
