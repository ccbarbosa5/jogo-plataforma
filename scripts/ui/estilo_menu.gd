class_name EstiloMenu
## Visual comum dos menus (pausa, título), feito pela ART (assets/sprites/ui/menus/,
## mockups v05 a v07): botões em nine-patch com 4 estados, painel e seletor animado.

const PASTA: String = "res://assets/sprites/ui/menus/"
const COR_TEXTO: Color = Color("fff6ea")
const COR_FOCO: Color = Color("ffe0b8")
const COR_DESATIVADO: Color = Color("7d7886")
const COR_DICA: Color = Color("a7a1ae")
const COR_SOMBRA: Color = Color("16111c")

static var _tema: Theme


## Tema dos botões (fonte Bold, cores e os 4 quadros de botao.png).
static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	var folha: Texture2D = FolhaSprite.carregar(PASTA + "botao.png")
	var estados: Dictionary = {"normal": 0, "hover": 1, "focus": 1, "pressed": 2, "disabled": 3}
	for estado: String in estados:
		var estilo := StyleBoxTexture.new()
		if folha != null:
			var quadro := AtlasTexture.new()
			quadro.atlas = folha
			quadro.region = Rect2(16 * estados[estado], 0, 16, 16)
			estilo.texture = quadro
		estilo.texture_margin_left = 4
		estilo.texture_margin_top = 4
		estilo.texture_margin_right = 4
		estilo.texture_margin_bottom = 4
		# Margem interna pequena: o texto nítido é menor que a moldura em pixels.
		estilo.content_margin_left = 3
		estilo.content_margin_right = 3
		estilo.content_margin_top = 0
		estilo.content_margin_bottom = 0
		estilo.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		estilo.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		t.set_stylebox(estado, "Button", estilo)
	t.set_font("font", "Button", Fontes.placa())
	t.set_font_size("font_size", "Button", Fontes.TAMANHO_BOTAO)
	t.set_color("font_color", "Button", COR_TEXTO)
	t.set_color("font_hover_color", "Button", COR_FOCO)
	t.set_color("font_focus_color", "Button", COR_FOCO)
	t.set_color("font_pressed_color", "Button", COR_FOCO)
	t.set_color("font_hover_pressed_color", "Button", COR_FOCO)
	t.set_color("font_disabled_color", "Button", COR_DESATIVADO)
	_tema = t
	return t


## Painel nine-patch (margem 8).
static func painel() -> NinePatchRect:
	var p := NinePatchRect.new()
	p.texture = FolhaSprite.carregar(PASTA + "painel.png")
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		p.set_patch_margin(lado, 8)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.theme = tema()
	return p


## Seta ao lado do botão em foco (2 quadros 6×9, 4 qps). Use posicionar_seletor() a cada frame.
static func seletor() -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = FolhaSprite.carregar(PASTA + "seletor.png")
	atlas.region = Rect2(0, 0, 6, 9)
	var s := TextureRect.new()
	s.texture = atlas
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func posicionar_seletor(s: TextureRect, foco: Control) -> void:
	s.visible = foco != null
	if foco == null:
		return
	s.position = foco.global_position + Vector2(-10.0, (foco.size.y - 9.0) * 0.5)
	(s.texture as AtlasTexture).region = Rect2(6 * (int(Time.get_ticks_msec() / 250) % 2), 0, 6, 9)


## Botão no estilo dos menus. O tamanho é aplicado depois de entrar na árvore (com o tema).
static func botao(pai: Control, texto: String, ret: Rect2, acao: Callable, tamanho: int = Fontes.TAMANHO_BOTAO) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = ret.position
	b.custom_minimum_size = ret.size
	b.add_theme_font_size_override("font_size", tamanho)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(acao)
	b.mouse_entered.connect(b.grab_focus)
	pai.add_child(b)
	b.size = ret.size
	return b


static func rotulo(pai: Control, texto: String, ret: Rect2, tamanho: int, cor: Color, centro: bool = false) -> Label:
	var r := Label.new()
	r.text = texto
	r.position = ret.position
	r.add_theme_font_override("font", Fontes.texto())
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", cor)
	r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centro:
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(r)
	r.size = ret.size
	return r


static func titulo(pai: Control, texto: String, largura: float, y: float) -> Label:
	var r: Label = rotulo(pai, texto, Rect2(0.0, y, largura, 16.0), Fontes.TAMANHO_TITULO, COR_FOCO, true)
	r.add_theme_font_override("font", Fontes.placa())
	return r
