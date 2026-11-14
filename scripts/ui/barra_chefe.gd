class_name BarraChefe
extends Control
## Barra de vida do chefe embaixo da tela: nome, fase e vida da fase atual.

const LARGURA: float = 240.0

var chefe: UrKesh


func _ready() -> void:
	position = Vector2((480.0 - LARGURA) * 0.5, 236.0)  # embaixo: o topo é das falas rápidas
	size = Vector2(LARGURA, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	visible = chefe != null and is_instance_valid(chefe) and chefe.esta_vivo()
	queue_redraw()


func _draw() -> void:
	if chefe == null or not is_instance_valid(chefe):
		return
	var v: Vida = chefe.vida
	var fracao: float = float(v.atual) / maxf(v.maxima, 1)
	var fases: Array[String] = ["", "O ANDADOR", "ANDADOR DANIFICADO", "A PÉ"]
	draw_string(Fontes.texto(), Vector2(0, 10), "UR-KESH", HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO, Color("ff5a2e"))
	draw_string(Fontes.pequena(), Vector2(0, 10), fases[chefe.fase], HORIZONTAL_ALIGNMENT_RIGHT, LARGURA, Fontes.TAMANHO_PEQUENA, Color("dccfae"))
	draw_rect(Rect2(0, 14, LARGURA, 6), Color("16111c"))
	draw_rect(Rect2(1, 15, (LARGURA - 2) * fracao, 4), Color("9c3527") if chefe.fase < 3 else Color("ff5a2e"))
