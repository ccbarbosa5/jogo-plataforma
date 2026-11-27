class_name LarvaArena
extends Node2D
## Larva da Ninhada (GD-09 §5.2): persegue o inimigo mais perto e some ao morder.

const COR: Color = Color("7d4c90")
const COR_ACIDO: Color = Color("a3e23c")
const RAIO: float = 3.0

var dano: int = 5
var velocidade: float = 140.0
var duracao: float = 4.0
var dono: JogadorArena


func _physics_process(delta: float) -> void:
	duracao -= delta
	if duracao <= 0.0:
		queue_free()
		return
	var alvo: InimigoArena = _mais_perto()
	if alvo == null:
		return
	global_position = global_position.move_toward(alvo.global_position, velocidade * delta)
	if global_position.distance_to(alvo.global_position) <= alvo.raio + RAIO:
		alvo.levar_dano(dano)
		if dono != null and is_instance_valid(dono):
			dono.ao_acertar()
		queue_free()


func _mais_perto() -> InimigoArena:
	var melhor: InimigoArena = null
	var melhor_d: float = INF
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var d: float = global_position.distance_to((no as Node2D).global_position)
		if d < melhor_d:
			melhor_d = d
			melhor = no
	return melhor


func _draw() -> void:
	draw_circle(Vector2.ZERO, RAIO, COR)
	draw_rect(Rect2(-1, -1, 2, 2), COR_ACIDO)
