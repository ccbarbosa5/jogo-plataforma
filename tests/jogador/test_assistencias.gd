extends TestCase
## Mira automática e tiro automático (GD-01 3.1, D-017).


func _alvo(posicao: Vector2, anunciando: bool = false) -> AlvoFalso:
	var a := AlvoFalso.new()
	a.anunciando = anunciando
	add_child(a)
	a.global_position = posicao
	return a


func _jogador_com(modo: Assistencias.ModoMira, tiro_auto: bool = false) -> Jogador:
	CenarioTeste.criar_chao(self)
	var j := CenarioTeste.criar_jogador(self)
	j.assistencias = Assistencias.new()
	j.assistencias.modo_mira = modo
	j.assistencias.tiro_automatico = tiro_auto
	return j


func test_converte_vetor_para_8_direcoes() -> void:
	afirmar_igual(MiraAutomatica.direcao_8(Vector2(10, 1)), Vector2i(1, 0), "direita")
	afirmar_igual(MiraAutomatica.direcao_8(Vector2(5, -5)), Vector2i(1, -1), "diagonal cima-direita")
	afirmar_igual(MiraAutomatica.direcao_8(Vector2(-1, -10)), Vector2i(0, -1), "cima")
	afirmar_igual(MiraAutomatica.direcao_8(Vector2(-7, 6)), Vector2i(-1, 1), "diagonal baixo-esquerda")
	afirmar_igual(MiraAutomatica.girar_8(Vector2i(1, 0), -1), Vector2i(1, -1), "girar 45° para cima")


func test_prioridade_para_quem_anuncia_ataque() -> void:
	var opcoes := Assistencias.new()
	var mira := MiraAutomatica.new()
	_alvo(Vector2(50, 0))
	var anunciando := _alvo(Vector2(200, 0), true)
	await esperar_frames(1)
	afirmar(mira.escolher_alvo(Vector2.ZERO, opcoes, tree) == anunciando, "escolhe quem está anunciando")


func test_alvo_grudento_so_troca_se_outro_estiver_40_por_cento_mais_perto() -> void:
	var opcoes := Assistencias.new()
	var mira := MiraAutomatica.new()
	var a := _alvo(Vector2(100, 0))
	await esperar_frames(1)
	afirmar(mira.escolher_alvo(Vector2.ZERO, opcoes, tree) == a, "primeiro alvo")
	var b := _alvo(Vector2(-70, 0))  # 30% mais perto: não troca
	await esperar_frames(1)
	afirmar(mira.escolher_alvo(Vector2.ZERO, opcoes, tree) == a, "mantém o alvo")
	b.global_position = Vector2(-50, 0)  # 50% mais perto: troca
	afirmar(mira.escolher_alvo(Vector2.ZERO, opcoes, tree) == b, "troca de alvo")
	b.global_position = Vector2(-2000, 0)  # fora da tela
	afirmar(mira.escolher_alvo(Vector2.ZERO, opcoes, tree) == a, "volta quando o alvo sai do alcance")


func test_mira_total_mira_sozinha_em_8_direcoes() -> void:
	var j := _jogador_com(Assistencias.ModoMira.TOTAL)
	await esperar_frames(3)
	_alvo(j.ponto_de_tiro() + Vector2(-80, -75))
	await esperar_frames(2)
	afirmar_igual(j.mira, Vector2i(-1, -1), "mira no alvo em diagonal")
	j.entrada.travar_mira_segurado = true
	j.entrada.direcao = Vector2i(1, 0)
	await esperar_frames(1)
	afirmar_igual(j.mira, Vector2i(1, 0), "travar a mira vence a assistência")


func test_mira_assistida_corrige_so_para_a_direcao_vizinha() -> void:
	var j := _jogador_com(Assistencias.ModoMira.ASSISTIDA)
	await esperar_frames(3)
	var a := _alvo(j.ponto_de_tiro() + Vector2(80, -80))
	await esperar_frames(2)
	afirmar_igual(j.mira, Vector2i(1, -1), "corrigiu de reto para diagonal (vizinha)")
	a.global_position = j.ponto_de_tiro() + Vector2(0, -100)
	await esperar_frames(2)
	afirmar_igual(j.mira, Vector2i(1, 0), "alvo a 90° não é vizinho: mira continua manual")


func test_tiro_automatico_so_atira_com_inimigo_na_linha() -> void:
	var j := _jogador_com(Assistencias.ModoMira.DESLIGADA, true)
	var tiros: Array[int] = [0]
	j.atirou.connect(func(_p: Projetil) -> void: tiros[0] += 1)
	await esperar_frames(10)
	afirmar_igual(tiros[0], 0, "sem inimigo, sem tiro")
	_alvo(j.ponto_de_tiro() + Vector2(150, 0))
	await esperar_frames(30)
	afirmar(tiros[0] >= 3, "atirou sozinho no inimigo na linha (%d)" % tiros[0])


func test_tiro_automatico_nao_gasta_arma_pesada_por_padrao() -> void:
	var j := _jogador_com(Assistencias.ModoMira.DESLIGADA, true)
	await esperar_frames(2)
	var pesada: DadosArma = j.arma.duplicate()
	pesada.municao = 100
	j.equipar(pesada)
	var tiros: Array[int] = [0]
	j.atirou.connect(func(_p: Projetil) -> void: tiros[0] += 1)
	_alvo(j.ponto_de_tiro() + Vector2(150, 0))
	await esperar_frames(20)
	afirmar_igual(tiros[0], 0, "arma pesada não dispara sozinha")
	j.assistencias.tiro_automatico_armas_pesadas = true
	await esperar_frames(20)
	afirmar(tiros[0] > 0, "com a sub-opção ligada, dispara")
