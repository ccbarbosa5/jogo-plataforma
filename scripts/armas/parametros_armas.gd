class_name ParametrosArmas
extends Resource
## Números das assinaturas e dos nós da árvore (GD-05 §4). Ajuste aqui, não no código.

@export_group("Mordida: Embalo")
@export var embalo_maximo: float = 20.0
@export var embalo_maximo_estendido: float = 30.0
## +1,25% de cadência por ponto.
@export var embalo_cadencia_por_ponto: float = 0.0125
@export var embalo_atraso_queda: float = 1.5
@export var embalo_queda_por_segundo: float = 5.0
@export_group("Mordida: árvore")
@export var campeao_a_cada: int = 10
@export var campeao_dano: int = 40
@export var campeao_mult_elite: float = 2.0
@export var rajada_balas: int = 3
@export var rajada_intervalo: float = 0.06
@export var rajada_pausa: float = 0.25
@export var critico_mult: float = 2.0
@export var critico_mult_execucao_elite: float = 3.0
@export var execucao_limite_vida: float = 0.25
@export var marca_duracao: float = 4.0
@export var marca_bonus_dano: float = 0.25
@export var cacada_devolve_s: float = 2.0
@export var algema_chance: float = 0.3
@export var algema_leve_s: float = 1.0
@export var algema_medio_s: float = 0.5
@export_group("Bramido: Coice e árvore")
@export var coice_px: float = 16.0
@export var perto_px: float = 32.0
@export var perto_bonus_dano: float = 0.3
@export var quebra_armadura_px: float = 24.0
@export var quebra_armadura_s: float = 3.0
@export var recuo_px: float = 24.0
## Impulso para cima no ar (px/s), 1 vez por pulo.
@export var recuo_impulso_ar: float = 150.0
@export var carga_s: float = 1.0
@export var explosao_raio: float = 40.0
@export var explosao_dano: int = 90
@export var carregador_tamanho: int = 2
@export var carregador_intervalo: float = 0.15
@export var carregador_recarga: float = 0.9
