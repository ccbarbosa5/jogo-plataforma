class_name Ferramenta
extends Node2D
## Base da habilidade própria de cada personagem (slot "Ferramenta", GD-01 seção 12).
## Ryker usa o Grilhão. Os outros 2 personagens terão as suas.
## O Jogador chama processar() todo frame de física, antes de limpar a entrada.

var jogador: Jogador


func processar(_delta: float) -> void:
	pass


## true enquanto a ferramenta controla o movimento do jogador.
func controla_movimento() -> bool:
	return false
