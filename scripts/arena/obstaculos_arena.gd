class_name ObstaculosArena
extends RefCounted
## Destroços sólidos da arena (GD-09 §3, ART-02 §3): sorteados longe do centro e uns dos outros.
## Cada um bloqueia uma caixa no chão (a parte de baixo do desenho); quem anda empurra-se para fora.
## O Zangão voa e não colide.

## Caixas de colisão no chão (posição = canto de cima à esquerda).
var caixas: Array[Rect2] = []
## Ponto de cada destroço (embaixo no centro, onde o sprite apoia) e o tipo (quadro da folha).
var pontos: Array[Vector2] = []
var tipos: Array[int] = []


func gerar(area: Rect2, rng: RandomNumberGenerator) -> void:
	var d: Dictionary = ConfigArena.secao("obstaculos")
	var caixa := Vector2(float(d["caixa"][0]), float(d["caixa"][1]))
	var centro: Vector2 = area.get_center()
	var dentro: Rect2 = area.grow(-32.0)
	caixas.clear()
	pontos.clear()
	tipos.clear()
	for tentativa in 200:
		if pontos.size() >= int(d["quantidade"]):
			break
		var p := Vector2(rng.randf_range(dentro.position.x, dentro.end.x), rng.randf_range(dentro.position.y, dentro.end.y))
		if p.distance_to(centro) < float(d["centro_livre"]):
			continue
		var perto: bool = false
		for q in pontos:
			if p.distance_to(q) < float(d["distancia_entre"]):
				perto = true
				break
		if perto:
			continue
		pontos.append(p.round())
		tipos.append(rng.randi() % int(d["tipos"]))
		caixas.append(Rect2(p.round() - Vector2(caixa.x * 0.5, caixa.y), caixa))


## true se um círculo (pés de quem anda) encosta em algum destroço.
func bloqueia(p: Vector2, raio: float) -> bool:
	for c in caixas:
		if c.grow(raio).has_point(p):
			return true
	return false


## Tira o círculo de dentro dos destroços pelo lado mais curto (desliza junto à borda).
func resolver(p: Vector2, raio: float) -> Vector2:
	for c in caixas:
		var g: Rect2 = c.grow(raio)
		if not g.has_point(p):
			continue
		var esquerda: float = p.x - g.position.x
		var direita: float = g.end.x - p.x
		var cima: float = p.y - g.position.y
		var baixo: float = g.end.y - p.y
		var menor: float = minf(minf(esquerda, direita), minf(cima, baixo))
		if menor == esquerda:
			p.x = g.position.x
		elif menor == direita:
			p.x = g.end.x
		elif menor == cima:
			p.y = g.position.y
		else:
			p.y = g.end.y
	return p
