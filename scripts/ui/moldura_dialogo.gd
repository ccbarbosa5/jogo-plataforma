class_name MolduraDialogo
extends NinePatchRect
## Caixa com a moldura da ART por personagem ou facção (D-032; assets/sprites/ui/molduras/).
## NinePatch de 48×48 com margens de 12 e bordas repetidas (padrão de período 8, sem emenda).
## Serve para a caixa de texto, a placa de nome e o painel da árvore (sempre a humana, D-047).

const PASTA: String = "res://assets/sprites/ui/molduras/"
## moldura -> arquivo
const ARQUIVOS: Dictionary = {
	"humano": "moldura_humana.png",
	"humano_danificada": "moldura_humana.png",  # SINAL e REGISTRO (NAR-01 v0.3)
	"eco": "moldura_eco.png",
	"kharn": "moldura_kharn.png",
	"vesh": "moldura_vesh.png",
	"ilo": "moldura_ilo.png",
	"antigos": "moldura_eco.png",
}
const MARGEM: int = 12

var moldura: String = "humano":
	set(valor):
		moldura = valor
		_aplicar()
var mostrar_seta: bool = true:
	set(valor):
		mostrar_seta = valor
		if _seta != null:
			_seta.visible = valor
## Posição horizontal da seta de continuar (negativo = canto direito).
var seta_x: float = -1.0

var _seta: TextureRect
var _seta_atlas: AtlasTexture


func _init() -> void:
	patch_margin_left = MARGEM
	patch_margin_top = MARGEM
	patch_margin_right = MARGEM
	patch_margin_bottom = MARGEM
	axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var folha_seta: Texture2D = FolhaSprite.carregar(PASTA + "seta_continuar.png")
	if folha_seta != null:
		_seta_atlas = AtlasTexture.new()
		_seta_atlas.atlas = folha_seta
		_seta_atlas.region = Rect2(0, 0, 9, 7)
		_seta = TextureRect.new()
		_seta.texture = _seta_atlas
		_seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_seta)
	_aplicar()


func _aplicar() -> void:
	texture = FolhaSprite.carregar(PASTA + ARQUIVOS.get(moldura, ARQUIVOS["humano"]))
	self_modulate = Color(0.7, 0.66, 0.66) if moldura == "humano_danificada" else Color.WHITE


func _process(_delta: float) -> void:
	if _seta == null or not mostrar_seta or not visible:
		return
	# 2 quadros a 4 qps (sobe e desce 1 px).
	_seta_atlas.region = Rect2(9 * (int(Time.get_ticks_msec() / 250) % 2), 0, 9, 7)
	var x: float = seta_x if seta_x >= 0.0 else size.x - 20.0
	_seta.position = Vector2(x, size.y - 14.0)


func _draw() -> void:
	if texture == null:  # sem a arte da ART: retângulo simples
		draw_rect(Rect2(Vector2.ZERO, size), Color("16111ce8"))
		draw_rect(Rect2(Vector2.ZERO, size), Color("3d4c60"), false, 2.0)
