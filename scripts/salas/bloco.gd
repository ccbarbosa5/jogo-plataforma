@tool
class_name Bloco
extends StaticBody2D
## Bloco de cenário provisório (sem arte): cria a própria colisão e se desenha como retângulo.
## Com uma_via ligado vira plataforma de mão única (sobe por baixo, desce com baixo + pulo).
## Quando ART entregar o tileset, as salas passam a usar TileMapLayer e este script fica só para protótipos.

@export var tamanho: Vector2 = Vector2(64, 16):
	set(valor):
		tamanho = valor
		_atualizar()
@export var uma_via: bool = false:
	set(valor):
		uma_via = valor
		_atualizar()
@export var ativo: bool = true:
	set(valor):
		ativo = valor
		_atualizar()
@export var cor: Color = Color("3b4252"):
	set(valor):
		cor = valor
		queue_redraw()

var _forma: CollisionShape2D


func _ready() -> void:
	_atualizar()


func _atualizar() -> void:
	if not is_inside_tree():
		return
	if _forma == null:
		_forma = CollisionShape2D.new()
		add_child(_forma)  # sem owner: não é salvo na cena
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	_forma.shape = retangulo
	_forma.position = tamanho * 0.5
	_forma.one_way_collision = uma_via
	_forma.set_deferred("disabled", not ativo)
	collision_layer = Camadas.PLATAFORMAS if uma_via else Camadas.MUNDO
	collision_mask = 0
	visible = ativo
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, tamanho), cor)
	var borda: Color = cor.lightened(0.25)
	draw_rect(Rect2(Vector2.ZERO, Vector2(tamanho.x, 2.0)), borda)
