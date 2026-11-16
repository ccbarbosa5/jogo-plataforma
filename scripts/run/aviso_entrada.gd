class_name AvisoEntrada
extends Node2D
## Aviso de 1,0 s antes de uma entrada por trás, de cima ou por uma toca (GD-08 §3.1):
## seta piscando na borda (por trás), sombra no chão e marca no alto (de cima), ou um buraco no
## chão que brilha (toca dos Roedores). Usa a cor AVISO (D-033).

## Quanto o buraco da toca fica aberto depois que o Roedor sai (s).
const TOCA_DEPOIS: float = 0.5

var origem: StringName = &"atras"
var _t: float = 0.0
var _encerrando: float = -1.0


## Fim do aviso: a seta/sombra some na hora; a toca fica um instante aberta e fecha.
func encerrar() -> void:
	if origem != &"toca":
		queue_free()
		return
	_encerrando = TOCA_DEPOIS


func _process(delta: float) -> void:
	_t += delta
	if _encerrando >= 0.0:
		_encerrando -= delta
		if _encerrando <= 0.0:
			queue_free()
	queue_redraw()


func _draw() -> void:
	var cor: Color = Inimigo.COR_AVISO
	if origem == &"toca":
		_desenhar_toca(cor)
		return
	var visivel: bool = int(_t * 8.0) % 2 == 0
	if not visivel:
		return
	if origem == &"cima":
		draw_rect(Rect2(-5, -2, 10, 3), Color(cor, 0.8))
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -10), Vector2(4, -10), Vector2(0, -4)]), cor)
	else:
		# Seta apontando para dentro da tela (para a direita).
		draw_colored_polygon(PackedVector2Array([Vector2(0, -14), Vector2(10, -8), Vector2(0, -2)]), cor)
		draw_rect(Rect2(-6, -10, 6, 4), cor)


## Buraco escuro no chão; enquanto avisa, a borda pisca na cor de aviso e solta terra.
func _desenhar_toca(cor: Color) -> void:
	var abertura: float = clampf(_t / 0.25, 0.0, 1.0)
	if _encerrando >= 0.0:
		abertura = clampf(_encerrando / TOCA_DEPOIS, 0.0, 1.0)
	var largura: float = roundf(12.0 * abertura)
	if largura < 2.0:
		return
	var buraco := Rect2(-largura * 0.5, 0, largura, 3)
	if _encerrando < 0.0 and int(_t * 8.0) % 2 == 0:
		draw_rect(buraco.grow(1.0), cor)
	draw_rect(buraco, Color("0d0a10"))
	if _encerrando < 0.0:
		# Terra pulando da borda.
		for k in 3:
			var fase: float = fmod(_t * 3.0 + k * 0.33, 1.0)
			var px: float = (k - 1) * largura * 0.4
			draw_rect(Rect2(roundf(px), roundf(-1.0 - fase * 6.0), 1, 1), Color("7a5a3c"))
