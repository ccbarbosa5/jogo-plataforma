class_name Vida
extends Node
## Componente de vida em blocos, usado pelo jogador e pelos inimigos.
## O dono chama receber_dano(); o componente cuida da invulnerabilidade e avisa por sinais.

signal mudou(atual: int, maxima: int)
signal dano_recebido(quantidade: int)
signal morreu

@export var maxima: int = 3
## Segundos de invulnerabilidade depois de levar dano (0 = nenhuma).
@export var invulnerabilidade_pos_dano: float = 0.0

var atual: int = 0
var _timer_invulneravel: float = 0.0


func _ready() -> void:
	atual = maxima


func reiniciar(nova_maxima: int = -1) -> void:
	if nova_maxima > 0:
		maxima = nova_maxima
	atual = maxima
	_timer_invulneravel = 0.0
	mudou.emit(atual, maxima)


func esta_vivo() -> bool:
	return atual > 0


func esta_invulneravel() -> bool:
	return _timer_invulneravel > 0.0


## Garante pelo menos `segundos` de invulnerabilidade (usado pelo dash).
func tornar_invulneravel(segundos: float) -> void:
	_timer_invulneravel = maxf(_timer_invulneravel, segundos)


## Retorna true se o dano foi aplicado (false se estava invulnerável ou já morto).
func receber_dano(quantidade: int) -> bool:
	if quantidade <= 0 or not esta_vivo() or esta_invulneravel():
		return false
	atual = maxi(atual - quantidade, 0)
	_timer_invulneravel = invulnerabilidade_pos_dano
	dano_recebido.emit(quantidade)
	mudou.emit(atual, maxima)
	if atual == 0:
		morreu.emit()
	return true


func curar(quantidade: int) -> void:
	if not esta_vivo():
		return
	atual = mini(atual + quantidade, maxima)
	mudou.emit(atual, maxima)


func _physics_process(delta: float) -> void:
	if _timer_invulneravel > 0.0:
		_timer_invulneravel -= delta
