class_name PontoNave
extends Area2D
## Algo para usar na nave (personagem, terminal, cápsula): mostra "E: <ação>" quando o Ryker
## está perto e avisa `usado` quando ele aperta Interagir. Desenho provisório por código.

signal usado(ponto: PontoNave)

enum Figura { ECO, GARRAK, VOSSA, SETE, TERMINAL, CAPSULA, RECONSTRUTOR }

var figura: Figura = Figura.TERMINAL
var acao: String = "usar"
var _jogador: Jogador


static func criar(pai: Node, pos: Vector2, figura_: Figura, acao_: String) -> PontoNave:
	var p := PontoNave.new()
	p.position = pos
	p.figura = figura_
	p.acao = acao_
	pai.add_child(p)
	return p


func _ready() -> void:
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 40)
	forma.shape = r
	forma.position = Vector2(0, -20)
	add_child(forma)
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func jogador_perto() -> bool:
	return _jogador != null


func _ao_entrar(corpo: Node2D) -> void:
	var j := corpo as Jogador
	if j != null:
		_jogador = j
		if not j.interagiu.is_connected(_ao_interagir):
			j.interagiu.connect(_ao_interagir)


func _ao_sair(corpo: Node2D) -> void:
	if corpo == _jogador:
		if _jogador.interagiu.is_connected(_ao_interagir):
			_jogador.interagiu.disconnect(_ao_interagir)
		_jogador = null


func _ao_interagir(_j: Jogador) -> void:
	usado.emit.call_deferred(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	match figura:
		Figura.ECO:
			var a: float = 0.55 + 0.15 * sin(t * 2.0)
			draw_rect(Rect2(-7, -34, 14, 30), Color(1.0, 0.79, 0.36, a))
			draw_circle(Vector2(0, -38), 6.0, Color(1.0, 0.85, 0.5, a))
			draw_rect(Rect2(-10, -4, 20, 4), Color(1.0, 0.79, 0.36, 0.4))
		Figura.GARRAK:
			draw_rect(Rect2(-12, -52, 24, 40), Color("56604a"))
			draw_rect(Rect2(-8, -60, 16, 10), Color("7c8a6c"))
			draw_rect(Rect2(-12, -12, 8, 12), Color("363d30"))
			draw_rect(Rect2(4, -12, 8, 12), Color("363d30"))
			draw_rect(Rect2(-12, -40, 24, 4), Color("dccfae"))
		Figura.VOSSA:
			draw_rect(Rect2(-8, -30, 16, 26), Color("d9b26a"))
			draw_circle(Vector2(0, -34), 6.0, Color("e0b0ff"))
			draw_rect(Rect2(-10, -4, 20, 4), Color("7a6a48"))
		Figura.SETE:
			draw_rect(Rect2(-5, -12, 10, 10), Color("4c2c5e"))
			draw_rect(Rect2(-3, -10, 6, 4), Color("7d4c90"))
			draw_rect(Rect2(-6, -16 - abs(sin(t * 8.0)) * 2.0, 4, 3), Color(0.72, 0.83, 0.88, 0.8))
		Figura.TERMINAL:
			draw_rect(Rect2(-10, -26, 20, 26), Color("2a6a66"))
			draw_rect(Rect2(-7, -23, 14, 9), Color("4fb0a6"))
		Figura.CAPSULA:
			draw_rect(Rect2(-14, -44, 28, 44), Color("5e6370"))
			draw_rect(Rect2(-8, -36, 16, 14), Color("dff8ff"))
			draw_rect(Rect2(-14, -4, 28, 4), Color("c4652e"))
		Figura.RECONSTRUTOR:
			draw_rect(Rect2(-16, -6, 32, 6), Color("4b4753"))
			draw_rect(Rect2(-12, -56, 24, 50), Color(1.0, 0.79, 0.36, 0.12 + 0.06 * sin(t * 3.0)))
	if jogador_perto() and not acao.is_empty():
		draw_string(Fontes.pequena(), Vector2(-50, -66), "E: " + acao, HORIZONTAL_ALIGNMENT_CENTER, 100,
				Fontes.TAMANHO_PEQUENA, Color("eceff4"))
