class_name AlvoFalso
extends Node2D
## Inimigo de mentira para testar a mira automática sem física nem IA.

var anunciando: bool = false


func _ready() -> void:
	add_to_group("inimigos")


func esta_anunciando() -> bool:
	return anunciando


func centro() -> Vector2:
	return global_position
