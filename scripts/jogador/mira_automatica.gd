class_name MiraAutomatica
extends RefCounted
## Escolha de alvo para as assistências de mira e tiro (GD-01, 3.1).
## Prioridade: (1) inimigo anunciando ataque, (2) o mais próximo.
## Alvo "grudento": só troca quando o atual morre, sai do alcance
## ou quando outro está bem mais perto (Assistencias.fator_troca_alvo).

const GRUPO_INIMIGOS: StringName = &"inimigos"

var alvo_atual: Node2D


## Converte um vetor qualquer para uma das 8 direções.
static func direcao_8(vetor: Vector2) -> Vector2i:
	if vetor.is_zero_approx():
		return Vector2i.ZERO
	var setor: int = wrapi(roundi(vetor.angle() / (PI / 4.0)), 0, 8)
	var direcoes: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	]
	return direcoes[setor]


## Gira uma direção de 8 por `passos` × 45°.
static func girar_8(direcao: Vector2i, passos: int) -> Vector2i:
	return direcao_8(Vector2(direcao).rotated(passos * PI / 4.0))


static func centro_de(inimigo: Node2D) -> Vector2:
	if inimigo.has_method("centro"):
		return inimigo.centro()
	return inimigo.global_position


func escolher_alvo(origem: Vector2, opcoes: Assistencias, arvore: SceneTree) -> Node2D:
	var candidatos: Array[Node2D] = _candidatos(origem, opcoes, arvore)
	if candidatos.is_empty():
		alvo_atual = null
		return null
	var melhor: Node2D = null
	var melhor_nota: float = INF
	for inimigo in candidatos:
		var nota: float = origem.distance_to(centro_de(inimigo))
		if inimigo.has_method("esta_anunciando") and inimigo.esta_anunciando():
			nota -= 100000.0  # quem está anunciando ataque vem primeiro
		if nota < melhor_nota:
			melhor_nota = nota
			melhor = inimigo
	if alvo_atual != null and is_instance_valid(alvo_atual) and alvo_atual in candidatos:
		var dist_atual: float = origem.distance_to(centro_de(alvo_atual))
		var dist_melhor: float = origem.distance_to(centro_de(melhor))
		if dist_melhor >= dist_atual * opcoes.fator_troca_alvo:
			return alvo_atual
	alvo_atual = melhor
	return alvo_atual


## Retorna um inimigo que está na direção `direcao` (cone de ±22,5°), ou null.
func inimigo_na_direcao(origem: Vector2, direcao: Vector2i, opcoes: Assistencias, arvore: SceneTree) -> Node2D:
	if direcao == Vector2i.ZERO:
		return null
	var eixo: Vector2 = Vector2(direcao).normalized()
	var melhor: Node2D = null
	var melhor_dist: float = INF
	for inimigo in _candidatos(origem, opcoes, arvore):
		var para: Vector2 = centro_de(inimigo) - origem
		if absf(eixo.angle_to(para)) > deg_to_rad(22.5):
			continue
		if para.length() < melhor_dist:
			melhor_dist = para.length()
			melhor = inimigo
	return melhor


func _candidatos(origem: Vector2, opcoes: Assistencias, arvore: SceneTree) -> Array[Node2D]:
	var lista: Array[Node2D] = []
	var alcance_px := Vector2(Unidades.px(opcoes.alcance.x), Unidades.px(opcoes.alcance.y))
	for no in arvore.get_nodes_in_group(GRUPO_INIMIGOS):
		var inimigo := no as Node2D
		if inimigo == null or inimigo.is_queued_for_deletion():
			continue
		var para: Vector2 = centro_de(inimigo) - origem
		if absf(para.x) <= alcance_px.x and absf(para.y) <= alcance_px.y:
			lista.append(inimigo)
	return lista
