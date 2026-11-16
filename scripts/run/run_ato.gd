class_name RunAto
extends Node2D
## Uma run do Ato 1 (GD-01 §7.3): sala 0 (Queda) → 1 → 2 → 3 → 4 (Loja ou Reparo) → 5 → 6 (Elite)
## → 7 (Reparo, aproximação da relíquia) → 8 (Chefe). O Ryker, a câmera, o HUD e as telas são
## os mesmos em todas as salas; cada sala é montada na hora pelo GeradorAto + MontadorSala.
## Na morte, a ECO "reconstrói" o Ryker: por enquanto a run recomeça (a nave entra na tarefa 6).

signal sala_carregada(sala: SalaRun)

@export var tempo_teleporte: float = 1.5
## Semente fixa para depurar (-1 = aleatória).
@export var semente: int = -1
@export var catalogo_kharn: CatalogoFaccao
@export var catalogo_vesh: CatalogoFaccao

@onready var jogador: Jogador = $Ryker
@onready var camera: CameraJogo = $Camera
@onready var hud: Hud = $Hud
@onready var projeteis: Node2D = $Projeteis

## Plano da sala seguinte, feito antes pela Leitura de Sinal.
var _plano_seguinte: Dictionary = {}
var gerador: GeradorAto
var sala: SalaRun
var numero_sala: int = -1
var tela_recompensa: TelaRecompensa
## Gambiarras (GD-07 §5): 1 entre 3 ao limpar cada sala de Combate ou Elite.
var tela_gambiarras: TelaGambiarras
var banco_gambiarras: BancoGambiarras
var rng_gambiarras: RandomNumberGenerator = RandomNumberGenerator.new()
## XP, nível e árvore de Combate do Ryker (GD-07 §4).
var progressao: ProgressaoPersonagem
var _trocando: bool = false
var barra_chefe: BarraChefe


func _ready() -> void:
	add_to_group(&"run_ato")
	Combate.reiniciar()
	Progresso.limpar_run()
	gerador = GeradorAto.new(Progresso, semente)
	jogador.container_projeteis = projeteis
	# Arma do Arsenal e melhorias da Vossa Margem (GD-01 §9).
	jogador.equipar(Ciclo.dados_da_arma())
	# Códice (NAR-05 §5.1): o parágrafo extra da arma destrava depois de 10 runs com ela.
	Progresso.incrementar("runs_" + String(Ciclo.arma_escolhida))
	MelhoriasPermanentes.aplicar(jogador, Progresso)
	progressao = ProgressaoPersonagem.new("ryker")
	progressao.aplicar(jogador, Progresso)
	Progresso.definir_run("nivel_inicial", progressao.nivel(Progresso))
	Progresso.definir_run("xp_ganho", 0)
	jogador.voltou.connect(func(_j: Jogador) -> void: hud.mostrar_mensagem("SINAL DE EMERGÊNCIA: A ECO TE PUXOU DE VOLTA", 1.5))
	jogador.morreu.connect(_ao_jogador_morrer)
	var grilhao := jogador.ferramenta as Grilhao
	if grilhao != null:
		grilhao.lancou.connect(func() -> void: Dialogos.tocar("queda_grilhao"))
	camera.alvos = [jogador]
	hud.conectar(jogador)
	($CaixaDialogo as CaixaDialogo).entrada = jogador.entrada
	tela_recompensa = TelaRecompensa.new()
	add_child(tela_recompensa)
	tela_recompensa.entrada = jogador.entrada
	barra_chefe = BarraChefe.new()
	hud.add_child(barra_chefe)
	banco_gambiarras = BancoGambiarras.new()
	if semente >= 0:
		rng_gambiarras.seed = semente
	else:
		rng_gambiarras.randomize()
	tela_gambiarras = TelaGambiarras.new()
	add_child(tela_gambiarras)
	carregar_sala(0)
	if Progresso.tem_flag("treino_garrak"):
		_treino_com_garrak.call_deferred()


