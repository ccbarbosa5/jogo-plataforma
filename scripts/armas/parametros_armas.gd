class_name ParametrosArmas
extends Resource
## Números dos efeitos de arma da árvore de Combate e das Gambiarras (GD-07 §4 e §5).
## Ajuste aqui, não no código.

@export_group("Marca do Grilhão (GD-07 §2)")
@export var marca_duracao: float = 4.0
@export var marca_bonus_dano: float = 0.25
## Marca Funda (ramo do Grilhão).
@export var marca_funda_duracao: float = 6.0
@export var marca_funda_bonus: float = 0.40

@export_group("Mordida")
## Três Golpes: o 3º acerto seguido no mesmo alvo é crítico.
@export var critico_mult: float = 2.0
@export var grande_arena_a_cada: int = 10
@export var grande_arena_dano: int = 40
@export var grande_arena_mult_elite: float = 2.0
## Rebite Duplo: a cada N tiros o próximo sai duplo (cada acúmulo tira 1 de N).
@export var rebite_duplo_a_cada: int = 5
@export var rebite_duplo_distancia_px: float = 3.0
@export var incandescente_por_acerto: float = 0.03
@export var incandescente_maximo: float = 0.30
@export var leque_graus: float = 6.0
@export var leque_mult_dano: float = 0.5
@export var cacador_marca_bonus: float = 0.20
@export var tiro_aviso_bonus: float = 0.50
## Rebite Guiado: curva no máximo este ângulo no total, a esta velocidade.
@export var guiado_graus: float = 15.0
@export var guiado_graus_por_s: float = 120.0
@export var guiado_alcance_px: float = 160.0
@export var prego_a_cada: int = 20
@export var prego_dano: int = 60

@export_group("Bramido")
@export var perto_px: float = 24.0
@export var abre_couraca_s: float = 3.0
@export var queima_roupa_bonus: float = 0.40
@export var recuo_px: float = 24.0
## Impulso para cima no ar (px/s), 1 vez por pulo.
@export var recuo_impulso_ar: float = 150.0
## Cano Duplo / Carregador de Arena: 2 disparos (3 com os dois).
@export var carregador_intervalo: float = 0.15
@export var carregador_recarga: float = 0.9
@export var bala_central_dano: int = 30
## Alcance da Bala Central: a tela inteira.
@export var bala_central_alcance_px: float = 480.0
@export var empurrao_px: float = 16.0
@export var estilhacos_por_acumulo: int = 2
@export var estilhaco_dano: int = 5
@export var carga_s: float = 1.0
@export var explosao_raio: float = 40.0
@export var explosao_dano: int = 90
