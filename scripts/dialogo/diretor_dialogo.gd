class_name DiretorDialogo
extends RefCounted
## Decide QUAIS falas tocam numa cena, a partir do banco e do progresso:
## condições, "uma vez", sorteio sem repetir a variante anterior e falas condicionais.
## Não desenha nada: a CaixaDialogo mostra o resultado.

var banco: BancoDialogos
var progresso: DadosProgresso
var _ultima_variante: Dictionary = {}  # id da cena -> índice sorteado da última vez


func _init(banco_: BancoDialogos, progresso_: DadosProgresso) -> void:
	banco = banco_
	progresso = progresso_


## true se a cena tocaria agora (existe, condição ok e, se for "uma vez", ainda não tocou).
func pode_tocar(id_cena: String) -> bool:
	if not banco.tem_cena(id_cena):
		return false
	var c: Dictionary = banco.cena(id_cena)
	var flag: String = c.get("uma_vez", "")
	if not flag.is_empty() and progresso.tem_flag(flag):
		return false
	return progresso.avaliar(c.get("condicao", ""))


## Monta a lista de falas da cena e já marca a flag "uma vez" (se houver).
## Retorna lista vazia quando a cena não deve tocar.
func preparar(id_cena: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if not pode_tocar(id_cena):
		return resultado
	var c: Dictionary = banco.cena(id_cena)
	var falas: Array = c.get("falas", [])
	if c.get("sortear", false):
		falas = _sortear(id_cena, c.get("variantes", []))
	for fala: Dictionary in falas:
		if progresso.avaliar(fala.get("condicao", "")):
			resultado.append(fala)
	var flag: String = c.get("uma_vez", "")
	if not flag.is_empty() and not resultado.is_empty():
		progresso.definir_flag(flag)
		progresso.salvar()
	return resultado


func modo(id_cena: String) -> String:
	return banco.cena(id_cena).get("modo", "conversa")


func _sortear(id_cena: String, variantes: Array) -> Array:
	if variantes.is_empty():
		return []
	var indice: int = randi() % variantes.size()
	var anterior: int = _ultima_variante.get(id_cena, -1)
	if variantes.size() > 1 and indice == anterior:
		indice = (indice + 1 + randi() % (variantes.size() - 1)) % variantes.size()
	_ultima_variante[id_cena] = indice
	return variantes[indice]
