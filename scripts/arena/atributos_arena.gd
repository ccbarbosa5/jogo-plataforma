class_name AtributosArena
extends RefCounted
## Atributos do Ryker na run (GD-09 §6.3): somam o que vem dos níveis e dos itens.
## As armas e o Ryker perguntam aqui o dano, a recarga, o alcance e o dano recebido finais.

## id do atributo → valor somado (os ids estão em data/arena/arena.json, "atributos").
var valores: Dictionary = {}
## Bônus das famílias de armas (GD-09 §5.3), recalculado quando as armas mudam.
var bonus: Dictionary = {}
var _limites: Dictionary = ConfigArena.secao("limites_atributos")


func valor(id: String) -> float:
	return float(valores.get(id, 0.0)) + float(bonus.get(id, 0.0))


func somar(id: String, quanto: float) -> void:
	valores[id] = float(valores.get(id, 0.0)) + quanto


func somar_efeitos(efeitos: Dictionary) -> void:
	for id in efeitos:
		somar(String(id), float(efeitos[id]))


## Dano de um acerto: (base + bônus fixo do tipo) × (1 + Dano% [+ Área%]). O crítico dobra.
## O bônus fixo: "dano_distancia" nas de distância; "dano_corpo" no corpo a corpo e nas orbitais.
func dano(base: int, tipo: String, critico: bool) -> int:
	var fixo: float = 0.0
	if tipo == "distancia":
		fixo = valor("dano_distancia")
	elif tipo == "corpo" or tipo == "orbital":
		fixo = valor("dano_corpo")
	var pct: float = valor("dano_pct") + (valor("area_dano_pct") if tipo == "area" else 0.0)
	var total: float = maxf(float(base) + fixo, 1.0) * (1.0 + pct / 100.0)
	return maxi(roundi(total * (2.0 if critico else 1.0)), 1)


func sorteia_critico(rng: RandomNumberGenerator) -> bool:
	return rng.randf() * 100.0 < valor("critico_pct")


## Recarga com a Cadência (% menos tempo, até o máximo do arena.json).
func recarga(base: float) -> float:
	var pct: float = clampf(valor("cadencia_pct"), -50.0, float(_limites["cadencia_maxima"]))
	return base * (1.0 - pct / 100.0)


## Alcance com o bônus (corpo a corpo ganha metade).
func alcance(base: float, tipo: String) -> float:
	if tipo == "orbital":
		return base  # o raio da órbita não muda
	var extra: float = valor("alcance") * (0.5 if tipo == "corpo" else 1.0)
	return maxf(base + extra, 16.0)


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


## Bônus de família: para cada família, conta as armas DIFERENTES dela e aplica a faixa 2/3/4+.
static func bonus_de_familias(ids_das_armas: Array) -> Dictionary:
	var armas: Dictionary = ConfigArena.secao("armas")
	var por_familia: Dictionary = {}
	for id in ids_das_armas:
		var f: String = String(armas[id]["familia"])
		if not por_familia.has(f):
			por_familia[f] = {}
		(por_familia[f] as Dictionary)[id] = true
	var total: Dictionary = {}
	var familias: Dictionary = ConfigArena.secao("familias")
	for f in por_familia:
		var n: int = mini((por_familia[f] as Dictionary).size(), 4)
		if n < 2 or not familias.has(f):
			continue
		var efeitos: Dictionary = familias[f].get(str(n), {})
		for k in efeitos:
			total[k] = float(total.get(k, 0.0)) + float(efeitos[k])
	return total
