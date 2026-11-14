class_name Hud
extends CanvasLayer
## HUD provisório: blocos de vida, cargas de dash, arma e mensagens centrais.

@onready var painel: HudPainel = $Painel
@onready var mensagem: Label = $Mensagem
var dica: Label

var _timer_mensagem: float = 0.0


func _ready() -> void:
	# Texto nítido (D-056); vale mesmo se o HUD nascer antes do autoload.
	mensagem.add_theme_font_override("font", Fontes.placa())
	mensagem.add_theme_font_size_override("font_size", Fontes.TAMANHO_PLACA)
	# Dica de teclas: só no tutorial da sala 0 (D-054). Sem barra de teclas fixa na tela.
	dica = Label.new()
	dica.name = "Dica"
	dica.add_theme_font_override("font", Fontes.pequena())
	dica.add_theme_font_size_override("font_size", Fontes.TAMANHO_PEQUENA)
	dica.add_theme_color_override("font_color", Color("fff6ea"))
	dica.add_theme_color_override("font_shadow_color", Color("16111c"))
	dica.add_theme_constant_override("shadow_offset_x", 1)
	dica.add_theme_constant_override("shadow_offset_y", 1)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.position = Vector2(0, 252)
	dica.size = Vector2(480, 12)
	dica.modulate.a = 0.85
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dica.visible = false
	add_child(dica)


func conectar(jogador: Jogador) -> void:
	painel.jogador = jogador


func mostrar_dica(texto: String) -> void:
	dica.text = texto
	dica.visible = not texto.is_empty()


func esconder_dica() -> void:
	dica.visible = false


## duracao <= 0 deixa a mensagem na tela até a próxima.
func mostrar_mensagem(texto: String, duracao: float = 0.0) -> void:
	mensagem.text = texto
	mensagem.visible = true
	_timer_mensagem = duracao


func _process(delta: float) -> void:
	if _timer_mensagem > 0.0:
		_timer_mensagem -= delta
		if _timer_mensagem <= 0.0:
			mensagem.visible = false
