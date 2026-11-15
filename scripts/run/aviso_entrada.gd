class_name AvisoEntrada
extends Node2D
## Aviso de 1,0 s antes de uma entrada por trás ou de cima (GD-08 §3.1): seta piscando na
## borda (por trás) ou sombra no chão e marca no alto (de cima). Usa a cor AVISO (D-033).

var origem: StringName = &"atras"
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var visivel: bool = int(_t * 8.0) % 2 == 0
	if not visivel:
		return
	var cor: Color = Inimigo.COR_AVISO
	if origem == &"cima":
		draw_rect(Rect2(-5, -2, 10, 3), Color(cor, 0.8))
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -10), Vector2(4, -10), Vector2(0, -4)]), cor)
	else:
		# Seta apontando para dentro da tela (para a direita).
		draw_colored_polygon(PackedVector2Array([Vector2(0, -14), Vector2(10, -8), Vector2(0, -2)]), cor)
		draw_rect(Rect2(-6, -10, 6, 4), cor)
