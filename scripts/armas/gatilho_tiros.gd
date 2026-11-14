class_name GatilhoTiros
extends RefCounted
## Efeitos "a cada N tiros" (ex.: Munição de Clã, "a cada 5 tiros").
## Cada disparo soma o `peso_disparo` da arma (GD-05 §2.3): o Bramido (2,5) dispara o efeito
## no 2º disparo, porque 2 × 2,5 ≥ 5.

var a_cada: float = 5.0
var acumulado: float = 0.0


func _init(a_cada_: float = 5.0) -> void:
	a_cada = a_cada_


## Soma um disparo. Retorna true quando o efeito dispara (e desconta N).
func alimentar(peso: float) -> bool:
	acumulado += peso
	if acumulado >= a_cada:
		acumulado -= a_cada
		return true
	return false
