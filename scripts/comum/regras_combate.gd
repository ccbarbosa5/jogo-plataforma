class_name RegrasCombate
extends Resource
## Regras globais de combate do GD-02 (armadura, Abalo, Ácido, teto de ataques, Chamado).
## Os valores ficam em scenes/comum/regras_combate.tres, para GD e QA ajustarem.

@export_group("Caos controlado (pilar 1)")
## Máximo de ataques anunciados ao mesmo tempo (D-026).
@export var teto_ataques_anunciados: int = 3

@export_group("Armadura frontal")
## Fração do dano frontal que a armadura bloqueia.
@export var reducao_armadura_frontal: float = 0.5

@export_group("Abalo (Kharn)")
@export var abalo_limite: float = 100.0
## Pontos perdidos por segundo quando o inimigo não é atingido.
@export var abalo_queda_por_segundo: float = 20.0
## Segundos sem levar golpe até o Abalo começar a cair.
@export var abalo_atraso_queda: float = 0.5
@export var atordoamento_abalo_comum: float = 1.5
@export var atordoamento_abalo_elite: float = 0.75
@export var atordoamento_abalo_chefe: float = 0.4
## Dano extra contra inimigos atordoados pelo Abalo (0,25 = +25%).
@export var bonus_dano_atordoado: float = 0.25

@export_group("Ácido (Vesh)")
@export var acido_maximo: int = 5
## Dano por segundo de cada acúmulo.
@export var acido_dano_por_segundo: float = 3.0
## Cada acúmulo reduz a armadura nesta fração (0,1 = 10%).
@export var acido_reducao_armadura: float = 0.1
@export var acido_duracao: float = 4.0

@export_group("Chamado")
## Dano causado para ganhar 1 ponto de Chamado.
@export var chamado_dano_por_ponto: float = 10.0
@export var chamado_maximo: float = 100.0
