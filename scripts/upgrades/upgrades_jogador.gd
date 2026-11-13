class_name UpgradesJogador
extends RefCounted
## Upgrades de UM jogador durante a run (D-026):
## - um upgrade por slot (Tiro, Granada, Dash, Ferramenta, Chamado); um novo substitui o anterior;
## - os Passivos se acumulam;
## - upgrades com pré-requisitos só entram se o jogador tiver todos.

signal mudou

var por_slot: Dictionary = {}  # DadosUpgrade.Slot -> DadosUpgrade
var passivos: Array[DadosUpgrade] = []


func pode_receber(upgrade: DadosUpgrade) -> bool:
	for requisito in upgrade.requisitos:
		if not tem(requisito):
			return false
	return true


## Adiciona o upgrade. Retorna o upgrade substituído (ou null).
## Se faltar pré-requisito, nada muda e retorna null (confira antes com pode_receber).
func adicionar(upgrade: DadosUpgrade) -> DadosUpgrade:
	if not pode_receber(upgrade):
		return null
	var substituido: DadosUpgrade = null
	if upgrade.slot == DadosUpgrade.Slot.PASSIVO:
		passivos.append(upgrade)
	else:
		substituido = por_slot.get(upgrade.slot)
		por_slot[upgrade.slot] = upgrade
	mudou.emit()
	return substituido


func no_slot(slot: DadosUpgrade.Slot) -> DadosUpgrade:
	return por_slot.get(slot)


func tem(id: StringName) -> bool:
	for u in todos():
		if u.id == id:
			return true
	return false


func todos() -> Array[DadosUpgrade]:
	var lista: Array[DadosUpgrade] = []
	for u: DadosUpgrade in por_slot.values():
		lista.append(u)
	lista.append_array(passivos)
	return lista


func quantidade_da_faccao(faccao: StringName) -> int:
	var n: int = 0
	for u in todos():
		if u.faccao == faccao:
			n += 1
	return n


func limpar() -> void:
	por_slot.clear()
	passivos.clear()
	mudou.emit()
