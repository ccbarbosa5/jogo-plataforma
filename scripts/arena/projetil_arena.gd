class_name ProjetilArena
extends Node2D
## Projétil das armas de distância da arena. Acerta o primeiro inimigo que tocar e some.

const RAIO: float = 2.0
const COR: Color = Color("ffe0b8")

var direcao: Vector2 = Vector2.RIGHT
var velocidade: float = 600.0
var dano: int = 1
## Quem atirou (para o Roubo de vida); pode ser null.
var dono: JogadorArena
var _distancia_restante: float = 200.0


func preparar(direcao_: Vector2, velocidade_: float, dano_: int, alcance: float) -> void:
	direcao = direcao_
	velocidade = velocidade_
	dano = dano_
	_distancia_restante = alcance


func _physics_process(delta: float) -> void:
	var passo: float = velocidade * delta
	position += direcao * passo
	_distancia_restante -= passo
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		if global_position.distance_to(inimigo.global_position) <= inimigo.raio + RAIO:
			inimigo.levar_dano(dano)
			if dono != null and is_instance_valid(dono):
				dono.ao_acertar()
			queue_free()
			return
	if _distancia_restante <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RAIO, COR)
