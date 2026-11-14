extends TestCase
## Chefe Ur-Kesh (GD-02 §5): três fases, avisos, núcleo, reforços, contra-ataque e a vitória
## que libera o Bramido (NAR-03).

const CENA: String = "res://scenes/inimigos/ur_kesh.tscn"
const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"
const ENTRADA: int = 32


func _antes() -> Jogador:
	Combate.reiniciar()
	CenarioTeste.criar_chao(self)
	return CenarioTeste.criar_jogador(self)


func _chefe(pos: Vector2 = Vector2(200, 0)) -> UrKesh:
	var c: UrKesh = (load(CENA) as PackedScene).instantiate()
	c.container_projeteis = self
	add_child(c)
	c.global_position = pos
	return c


func _parar(c: UrKesh) -> void:
	# Congela a IA (só os testes de ataque ligam o que precisam).
	c.estado = UrKesh.Estado.DESCANSO
	c._timer = 999.0
	c._timer_bark = 999.0


func test_fase_1_andador_pesado_com_radiador_nas_costas() -> void:
	_antes()
	var c := _chefe()
	await esperar_frames(2)
	afirmar_igual([c.fase, c.vida.maxima, c.peso, c.categoria], [1, 1500, Inimigo.Peso.PESADO, Inimigo.Categoria.CHEFE], "fase 1")
	c.olhando = -1
	c._posicionar_pontos()
	afirmar(c.radiador.position.x > 0.0, "radiador nas costas")
	c.radiador.receber_ataque(InfoDano.criar(10, null))
	afirmar_igual(c.vida.atual, 1480, "radiador: dano dobrado")


func test_varredura_tem_laser_de_0_8_s() -> void:
	var j := _antes()
	var c := _chefe(Vector2(220, 0))
	c._ataque = 2  # o próximo do rodízio é a varredura
	c._timer = 0.0
	await esperar_frames(ENTRADA + 3)
	afirmar_igual(c.estado, UrKesh.Estado.AVISO_VARREDURA, "laser de mira")
	await esperar_frames(42)
	afirmar_igual(c.estado, UrKesh.Estado.AVISO_VARREDURA, "ainda mirando")
	await esperar_frames(10)
	afirmar_igual(c.estado, UrKesh.Estado.VARREDURA, "varre depois de 0,8 s")
	afirmar(c.altura_varredura > 18.0 and c.altura_varredura < 28.0, "na altura do peito (dash ou agachado passam)")
	afirmar(j != null, "jogador na arena")


func test_salto_sombra_1_s_e_pisao_pesado() -> void:
	var j := _antes()
	var c := _chefe(Vector2(240, 0))
	await esperar_frames(ENTRADA)
	_parar(c)
	var vida: int = j.vida.atual
	c.comecar_salto(j.global_position)
	afirmar(c.esta_anunciando(), "sombra no pouso")
	await esperar_frames(50)
	afirmar_igual(j.vida.atual, vida, "ainda no ar (1,0 s)")
	await esperar_frames(14)
	afirmar_igual(j.vida.atual, vida - 2, "pisão [PESADO] no pouso")
	afirmar_proximo(c.global_position.x, 0.0, 1.0, "pousou onde a sombra marcou")


func test_saraivada_5_alvos_e_o_espaco_entre_eles_e_seguro() -> void:
	var j := _antes()
	var c := _chefe(Vector2(300, 0))
	await esperar_frames(ENTRADA)
	_parar(c)
	var vida: int = j.vida.atual
	c.comecar_misseis(Vector2(j.global_position.x - 32.0, 0))  # Ryker entre dois alvos
	afirmar_igual(c.alvos_misseis.size(), 5, "5 alvos no chão")
	afirmar_proximo(c.alvos_misseis[1].x - c.alvos_misseis[0].x, 64.0, 0.1, "espaçados")
	await esperar_frames(80)
	afirmar_igual(j.vida.atual, vida, "entre os alvos não leva dano")


func test_fase_2_em_66_por_cento_com_reforcos_e_avisos_iguais() -> void:
	_antes()
	var c := _chefe()
	await esperar_frames(2)
	var aviso: float = c.tempo_aviso_varredura
	c.receber_ataque(InfoDano.criar(520, null, Vector2(-1, 0)))
	afirmar_igual(c.fase, 2, "fase 2 abaixo de 66%")
	afirmar_proximo(c.fator_velocidade(), 0.85, 0.001, "15% mais rápido")
	afirmar_proximo(c.tempo_aviso_varredura, aviso, 0.001, "os avisos não diminuem")
	afirmar_igual(c.trazer_reforcos(), 2, "a nave deixa 2 Guerreiros")
	afirmar_igual(c.trazer_reforcos(), 0, "só repõe quando morrem")


