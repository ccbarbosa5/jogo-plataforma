class_name DadosArma
extends Resource
## Dados-base de uma arma (GD-07 §1). Um arquivo .tres por arma em scenes/armas/.
## No nível 1 a arma só atira: o jeito de atirar vem daqui; o resto vem da árvore de Combate
## e das Gambiarras (ModificadorArma, ver ArmaEquipada). Munição infinita, sem troca na run.

@export var id: StringName = &"mordida"
@export var nome: String = "Arma"
## Uma frase sobre o jeito de atirar (Arsenal).
@export var descricao: String = ""
## Qual folha de tronco do Ryker usar (assets/sprites/personagens/ryker/): mordida ou bramido.
@export var visual: StringName = &"mordida"
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
## Sprite do projétil (apontando para a direita). Vazio = retângulo provisório.
@export var textura_projetil: Texture2D
## Quantos "tiros" cada disparo vale nos efeitos que contam tiros (upgrades de facção).
@export var peso_disparo: float = 1.0
## Multiplica a chance e o acúmulo dos efeitos "ao acertar" de cada projétil (facções).
@export var fator_efeito: float = 1.0
## Queda de dano por distância (Bramido): a partir de `queda_dano_px` o dano vale `mult_queda_dano`.
## 0 = sem queda.
@export var queda_dano_px: float = 0.0
@export var mult_queda_dano: float = 0.5
@export var icone: Texture2D
