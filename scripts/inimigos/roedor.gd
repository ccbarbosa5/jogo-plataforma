class_name Roedor
extends InimigoEnxame
## Roedor (Vesh, enxame, GD-08 §2): 10×8, 12 de vida (1 tiro da Mordida), 4,5 tiles/s.
## Corre pelo chão até o jogador, pula degraus de até 1,5 tile e sobe paredes curtas (até 2 tiles).

const PASTA_SPRITES: String = "res://assets/sprites/inimigos/vesh/roedor/"

@export var altura_pulo_tiles: float = 1.5
@export var escalada_maxima_tiles: float = 2.0

var sprite: FolhaSprite
var _escalado: float = 0.0
var _escalando: bool = false


func _ready() -> void:
	super()
	sprite = FolhaSprite.new()
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.registrar(&"correr", FolhaSprite.carregar(PASTA_SPRITES + "roedor_correr.png"), 4, 12.0)
	sprite.registrar(&"pulo", FolhaSprite.carregar(PASTA_SPRITES + "roedor_pulo.png"), 1)
	sprite.registrar(&"escalar", FolhaSprite.carregar(PASTA_SPRITES + "roedor_escalar.png"), 2, 10.0)
	sprite.registrar(&"recuo", FolhaSprite.carregar(PASTA_SPRITES + "roedor_recuo.png"), 1)
	sprite.tocar(&"correr")


func _ao_reiniciar() -> void:
	_escalado = 0.0
	_escalando = false


func _perseguir(alvo: Node2D, delta: float) -> void:
	if alvo == null:
		velocity.x = move_toward(velocity.x, 0.0, Unidades.px(20.0) * delta)
		return
	var dx: float = alvo.global_position.x - global_position.x
	if absf(dx) > 2.0:
		olhando = 1 if dx > 0.0 else -1
	velocity.x = olhando * Unidades.px(velocidade)
	_escalando = false
	if is_on_floor():
		_escalado = 0.0
		if is_on_wall():
			velocity.y = -sqrt(2.0 * _gravidade() * Unidades.px(altura_pulo_tiles + 0.25))
	elif is_on_wall() and _escalado < Unidades.px(escalada_maxima_tiles):
		# Sobe a parede curta.
		_escalando = true
		velocity.y = -Unidades.px(velocidade)
		_escalado += Unidades.px(velocidade) * delta


func _physics_process(delta: float) -> void:
	super(delta)
	if sprite == null:
		return
	sprite.flip_h = olhando < 0
	sprite.modulate = Color(1.8, 1.8, 1.8) if _timer_flash > 0.0 else Color.WHITE
	if esta_recuando():
		sprite.tocar(&"recuo")
	elif _escalando:
		sprite.tocar(&"escalar")
	elif not is_on_floor():
		sprite.tocar(&"pulo")
	else:
		sprite.tocar(&"correr")


func _criar_efeito_morte() -> void:
	var folha: Texture2D = FolhaSprite.carregar(PASTA_SPRITES + "roedor_morte.png")
	if folha != null and get_parent() != null:
		EfeitoFolha.new().iniciar(get_parent(), global_position, folha, 4, 14.0, olhando < 0)
