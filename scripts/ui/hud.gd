class_name Hud
extends CanvasLayer
## HUD provisório: blocos de vida, cargas de dash, arma e mensagens centrais.

@onready var painel: HudPainel = $Painel
@onready var mensagem: Label = $Mensagem

var _timer_mensagem: float = 0.0


func conectar(jogador: Jogador) -> void:
	painel.jogador = jogador


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
