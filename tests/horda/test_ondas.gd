extends TestCase
## GD-08 §3 e §5: ondas contínuas de enxame (DiretorHorda).


## Monta uma arena de carcaça com o jogador dentro, e a configuração do diretor ajustada.
func _arena(ajustes: Dictionary = {}, ondas: Array = [], blocos: Array = ["entrada_varrek", "carcaca_a1", "saida_varrek"],
		x_jogador: float = -1.0) -> SalaRun:
	Combate.reiniciar()
	var g := GeradorAto.new(null, 3)
	var plano := {"numero": 1, "nome": "teste", "bioma": "carcaca", "tipo": "combate", "elite": false,
			"blocos": blocos, "ondas": ondas, "portas": ["kharn", "dados"]}
	var sala := MontadorSala.montar(plano, g.blocos)
	add_child(sala)
	var j := CenarioTeste.criar_jogador(self, Vector2(sala.arena.position.x + 60.0 if x_jogador < 0.0 else x_jogador, 224.0))
	j.vida.reiniciar(999)
	var camera := CameraJogo.new()
	add_child(camera)
	camera.alvos.append(j)
	camera.definir_limites(sala.limites())
	camera.posicionar_imediato()
	sala.iniciar(j, camera, self, g.ondas)
	for chave: String in ajustes:
		sala.diretor.config[chave] = ajustes[chave]
		if sala.diretor.geral.has(chave):
			sala.diretor.geral[chave] = ajustes[chave]
	return sala


## Mata quem encosta para o jogador não ficar soterrado (a contagem por origem continua).
func _limpar_perto(sala: SalaRun, raio: float) -> void:
	for no in sala.inimigos.get_children():
		var i := no as Inimigo
		if i != null and i.esta_vivo() and i.global_position.distance_to(sala.jogador.global_position) < raio:
			i.vida.receber_dano(9999, true)


func test_1_quase_tudo_vem_da_direita_e_ninguem_surge_perto() -> void:
	var sala := _arena({"duracao": 8.0, "taxa": 4.0, "pico": 20, "teto": 60, "teto_pico": 60})
	var perto: Array[int] = [0]
	sala.diretor.entrou.connect(func(i: Inimigo, _o: StringName) -> void:
		if i.global_position.distance_to(sala.jogador.global_position) < Unidades.px(6.0) - 0.5:
			perto[0] += 1)
	await esperar_frames(2)
	afirmar(sala.arena_ativa, "arena começou")
	for k in 9 * 60:
		await esperar_frames(1)
		if k % 10 == 0:
			_limpar_perto(sala, 40.0)
	var e: Dictionary = sala.diretor.entradas
	var total: int = e[DiretorHorda.DIREITA] + e[DiretorHorda.ATRAS] + e[DiretorHorda.CIMA]
	afirmar(total >= 40, "entraram %d" % total)
	afirmar(float(e[DiretorHorda.DIREITA]) / total >= 0.75, "~80%% pela direita (%d de %d)" % [e[DiretorHorda.DIREITA], total])
	afirmar_igual(perto[0], 0, "nada surge a menos de 6 tiles")


