class_name Zangao
extends InimigoEnxame
## Zangão (Vesh, enxame, GD-08 §2): 12×12, voa, 8 de vida, 5 tiles/s, peso Leve.
## Voa em zigue-zague até o jogador. Só machuca por contato (o mergulho anunciado saiu).

const PASTA_SPRITES: String = "res://assets/sprites/inimigos/vesh/zangao/"

## Amplitude do zigue-zague (fração da velocidade) e frequência (rad/s).
@export var zigue: float = 0.7
@export var frequencia_zigue: float = 6.0

## A esta distância (px) o Zangão ignora o desvio do bando e vai direto ao jogador.
const PERTO_DIRETO: float = 40.0

var sprite: FolhaSprite
var _fase: float = 0.0


func _ready() -> void:
	super()
	collision_mask = Camadas.MUNDO
	_fase = randf() * TAU
	sprite = FolhaSprite.new()
	sprite.name = "Sprite"
	sprite.position = Vector2(0, 2)
	add_child(sprite)
	sprite.registrar(&"voo", FolhaSprite.carregar(PASTA_SPRITES + "zangao_voo.png"), 4, 16.0)
	sprite.tocar(&"voo")


func _perseguir(alvo: Node2D, delta: float) -> void:
	_fase += delta * frequencia_zigue
	if alvo == null:
		velocity = velocity.move_toward(Vector2.ZERO, Unidades.px(20.0) * delta)
		return
	var para: Vector2 = MiraAutomatica.centro_de(alvo) - centro()
	# Espalha o bando na chegada; de perto, vai direto (senão podia ficar rondando ao lado do
	# jogador sem encostar quando o desvio sorteado era grande).
	if para.length() > PERTO_DIRETO:
		para.x += desvio_x
	var dir: Vector2 = para.normalized()
	var lado: Vector2 = Vector2(-dir.y, dir.x) * sin(_fase) * zigue
	velocity = (dir + lado).normalized() * Unidades.px(velocidade)
	olhar_para(alvo)


func _physics_process(delta: float) -> void:
	super(delta)
	if sprite != null:
		sprite.flip_h = olhando < 0
		sprite.modulate = Color(1.8, 1.8, 1.8) if _timer_flash > 0.0 else Color.WHITE


func _criar_efeito_morte() -> void:
	var folha: Texture2D = FolhaSprite.carregar(PASTA_SPRITES + "zangao_morte.png")
	if folha != null and get_parent() != null:
		EfeitoFolha.new().iniciar(get_parent(), global_position + Vector2(0, 2), folha, 3, 14.0, olhando < 0)


func _draw() -> void:
	_desenhar_status()
