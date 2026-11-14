class_name ProjetilArco
extends Node2D
## Tiro em arco que cai num ponto marcado (GD-02 §4): o morteiro do Artilheiro e a cusparada do
## Cuspidor. Segue uma parábola de `origem` até `destino` em `duracao` segundos e, ao chegar,
## explode (morteiro, [PESADO]) ou vira uma poça de ácido (cusparada). O alvo fica marcado no
## chão durante o voo (aviso). Desenho provisório.

enum Tipo { MORTEIRO, CUSPARADA }

var tipo: Tipo = Tipo.MORTEIRO
var autor: Inimigo
var origem: Vector2
var destino: Vector2
var duracao: float = 1.0
var altura: float = 64.0
var raio: float = 24.0
var dano: int = 2
var _t: float = 0.0


static func lancar(pai: Node, tipo_: Tipo, autor_: Inimigo, origem_: Vector2, destino_: Vector2,
		duracao_: float, altura_: float) -> ProjetilArco:
	var p := ProjetilArco.new()
	p.tipo = tipo_
	p.autor = autor_
	p.origem = origem_
	p.destino = destino_
	p.duracao = duracao_
	p.altura = altura_
	p.position = origem_
	pai.add_child(p)
	return p


func posicao_em(t: float) -> Vector2:
	var u: float = clampf(t / duracao, 0.0, 1.0)
	return origem.lerp(destino, u) + Vector2(0.0, -4.0 * altura * u * (1.0 - u))


func _physics_process(delta: float) -> void:
	_t += delta
	global_position = posicao_em(_t)
	if _t >= duracao:
		_impacto()
	queue_redraw()


func _impacto() -> void:
	match tipo:
		Tipo.MORTEIRO:
			ExplosaoInimiga.causar(get_parent(), destino, raio, dano, autor)
		Tipo.CUSPARADA:
			PocaAcido.criar(get_parent(), destino, autor)
	queue_free()


func _draw() -> void:
	# Marca no chão (aviso) + o projétil.
	var marca: Vector2 = destino - global_position
	var restante: float = duracao - _t
	draw_arc(marca, raio * 0.7, 0.0, TAU, 16, Inimigo.cor_do_aviso(restante), 1.0)
	draw_line(marca + Vector2(-4, 0), marca + Vector2(4, 0), Inimigo.cor_do_aviso(restante), 1.0)
	if tipo == Tipo.MORTEIRO:
		draw_rect(Rect2(-3, -3, 6, 6), Color("dccfae"))
		draw_rect(Rect2(-1, -1, 2, 2), Color("ff5a2e"))
	else:
		draw_circle(Vector2.ZERO, 3.0, Color("a3e23c"))
