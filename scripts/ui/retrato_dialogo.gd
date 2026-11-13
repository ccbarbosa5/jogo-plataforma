class_name RetratoDialogo
extends Control
## Retrato grande de meio corpo (D-032, ~144×208 px).
## Procura o PNG de ART em assets/sprites/retratos/<falante>_<expressao>.png
## (ex.: ryker_neutro.png, eco_sorrindo.png). Sem arquivo, desenha um retrato provisório.
## Animação sutil: respira; a ECO solta partículas de luz.

const TAMANHO: Vector2 = Vector2(144, 208)
const PASTA: String = "res://assets/sprites/retratos/"

var codigo: String = ""
var cor: Color = Color.WHITE
var moldura: String = "humano"
var espelhar: bool = false
var textura: Texture2D
var ativo: bool = true


func mostrar(codigo_: String, expressao: String, cor_: Color, moldura_: String) -> void:
	codigo = codigo_
	cor = cor_
	moldura = moldura_
	textura = carregar_textura(codigo_, expressao)
	visible = true
	queue_redraw()


static func caminho(codigo_: String, expressao: String) -> String:
	return PASTA + "%s_%s.png" % [codigo_.to_lower().replace("-", "_"), expressao]


static func carregar_textura(codigo_: String, expressao: String) -> Texture2D:
	for e: String in [expressao, "neutro"]:
		var arquivo: String = caminho(codigo_, e)
		if ResourceLoader.exists(arquivo):
			return load(arquivo) as Texture2D
	return null


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var respira: float = sin(t * 2.0) * 1.0
	var escurecer: Color = Color(1, 1, 1, 1) if ativo else Color(0.45, 0.45, 0.5, 1)
	if textura != null:
		if espelhar:
			draw_texture_rect(textura, Rect2(Vector2(TAMANHO.x, respira), Vector2(-TAMANHO.x, TAMANHO.y)), false, escurecer)
		else:
			draw_texture_rect(textura, Rect2(Vector2(0, respira), TAMANHO), false, escurecer)
	else:
		_desenhar_provisorio(respira, escurecer)
	if moldura == "eco" and ativo:
		for i in 7:
			var fase: float = fmod(t * 0.35 + i * 0.137, 1.0)
			var x: float = 24.0 + fmod(i * 47.0, TAMANHO.x - 48.0)
			draw_rect(Rect2(Vector2(x, TAMANHO.y * (1.0 - fase)), Vector2(2, 2)), Color(1.0, 0.79, 0.36, 1.0 - fase))


## Silhueta de meio corpo na cor do personagem, com as iniciais (até ART entregar).
func _desenhar_provisorio(respira: float, escurecer: Color) -> void:
	var base: Color = cor.darkened(0.55) * escurecer
	var claro: Color = cor * escurecer
	var y: float = respira
	draw_rect(Rect2(Vector2(22, 112 + y), Vector2(100, 96)), base)            # tronco
	draw_rect(Rect2(Vector2(10, 128 + y), Vector2(124, 80)), base.darkened(0.2))  # ombros
	draw_rect(Rect2(Vector2(46, 36 + y), Vector2(52, 66)), claro.darkened(0.25))  # cabeça
	draw_rect(Rect2(Vector2(60, 96 + y), Vector2(24, 18)), claro.darkened(0.35))  # pescoço
	var olho_x: float = 60.0 if not espelhar else 66.0
	draw_rect(Rect2(Vector2(olho_x, 62 + y), Vector2(6, 3)), Color(0.09, 0.07, 0.11) * escurecer)
	draw_rect(Rect2(Vector2(olho_x + 14, 62 + y), Vector2(6, 3)), Color(0.09, 0.07, 0.11) * escurecer)
	var iniciais: String = codigo.substr(0, 2)
	draw_string(ThemeDB.fallback_font, Vector2(0, 170 + y), iniciais, HORIZONTAL_ALIGNMENT_CENTER, TAMANHO.x, 28, claro.lightened(0.3))
	draw_string(ThemeDB.fallback_font, Vector2(0, 200 + y), "retrato provisório", HORIZONTAL_ALIGNMENT_CENTER, TAMANHO.x, 7, Color(1, 1, 1, 0.35) * escurecer)
