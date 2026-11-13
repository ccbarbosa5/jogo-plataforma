class_name ModificadorArma
extends Resource
## Um modificador aplicado sobre a arma (D-038). É o que cada nó da mini árvore de
## habilidades vai produzir: mudar o COMPORTAMENTO da arma (cadência, dispersão,
## quantidade de projéteis, alcance...). Os efeitos de facção (Abalo, Ácido) ficam nos upgrades.
## A árvore em si (nós, ramos, pontos) espera o GD-05.

@export var id: StringName = &""
@export var nome: String = ""
## Multiplicadores (1 = sem mudança).
@export var mult_dano: float = 1.0
@export var mult_cadencia: float = 1.0
@export var mult_velocidade_projetil: float = 1.0
@export var mult_duracao_projetil: float = 1.0
## Somas.
@export var soma_dano: int = 0
@export var soma_projeteis_por_tiro: int = 0
@export var soma_espalhamento_graus: float = 0.0
## Marcadores de comportamento novo (ex.: &"perfurante", &"carga"). O código de cada
## comportamento entra quando o GD-05 definir os nós.
@export var marcadores: Array[StringName] = []
