class_name MolduraDialogo
extends Control
## Caixa de texto com moldura decorada por personagem ou facção (D-032).
## Desenho provisório e original (nada do Hades): fundo escuro, borda dupla, cantos
## e um detalhe por facção. ART troca por um NinePatch quando tiver a arte.

const FUNDO: Color = Color("16111ce8")

## moldura -> [borda, acento]
const CORES: Dictionary = {
	"humano": [Color("3d4c60"), Color("c4652e")],   # sucata remendada
	"eco": [Color("2a6a66"), Color("ffc95c")],      # luz âmbar sobre o teal da nave
	"kharn": [Color("9c3527"), Color("dccfae")],    # metal e osso vermelho-brasa
	"vesh": [Color("4c2c5e"), Color("ffc95c")],     # resina e quitina âmbar
	"ilo": [Color("b08d57"), Color("b8d4e0")],      # latão e vidro
	"antigos": [Color("2a6a66"), Color("4fb0a6")],  # tecnologia dos Antigos
}

var moldura: String = "humano":
	set(valor):
		moldura = valor
		queue_redraw()
var mostrar_seta: bool = true
## Posição horizontal da seta de continuar (negativo = canto direito).
var seta_x: float = -1.0


func cores() -> Array:
	return CORES.get(moldura, CORES["humano"])


func _process(_delta: float) -> void:
	if visible and mostrar_seta:
		queue_redraw()


func _draw() -> void:
	var c: Array = cores()
	var borda: Color = c[0]
	var acento: Color = c[1]
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, FUNDO)
	draw_rect(r, borda, false, 2.0)
	draw_rect(r.grow(-4), borda.darkened(0.3), false, 1.0)
	for canto: Vector2 in [Vector2.ZERO, Vector2(size.x - 6, 0), Vector2(0, size.y - 6), size - Vector2(6, 6)]:
		draw_rect(Rect2(canto, Vector2(6, 6)), acento)
	match moldura:
		"kharn":  # dentes de osso no topo
			for x in range(16, int(size.x) - 16, 24):
				draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 6, 0), Vector2(x + 3, 5)]), acento)
		"vesh":  # gotas de resina
			for x in range(20, int(size.x) - 20, 36):
				draw_circle(Vector2(x, size.y - 1), 2.0, acento)
		"humano":  # remendos parafusados
			for x: float in [size.x * 0.3, size.x * 0.7]:
				draw_rect(Rect2(Vector2(x, -2), Vector2(14, 5)), borda.lightened(0.2))
				draw_rect(Rect2(Vector2(x + 2, -1), Vector2(2, 2)), acento)
				draw_rect(Rect2(Vector2(x + 10, -1), Vector2(2, 2)), acento)
		"eco", "antigos":  # linha de luz
			draw_line(Vector2(12, 2), Vector2(size.x - 12, 2), Color(acento, 0.6), 1.0)
		"ilo":  # rebites de latão
			for x in range(12, int(size.x) - 12, 20):
				draw_circle(Vector2(x, 2), 1.5, acento)
	if mostrar_seta and int(Time.get_ticks_msec() / 400) % 2 == 0:
		var p: Vector2 = Vector2(seta_x if seta_x >= 0.0 else size.x - 14.0, size.y - 10.0)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(8, 0), p + Vector2(4, 5)]), acento)
