class_name AreaAcido
extends Node2D
## Área de ácido dos upgrades Vesh (desenho provisório):
## - Rastro de Enxame: a cada `intervalo`, dano e 1 acúmulo em quem estiver dentro;
## - Colmeia Faminta: poça que passa `acidos` acúmulos UMA vez para cada inimigo que tocar.

var tamanho: Vector2 = Vector2(16, 8)
var duracao: float = 2.0
var intervalo: float = 0.5
var dano_por_segundo: float = 0.0
var acidos: int = 1
var uma_vez_por_inimigo: bool = false
var autor: Node
var _timer: float = 0.0
var _ja_tocados: Array[Inimigo] = []
var _total: float = 0.0


static func criar(pai: Node, posicao: Vector2, tamanho_: Vector2, duracao_: float, autor_: Node) -> AreaAcido:
	var a := AreaAcido.new()
	a.position = posicao
	a.tamanho = tamanho_
	a.duracao = duracao_
	a._total = duracao_
	a.autor = autor_
	pai.add_child(a)
	return a


## Retângulo da área (os pés no centro de baixo).
func retangulo() -> Rect2:
	return Rect2(global_position - Vector2(tamanho.x * 0.5, tamanho.y), tamanho)


func _physics_process(delta: float) -> void:
	duracao -= delta
	if duracao <= 0.0:
		queue_free()
		return
	_timer -= delta
	var tocar: bool = uma_vez_por_inimigo or _timer <= 0.0
	if not tocar:
		return
	if _timer <= 0.0:
		_timer = intervalo
	var area: Rect2 = retangulo()
	for no in get_tree().get_nodes_in_group("inimigos"):
		var i := no as Inimigo
		if i == null or not i.esta_vivo():
			continue
		var corpo := Rect2(i.global_position - Vector2(i.tamanho.x * 0.5, i.tamanho.y), i.tamanho)
		if not area.intersects(corpo):
			continue
		if uma_vez_por_inimigo:
			if i in _ja_tocados:
				continue
			_ja_tocados.append(i)
		if dano_por_segundo > 0.0:
			var info := InfoDano.criar(roundi(dano_por_segundo * intervalo), autor)
			info.explosao = true  # ácido no chão ignora a armadura frontal
			i.receber_ataque(info)
		if i.esta_vivo() and acidos > 0:
			i.adicionar_acido(acidos, autor)
	queue_redraw()


func _draw() -> void:
	var a: float = clampf(duracao / maxf(_total, 0.01), 0.0, 1.0)
	draw_rect(Rect2(-tamanho.x * 0.5, -tamanho.y, tamanho.x, tamanho.y), Color(0.64, 0.89, 0.24, 0.35 * a))
	draw_rect(Rect2(-tamanho.x * 0.5, -2, tamanho.x, 2), Color(0.64, 0.89, 0.24, 0.8 * a))
