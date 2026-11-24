class_name SucataArena
extends Node2D
## Sucata solta pelos inimigos (GD-09 §6.1): dinheiro e experiência ao mesmo tempo.
## Voa até o Ryker quando ele chega no raio do ímã (ou no fim da onda, `atrair()`).

signal coletada(valor: int)

const GRUPO: StringName = &"sucata_arena"
const VELOCIDADE_IMA: float = 220.0
const RAIO_COLETA: float = 8.0
const COR: Color = Color("5ec8c0")

var valor: int = 1
var jogador: JogadorArena
var _atraida: bool = false
var _velocidade: float = VELOCIDADE_IMA


func _ready() -> void:
	add_to_group(GRUPO)


## Fim da onda: voa até o Ryker de qualquer distância.
func atrair(velocidade: float) -> void:
	_atraida = true
	_velocidade = maxf(velocidade, VELOCIDADE_IMA)


func _physics_process(delta: float) -> void:
	if jogador == null or not is_instance_valid(jogador):
		return
	var distancia: float = global_position.distance_to(jogador.global_position)
	if distancia <= RAIO_COLETA:
		remove_from_group(GRUPO)
		coletada.emit(valor)
		queue_free()
		return
	if _atraida or distancia <= jogador.ima:
		_atraida = true
		global_position = global_position.move_toward(jogador.global_position, _velocidade * delta)


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0)]), COR)