## Monta e entra na sala `n` do mapa.
func carregar_sala(n: int) -> SalaRun:
	if sala != null and is_instance_valid(sala):
		remove_child(sala)
		sala.queue_free()
	for p in projeteis.get_children():
		p.queue_free()
	numero_sala = n
	# Leitura de Sinal: a sala seguinte já foi planejada para mostrar nas portas.
	var plano: Dictionary = _plano_seguinte if int(_plano_seguinte.get("numero", -1)) == n else gerador.planejar_sala(n)
	_plano_seguinte = {}
	sala = MontadorSala.montar(plano, gerador.blocos)
	add_child(sala)
	move_child(sala, 1)
	sala.iniciar(jogador, camera, projeteis, gerador.ondas)
	sala.porta_escolhida.connect(_ao_escolher_porta)
	sala.concluida.connect(_ao_concluir_sala)
	sala.inimigo_morreu.connect(_ao_inimigo_morrer)
	sala.arena_comecou.connect(_ao_comecar_arena)
	sala.chefe_apareceu.connect(func(c: UrKesh) -> void: barra_chefe.chefe = c)
	if not sala.portas.is_empty():  # loja e reparo: portas desde o começo
		mostrar_leitura_de_sinal.call_deferred()
	jogador.global_position = sala.inicio
	jogador.velocity = Vector2.ZERO
	jogador.posicao_segura = sala.inicio
	jogador.entrar_na_sala()
	camera.definir_limites(sala.limites())
	camera.posicionar_imediato()
	hud.mostrar_mensagem("SALA %d · %s" % [n, String(plano["nome"]).to_upper()], 1.8)
	if n == 0:
		hud.mostrar_dica(dica_do_tutorial())
	else:
		hud.esconder_dica()
	_tocar_fala_de_entrada(plano)
	sala_carregada.emit(sala)
	return sala


## Dica de teclas da sala 0 (D-054), com as teclas que o jogador escolheu nos Controles.
static func dica_do_tutorial() -> String:
	var c: Callable = Config.tecla_principal
	return "%s %s andar · %s pular · Mouse mirar · %s atirar · %s Grilhão · %s dash · %s granada · Esc pausa" % [
		c.call(&"mover_esquerda"), c.call(&"mover_direita"), c.call(&"pular"), c.call(&"atirar"),
		c.call(&"ferramenta"), c.call(&"dash"), c.call(&"granada")]


func _tocar_fala_de_entrada(plano: Dictionary) -> void:
	match plano["tipo"]:
		"loja":
			if not Dialogos.tocar("loja_primeira"):
				Dialogos.tocar("loja_entrada")


## Créditos por inimigo (GD-02 §6.5; enxame: 10% de 1, GD-08 §4) e +5 quando a facção rival mata (§4.4).
func _ao_inimigo_morrer(inimigo: Inimigo, pela_rival: bool) -> void:
	var ganho: int = randi_range(inimigo.creditos.x, inimigo.creditos.y) if randf() < inimigo.chance_creditos else 0
	if pela_rival:
		ganho += 5
	jogador.creditos += ganho
	ganhar_xp(progressao.xp_do_inimigo(inimigo))
	# NAR-06 §2.7: 1º abate da 1ª descida com um Ápice comprado ("é o que eu fazia na final").
	if progressao.apices(Progresso) > 0:
		Dialogos.tocar("campo_primeiro_apice")


## XP permanente (GD-07 §4.1), com a Memória da Âncora. Fica salvo mesmo se o Ryker morrer;
## o total da run aparece na nave, na reconstrução.
func ganhar_xp(valor: int) -> void:
	var xp: int = roundi(valor * MelhoriasPermanentes.mult_xp(Progresso))
	progressao.ganhar_xp(Progresso, xp)
	Progresso.definir_run("xp_ganho", Progresso.valor("xp_ganho") + xp)


## Núcleos com a Coleta Fina (árvore Passiva).
func ganhar_nucleos(valor: int) -> int:
	var total: int = roundi(valor * MelhoriasPermanentes.mult_nucleos(Progresso))
	Progresso.incrementar("nucleos", total)
	return total


func _ao_comecar_arena() -> void:
	if sala.plano["tipo"] != "chefe":
		hud.mostrar_mensagem("ALERTA!", 1.0)
		return
	# Encontro com Ur-Kesh (NAR-01): 1ª vez ou entradas que reagem à run.
	Progresso.incrementar("urkesh_encontros")
	if not Dialogos.tocar("urkesh_primeiro"):
		Dialogos.tocar("urkesh_entrada")


func _ao_concluir_sala() -> void:
	hud.mostrar_mensagem("SALA LIMPA!", 1.2)
	mostrar_leitura_de_sinal.call_deferred()
	var tipo: String = sala.plano.get("tipo", "")
	if tipo == "combate" or tipo == "elite":
		oferecer_gambiarra.call_deferred(tipo == "elite")
	if numero_sala == 0:
		Progresso.definir_flag("queda_completa_vista")
		Progresso.salvar()
	if sala.plano["tipo"] == "chefe":
		_fim_do_ato()


