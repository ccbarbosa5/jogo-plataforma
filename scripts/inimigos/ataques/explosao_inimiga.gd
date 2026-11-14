class_name ExplosaoInimiga
extends Node2D
## Explosão de ataque inimigo (morteiro): fere jogadores no raio e, na zona de guerra, a
## facção rival (GD-02 §4.4). Visual provisório.

const DURACAO: float = 0.3

var raio: float = 24.0
var _t: float = 0.0


static func causar(pai: Node, posicao: Vector2, raio_px: float, dano: int, autor: Inimigo) -> Array[Node]:
	var atingidos: Array[Node] = []
	for no in pai.get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j != null and not j.esta_morto() and j.global_position.distance_to(posicao) <= raio_px + 6.0:
			if j.receber_ataque(InfoDano.criar(dano, autor if is_instance_valid(autor) else null)):
				atingidos.append(j)
	if autor != null and is_instance_valid(autor) and autor.ataca_faccao_rival:
		for no in pai.get_tree().get_nodes_in_group("inimigos"):
			var i := no as Inimigo
			if i != null and autor.pode_ferir(i) and i.centro().distance_to(posicao) <= raio_px + i.tamanho.x * 0.5:
				var info := InfoDano.criar(30 * dano, autor)
				info.explosao = true
				if i.receber_ataque(info):
					atingidos.append(i)
	var v := ExplosaoInimiga.new()
	v.raio = raio_px
	v.position = posicao
	pai.add_child.call_deferred(v)
	return atingidos


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var f: float = _t / DURACAO
	draw_circle(Vector2.ZERO, raio * (0.5 + 0.5 * f), Color(1.0, 0.45, 0.2, 0.7 * (1.0 - f)))
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 20, Color(1.0, 0.95, 0.6, 1.0 - f), 1.0)
