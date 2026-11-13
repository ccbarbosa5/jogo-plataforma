class_name DadosArma
extends Resource
## Dados de uma arma (GD-01, seção 5). Um arquivo .tres por arma em scenes/armas/.

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
## -1 = infinita (arma principal). Pickups pesados usam munição limitada.
@export var municao: int = -1
@export var cena_projetil: PackedScene
