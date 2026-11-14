class_name MachadoBumerangue
extends Node2D
## Machado de energia arremessado por Ur-Kesh (GD-02 §5, fase 3): vai em linha reta e volta
## como bumerangue. Acerta o jogador no máximo 1 vez na ida e 1 vez na volta (pula-se as duas).

var autor: Inimigo
var direcao: float = 1.0
var alcance: float = 200.0
var velocidade: float = 260.0
var altura: float = 30.0
var dano: int = 1
var voltando: bool = false
var _percorrido: float = 0.0
var _atingidos: Array[Node] = []
var _angulo: float = 0.0


static func lancar(pai: Node, pos: Vector2, direcao_: float, autor_: Inimigo) -> MachadoBumerangue:
	var m := MachadoBumerangue.new()
	m.position = pos
	m.direcao = direcao_
	m.autor = autor_
	pai.add_child(m)
	return m


func _physics_process(delta: float) -> void:
	_angulo += delta * 18.0
	var passo: float = velocidade * delta
	if not voltando:
		position.x += direcao * passo
		_percorrido += passo
		if _percorrido >= alcance:
			voltando = true
			_atingidos.clear()
	else:
		var destino: Vector2 = autor.centro() if is_instance_valid(autor) else global_position
		var para: Vector2 = destino - global_position
		if para.length() <= passo or not is_instance_valid(autor):
			queue_free()
			return
		global_position += para.normalized() * passo
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j != null and not j.esta_morto() and not j in _atingidos \
				and Rect2(global_position - Vector2(8, 8), Vector2(16, 16)).intersects(Rect2(j.global_position - Vector2(6, 28), Vector2(12, 28))):
			_atingidos.append(j)
			j.receber_ataque(InfoDano.criar(dano, autor if is_instance_valid(autor) else null))
	queue_redraw()


func _draw() -> void:
	var a := Vector2(cos(_angulo), sin(_angulo)) * 8.0
	draw_line(-a, a, Color("4b4753"), 2.0)
	draw_circle(a, 4.0, Color("ff5a2e"))