func test_1_entradas_por_tras_e_de_cima_so_no_pico_e_com_aviso_de_1_s() -> void:
	var sala := _arena({"duracao": 6.0, "taxa": 2.0, "pico": 16, "fracao_atras_pico": 0.4, "fracao_cima_pico": 0.4,
			"teto": 60, "teto_pico": 60}, [], ["entrada_varrek", "carcaca_a1", "saida_varrek"], 240.0 + 240.0)
	var avisos: Dictionary = {}  # posição -> [tempos]
	var relogio: Array[float] = [0.0]
	var erros: Array[String] = []
	var excecoes: Array[int] = [0]
	sala.diretor.aviso_entrada.connect(func(pos: Vector2, _o: StringName) -> void:
		if not avisos.has(pos):
			avisos[pos] = []
		avisos[pos].append(relogio[0])
		if not sala.diretor.em_pico:
			erros.append("aviso fora do pico"))
	sala.diretor.entrou.connect(func(i: Inimigo, o: StringName) -> void:
		if o == DiretorHorda.DIREITA:
			return
		excecoes[0] += 1
		if not avisos.has(i.position) or avisos[i.position].is_empty():
			erros.append("entrou por %s sem aviso" % o)
			return
		var t: float = avisos[i.position].pop_front()
		if relogio[0] - t < 0.95:
			erros.append("aviso curto (%.2f s)" % (relogio[0] - t)))
	var pico_em: Array[float] = [-1.0]
	sala.diretor.pico_anunciado.connect(func() -> void: pico_em[0] = relogio[0])
	await esperar_frames(1)
	for k in 7 * 60:
		await esperar_frames(1)
		relogio[0] += 1.0 / 60.0
		if k % 10 == 0:
			_limpar_perto(sala, 40.0)
	afirmar(excecoes[0] >= 3, "houve entradas por trás e de cima (%d)" % excecoes[0])
	afirmar_igual(erros, [] as Array[String], "só no pico e sempre 1,0 s depois do aviso")
	afirmar_proximo(pico_em[0], 6.0 * 0.6 - 1.5, 0.1, "o pico é anunciado 1,5 s antes (aos 60%)")


func test_2_teto_de_vivos_e_respeitado() -> void:
	var sala := _arena({"duracao": 6.0, "taxa": 20.0, "teto": 12, "pico": 30, "teto_pico": 40})
	var maior: int = 0
	var maior_pico: int = 0
	for k in 6 * 60:
		await esperar_frames(1)
		var v: int = sala.diretor.vivos()
		if sala.diretor.em_pico:
			maior_pico = maxi(maior_pico, v)
		else:
			maior = maxi(maior, v)
	afirmar(maior <= 12, "teto da sala (%d)" % maior)
	afirmar(maior_pico <= 40, "teto do pico: 40 (%d)" % maior_pico)
	afirmar(maior >= 10, "chegou perto do teto (%d)" % maior)


func test_5_a_sala_termina_entradas_param_pesados_morrem_enxame_foge() -> void:
	var g := GeradorAto.new(null, 3)
	var onda: Dictionary = {}
	for o in g.ondas.ondas:
		if o["id"] == "guerreiro_1":
			onda = o
	var sala := _arena({"duracao": 3.0, "taxa": 3.0, "pico": 0, "fuga_depois": 1.0, "primeiro_pesado": 0.5}, [onda])
	await esperar_frames(3 * 60 + 10)
	afirmar_igual(sala.diretor.fase, DiretorHorda.Fase.ESPERA_PESADOS, "a duração acabou: entradas param")
	var antes: int = sala.diretor.entradas[DiretorHorda.DIREITA]
	await esperar_frames(30)
	afirmar_igual(sala.diretor.entradas[DiretorHorda.DIREITA], antes, "ninguém mais entra")
	afirmar(sala.diretor.pesados_vivos() >= 1, "o Guerreiro ainda vivo segura a sala")
	afirmar(not sala.arena_concluida, "sem portas com pesado vivo")
	var xp_antes: int = sala.diretor.vivos_enxame()
	afirmar(xp_antes > 0, "tem enxame sobrando")
	var mortes: Array[int] = [0]
	sala.inimigo_morreu.connect(func(_i: Inimigo, _r: bool) -> void: mortes[0] += 1)
	for i in sala.diretor.pesados:
		if is_instance_valid(i):
			i.vida.receber_dano(9999, true)
	await esperar_frames(3)
	var mortes_pesados: int = mortes[0]
	afirmar_igual(sala.diretor.fase, DiretorHorda.Fase.ESPERA_FUGA, "pesados mortos: espera para o enxame fugir")
	await esperar_frames(70)
	afirmar_igual(sala.diretor.fase, DiretorHorda.Fase.FUGA, "o enxame foge")
	await esperar_frames(150)
	afirmar(sala.arena_concluida, "a sala termina")
	afirmar_igual(mortes[0], mortes_pesados, "quem fugiu não conta como morte (sem XP)")
	await esperar_frames(2)
	afirmar_igual(sala.portas.size(), 2, "as portas aparecem")


