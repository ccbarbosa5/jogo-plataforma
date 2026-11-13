class_name Projetil
extends Area2D
## Projétil genérico: anda em linha reta e entrega um InfoDano a quem tiver receber_ataque().
## Quem atira define camada, máscara e o InfoDano. Tiros do jogador também acertam pontos fracos.

@export var cor: Color = Color.WHITE
@export var tamanho: Vector2 = Vector2(6, 2)

var velocidade: Vector2 = Vector2.ZERO
var info: InfoDano = InfoDano.new()
var tempo_restante: float = 1.0
## Facção de quem atirou: o tiro atravessa aliados da mesma facção.
var faccao_autor: StringName = &""
var _ativo: bool = true


func configurar(posicao: Vector2, direcao: Vector2, velocidade_px: float, info_dano: InfoDano,
		duracao: float, camada: int, mascara: int) -> void:
	global_position = posicao
	velocidade = direcao.normalized() * velocidade_px
	rotation = velocidade.angle()
	info = info_dano
	info.direcao = velocidade.normalized()
	tempo_restante = duracao
	collision_layer = camada
	collision_mask = mascara


func _ready() -> void:
	body_entered.connect(_ao_tocar_corpo)
	area_entered.connect(_ao_tocar_area)


func _physics_process(delta: float) -> void:
	position += velocidade * delta
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		queue_free()


func _ao_tocar_area(area: Area2D) -> void:
	if _ativo and area is PontoFraco:
		_acertar(area)


func _ao_tocar_corpo(corpo: Node2D) -> void:
	if not _ativo:
		return
	if faccao_autor != &"" and corpo.get("faccao") == faccao_autor:
		return  # aliado
	# Se no mesmo instante também tocou o ponto fraco desse corpo, ele tem prioridade.
	for area in get_overlapping_areas():
		if area is PontoFraco and (area as PontoFraco).dono() == corpo:
			_acertar(area)
			return
	_acertar(corpo)


func _acertar(alvo: Node) -> void:
	if alvo.has_method("receber_ataque"):
		# Alvo invulnerável (ex.: durante o dash) deixa o tiro passar.
		if alvo.receber_ataque(info.copiar()):
			_destruir()
	else:
		_destruir()


func _destruir() -> void:
	_ativo = false
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-tamanho * 0.5, tamanho), cor)
