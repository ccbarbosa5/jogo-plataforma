class_name AliadoEnxame
extends Node2D
## Aliado invocado pelos upgrades Vesh (desenho provisório):
## - ZANGAO: voa até o inimigo mais perto e morde (dano a cada `intervalo`) até o tempo acabar;
## - LARVA: corre até um inimigo, morde uma vez (dano + Ácido) e some.
## Fica no grupo "aliados_jogador" (Nós Somos Muitos conta quantos estão ativos).

enum Tipo { ZANGAO, LARVA }

const GRUPO: StringName = &"aliados_jogador"

var tipo: Tipo = Tipo.ZANGAO
var autor: Node
var dano: int = 8
var acidos: int = 0
var duracao: float = 8.0
var velocidade: float = 140.0
var intervalo: float = 0.5
## Origem (para Corpo Solto contar só os seus).
var origem: StringName = &""
var alvo: Inimigo
var _timer_mordida: float = 0.0
var _fase: float = 0.0


static func criar(pai: Node, posicao: Vector2, tipo_: Tipo, autor_: Node, dano_: int, duracao_: float,
		acidos_: int = 0, origem_: StringName = &"") -> AliadoEnxame:
	var a := AliadoEnxame.new()
	a.tipo = tipo_
	a.autor = autor_
	a.dano = dano_
	a.duracao = duracao_
	a.acidos = acidos_
	a.origem = origem_
	a.velocidade = 140.0 if tipo_ == Tipo.ZANGAO else 90.0
	a.position = posicao
	pai.add_child(a)
	return a


func _ready() -> void:
	add_to_group(GRUPO)
	_fase = randf() * TAU


func _physics_process(delta: float) -> void:
	duracao -= delta
	_timer_mordida -= delta
	_fase += delta * 6.0
	if duracao <= 0.0:
		queue_free()
		return
	if alvo == null or not is_instance_valid(alvo) or not alvo.esta_vivo():
		alvo = _mais_perto()
	if alvo == null:
		queue_redraw()
		return
	var destino: Vector2 = alvo.centro()
	if tipo == Tipo.LARVA:
		destino.y = alvo.global_position.y - 3.0
	var para: Vector2 = destino - global_position
	if para.length() <= 8.0:
		if _timer_mordida <= 0.0:
			_morder()
	else:
		global_position += para.normalized() * minf(velocidade * delta, para.length())
	queue_redraw()


func _morder() -> void:
	_timer_mordida = intervalo
	var info := InfoDano.criar(dano, autor, Vector2(signf(alvo.global_position.x - global_position.x), 0.0))
	alvo.receber_ataque(info)
	if acidos > 0 and alvo.esta_vivo():
		alvo.adicionar_acido(acidos, autor)
	if tipo == Tipo.LARVA:
		queue_free()


func _mais_perto() -> Inimigo:
	var melhor: Inimigo = null
	var menor: float = INF
	for no in get_tree().get_nodes_in_group("inimigos"):
		var i := no as Inimigo
		if i == null or not i.esta_vivo():
			continue
		var d: float = i.centro().distance_squared_to(global_position)
		if d < menor:
			menor = d
			melhor = i
	return melhor


func _draw() -> void:
	if tipo == Tipo.ZANGAO:
		var y: float = sin(_fase) * 1.5
		draw_rect(Rect2(-3, -2 + y, 6, 4), Color("a3e23c"))
		draw_rect(Rect2(-4, -4 + y, 3, 2), Color(0.85, 1.0, 0.75, 0.7))
		draw_rect(Rect2(1, -4 + y, 3, 2), Color(0.85, 1.0, 0.75, 0.7))
	else:
		draw_rect(Rect2(-3, -3, 6, 3), Color("c9e07a"))
		draw_rect(Rect2(2, -3, 2, 2), Color("16111c"))
