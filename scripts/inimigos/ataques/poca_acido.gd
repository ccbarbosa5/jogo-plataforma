class_name PocaAcido
extends Node2D
## Poça de ácido da cusparada do Cuspidor (GD-02 §4.2): fica 3 s no chão e tira 1 bloco de
## quem pisa (a invulnerabilidade pós-dano evita dano em sequência). Na zona de guerra, também
## passa Ácido para os Kharn (GD-02 §4.4).

const DURACAO: float = 3.0
const LARGURA: float = 24.0
const ALTURA: float = 6.0

var autor: Inimigo
var duracao: float = DURACAO
var _ja_kharn: Array[Inimigo] = []


static func criar(pai: Node, pes: Vector2, autor_: Inimigo) -> PocaAcido:
	var p := PocaAcido.new()
	p.autor = autor_
	p.position = pes
	pai.add_child.call_deferred(p)
	return p


func retangulo() -> Rect2:
	return Rect2(global_position - Vector2(LARGURA * 0.5, ALTURA), Vector2(LARGURA, ALTURA))


func _physics_process(delta: float) -> void:
	duracao -= delta
	if duracao <= 0.0:
		queue_free()
		return
	var area: Rect2 = retangulo()
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j != null and not j.esta_morto() and area.intersects(Rect2(j.global_position - Vector2(6, 4), Vector2(12, 4))):
			j.receber_ataque(InfoDano.criar(1, autor if is_instance_valid(autor) else null))
	if autor != null and is_instance_valid(autor) and autor.ataca_faccao_rival:
		for no in get_tree().get_nodes_in_group("inimigos"):
			var i := no as Inimigo
			if i != null and i.faccao == &"kharn" and i.esta_vivo() and not i in _ja_kharn \
					and area.intersects(Rect2(i.global_position - Vector2(i.tamanho.x * 0.5, 4), Vector2(i.tamanho.x, 4))):
				_ja_kharn.append(i)
				i.adicionar_acido(2, autor)
	queue_redraw()


func _draw() -> void:
	var a: float = clampf(duracao / DURACAO, 0.0, 1.0)
	draw_rect(Rect2(-LARGURA * 0.5, -3, LARGURA, 3), Color(0.64, 0.89, 0.24, 0.85 * a))
	draw_rect(Rect2(-LARGURA * 0.5 + 3, -5, 4, 2), Color(0.34, 0.56, 0.12, a))
	draw_rect(Rect2(LARGURA * 0.5 - 8, -4, 3, 1), Color(0.34, 0.56, 0.12, a))