## Leitura de Sinal (GD-03 §3.3, Ponte): cada porta mostra o que vem na sala seguinte (o tipo
## da sala e as recompensas das portas dela). A sala seguinte é planejada agora e usada depois,
## então a prévia é exata.
func mostrar_leitura_de_sinal() -> void:
	if not Progresso.tem_flag("leitura_sinal") or sala == null or sala.portas.is_empty():
		return
	if numero_sala + 1 >= gerador.quantidade_de_salas():
		return
	_plano_seguinte = gerador.planejar_sala(numero_sala + 1)
	var texto: String = texto_da_previa(_plano_seguinte)
	for porta in sala.portas:
		if is_instance_valid(porta):
			porta.previa = texto


static func texto_da_previa(plano: Dictionary) -> String:
	var nomes: Array[String] = []
	for t: String in plano.get("portas", []):
		nomes.append(RegrasRecompensas.NOMES.get(t, t))
	var sala_seguinte: String = String(plano.get("nome", ""))
	if plano.get("elite", false):
		sala_seguinte += " (Elite)"
	if nomes.is_empty():
		return "Depois: %s" % sala_seguinte
	return "Depois: %s → %s" % [sala_seguinte, ", ".join(nomes)]


## Vitória sobre Ur-Kesh (GD-02 §5): Núcleos, Dados e, na 1ª vez, o Bramido (NAR-03).
## No VS a run termina aqui ("Continua no Ato 2").
func _fim_do_ato() -> void:
	var primeira: bool = not Progresso.tem_flag("bramido_liberado")
	Progresso.incrementar("urkesh_vitorias")
	Progresso.incrementar("vitorias_ato1")
	var nucleos: int = ganhar_nucleos(50)
	if primeira:
		ganhar_xp(int(progressao.xp["chefe_primeira_vitoria"]))  # +100 só na 1ª vitória
	Progresso.incrementar("dados", 25 if primeira else 10)
	Progresso.incrementar("duvida")  # D-034: vitórias também contam
	Dialogos.tocar("vitoria")
	Progresso.definir_flag("bramido_liberado")
	Progresso.salvar()
	barra_chefe.chefe = null
	var texto: String = "VITÓRIA SOBRE UR-KESH\n+%d Núcleos · +%d Dados" % [nucleos, 25 if primeira else 10]
	if primeira:
		texto += "\nBramido liberado no Arsenal"
	hud.mostrar_mensagem(texto + "\nContinua no Ato 2")
	if not Ciclo.trocar_cena:
		return  # testes: fica na run
	await get_tree().create_timer(4.0).timeout
	var caixa := get_tree().get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	while caixa != null and caixa.esta_ativa():
		await caixa.terminou
	Ciclo.voltar_para_nave("vitoria")


func _ao_escolher_porta(porta: PortaSaida) -> void:
	if _trocando:
		return
	_trocando = true
	var ok: bool = await aplicar_recompensa(porta.tipo)
	_trocando = false
	if not ok:
		sala.reabrir_portas()  # D-068: voltou sem escolher; as portas continuam lá
		return
	sala.confirmar_porta(porta)
	if numero_sala + 1 < gerador.quantidade_de_salas():
		carregar_sala.call_deferred(numero_sala + 1)


## Aplica a recompensa da porta (GD-01 §7.4). Espera as telas fecharem. Devolve false se o
## jogador voltou da escolha sem escolher (D-068).
func aplicar_recompensa(tipo: String) -> bool:
	match tipo:
		"kharn", "vesh":
			if tela_recompensa.abrir(jogador, catalogo_kharn if tipo == "kharn" else catalogo_vesh):
				await tela_recompensa.fechou
				return not tela_recompensa.cancelada
		"creditos":
			var v: int = gerador.valor_recompensa("creditos")
			jogador.creditos += v
			hud.mostrar_mensagem("+%d Créditos" % v, 1.2)
		"nucleos", "dados":
			var v: int = gerador.valor_recompensa(tipo)
			if tipo == "nucleos":
				v = ganhar_nucleos(v)
			else:
				Progresso.incrementar(tipo, v)
			Progresso.salvar()
			hud.mostrar_mensagem("+%d %s" % [v, "Núcleos" if tipo == "nucleos" else "Dados de Inteligência"], 1.2)
		"vida_maxima":
			jogador.vida.maxima += 1
			jogador.vida.curar(1)
			hud.mostrar_mensagem("+1 bloco de vida máximo", 1.2)
	return true


## Gambiarra (GD-07 §5.1): 3 cartas da arma em uso; Elite garante 1 Rara ou melhor.
## `so_comuns`: Treino com Garrak. Espera a escolha.
func oferecer_gambiarra(elite: bool = false, so_comuns: bool = false, titulo: String = "GAMBIARRA") -> void:
	var sortear := func() -> Array[ModificadorArma]:
		return banco_gambiarras.sortear(jogador.arma_equipada, rng_gambiarras, elite, so_comuns)
	tela_gambiarras.ao_recalibrar = sortear
	if tela_gambiarras.abrir(jogador, sortear.call(), titulo):
		var m: ModificadorArma = await tela_gambiarras.fechou
		registrar_gambiarra(m)


