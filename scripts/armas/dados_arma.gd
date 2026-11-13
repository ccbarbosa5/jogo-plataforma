class_name DadosArma
extends Resource
## Dados-base de uma arma (D-038). Um arquivo .tres por arma em scenes/armas/.
## Munição infinita: não existem armas pesadas nem troca de arma durante a run.
## A mini árvore de habilidades modifica estes valores via ModificadorArma (ver ArmaEquipada).

@export var nome: String = "Arma"
## Tiros por segundo segurando o botão.
@export var cadencia: float = 8.0
@export var dano: int = 1
## tiles/s
@export var velocidade_projetil: float = 30.0
## Segundos até o projétil sumir.
@export var duracao_projetil: float = 0.9
## Desvio aleatório máximo, em graus, para cada lado.
@export var espalhamento_graus: float = 0.0
@export var projeteis_por_tiro: int = 1
@export var cena_projetil: PackedScene
