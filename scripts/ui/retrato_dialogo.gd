class_name RetratoDialogo
extends Control
## Retrato grande de meio corpo (D-032): 144×208 px, virado para a direita.
## A ART entrega uma folha por personagem com um quadro por expressão
## (assets/sprites/retratos/<falante>/<falante>_retratos.png; ordem no LEIAME de lá
## e no campo "expressoes" do arquivo de falas). O lado direito usa espelho.
## Sem folha, desenha um retrato provisório. SINAL e REGISTRO não têm retrato: estática.
## Animação sutil por código: respira (1 px); a ECO solta partículas de luz.

const TAMANHO: Vector2 = Vector2(144, 208)
const PASTA: String = "res://assets/sprites/retratos/"

var codigo: String = ""
var cor: Color = Color.WHITE
var moldura: String = "humano"
var tipo: String = "retrato"  # ou "estatica"
var espelhar: bool = false
var textura: Texture2D
var ativo: bool = true


func mostrar(codigo_: String, expressao: String, expressoes: Array, cor_: Color, moldura_: String, tipo_: String = "retrato") -> void:
	codigo = codigo_
	cor = cor_
	moldura = moldura_
	tipo = tipo_
	textura = carregar_textura(codigo_, expressao, expressoes)
	visible = true
	queue_redraw()


static func pasta_do(codigo_: String) -> String:
	return codigo_.to_lower().replace("-", "_")


static func caminho(codigo_: String) -> String:
	var nome: String = pasta_do(codigo_)
	return PASTA + "%s/%s_retratos.png" % [nome, nome]


## Recorta o quadro da expressão (a 1ª da lista é a padrão).
static func carregar_textura(codigo_: String, expressao: String, expressoes: Array) -> Texture2D:
	var arquivo: String = caminho(codigo_)
	if not ResourceLoader.exists(arquivo):
		return null
	var folha := load(arquivo) as Texture2D
	var indice: int = maxi(expressoes.find(expressao), 0)
	var quadros: int = maxi(int(folha.get_width() / TAMANHO.x), 1)
	var recorte := AtlasTexture.new()
	recorte.atlas = folha
	recorte.region = Rect2(mini(indice, quadros - 1) * TAMANHO.x, 0, TAMANHO.x, TAMANHO.y)
	return recorte


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var respira: float = roundf(sin(t * PI) * 0.5)  # 1 px a cada ~2 s
	var tom: Color = Color.WHITE if ativo else Color(0.62, 0.6, 0.66)
	if tipo == "estatica":
		_desenhar_estatica(t, tom)
		return
	if textura != null:
		# Espelha por transformação: AtlasTexture não aceita tamanho negativo.
		if espelhar:
			draw_set_transform(Vector2(TAMANHO.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(textura, Rect2(Vector2(0, respira), TAMANHO), false, tom)
		draw_set_transform(Vector2.ZERO)
	else:
		_desenhar_provisorio(respira, tom)
	if moldura == "eco" and ativo:
		for i in 7:
			var fase: float = fmod(t * 0.35 + i * 0.137, 1.0)
			var x: float = 24.0 + fmod(i * 47.0, TAMANHO.x - 48.0)
			draw_rect(Rect2(Vector2(roundf(x), roundf(TAMANHO.y * (1.0 - fase))), Vector2(2, 2)), Color(1.0, 0.79, 0.36, 1.0 - fase))


## Sem retrato (SINAL, REGISTRO): uma tela com estática e uma onda de rádio.
func _desenhar_estatica(t: float, tom: Color) -> void:
	var r := Rect2(Vector2(16, 70), Vector2(112, 80))
	draw_rect(r, Color("16111c") * tom)
	var semente: int = int(t * 12.0)
	for i in 90:
		var h: int = (i * 7919 + semente * 104729) % 9973
		var p := Vector2(r.position.x + h % int(r.size.x), r.position.y + (h / 97) % int(r.size.y))
		draw_rect(Rect2(p, Vector2(2, 1)), Color(cor, 0.5) * tom)
	var anterior := Vector2(r.position.x, r.get_center().y)
	for x in range(0, int(r.size.x), 4):
		var y: float = r.get_center().y + sin(x * 0.25 + t * 6.0) * 12.0 * sin(t * 2.0)
		var ponto := Vector2(r.position.x + x, roundf(y))
		draw_line(anterior, ponto, cor * tom, 1.0)
		anterior = ponto
	draw_rect(r, cor.darkened(0.3) * tom, false, 1.0)


## Silhueta de meio corpo na cor do personagem (até a ART entregar o retrato).
func _desenhar_provisorio(respira: float, tom: Color) -> void:
	var base: Color = cor.darkened(0.55) * tom
	var claro: Color = cor * tom
	var y: float = respira
	draw_rect(Rect2(Vector2(22, 112 + y), Vector2(100, 96)), base)
	draw_rect(Rect2(Vector2(10, 128 + y), Vector2(124, 80)), base.darkened(0.2))
	draw_rect(Rect2(Vector2(46, 36 + y), Vector2(52, 66)), claro.darkened(0.25))
	draw_rect(Rect2(Vector2(60, 96 + y), Vector2(24, 18)), claro.darkened(0.35))
	var olho_x: float = 66.0 if not espelhar else 60.0
	draw_rect(Rect2(Vector2(olho_x, 62 + y), Vector2(6, 3)), Color("16111c") * tom)
	draw_rect(Rect2(Vector2(olho_x + 14, 62 + y), Vector2(6, 3)), Color("16111c") * tom)
	draw_string(Fontes.pequena(), Vector2(0, 196 + y), "retrato provisório", HORIZONTAL_ALIGNMENT_CENTER, TAMANHO.x, Fontes.TAMANHO_PEQUENA, Color(1, 1, 1, 0.35) * tom)
