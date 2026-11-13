class_name HudPainel
extends Control
## Desenha o estado do jogador: vida em blocos bem visíveis (pedido de GD), dash e arma.

const COR_VIDA: Color = Color("e84a5f")
const COR_VAZIO: Color = Color("4c566a")
const COR_DASH: Color = Color("7fdcff")

var jogador: Jogador


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(jogador):
		return
	var vida: Vida = jogador.vida
	for i in vida.maxima:
		var bloco := Rect2(Vector2(i * 13.0, 0.0), Vector2(11.0, 9.0))
		draw_rect(bloco, COR_VIDA if i < vida.atual else COR_VAZIO)
		draw_rect(bloco, Color.BLACK, false, 1.0)
	for i in jogador.parametros.cargas_dash:
		var barra := Rect2(Vector2(i * 13.0, 12.0), Vector2(11.0, 3.0))
		draw_rect(barra, COR_DASH if i < jogador.cargas_dash else COR_VAZIO)
	if jogador.arma != null:
		var texto: String = jogador.arma.nome
		if jogador.municao > 0:
			texto += "  %d" % jogador.municao
		draw_string(ThemeDB.fallback_font, Vector2(0.0, 27.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
