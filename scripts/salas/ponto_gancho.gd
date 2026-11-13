@tool
class_name PontoGancho
extends Area2D
## Ponto do cenário onde o Grilhão engata e puxa o Ryker (ex.: argola, viga, destroço).

const RAIO: float = 5.0


func _ready() -> void:
	collision_layer = Camadas.GANCHOS
	collision_mask = 0
	monitoring = false
	if get_child_count() == 0:
		var forma := CollisionShape2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = RAIO
		forma.shape = circulo
		add_child(forma)  # sem owner: não é salvo na cena


## Argola de ancoragem do tileset de Varrek (linha 2, coluna 6), igual em todo ponto de gancho.
const FOLHA: String = "res://assets/sprites/cenarios/varrek/varrek_tileset.png"
const REGIAO: Rect2 = Rect2(96, 32, 16, 16)


func _draw() -> void:
	var textura: Texture2D = FolhaSprite.carregar(FOLHA)
	if textura != null:
		draw_texture_rect_region(textura, Rect2(-REGIAO.size * 0.5, REGIAO.size), REGIAO)
	else:
		draw_arc(Vector2.ZERO, RAIO, 0.0, TAU, 16, Color("ebcb8b"), 2.0)