func test_trecho_tem_enxame_e_acelera_com_jogador_parado() -> void:
	var sala := _arena({"trecho": 2.0}, [], ["entrada_varrek", "carcaca_t1", "carcaca_a1", "saida_varrek"], 300.0)
	await esperar_frames(60)
	afirmar_igual(sala.diretor.fase, DiretorHorda.Fase.TRECHO, "trecho começou depois da entrada")
	var primeiro: int = sala.diretor.entradas[DiretorHorda.DIREITA]
	afirmar(primeiro >= 1, "enxame no trecho (%d)" % primeiro)
	await esperar_frames(4 * 60)
	_limpar_perto(sala, 9999.0)
	var antes: int = sala.diretor.entradas[DiretorHorda.DIREITA]
	await esperar_frames(120)
	var depois: int = sala.diretor.entradas[DiretorHorda.DIREITA] - antes
	afirmar(depois >= 5, "parado há mais de 4 s: +50%% (%d em 2 s)" % depois)


func test_6_desempenho_40_inimigos_e_tiros_a_60_fps() -> void:
	var sala := _arena({"duracao": 999.0, "taxa": 0.0, "pico": 0})
	var j: Jogador = sala.jogador
	var tipos: Array[String] = ["roedor", "chacal", "zangao"]
	for k in 36:
		var e: InimigoEnxame = sala.pool.pegar(tipos[k % 3])
		e.position = Vector2(sala.arena.position.x + 200.0 + (k % 12) * 14.0, 223.0 if tipos[k % 3] != "zangao" else 150.0)
		sala.inimigos.add_child(e)
		e.vida.reiniciar(99999)
	for k in 4:
		var g := sala._criar_inimigo("guerreiro", Vector2(sala.arena.position.x + 300.0 + k * 20.0, 223.0), true)
		g.vida.reiniciar(99999)
	j.vida.tornar_invulneravel(999.0)
	j.entrada.atirar_segurado = true
	await esperar_frames(10)
	afirmar(sala.diretor.vivos() >= 40, "40 inimigos (%d)" % sala.diretor.vivos())
	# A lógica do jogo roda na física (a 60 Hz). Ela precisa caber com folga num quadro de
	# 16,6 ms para sobrar tempo ao desenho: o limite aqui é 10 ms (a máquina do CI é lenta).
	var fisica: float = 0.0
	var quadros: int = 120
	for k in quadros:
		await esperar_frames(1)
		fisica += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var ms: float = fisica * 1000.0 / quadros
	j.entrada.atirar_segurado = false
	print("    desempenho: física %.2f ms por quadro com %d inimigos e tiros" % [ms, sala.diretor.vivos()])
	afirmar(ms < 10.0, "lógica cabe em 60 fps com folga (%.2f ms)" % ms)


