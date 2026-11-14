class_name EstadoAto
extends RefCounted
## O que o gerador precisa lembrar durante um ato (uma run do VS).

## Trechos e arenas já usados: uma run nunca repete (GD-03 §2.5).
var blocos_usados: Array[String] = []
## Portas de Aprimoramento já mostradas neste ato (máximo 3).
var aprimoramentos: int = 0
## Saídas seguidas sem porta de facção (garantia: nunca mais de 2).
var salas_sem_faccao: int = 0
## +1 bloco de vida máximo já apareceu neste ato (máximo 1).
var vida_maxima_dada: bool = false
## 1ª run do jogo: sala 0 completa (tutorial) e saída Kharn + Vesh.
var primeira_run: bool = false


## Registra as portas de uma saída já sorteada.
func registrar_portas(tipos: Array) -> void:
	if "aprimoramento" in tipos:
		aprimoramentos += 1
	if "vida_maxima" in tipos:
		vida_maxima_dada = true
	if "kharn" in tipos or "vesh" in tipos:
		salas_sem_faccao = 0
	else:
		salas_sem_faccao += 1
