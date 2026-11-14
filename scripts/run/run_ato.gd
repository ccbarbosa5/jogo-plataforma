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
	sala.arena_comecou.connect(func() -> void: hud.mostrar_mensagem("ALERTA!", 1.0))
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
		"chefe":
			if not Dialogos.tocar("urkesh_primeiro"):
				Dialogos.tocar("urkesh_entrada")


func _ao_concluir_sala() -> void:
	hud.mostrar_mensagem("SALA LIMPA!", 1.2)
	if numero_sala == 0:
		Progresso.definir_flag("queda_completa_vista")
		Progresso.salvar()
	if sala.plano["tipo"] == "chefe":
		_fim_do_ato()


## Fim provisório do Ato 1: o chefe Ur-Kesh entra na tarefa 5.
func _fim_do_ato() -> void:
	jogador.ganhar_aprimoramento(1)  # o chefe dá 1 Ponto garantido (GD-01 §7.2)
	Progresso.incrementar("vitorias_ato1")
	Progresso.salvar()
	hud.mostrar_mensagem("FIM DO ATO 1\n(o chefe Ur-Kesh entra na próxima etapa)\nR: nova run")


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
	Progresso.incrementar("mortes_total")
	Progresso.definir_flag("1a_morte")
	Progresso.salvar()  # Núcleos e Dados ficam (GD-01 §8)
	hud.mostrar_mensagem("ECO: RECONSTRUINDO...")
	await get_tree().create_timer(tempo_teleporte).timeout
	get_tree().reload_current_scene()