func test_roedores_saem_de_tocas_so_no_pico_com_aviso_e_longe_do_jogador() -> void:
	# Item 30 (GD-08 §3.1): buraco no chão brilha 1,0 s antes; nunca a menos de 6 tiles; exceção
	# dentro dos 10% "de cima" (nunca a entrada principal).
	var sala := _arena({"duracao": 6.0, "taxa": 2.0, "pico": 14, "fracao_atras_pico": 0.0, "fracao_cima_pico": 0.6,
			"fracao_toca_no_cima": 1.0, "mistura": {"roedor": 1.0}, "teto": 60, "teto_pico": 60},
			[], ["entrada_varrek", "carcaca_a1", "saida_varrek"], 240.0 + 240.0)
	var avisos: Dictionary = {}  # posição -> [tempos]
	var relogio: Array[float] = [0.0]
	var erros: Array[String] = []
	var pelas_tocas: Array[int] = [0]
	sala.diretor.aviso_entrada.connect(func(pos: Vector2, o: StringName) -> void:
		if o != DiretorHorda.TOCA:
			erros.append("aviso de %s (esperava só tocas)" % o)
			return
		if not avisos.has(pos):
			avisos[pos] = []
		avisos[pos].append(relogio[0])
		if not sala.diretor.em_pico:
			erros.append("toca fora do pico")
		if pos.distance_to(sala.jogador.global_position) < Unidades.px(6.0) - 0.5:
			erros.append("toca a menos de 6 tiles")
		if absf(pos.x - sala.camera.global_position.x) > 240.0:
			erros.append("toca fora da tela"))
	sala.diretor.entrou.connect(func(i: Inimigo, o: StringName) -> void:
		if o != DiretorHorda.TOCA:
			return
		pelas_tocas[0] += 1
		if not i is Roedor:
			erros.append("saiu da toca algo que não é Roedor")
		if i.velocity.y >= 0.0:
			erros.append("não pulou para fora do buraco")
		if not avisos.has(i.position) or avisos[i.position].is_empty():
			erros.append("saiu da toca sem aviso")
			return
		var t: float = avisos[i.position].pop_front()
		if relogio[0] - t < 0.95:
			erros.append("aviso curto (%.2f s)" % (relogio[0] - t)))
	await esperar_frames(1)
	var viu_buraco: bool = false
	for k in 7 * 60:
		await esperar_frames(1)
		relogio[0] += 1.0 / 60.0
		for no in sala.get_children():
			if no is AvisoEntrada and (no as AvisoEntrada).origem == DiretorHorda.TOCA:
				viu_buraco = true
		if k % 10 == 0:
			_limpar_perto(sala, 40.0)
	afirmar(pelas_tocas[0] >= 3, "Roedores saíram de tocas (%d)" % pelas_tocas[0])
	afirmar(viu_buraco, "o buraco aparece no chão")
	afirmar_igual(erros, [] as Array[String], "só no pico, com aviso de 1,0 s, longe do jogador e na tela")
	afirmar_igual(sala.diretor.entradas[DiretorHorda.TOCA], pelas_tocas[0], "contadas como entrada por toca")
	afirmar(sala.diretor.entradas[DiretorHorda.DIREITA] > pelas_tocas[0], "a direita continua sendo a entrada principal")
	# Com os valores do jogo, as tocas ficam dentro dos 10% "de cima" do pico.
	var geral: Dictionary = DiretorHorda.carregar_dados()["geral"]
	afirmar(float(geral["fracao_cima_pico"]) <= 0.1 and float(geral["fracao_toca_no_cima"]) <= 1.0, "tocas dentro dos 10% de cima")


func test_sem_roedor_na_mistura_nao_ha_tocas() -> void:
	var sala := _arena({"duracao": 6.0, "taxa": 2.0, "pico": 14, "fracao_atras_pico": 0.0, "fracao_cima_pico": 0.6,
			"fracao_toca_no_cima": 1.0, "mistura": {"chacal": 1.0}, "teto": 60, "teto_pico": 60},
			[], ["entrada_varrek", "carcaca_a1", "saida_varrek"], 240.0 + 240.0)
	await esperar_frames(1)
	for k in 7 * 60:
		await esperar_frames(1)
		if k % 10 == 0:
			_limpar_perto(sala, 40.0)
	afirmar_igual(sala.diretor.entradas[DiretorHorda.TOCA], 0, "sala sem Roedor: sem tocas")
	afirmar(sala.diretor.entradas[DiretorHorda.CIMA] > 0, "os Zangões de cima continuam")
