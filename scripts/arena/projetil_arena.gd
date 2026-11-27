class_name ProjetilArena
extends Node2D
## Projétil das armas de distância da arena. Acerta o primeiro inimigo que tocar e some, a não ser
## que ricocheteie (Liquidação). Efeitos opcionais (GD-09 §5.2): Ácido (Ferrão), empurrão uma vez
## por disparo (Bramido, os balins dividem a lista `empurrados`) e Lucro (Liquidação).

const RAIO: float = 2.0
const COR_PADRAO: Color = Color("dff8ff")

var direcao: Vector2 = Vector2.RIGHT
var velocidade: float = 600.0
var dano: int = 1
var cor: Color = COR_PADRAO
## Quem atirou (Roubo de vida e sorteios); pode ser null.
var dono: JogadorArena
var chance_acido: float = 0.0
var acido_duracao_extra: float = 0.0
var empurrao: float = 0.0
## Inimigos já empurrados neste disparo (compartilhada entre os balins).
var empurrados: Array = []
var ricochetes: int = 0
var chance_lucro: float = 0.0

var _alcance: float = 200.0
var _distancia_restante: float = 200.0
var _atingidos: Array = []


func preparar(direcao_: Vector2, velocidade_: float, dano_: int, alcance: float) -> void:
	direcao = direcao_
	velocidade = velocidade_
	dano = dano_
	_alcance = alcance
	_distancia_restante = alcance


func _physics_process(delta: float) -> void:
	var passo: float = velocidade * delta
	position += direcao * passo
	_distancia_restante -= passo
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		if _atingidos.has(inimigo):
			continue
		if global_position.distance_to(inimigo.global_position) <= inimigo.raio + RAIO:
			_acertar(inimigo)
			return
	if _distancia_restante <= 0.0:
		queue_free()


func _sorteio(chance: float) -> bool:
	var r: float = dono.rng.randf() if dono != null and is_instance_valid(dono) else randf()
	return r * 100.0 < chance


func _acertar(inimigo: InimigoArena) -> void:
	_atingidos.append(inimigo)
	if chance_lucro > 0.0 and inimigo.vida <= dano and _sorteio(chance_lucro):
		inimigo.sucata += 1  # Lucro: o abate rende 1 Sucata a mais
	var morreu: bool = inimigo.levar_dano(dano)
	if dono != null and is_instance_valid(dono):
		dono.ao_acertar()
	if not morreu:
		if chance_acido > 0.0 and _sorteio(chance_acido):
			inimigo.aplicar_acido(acido_duracao_extra)
		if empurrao > 0.0 and not empurrados.has(inimigo):
			empurrados.append(inimigo)
			inimigo.global_position += direcao * empurrao
	if ricochetes > 0 and _ricochetear():
		return
	queue_free()


## Vira para o inimigo vivo mais perto que ainda não foi acertado, dentro do alcance.
func _ricochetear() -> bool:
	var melhor: InimigoArena = null
	var melhor_d: float = _alcance
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		if _atingidos.has(inimigo):
			continue
		var d: float = global_position.distance_to(inimigo.global_position)
		if d < melhor_d:
			melhor_d = d
			melhor = inimigo
	if melhor == null:
		return false
	ricochetes -= 1
	direcao = (melhor.global_position - global_position).normalized()
	_distancia_restante = _alcance
	return true


func _draw() -> void:
	draw_circle(Vector2.ZERO, RAIO, cor)
