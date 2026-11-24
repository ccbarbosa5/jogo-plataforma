class_name DiretorOndas
extends RefCounted
## As contas das ondas da arena (GD-09 §2 e §9): duração, taxa de nascimento, mistura de
## inimigos, pico e ponto de nascimento. Sem nós: a ArenaJogo pergunta e cria os inimigos.

var ondas: Array = ConfigArena.ondas()
var arena: Dictionary = ConfigArena.secao("arena")
var rng := RandomNumberGenerator.new()


func total_de_ondas() -> int:
	return ondas.size()


## indice começa em 0.
func duracao(indice: int) -> float:
	return float(ondas[indice]["duracao"])


## Inimigos por segundo no tempo t da onda: sobe em linha reta do início ao fim; nos últimos
## segundos de uma onda com pico, a taxa dobra.
func taxa(indice: int, t: float) -> float:
	var onda: Dictionary = ondas[indice]
	var faixa: Array = onda["taxa"]
	var d: float = float(onda["duracao"])
	var valor: float = lerpf(float(faixa[0]), float(faixa[1]), clampf(t / d, 0.0, 1.0))
	if bool(onda.get("pico", false)) and t >= d - float(arena["pico_segundos_finais"]):
		valor *= float(arena["pico_multiplicador"])
	return valor


## Sorteia o tipo de inimigo pela mistura da onda.
func sortear_tipo(indice: int) -> String:
	var mistura: Dictionary = ondas[indice]["mistura"]
	var soma: float = 0.0
	for k in mistura:
		soma += float(mistura[k])
	var r: float = rng.randf() * soma
	for k in mistura:
		r -= float(mistura[k])
		if r <= 0.0:
			return String(k)
	return String(mistura.keys()[-1])


## Retângulo onde inimigos e o Ryker podem ficar (a arena menos as paredes).
func area_util() -> Rect2:
	var m: float = float(arena["margem_parede"])
	return Rect2(m, m, float(arena["largura"]) - 2.0 * m, float(arena["altura"]) - 2.0 * m)


## Ponto aleatório da arena a pelo menos `distancia_minima_nascer` do Ryker.
func ponto_de_nascimento(pos_jogador: Vector2) -> Vector2:
	var area: Rect2 = area_util()
	var minimo: float = float(arena["distancia_minima_nascer"])
	for tentativa in 30:
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if p.distance_to(pos_jogador) >= minimo:
			return p
	# Arena pequena demais para o sorteio: o canto mais longe do Ryker.
	var cantos: Array[Vector2] = [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	var longe: Vector2 = cantos[0]
	for c in cantos:
		if c.distance_to(pos_jogador) > longe.distance_to(pos_jogador):
			longe = c
	return longe


func teto() -> int:
	return int(arena["teto_inimigos"])
