class_name PontoFraco
extends Area2D
## Hitbox de ponto fraco, filha de um Inimigo (radiador do andador, tanque do Brutamontes, núcleo do Ninho).
## Acertar aqui multiplica o dano. Com o Golpe de Arena do Ryker ativo, o bônus dobra de novo.
## Só tiros mirados e o Grilhão alcançam pontos fracos (a mira automática mira no centro do corpo).

@export var multiplicador: float = 2.0
## Tamanho da hitbox em px.
@export var tamanho: Vector2 = Vector2(10, 10)


func _ready() -> void:
	collision_layer = Camadas.PONTOS_FRACOS
	collision_mask = 0
	monitoring = false
	if get_child_count() == 0:
		var forma := CollisionShape2D.new()
		var retangulo := RectangleShape2D.new()
		retangulo.size = tamanho
		forma.shape = retangulo
		add_child(forma)


func dono() -> Inimigo:
	return get_parent() as Inimigo


func receber_ataque(info: InfoDano) -> bool:
	var inimigo: Inimigo = dono()
	if inimigo == null:
		return false
	var golpe := info.copiar()
	golpe.ponto_fraco = true
	golpe.multiplicador *= multiplicador
	if info.autor != null and is_instance_valid(info.autor) and info.autor.has_method("golpe_de_arena_ativo") \
			and info.autor.golpe_de_arena_ativo():
		golpe.multiplicador *= 2.0
	return inimigo.receber_ataque(golpe)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Pulsante (pedido de GD a ART).
	var pulso: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0)
	draw_rect(Rect2(-tamanho * 0.5, tamanho), Color(1.0, 0.85, 0.3, 0.5 + 0.5 * pulso))
