class_name AtributosArena
extends RefCounted
## Atributos do Ryker na run (GD-09 §6.3): somam o que vem dos níveis e dos itens.
## As armas e o Ryker perguntam aqui o dano, a recarga, o alcance e o dano recebido finais.

## id do atributo → valor somado (os ids estão em data/arena/arena.json, "atributos").
var valores: Dictionary = {}
var _limites: Dictionary = ConfigArena.secao("limites_atributos")


func valor(id: String) -> float:
	return float(valores.get(id, 0.0))


func somar(id: String, quanto: float) -> void:
	valores[id] = valor(id) + quanto


func somar_efeitos(efeitos: Dictionary) -> void:
	for id in efeitos:
		somar(String(id), float(efeitos[id]))


## Dano de um acerto: (base + bônus fixo do tipo) × (1 + Dano%). O crítico dobra.
func dano(base: int, tipo: String, critico: bool) -> int:
	var fixo: float = valor("dano_distancia") if tipo == "distancia" else valor("dano_corpo")
	var total: float = maxf(float(base) + fixo, 1.0) * (1.0 + valor("dano_pct") / 100.0)
	return maxi(roundi(total * (2.0 if critico else 1.0)), 1)


func sorteia_critico(rng: RandomNumberGenerator) -> bool:
	return rng.randf() * 100.0 < valor("critico_pct")


## Recarga com a Cadência (% menos tempo, até o máximo do arena.json).
func recarga(base: float) -> float:
	var pct: float = clampf(valor("cadencia_pct"), -50.0, float(_limites["cadencia_maxima"]))
	return base * (1.0 - pct / 100.0)


## Alcance com o bônus (corpo a corpo ganha metade).
func alcance(base: float, tipo: String) -> float:
	var bonus: float = valor("alcance") * (0.5 if tipo == "corpo" else 1.0)
	return maxf(base + bonus, 16.0)


## Multiplicador do dano recebido pela Armadura (pode passar de 1 com armadura negativa).
func fator_armadura() -> float:
	var f: float = 1.0 - float(_limites["armadura_por_ponto"]) * valor("armadura")
	return maxf(f, float(_limites["dano_recebido_minimo"]))


func chance_esquiva() -> float:
	return clampf(valor("esquiva_pct"), 0.0, float(_limites["esquiva_maxima"]))


## Segundos entre cada ponto de vida regenerado (0 = sem regeneração).
func intervalo_regeneracao() -> float:
	var r: float = valor("regeneracao")
	return float(_limites["regeneracao_base"]) / r if r > 0.0 else 0.0
