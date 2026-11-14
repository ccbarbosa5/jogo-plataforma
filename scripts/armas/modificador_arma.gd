class_name ModificadorArma
extends Resource
## Um nó da mini árvore de habilidades (D-038, GD-05 §8). Muda o COMPORTAMENTO da arma
## (cadência, dispersão, quantidade de projéteis, alcance...). Efeitos de facção ficam nos upgrades.
## Cada marcador é um comportamento com código próprio em ControleArma.

@export var id: StringName = &""
@export var nome: String = ""
@export_multiline var descricao: String = ""
## Multiplicadores (1 = sem mudança).
@export var mult_dano: float = 1.0
@export var mult_cadencia: float = 1.0
@export var mult_velocidade_projetil: float = 1.0
@export var mult_duracao_projetil: float = 1.0
## Somas.
@export var soma_dano: int = 0
@export var soma_projeteis_por_tiro: int = 0
@export var soma_espalhamento_graus: float = 0.0
## Marcadores de comportamento novo (lista no GD-05 §8).
@export var marcadores: Array[StringName] = []