func test_ajoelha_e_expoe_o_nucleo_triplo() -> void:
	_antes()
	var c := _chefe()
	await esperar_frames(ENTRADA)
	c.receber_ataque(InfoDano.criar(520, null, Vector2(-1, 0)))
	c.ajoelhar()
	afirmar(c.esta_ajoelhado(), "ajoelhou")
	afirmar(c.nucleo.collision_layer != 0, "núcleo exposto")
	var antes: int = c.vida.atual
	c.nucleo.receber_ataque(InfoDano.criar(10, null))
	afirmar_igual(c.vida.atual, antes - 30, "núcleo: dano ×3")
	await esperar_frames(190)
	afirmar(not c.esta_ajoelhado(), "levanta depois de 3 s")
	afirmar_igual(c.nucleo.collision_layer, 0, "núcleo escondido")


func test_andador_cai_e_vem_a_fase_3_a_pe() -> void:
	_antes()
	var c := _chefe()
	await esperar_frames(2)
	c.vida.receber_dano(1500, true)
	await esperar_frames(1)
	afirmar(is_instance_valid(c) and c.esta_vivo(), "o andador cai, Ur-Kesh não")
	afirmar_igual([c.fase, c.vida.maxima, c.peso, c.tamanho], [3, 600, Inimigo.Peso.MEDIO, Vector2(32, 70)], "fase 3 a pé")
	c.vida.receber_dano(600, true)
	await esperar_frames(1)
	afirmar(not is_instance_valid(c) or not c.esta_vivo(), "na fase 3, morre")


func test_contra_ataque_do_grilhao_quebra_a_guarda() -> void:
	var j := _antes()
	var c := _chefe(Vector2(60, 0))
	await esperar_frames(2)
	c.vida.receber_dano(1500, true)
	await esperar_frames(1)
	c.estado = UrKesh.Estado.AVISO_AVANCO
	c._timer = 0.7
	(j.ferramenta as Grilhao)._ao_acertar(c)
	afirmar(c.guarda_quebrada_ativa(), "guarda quebrada")
	afirmar_proximo(c._timer_atordoado, 2.0, 0.05, "atordoado por 2,0 s")
	var antes: int = c.vida.atual
	c.receber_ataque(InfoDano.criar(10, null))
	afirmar_igual(c.vida.atual, antes - 20, "leva o dobro")


func test_rugido_chama_4_zangoes_e_o_machado_volta() -> void:
	_antes()
	var c := _chefe(Vector2(200, 0))
	await esperar_frames(2)
	c.vida.receber_dano(1500, true)
	await esperar_frames(1)
	afirmar_igual(c.chamar_zangoes(), 4, "4 Zangões")
	var m := MachadoBumerangue.lancar(self, c.centro(), -1.0, c)
	await esperar_frames(60)
	afirmar(is_instance_valid(m) and m.voltando, "o machado vai e volta")
	await esperar_frames(90)
	afirmar(not is_instance_valid(m), "voltou para a mão")


func test_sala_8_traz_o_chefe_e_a_vitoria_libera_o_bramido() -> void:
	var run: RunAto = instanciar(CENA_RUN)
	await esperar_frames(3)
	var encontros: int = Progresso.valor("urkesh_encontros")
	var nucleos: int = Progresso.valor("nucleos")
	var vitorias: int = Progresso.valor("urkesh_vitorias")
	var s := run.carregar_sala(8)
	run.jogador.vida.tornar_invulneravel(999.0)
	s.comecar_arena()
	await esperar_frames(2)
	_fechar_falas()
	afirmar_igual(Progresso.valor("urkesh_encontros"), encontros + 1, "conta o encontro")
	var chefe: UrKesh = null
	for i in s.inimigos.get_children():
		if i is UrKesh:
			chefe = i
	afirmar(chefe != null, "Ur-Kesh na arena")
	afirmar(run.barra_chefe.chefe == chefe, "barra de vida do chefe")
	chefe.vida.receber_dano(1500, true)
	await esperar_frames(2)
	_fechar_falas()
	chefe.vida.receber_dano(600, true)
	for i in s.inimigos.get_children():
		if i is Inimigo and i.esta_vivo():
			i.vida.receber_dano(9999, true)
	await esperar_frames(3)
	_fechar_falas()
	afirmar(s.arena_concluida, "arena do chefe limpa")
	afirmar(Progresso.tem_flag("bramido_liberado"), "1ª vitória libera o Bramido")
	afirmar_igual(Progresso.valor("urkesh_vitorias"), vitorias + 1, "conta a vitória")
	afirmar_igual(Progresso.valor("nucleos"), nucleos + 50, "+50 Núcleos")
	tree.paused = false


func _fechar_falas() -> void:
	var caixa := tree.get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	var limite: int = 50
	while caixa != null and caixa.esta_ativa() and limite > 0:
		caixa.avancar()
		limite -= 1
	tree.paused = false