## Conta a Gambiarra na run (Garrak comenta na volta) e o Ryker fala ao escolher (NAR-06 §2.6).
func registrar_gambiarra(m: ModificadorArma) -> void:
	if m == null:
		return
	Progresso.definir_run("gambiarras_pegas", int(Progresso.estado_run.get("gambiarras_pegas", 0)) + 1)
	if m.raridade == ModificadorArma.Raridade.EPICA:
		Progresso.definir_run("gambiarra_epica", true)
	Progresso.definir_flag("1a_gambiarra_pega")  # destrava "arsenal_aprimoramento" na nave
	if m.id == &"prego_do_rato" and Dialogos.tocar("gambiarra_prego"):
		return
	if m.raridade == ModificadorArma.Raridade.EPICA and Dialogos.tocar("gambiarra_epica_primeira"):
		return
	if not Dialogos.tocar("campo_aprimoramento_primeiro"):
		Dialogos.tocar("campo_aprimoramento")


## Treino com Garrak (desbloqueio com Dados): começa a run com 1 Gambiarra Comum à escolha.
## Espera as falas da queda terminarem.
func _treino_com_garrak() -> void:
	var caixa := get_tree().get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	while caixa != null and caixa.esta_ativa():
		await caixa.terminou
	await oferecer_gambiarra(false, true, "TREINO COM GARRAK")


## Loja do Ilo: Oferta da facção escolhida na banca (GD-02 §6.5). Devolve true se o jogador
## escolheu (D-068: voltar sem escolher não gasta nada).
func abrir_dadiva(j: Jogador, faccao: String) -> bool:
	if not tela_recompensa.abrir(j, catalogo_kharn if faccao == "kharn" else catalogo_vesh):
		return false
	await tela_recompensa.fechou
	return not tela_recompensa.cancelada


## Reparo: a Oferta extra é de uma facção sorteada (a mesma se o jogador voltar e abrir de novo).
var _faccao_extra: String = ""


func oferecer_dadiva_extra(j: Jogador) -> bool:
	if _faccao_extra.is_empty():
		_faccao_extra = "kharn" if randf() < 0.5 else "vesh"
	var ok: bool = await abrir_dadiva(j, _faccao_extra)
	if ok:
		_faccao_extra = ""
	return ok


func _unhandled_input(evento: InputEvent) -> void:
	if Depuracao.ativa():
		_atalhos_de_teste(evento)


## F2/F3 assistências, F10 próxima sala, F11 sala de teste, R reinicia. Só em depuração (D-054).
func _atalhos_de_teste(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()
	if evento.is_action_pressed("debug_tiro_automatico"):
		jogador.assistencias.tiro_automatico = not jogador.assistencias.tiro_automatico
		hud.mostrar_mensagem("Tiro automático: %s" % ("LIGADO" if jogador.assistencias.tiro_automatico else "DESLIGADO"), 1.2)
	if evento.is_action_pressed("debug_mira_automatica"):
		var opcoes: Assistencias = jogador.assistencias
		opcoes.modo_mira = ((opcoes.modo_mira + 1) % 3) as Assistencias.ModoMira
		hud.mostrar_mensagem("Mira automática: %s" % ["DESLIGADA", "ASSISTIDA", "TOTAL"][opcoes.modo_mira], 1.2)
	if evento.is_action_pressed("debug_proxima_sala") and numero_sala + 1 < gerador.quantidade_de_salas():
		carregar_sala(numero_sala + 1)  # pular sala (teste)
	if evento.is_action_pressed("debug_sala_teste"):
		get_tree().change_scene_to_file("res://scenes/salas/sala_teste.tscn")


func _ao_jogador_morrer(_j: Jogador) -> void:
	if sala != null and sala.plano.get("tipo", "") == "chefe" and sala.arena_ativa:
		Progresso.incrementar("mortes_urkesh")
		Progresso.definir_flag("1a_morte_urkesh")
		Dialogos.tocar("urkesh_mata_ryker")
	Progresso.incrementar("mortes_total")
	Progresso.definir_flag("1a_morte")
	Progresso.salvar()  # Núcleos e Dados ficam (GD-01 §8)
	hud.mostrar_mensagem("ECO: RECONSTRUINDO...")
	await get_tree().create_timer(tempo_teleporte).timeout
	Ciclo.voltar_para_nave("morte")
