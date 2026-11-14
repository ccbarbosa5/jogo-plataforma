class_name Sala
extends Node2D
## Sala de teste da Fase 1 (GD-01, 7.1): trecho com rolagem lateral que termina
## numa arena com a câmera travada e uma onda de inimigos.
## Na morte, a ECO "reconstrói" o Ryker: por enquanto, a sala simplesmente reinicia.

@export var limites_sala: Rect2 = Rect2(0, 0, 1440, 270)
@export var limites_arena: Rect2 = Rect2(960, 0, 480, 270)
@export var cena_inimigo: PackedScene
@export var tempo_teleporte: float = 1.5
## Créditos para testar a loja Ilo enquanto os inimigos não dão Créditos (proposta à GD).
@export var creditos_iniciais: int = 100
## Armas do Arsenal provisório (F7 troca).
@export var armas_arsenal: Array[DadosArma] = []
## Facções das portas de recompensa (Kharn e Vesh no VS).
@export var catalogos_faccoes: Array[CatalogoFaccao] = []

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
var _cena_revisao: int = -1
var tela_arvore: TelaArvore
var tela_recompensa: TelaRecompensa
var _oferta_debug: int = 0


func _ready() -> void:
	Combate.reiniciar()
	jogador.container_projeteis = projeteis
	jogador.entrar_na_sala()
	jogador.limite_queda_y = limites_sala.end.y + 24.0
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
	($CaixaDialogo as CaixaDialogo).entrada = jogador.entrada
	tela_arvore = TelaArvore.new()
	add_child(tela_arvore)
	tela_arvore.entrada = jogador.entrada
	jogador.ganhou_aprimoramento.connect(func(j: Jogador) -> void: tela_arvore.abrir.call_deferred(j))
	jogador.creditos = creditos_iniciais
	tela_recompensa = TelaRecompensa.new()
	add_child(tela_recompensa)
	tela_recompensa.entrada = jogador.entrada
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
	if evento.is_action_pressed("debug_ver_dialogos"):
		# Revisão das falas no jogo (NAR, ART, QA): cada F6 mostra a próxima cena, sem gravar progresso.
		var cenas: Array = Dialogos.banco.cenas.keys()
		_cena_revisao = (_cena_revisao + 1) % cenas.size()
		hud.mostrar_mensagem("Cena %d/%d: %s" % [_cena_revisao + 1, cenas.size(), cenas[_cena_revisao]], 2.0)
		Dialogos.previsualizar(cenas[_cena_revisao])
	if evento.is_action_pressed("arvore") and not tela_arvore.esta_aberta():
		# Fora de combate a árvore abre a qualquer hora (GD-05 §2.2).
		if arena_ativa:
			hud.mostrar_mensagem("A árvore só abre fora de combate", 1.0)
		else:
			tela_arvore.abrir(jogador)
	if evento.is_action_pressed("debug_trocar_arma") and not armas_arsenal.is_empty():
		# Arsenal provisório: troca a arma e zera a árvore (D-038: na run de verdade não se troca).
		var i: int = (armas_arsenal.find(jogador.arma) + 1) % armas_arsenal.size()
		jogador.equipar(armas_arsenal[i])
		hud.mostrar_mensagem("Arsenal: %s" % armas_arsenal[i].nome, 1.2)
		if armas_arsenal[i].id == &"bramido":
			Dialogos.tocar("arsenal_escolha_bramido")
		else:
			Dialogos.tocar("arsenal_escolha_mordida")
	if evento.is_action_pressed("debug_oferta") and not catalogos_faccoes.is_empty() and not tela_recompensa.esta_aberta():
		# Abre uma oferta de dádiva, alternando as facções.
		tela_recompensa.abrir(jogador, catalogos_faccoes[_oferta_debug % catalogos_faccoes.size()])
		_oferta_debug += 1
	if evento.is_action_pressed("debug_aprimoramento"):
		jogador.ganhar_aprimoramento(1)
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
	var jogadores: Array[Vector2] = []
	for no in get_tree().get_nodes_in_group("jogadores"):
		jogadores.append((no as Node2D).global_position)
	var limite := Vector2(limites_arena.position.x + 16.0, limites_arena.end.x - 16.0)
	for ponto in pontos_onda.get_children():
		var inimigo: Inimigo = cena_inimigo.instantiate()
		# Entrada justa (D-036): nunca a menos de 6 tiles de um jogador.
		inimigo.position = RegrasSurgimento.posicao_justa((ponto as Node2D).position, jogadores, limite)
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
	hud.mostrar_mensagem("SALA LIMPA!")
	# Saídas da sala (GD-01 §7.1): dádiva Kharn, Aprimoramento de Arma e dádiva Vesh.
	# O jogador pega 1; as outras somem.
	var centro: float = limites_arena.get_center().x
	var porta := PortaAprimoramento.new()
	porta.position = Vector2(centro, 240.0)
	add_child.call_deferred(porta)
	for i in catalogos_faccoes.size():
		var pf := PortaFaccao.new()
		pf.catalogo = catalogos_faccoes[i]
		pf.position = Vector2(centro + (-56.0 if i == 0 else 56.0 * i), 240.0)
		add_child.call_deferred(pf)


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
