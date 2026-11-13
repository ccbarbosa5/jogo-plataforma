class_name ParametrosJogador
extends Resource
## Valores de balanceamento do protagonista (GD-01, seção 3).
## Distâncias em tiles e tempos em segundos. GD e QA ajustam pelo arquivo
## scenes/jogador/parametros_jogador.tres, sem mexer no código.

@export_group("Corrida")
## tiles/s
@export var velocidade_corrida: float = 7.0
## tiles/s² (alto = aceleração quase instantânea)
@export var aceleracao: float = 120.0
## Fração da velocidade ao andar agachado (0 = não anda agachado).
@export var multiplicador_agachado: float = 0.35

@export_group("Pulo")
## Altura máxima em tiles (segurando o botão).
@export var altura_pulo: float = 3.5
## Segundos até o topo do pulo.
@export var tempo_ate_topo: float = 0.38
## Gravidade extra na descida (deixa o pulo mais "pesado").
@export var multiplicador_gravidade_queda: float = 1.5
## Ao soltar o botão subindo, a velocidade vertical é multiplicada por isto.
@export var corte_pulo: float = 0.45
## tiles/s
@export var velocidade_queda_maxima: float = 22.0
@export var coyote_time: float = 0.1
@export var buffer_pulo: float = 0.1

@export_group("Dash")
## tiles
@export var distancia_dash: float = 3.0
@export var duracao_dash: float = 0.18
@export var invulnerabilidade_dash: float = 0.15
@export var cargas_dash: int = 1
@export var recarga_dash: float = 0.7

@export_group("Vida")
@export var vida_maxima: int = 4
@export var invulnerabilidade_dano: float = 0.8


func gravidade_px() -> float:
	return 2.0 * Unidades.px(altura_pulo) / (tempo_ate_topo * tempo_ate_topo)


## Velocidade inicial do pulo, já compensando a integração por frames
## para que a altura real seja exatamente altura_pulo.
func velocidade_pulo_px() -> float:
	var g: float = gravidade_px()
	var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
	var meio: float = g * dt * 0.5
	return -meio + sqrt(meio * meio + 2.0 * g * Unidades.px(altura_pulo))


func velocidade_corrida_px() -> float:
	return Unidades.px(velocidade_corrida)


func aceleracao_px() -> float:
	return Unidades.px(aceleracao)


func velocidade_queda_maxima_px() -> float:
	return Unidades.px(velocidade_queda_maxima)


func velocidade_dash_px() -> float:
	return Unidades.px(distancia_dash) / duracao_dash
