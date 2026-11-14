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

var gerador: GeradorAto
var sala: SalaRun
var numero_sala: int = -1
var tela_arvore: TelaArvore
var tela_recompensa: TelaRecompensa
var _trocando: bool = false
var barra_chefe: BarraChefe


func _ready() -> void:
	add_to_group(&"run_ato")
	Combate.reiniciar()
	Progresso.limpar_run()
	gerador = GeradorAto.new(Progresso, semente)
	jogador.container_projeteis = projeteis
	jogador.morreu.connect(_ao_jogador_morrer)
	var grilhao := jogador.ferramenta as Grilhao
	if grilhao != null:
		grilhao.lancou.connect(func() -> void: Dialogos.tocar("queda_grilhao"))
	camera.alvos = [jogador]
	hud.conectar(jogador)
	($CaixaDialogo as CaixaDialogo).entrada = jogador.entrada
	tela_arvore = TelaArvore.new()
	add_child(tela_arvore)
	tela_arvore.entrada = jogador.entrada
	tela_recompensa = TelaRecompensa.new()
	add_child(tela_recompensa)
	tela_recompensa.entrada = jogador.entrada
	barra_chefe = BarraChefe.new()
	hud.add_child(barra_chefe)
	carregar_sala(0)


## Monta e entra na sala `n` do mapa.
func carregar_sala(n: int) -> SalaRun:
	if sala != null and is_instance_valid(sala):
		remove_child(sala)
		sala.queue_free()
	for p in projeteis.get_children():
		p.queue_free()
	numero_sala = n
	var plano: Dictionary = gerador.planejar_sala(n)
	sala = MontadorSala.montar(plano, gerador.blocos)
	add_child(sala)
	move_child(sala, 1)
	sala.iniciar(jogador, camera, projeteis, gerador.ondas)
	sala.porta_escolhida.connect(_ao_escolher_porta)
	sala.concluida.connect(_ao_concluir_sala)
	sala.inimigo_morreu.connect(_ao_inimigo_morrer)
	sala.arena_comecou.connect(_ao_comecar_arena)
	sala.chefe_apareceu.connect(func(c: UrKesh) -> void: barra_chefe.chefe = c)
	jogador.global_position = sala.inicio
	jogador.velocity = Vector2.ZERO
	jogador.posicao_segura = sala.inicio
	jogador.entrar_na_sala()
	camera.definir_limites(sala.limites())
	camera.posicionar_imediato()
	hud.mostrar_mensagem("SALA %d · %s" % [n, String(plano["nome"]).to_upper()], 1.8)
	_tocar_fala_de_entrada(plano)
	sala_carregada.emit(sala)
	return sala


func _tocar_fala_de_entrada(plano: Dictionary) -> void:
	match plano["tipo"]:
		"loja":
			if not Dialogos.tocar("loja_primeira"):
				Dialogos.tocar("loja_entrada")


## Créditos por inimigo (GD-02 §6.5) e +5 quando a facção rival mata (§4.4).
func _ao_inimigo_morrer(inimigo: Inimigo, pela_rival: bool) -> void:
	var ganho: int = randi_range(inimigo.creditos.x, inimigo.creditos.y)
	if pela_rival:
		ganho += 5
	jogador.creditos += ganho


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
	if numero_sala == 0:
		Progresso.definir_flag("queda_completa_vista")
		Progresso.salvar()
	if sala.plano["tipo"] == "chefe":
		_fim_do_ato()


## Vitória sobre Ur-Kesh (GD-02 §5): Núcleos, Dados e, na 1ª vez, o Bramido (NAR-03).
## No VS a run termina aqui ("Continua no Ato 2"); o Ponto de Aprimoramento vale para o ato seguinte.
func _fim_do_ato() -> void:
	var primeira: bool = not Progresso.tem_flag("bramido_liberado")
	Progresso.incrementar("urkesh_vitorias")
	Progresso.incrementar("vitorias_ato1")
	Progresso.incrementar("nucleos", 50)
	Progresso.incrementar("dados", 25 if primeira else 10)
	Progresso.incrementar("duvida")  # D-034: vitórias também contam
	Dialogos.tocar("vitoria")
	Progresso.definir_flag("bramido_liberado")
	Progresso.salvar()
	barra_chefe.chefe = null
	var texto: String = "VITÓRIA SOBRE UR-KESH\n+50 Núcleos · +%d Dados" % (25 if primeira else 10)
	if primeira:
		texto += "\nBramido liberado no Arsenal"
	hud.mostrar_mensagem(texto + "\nContinua no Ato 2 · R: nova run")


func _ao_escolher_porta(porta: PortaSaida) -> void:
	if _trocando:
		return
	_trocando = true
	await aplicar_recompensa(porta.tipo)
	_trocando = false
	if numero_sala + 1 < gerador.quantidade_de_salas():
		carregar_sala.call_deferred(numero_sala + 1)


## Aplica a recompensa da porta (GD-01 §7.4). Espera as telas fecharem.
func aplicar_recompensa(tipo: String) -> void:
	match tipo:
		"kharn", "vesh":
			if tela_recompensa.abrir(jogador, catalogo_kharn if tipo == "kharn" else catalogo_vesh):
				await tela_recompensa.fechou
		"aprimoramento":
			jogador.ganhar_aprimoramento(1)
			await tela_arvore.fechou
		"creditos":
			var v: int = gerador.valor_recompensa("creditos")
			jogador.creditos += v
			hud.mostrar_mensagem("+%d Créditos" % v, 1.2)
		"nucleos", "dados":
			var v: int = gerador.valor_recompensa(tipo)
			Progresso.incrementar(tipo, v)
			Progresso.salvar()
			hud.mostrar_mensagem("+%d %s" % [v, "Núcleos" if tipo == "nucleos" else "Dados de Inteligência"], 1.2)
		"vida_maxima":
			jogador.vida.maxima += 1
			jogador.vida.curar(1)
			hud.mostrar_mensagem("+1 bloco de vida máximo", 1.2)


## Reparo: a dádiva extra é de uma facção sorteada.
func oferecer_dadiva_extra(j: Jogador) -> void:
	tela_recompensa.abrir(j, catalogo_kharn if randf() < 0.5 else catalogo_vesh)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()
	if evento.is_action_pressed("arvore") and not tela_arvore.esta_aberta():
		if sala != null and sala.arena_ativa:
			hud.mostrar_mensagem("A árvore só abre fora de combate", 1.0)
		else:
			tela_arvore.abrir(jogador)
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
	get_tree().reload_current_scene()
