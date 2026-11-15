class_name Disparo
extends RefCounted
## Um aperto de gatilho: todos os balins do Bramido saem no mesmo disparo.
## Guarda o que precisa ser contado "uma vez por disparo".

## Alvos já empurrados neste disparo (Empurrão de Campeão: os balins não somam).
var empurrados: Array[Node] = []
