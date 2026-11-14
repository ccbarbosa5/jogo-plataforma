class_name Explosao
extends Node2D
## Explosão em área dos upgrades (Munição de Clã, Corrente Rubra, Bombardeio).
## Explosao.causar() aplica o dano na hora e deixa um círculo que some (visual provisório).

const DURACAO: float = 0.25

var raio: float = 16.0
var cor: Color = Color(1.0, 0.45, 0.15)
var _t: float = 0.0


## Dano em todos os inimigos vivos a até `raio_px` de `posicao`. Retorna os atingidos.
static func causar(pai: Node, posicao: Vector2, raio_px: float, dano: int, autor: Node,
		abalo: float = 0.0, empurrao_px: float = 0.0, cor_: Color = Color(1.0, 0.45, 0.15)) -> Array[Inimigo]:
	var atingidos: Array[Inimigo] = []
	for no in pai.get_tree().get_nodes_in_group("inimigos"):
		var inimigo := no as Inimigo
		if inimigo == null or not inimigo.esta_vivo():
			continue
		var para: Vector2 = inimigo.centro() - posicao
		if para.length() > raio_px + inimigo.tamanho.x * 0.5:
			continue
		var direcao: Vector2 = Vector2(signf(para.x) if para.x != 0.0 else 1.0, -0.5).normalized()
		var info := InfoDano.criar(dano, autor, direcao)
		info.explosao = true
		info.abalo = abalo
		if empurrao_px > 0.0:
			info.empurrao = direcao * empurrao_px
		if inimigo.receber_ataque(info):
			atingidos.append(inimigo)
	var visual := Explosao.new()
	visual.raio = raio_px
	visual.cor = cor_
	visual.position = posicao
	pai.add_child.call_deferred(visual)
	return atingidos


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var f: float = _t / DURACAO
	draw_circle(Vector2.ZERO, raio * (0.4 + 0.6 * f), Color(cor, 0.6 * (1.0 - f)))
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 20, Color(1.0, 0.9, 0.5, 1.0 - f), 1.0)
