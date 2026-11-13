class_name RegrasSurgimento
## Entrada justa (GD-03 2.4; D-036): nenhum inimigo surge a menos de
## Combate.regras.distancia_minima_surgimento tiles de um jogador.


## Devolve uma posição de surgimento justa. Se `desejada` está perto demais de algum jogador,
## empurra na horizontal para longe dele, sem sair de [limite_x.x, limite_x.y].
## Se não houver lugar justo dentro dos limites, devolve a posição mais distante possível.
static func posicao_justa(desejada: Vector2, jogadores: Array[Vector2], limite_x: Vector2) -> Vector2:
	var minimo: float = Unidades.px(Combate.regras.distancia_minima_surgimento)
	if _e_justa(desejada, jogadores, minimo):
		return desejada
	var candidatos: Array[Vector2] = []
	for j in jogadores:
		var dy: float = desejada.y - j.y
		var dx: float = sqrt(maxf(minimo * minimo - dy * dy, 0.0)) + 1.0
		candidatos.append(Vector2(j.x + dx, desejada.y))
		candidatos.append(Vector2(j.x - dx, desejada.y))
	candidatos.append(Vector2(limite_x.x, desejada.y))
	candidatos.append(Vector2(limite_x.y, desejada.y))
	var melhor: Vector2 = desejada
	var melhor_desvio: float = INF
	var mais_longe: Vector2 = desejada
	var maior_folga: float = -INF
	for c in candidatos:
		c.x = clampf(c.x, limite_x.x, limite_x.y)
		var folga: float = _menor_distancia(c, jogadores)
		if folga > maior_folga:
			maior_folga = folga
			mais_longe = c
		if folga >= minimo - 0.01 and absf(c.x - desejada.x) < melhor_desvio:
			melhor_desvio = absf(c.x - desejada.x)
			melhor = c
	return melhor if melhor_desvio < INF else mais_longe


static func _e_justa(p: Vector2, jogadores: Array[Vector2], minimo: float) -> bool:
	return _menor_distancia(p, jogadores) >= minimo


static func _menor_distancia(p: Vector2, jogadores: Array[Vector2]) -> float:
	var menor: float = INF
	for j in jogadores:
		menor = minf(menor, p.distance_to(j))
	return menor
