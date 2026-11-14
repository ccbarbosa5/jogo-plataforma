class_name OndaChoque
extends Node2D
## Onda de choque do pisão do Brutamontes [PESADO] (GD-02 §4.3): corre pelo chão nos dois
## sentidos e tira 2 blocos de quem estiver no chão no caminho. Desvia-se com um pulo.

const ALTURA: float = 12.0
const LARGURA: float = 10.0

var direcao: float = 1.0
var velocidade: float = 200.0
var alcance: float = 220.0
var dano: int = 2
var autor: Inimigo
var _percorrido: float = 0.0
var _atingidos: Array[Node] = []


static func criar(pai: Node, pes: Vector2, direcao_: float, autor_: Inimigo) -> OndaChoque:
	var o := OndaChoque.new()
	o.position = pes
	o.direcao = direcao_
	o.autor = autor_
	pai.add_child(o)
	return o


func retangulo() -> Rect2:
	return Rect2(global_position - Vector2(LARGURA * 0.5, ALTURA), Vector2(LARGURA, ALTURA))


func _physics_process(delta: float) -> void:
	var passo: float = velocidade * delta
	position.x += direcao * passo
	_percorrido += passo
	if _percorrido >= alcance:
		queue_free()
		return
	var area: Rect2 = retangulo()
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j == null or j.esta_morto() or j in _atingidos:
			continue
		if area.intersects(Rect2(j.global_position - Vector2(6, 2), Vector2(12, 2))):
			_atingidos.append(j)
			j.receber_ataque(InfoDano.criar(dano, autor if is_instance_valid(autor) else null))
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-LARGURA * 0.5, 0), Vector2(0, -ALTURA), Vector2(LARGURA * 0.5, 0)]),
			Color(0.86, 0.81, 0.68, 0.85))
	draw_line(Vector2(-LARGURA, 0), Vector2(LARGURA, 0), Color("ff5a2e"), 1.0)
