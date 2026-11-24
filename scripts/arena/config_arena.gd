class_name ConfigArena
extends RefCounted
## Números da arena (GD-09), lidos de data/arena/arena.json uma vez só.

const CAMINHO: String = "res://data/arena/arena.json"

static var _dados: Dictionary = {}


static func dados() -> Dictionary:
	if _dados.is_empty():
		var texto: String = FileAccess.get_file_as_string(CAMINHO)
		var lido: Variant = JSON.parse_string(texto)
		assert(lido is Dictionary, "arena.json inválido")
		_dados = lido
	return _dados


static func secao(nome: String) -> Dictionary:
	return dados().get(nome, {})


static func arma(id: String) -> Dictionary:
	return secao("armas").get(id, {})


static func inimigo(id: String) -> Dictionary:
	return secao("inimigos").get(id, {})


static func ondas() -> Array:
	return dados().get("ondas", [])


## Multiplicador de dano de uma arma no nível 1..4.
static func multiplicador_dano(nivel: int) -> float:
	var lista: Array = secao("niveis_arma")["multiplicador_dano"]
	return float(lista[clampi(nivel, 1, lista.size()) - 1])


## Recarga de uma arma no nível: cai 10% a cada nível acima do 1.
static func recarga(id: String, nivel: int) -> float:
	var reducao: float = float(secao("niveis_arma")["reducao_recarga_por_nivel"])
	return float(arma(id)["recarga"]) * pow(1.0 - reducao, nivel - 1)


## Vida e dano dos inimigos sobem com a onda da run (GD-09 §9.1). onda começa em 1.
static func forca(onda: int) -> Dictionary:
	var f: Dictionary = secao("forca_por_onda")
	return {
		"vida": 1.0 + float(f["vida"]) * (onda - 1),
		"dano": 1.0 + float(f["dano"]) * (onda - 1),
	}
