class_name Sala
extends Node2D
## Sala de teste da Fase 1 (GD-01, 7.1): trecho com rolagem lateral que termina
## numa arena com a câmera travada e uma onda de inimigos.
## Na morte, a ECO "reconstrói" o Ryker: por enquanto, a sala simplesmente reinicia.

@export var limites_sala: Rect2 = Rect2(0, 0, 1440, 270)
@export var limites_arena: Rect2 = Rect2(960, 0, 480, 270)
@export var cena_inimigo: PackedScene
@export var tempo_teleporte: float = 1.5

@onready var jogador: Jogador = $Ryker
@onready var camera: CameraJogo = $Camera
@onready var hud: Hud = $Hud
@onready var projeteis: Node2D = $Projeteis
@onready var inimigos: Node2D = $Inimigos
@onready var gatilho_arena: Area2D = $GatilhoArena
@onready var paredes_arena: Node2D = $ParedesArena
@onready var pontos_onda: Node2D = $PontosOnda

var arena_ativa: bool = false
var arena_concluida: bool = false
var _onda: Array[Inimigo] = []


func _ready() -> void:
	Combate.reiniciar()
	jogador.container_projeteis = projeteis
	jogador.reabastecer_granadas()
	var grilhao := jogador.ferramenta as Grilhao
	if grilhao != null:
		grilhao.lancou.connect(func() -> void: Dialogos.tocar("queda_grilhao"))
	jogador.morreu.connect(_ao_jogador_morrer)
	for inimigo in inimigos.get_children():
		_registrar_inimigo(inimigo as Inimigo)
	camera.alvos = [jogador]
	camera.definir_limites(limites_sala)
	camera.posicionar_imediato()
	hud.conectar(jogador)
	gatilho_arena.collision_layer = 0
	gatilho_arena.collision_mask = Camadas.JOGADOR
	gatilho_arena.body_entered.connect(_ao_entrar_arena)
	_ativar_paredes(false)
	hud.mostrar_mensagem("PROTÓTIPO · FASE 1", 2.0)
	Dialogos.tocar("queda_saida")


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()
	# Atalhos provisórios até existir o menu de opções (Fase 2).
	var opcoes: Assistencias = jogador.assistencias
	if evento.is_action_pressed("debug_mira_automatica"):
		opcoes.modo_mira = ((opcoes.modo_mira + 1) % 3) as Assistencias.ModoMira
		var nomes: Array[String] = ["DESLIGADA", "ASSISTIDA", "TOTAL"]
		hud.mostrar_mensagem("Mira automática: %s" % nomes[opcoes.modo_mira], 1.2)
	if evento.is_action_pressed("debug_tiro_automatico"):
		opcoes.tiro_automatico = not opcoes.tiro_automatico
		hud.mostrar_mensagem("Tiro automático: %s" % ("LIGADO" if opcoes.tiro_automatico else "DESLIGADO"), 1.2)
	if evento.is_action_pressed("debug_apagar_progresso"):
		Progresso.apagar()
		hud.mostrar_mensagem("Progresso apagado (falas de \"1ª vez\" voltam a tocar)", 1.5)


func _registrar_inimigo(inimigo: Inimigo) -> void:
	if inimigo == null:
		return
	inimigo.container_projeteis = projeteis
	inimigo.morreu.connect(_ao_inimigo_morrer)


func _ao_entrar_arena(corpo: Node2D) -> void:
	if arena_ativa or arena_concluida or not corpo is Jogador:
		return
	arena_ativa = true
	# Adiado: não dá para criar áreas de física no meio do aviso de colisão.
	_iniciar_arena.call_deferred()


func _iniciar_arena() -> void:
	camera.definir_limites(limites_arena)
	_ativar_paredes(true)
	hud.mostrar_mensagem("ALERTA!", 1.0)
	for ponto in pontos_onda.get_children():
		var inimigo: Inimigo = cena_inimigo.instantiate()
		inimigo.position = (ponto as Node2D).position
		inimigos.add_child(inimigo)
		_registrar_inimigo(inimigo)
		_onda.append(inimigo)


func _ao_inimigo_morrer(inimigo: Inimigo) -> void:
	Dialogos.tocar("queda_primeira_morte_inimigo")
	_onda.erase(inimigo)
	if arena_ativa and _onda.is_empty():
		_concluir_arena()


func _concluir_arena() -> void:
	arena_ativa = false
	arena_concluida = true
	_ativar_paredes(false)
	hud.mostrar_mensagem("SALA LIMPA!\n(as portas com recompensa entram na Fase 2)")


func _ativar_paredes(ativas: bool) -> void:
	for parede in paredes_arena.get_children():
		(parede as Bloco).ativo = ativas


func _ao_jogador_morrer(_jogador: Jogador) -> void:
	Progresso.incrementar("mortes_total")
	Progresso.definir_flag("1a_morte")
	Progresso.salvar()
	hud.mostrar_mensagem("ECO: RECONSTRUINDO...")
	await get_tree().create_timer(tempo_teleporte).timeout
	get_tree().reload_current_scene()
