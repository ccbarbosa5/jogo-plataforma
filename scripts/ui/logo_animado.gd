class_name LogoAnimado
extends Control
## D-073A: o logo de No Rest se acende toda vez que o jogo abre, antes do menu.
## Folha da ART-6 (assets/sprites/ui/LEIAME.md): 8×7 quadros de 279×86, 56 quadros a 12 qps.
## Segura o último quadro, escurece e vai para o menu. Qualquer tecla, clique ou botão pula.

const FOLHA: String = "res://assets/sprites/ui/titulo/logo_animado.png"
const BRASA: String = "res://assets/sprites/ui/titulo/brasa.png"
const TELA: Vector2 = Vector2(480, 270)
const COLUNAS: int = 8
const LINHAS: int = 7
const QUADROS: int = 56
const QUADRO_QUEBRA: int = 30
const COR_FUNDO: Color = Color("16111c")
## Folga da folha em volta do logo de 259×66.
const FOLGA: float = 10.0
## Topo do logo no menu (TelaTitulo), para a troca ficar sem salto.
const TOPO_LOGO_MENU: float = 22.0
const LARGURA_LOGO: float = 259.0

@export var qps: float = 12.0
@export var segurar_no_fim: float = 1.0
@export var duracao_fade: float = 0.5
@export var tremor_px: float = 2.0
@export var duracao_tremor: float = 0.2

signal terminou

var tempo: float = 0.0
var pulou: bool = false
var acabou: bool = false
var _sprite: Sprite2D
var _brasas: CPUParticles2D
var _base: Vector2
var _tremor: float = 0.0
var _quebrou: bool = false


func _ready() -> void:
	size = TELA
	var fundo := ColorRect.new()
	fundo.name = "Fundo"
	fundo.color = COR_FUNDO
	fundo.size = TELA
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	_brasas = CPUParticles2D.new()
	_brasas.name = "Brasas"
	_brasas.texture = FolhaSprite.carregar(BRASA)
	var material_brasa := CanvasItemMaterial.new()
	material_brasa.particles_animation = true
	material_brasa.particles_anim_h_frames = 3
	material_brasa.particles_anim_v_frames = 1
	_brasas.material = material_brasa
	_brasas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_brasas.amount = 24
	_brasas.lifetime = 6.0
	_brasas.emitting = false
	_brasas.position = Vector2(TELA.x * 0.5, TELA.y + 4.0)
	_brasas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_brasas.emission_rect_extents = Vector2(TELA.x * 0.5, 4.0)
	_brasas.direction = Vector2(0, -1)
	_brasas.spread = 18.0
	_brasas.gravity = Vector2(0, -2)
	_brasas.initial_velocity_min = 16.0
	_brasas.initial_velocity_max = 32.0
	_brasas.anim_offset_max = 1.0
	add_child(_brasas)
	_sprite = Sprite2D.new()
	_sprite.name = "Logo"
	_sprite.texture = FolhaSprite.carregar(FOLHA)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	_sprite.hframes = COLUNAS
	_sprite.vframes = LINHAS
	_base = Vector2(roundf((TELA.x - LARGURA_LOGO) * 0.5) - FOLGA, TOPO_LOGO_MENU - FOLGA)
	_sprite.position = _base
	add_child(_sprite)


func duracao_total() -> float:
	return QUADROS / qps + segurar_no_fim + duracao_fade


func quadro_atual() -> int:
	return _sprite.frame


func _process(delta: float) -> void:
	if acabou:
		return
	tempo += delta
	_sprite.frame = mini(int(tempo * qps), QUADROS - 1)
	if not _quebrou and _sprite.frame >= QUADRO_QUEBRA:
		_quebrou = true
		_brasas.emitting = true
		_tremor = duracao_tremor
	if _tremor > 0.0:
		_tremor -= delta
		_sprite.position = _base + Vector2(randf_range(-tremor_px, tremor_px), randf_range(-tremor_px, tremor_px)).round()
	else:
		_sprite.position = _base
	var inicio_fade := QUADROS / qps + segurar_no_fim
	# Só o logo e as brasas somem; o fundo escuro fica (sem piscar a cor padrão da janela).
	var alfa := 1.0 - clampf((tempo - inicio_fade) / duracao_fade, 0.0, 1.0)
	_sprite.modulate.a = alfa
	_brasas.modulate.a = alfa
	if tempo >= duracao_total():
		_ir_para_menu()


func _input(evento: InputEvent) -> void:
	if acabou:
		return
	var vale: bool = (evento is InputEventKey and evento.pressed and not evento.echo) \
		or (evento is InputEventMouseButton and evento.pressed) \
		or (evento is InputEventJoypadButton and evento.pressed)
	if vale:
		get_viewport().set_input_as_handled()
		pular()


## Qualquer tecla, clique ou botão: direto para o menu.
func pular() -> void:
	if acabou:
		return
	pulou = true
	_ir_para_menu()


func _ir_para_menu() -> void:
	acabou = true
	terminou.emit()
	Ciclo.ir_para_titulo()
