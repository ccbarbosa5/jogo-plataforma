class_name Disparo
extends RefCounted
## Um aperto de gatilho: todos os balins do Bramido ou as 3 balas de uma rajada da Mordida.
## Guarda o que precisa ser contado "uma vez por disparo".

## Alvos já empurrados pelo Coice neste disparo (os balins não somam).
var empurrados: Array[Node] = []
## Rajada (Mordida B): alvo acertado por cada bala, pela ordem (1, 2, 3).
var alvos_rajada: Dictionary = {}
