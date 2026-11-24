class_name InventarioArmas
extends RefCounted
## As armas do Ryker na arena (GD-09 §5.1): até 6 slots; com os slots cheios, uma arma igual e
## do mesmo nível funde com a que já existe e vira uma do nível seguinte.

## Cada item: {"id": String, "nivel": int}
var armas: Array[Dictionary] = []
var slots: int = 6


func _init(slots_: int = 6) -> void:
	slots = slots_


func pode_receber(id: String, nivel: int) -> bool:
	return armas.size() < slots or _indice_para_fundir(id, nivel) >= 0


## Devolve true se a arma entrou (num slot livre ou fundindo).
func adicionar(id: String, nivel: int = 1) -> bool:
	if armas.size() < slots:
		armas.append({"id": id, "nivel": nivel})
		return true
	var i: int = _indice_para_fundir(id, nivel)
	if i < 0:
		return false
	armas[i]["nivel"] = nivel + 1
	return true


func _indice_para_fundir(id: String, nivel: int) -> int:
	var maximo: int = int(ConfigArena.secao("niveis_arma")["maximo"])
	if nivel >= maximo:
		return -1
	for i in armas.size():
		if armas[i]["id"] == id and int(armas[i]["nivel"]) == nivel:
			return i
	return -1
