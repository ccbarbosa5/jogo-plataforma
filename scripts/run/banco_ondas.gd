class_name BancoOndas
extends RefCounted
## Banco de ondas feito à mão (data/salas/ondas_varrek.json) e o orçamento de ameaça (GD-03 §2.4).
## O gerador sorteia ondas do banco até gastar o orçamento, em 2 ou 3 ondas por arena,
## sem nunca passar dele.

const ARQUIVO_VARREK: String = "res://data/salas/ondas_varrek.json"

var custos: Dictionary = {}
var ondas: Array[Dictionary] = []


func carregar(caminho: String = ARQUIVO_VARREK) -> Error:
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if typeof(dados) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	custos = dados.get("custos", {})
	ondas.clear()
	for o: Dictionary in dados.get("ondas", []):
		ondas.append(o)
	return OK


func custo_inimigo(tipo: String) -> int:
	return int(custos.get(tipo, 0))


func custo(onda: Dictionary) -> int:
	var total: int = 0
	for i: Dictionary in onda["inimigos"]:
		total += custo_inimigo(i["tipo"])
	return total


static func custo_total(banco: BancoOndas, lista: Array) -> int:
	var t: int = 0
	for o: Dictionary in lista:
		t += banco.custo(o)
	return t


func _serve(onda: Dictionary, bioma: String) -> bool:
	var biomas: Array = onda.get("biomas", ["*"])
	return "*" in biomas or bioma in biomas


func onda_elite(rng: RandomNumberGenerator) -> Dictionary:
	var elites: Array[Dictionary] = []
	for o in ondas:
		if o.get("elite", false):
			elites.append(o)
	return elites[rng.randi_range(0, elites.size() - 1)] if not elites.is_empty() else {}


## Sorteia de `minimo` a `maximo` ondas comuns cujo custo somado não passa de `orcamento`.
func planejar(orcamento: int, bioma: String, rng: RandomNumberGenerator, minimo: int = 2, maximo: int = 3) -> Array[Dictionary]:
	var comuns: Array[Dictionary] = []
	var menor: int = 999
	for o in ondas:
		if not o.get("elite", false) and _serve(o, bioma):
			comuns.append(o)
			menor = mini(menor, custo(o))
	var quantas: int = rng.randi_range(minimo, maximo)
	# Não sorteia mais ondas do que o orçamento comporta (ex.: 8 com ondas de 4 = 2 ondas).
	if menor > 0 and menor < 999:
		quantas = clampi(quantas, 1, maxi(1, orcamento / menor))
	var plano: Array[Dictionary] = []
	var restante: int = orcamento
	for i in quantas:
		var reserva: int = (quantas - i - 1) * menor
		var candidatas: Array[Dictionary] = []
		for o in comuns:
			if custo(o) <= restante - reserva:
				candidatas.append(o)
		if candidatas.is_empty():
			break
		# Preferência pelas ondas que gastam mais do que sobra para esta onda.
		candidatas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return custo(a) > custo(b))
		var metade: int = maxi(1, ceili(candidatas.size() / 2.0))
		var escolhida: Dictionary = candidatas[rng.randi_range(0, metade - 1)] if i < quantas - 1 \
				else candidatas[0]
		plano.append(escolhida)
		restante -= custo(escolhida)
	return plano
