class_name Projetil
extends Area2D
## Projétil genérico: anda em linha reta e causa dano em quem tiver receber_dano().
## Quem atira define camada e máscara (tiro do jogador acerta inimigos, e vice-versa).

@export var cor: Color = Color.WHITE
@export var tamanho: Vector2 = Vector2(6, 2)

var velocidade: Vector2 = Vector2.ZERO
var dano: int = 1
var tempo_restante: float = 1.0
var _ativo: bool = true


func configurar(posicao: Vector2, direcao: Vector2, velocidade_px: float, dano_: int,
		duracao: float, camada: int, mascara: int) -> void:
	global_position = posicao
	velocidade = direcao.normalized() * velocidade_px
	rotation = velocidade.angle()
	dano = dano_
	tempo_restante = duracao
	collision_layer = camada
	collision_mask = mascara


func _ready() -> void:
	body_entered.connect(_ao_tocar_corpo)


func _physics_process(delta: float) -> void:
	position += velocidade * delta
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		queue_free()


func _ao_tocar_corpo(corpo: Node2D) -> void:
	if not _ativo:
		return
	if corpo.has_method("receber_dano"):
		# Alvo invulnerável (ex.: durante o dash) deixa o tiro passar.
		if corpo.receber_dano(dano, self):
			_destruir()
	else:
		_destruir()


func _destruir() -> void:
	_ativo = false
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-tamanho * 0.5, tamanho), cor)
