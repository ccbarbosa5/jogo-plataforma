class_name GranadaArena
extends Node2D
## Granada de Clã (GD-09 §5.2): voa em arco até onde o alvo estava e explode em área.

const COR: Color = Color("56604a")
const COR_PAVIO: Color = Color("ff5a2e")
const COR_EXPLOSAO: Color = Color("ffb347")
const DURACAO_CLARAO: float = 0.15

var dano: int = 15
var raio_explosao: float = 32.0
var dono: JogadorArena
var explodiu: bool = false

var _inicio: Vector2
var _destino: Vector2
var _tempo_voo: float = 0.5
var _altura: float = 24.0
var _t: float = 0.0
var _clarao: float = 0.0


func preparar(inicio: Vector2, destino: Vector2, tempo_voo: float, altura: float) -> void:
	_inicio = inicio
	_destino = destino
	_tempo_voo = maxf(tempo_voo, 0.05)
	_altura = altura
	global_position = inicio


func _physics_process(delta: float) -> void:
	if explodiu:
		_clarao -= delta
		queue_redraw()
		if _clarao <= 0.0:
			queue_free()
		return
	_t += delta
	var p: float = clampf(_t / _tempo_voo, 0.0, 1.0)
	global_position = _inicio.lerp(_destino, p)
	queue_redraw()
	if p >= 1.0:
		explodir()


## Fere todos os inimigos no raio da explosão.
func explodir() -> void:
	explodiu = true
	_clarao = DURACAO_CLARAO
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		if global_position.distance_to(inimigo.global_position) <= raio_explosao + inimigo.raio:
			inimigo.levar_dano(dano)
			if dono != null and is_instance_valid(dono):
				dono.ao_acertar()
	queue_redraw()


func _draw() -> void:
	if explodiu:
		draw_circle(Vector2.ZERO, raio_explosao * (1.0 - _clarao / DURACAO_CLARAO * 0.4), Color(COR_EXPLOSAO, 0.5))
		return
	# Altura do arco só no desenho: a posição no chão segue reta.
	var alto: float = sin(clampf(_t / _tempo_voo, 0.0, 1.0) * PI) * _altura
	draw_circle(Vector2(0, -alto), 3.0, COR)
	draw_rect(Rect2(-1, -alto - 5, 2, 2), COR_PAVIO)
