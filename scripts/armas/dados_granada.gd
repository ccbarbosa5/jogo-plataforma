class_name DadosGranada
extends Resource
## Dados da granada (GD-02, seção 1.3). Arquivo: scenes/armas/granada_padrao.tres.

@export var por_sala: int = 3
@export var dano: int = 50
## Raio da explosão em tiles (32 px).
@export var raio: float = 2.0
## Explode sozinha depois deste tempo, se não bater em nada.
@export var tempo_maximo: float = 1.2
## Velocidade de lançamento em tiles/s (x para a frente, y para cima).
@export var velocidade_lancamento: Vector2 = Vector2(9.0, 13.0)
## tiles/s²
@export var gravidade: float = 38.0
## Velocidade do empurrão aplicado nos inimigos (tiles/s).
@export var empurrao: float = 10.0
## Abalo aplicado (0 no padrão; upgrades Kharn aumentam).
@export var abalo: float = 0.0
@export var cena: PackedScene
