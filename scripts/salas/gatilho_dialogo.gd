class_name GatilhoDialogo
extends Area2D
## Área que toca uma cena de diálogo quando um jogador entra (ex.: QUED_02 antes do 1º inimigo grande).
## A própria cena decide se toca de novo ("uma_vez" no arquivo de diálogos).

@export var cena: String = ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	monitorable = false
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo is Jogador and not cena.is_empty():
		Dialogos.tocar.call_deferred(cena)
