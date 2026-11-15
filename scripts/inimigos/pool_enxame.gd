class_name PoolEnxame
extends Node
## Pool de inimigos de enxame (D-062: dezenas na tela sem criar e apagar nós o tempo todo).
## pegar() devolve um inimigo pronto (novo ou reaproveitado); quem morre ou foge volta com
## devolver(). O pool não põe o inimigo na árvore: quem pede faz add_child.

var _livres: Dictionary = {}  # tipo -> Array[InimigoEnxame]
var criados: int = 0
var reaproveitados: int = 0


func pegar(tipo: String) -> InimigoEnxame:
	var lista: Array = _livres.get(tipo, [])
	for k in range(lista.size() - 1, -1, -1):
		var i: InimigoEnxame = lista[k]
		if not is_instance_valid(i):
			lista.remove_at(k)
		elif i.get_parent() == null:  # já saiu da árvore (a saída é adiada)
			lista.remove_at(k)
			reaproveitados += 1
			i.reiniciar()
			return i
	var novo := MontadorSala.cena_inimigo(tipo).instantiate() as InimigoEnxame
	if novo == null:
		return null
	novo.pool = self
	novo.tipo = tipo
	criados += 1
	return novo


func devolver(inimigo: InimigoEnxame) -> void:
	if not _livres.has(inimigo.tipo):
		_livres[inimigo.tipo] = []
	if inimigo in _livres[inimigo.tipo]:
		return
	_livres[inimigo.tipo].append(inimigo)
	if inimigo.get_parent() != null:
		inimigo.get_parent().remove_child.call_deferred(inimigo)


func livres(tipo: String) -> int:
	return _livres.get(tipo, []).size()


func _exit_tree() -> void:
	for lista: Array in _livres.values():
		for i in lista:
			if is_instance_valid(i) and i.get_parent() == null:
				i.free()
	_livres.clear()
