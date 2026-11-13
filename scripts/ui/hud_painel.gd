class_name HudPainel
extends Control
## Desenha o estado do jogador: vida em blocos bem visíveis (pedido de GD), dash, Grilhão,
## granadas, barra de Chamado e arma.

const COR_VIDA: Color = Color("e84a5f")
const COR_VAZIO: Color = Color("4c566a")
const COR_DASH: Color = Color("7fdcff")
const COR_GRILHAO: Color = Color("ebcb8b")
const COR_GRANADA: Color = Color("6c8a3e")
const COR_CHAMADO: Color = Color("b48ead")

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
	var y: float = 12.0
	for i in jogador.parametros.cargas_dash:
		draw_rect(Rect2(Vector2(i * 13.0, y), Vector2(11.0, 3.0)), COR_DASH if i < jogador.cargas_dash else COR_VAZIO)
	var grilhao := jogador.ferramenta as Grilhao
	if grilhao != null:
		var pronto: float = 1.0 if grilhao.esta_pronto() else 0.0
		if not grilhao.esta_pronto() and grilhao.estado == Grilhao.Estado.PRONTO:
			pronto = 1.0 - grilhao.recarga_restante() / grilhao.recarga
		draw_rect(Rect2(Vector2(26.0, y), Vector2(24.0, 3.0)), COR_VAZIO)
		draw_rect(Rect2(Vector2(26.0, y), Vector2(24.0 * clampf(pronto, 0.0, 1.0), 3.0)), COR_GRILHAO)
	y += 6.0
	for i in jogador.granadas:
		draw_rect(Rect2(Vector2(i * 7.0, y), Vector2(5.0, 5.0)), COR_GRANADA)
	y += 8.0
	var fracao: float = jogador.barra_chamado / Combate.regras.chamado_maximo
	draw_rect(Rect2(Vector2(0.0, y), Vector2(50.0, 3.0)), COR_VAZIO)
	draw_rect(Rect2(Vector2(0.0, y), Vector2(50.0 * fracao, 3.0)), COR_CHAMADO)
	y += 13.0
	if jogador.arma != null:
		var texto: String = jogador.arma.nome
		if jogador.municao > 0:
			texto += "  %d" % jogador.municao
		draw_string(ThemeDB.fallback_font, Vector2(0.0, y), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
