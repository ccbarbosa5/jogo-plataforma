class_name ArmaArena
extends Node2D
## Uma arma automática da arena (GD-09 §5): mira sozinha no inimigo mais perto dentro do alcance
## (medido do Ryker) e atira quando a recarga acaba. Sem alvo no alcance, não atira.
## "distancia" solta um projétil; "corpo" golpeia em arco e puxa os inimigos para perto.

signal atirou(alvo: InimigoArena)

const COR_GOLPE: Color = Color("ffb347")

var id: String
var nivel: int = 1
var tipo: String
var dano: int
var recarga: float
var alcance: float
var dados: Dictionary

var _espera: float = 0.0
var _golpe_visivel: float = 0.0
var _golpe_direcao: Vector2 = Vector2.RIGHT


func configurar(id_: String, nivel_: int) -> void:
	id = id_
	nivel = nivel_
	dados = ConfigArena.arma(id)
	tipo = String(dados["tipo"])
	dano = roundi(float(dados["dano"]) * ConfigArena.multiplicador_dano(nivel))
	recarga = ConfigArena.recarga(id, nivel)
	alcance = float(dados["alcance"])


func _physics_process(delta: float) -> void:
	_espera = maxf(_espera - delta, 0.0)
	if _golpe_visivel > 0.0:
		_golpe_visivel -= delta
		queue_redraw()
	if _espera > 0.0:
		return
	var alvo: InimigoArena = alvo_mais_perto()
	if alvo == null:
		return
	_espera = recarga
	if tipo == "corpo":
		_golpear(alvo)
	else:
		_disparar(alvo)
	atirou.emit(alvo)


## O inimigo vivo mais perto do Ryker (o dono) dentro do alcance, ou null.
func alvo_mais_perto() -> InimigoArena:
	var origem: Vector2 = _origem()
	var melhor: InimigoArena = null
	var melhor_d: float = alcance
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		var d: float = origem.distance_to(inimigo.global_position) - inimigo.raio
		if d <= melhor_d:
			melhor_d = d
			melhor = inimigo
	return melhor


func _origem() -> Vector2:
	var dono: Node2D = get_parent().get_parent() as Node2D
	return dono.global_position if dono != null else global_position


func _disparar(alvo: InimigoArena) -> void:
	var p := ProjetilArena.new()
	var direcao: Vector2 = (alvo.global_position - global_position).normalized()
	p.preparar(direcao, float(dados["velocidade_projetil"]), dano, alcance + 16.0)
	p.position = global_position
	# O projétil vive no mundo (não acompanha o Ryker depois de sair).
	var mundo: Node = get_tree().get_first_node_in_group(ArenaJogo.GRUPO_MUNDO)
	(mundo if mundo != null else get_tree().current_scene).add_child(p)


func _golpear(alvo: InimigoArena) -> void:
	var origem: Vector2 = _origem()
	_golpe_direcao = (alvo.global_position - origem).normalized()
	var meio_arco: float = deg_to_rad(float(dados["arco_graus"]) * 0.5)
	var puxao: float = float(dados["puxao"])
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		var para: Vector2 = inimigo.global_position - origem
		if para.length() - inimigo.raio > alcance:
			continue
		if absf(_golpe_direcao.angle_to(para)) > meio_arco:
			continue
		# Puxa para perto antes do dano (o golpe pode matar).
		inimigo.global_position -= para.normalized() * minf(puxao, maxf(para.length() - 12.0, 0.0))
		inimigo.levar_dano(dano)
	_golpe_visivel = 0.15
	queue_redraw()


func _draw() -> void:
	if _golpe_visivel <= 0.0:
		return
	var centro: Vector2 = -position  # desenha o arco em volta do Ryker
	var meio_arco: float = deg_to_rad(float(dados["arco_graus"]) * 0.5)
	var a: float = _golpe_direcao.angle()
	draw_arc(centro, alcance * 0.8, a - meio_arco, a + meio_arco, 12, COR_GOLPE, 2.0)
