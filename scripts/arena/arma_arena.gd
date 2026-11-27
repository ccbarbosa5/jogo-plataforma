class_name ArmaArena
extends Node2D
## Uma arma automática da arena (GD-09 §5): mira sozinha no inimigo mais perto dentro do alcance
## (medido do Ryker) e atira quando a recarga acaba. Sem alvo no alcance, não atira.
## Tipos (data/arena/arena.json): "distancia" solta projéteis (balins, Ácido, empurrão, ricochete);
## "corpo" golpeia em arco e puxa; "area" lança uma granada; "invocacao" solta larvas;
## "orbital" mantém esferas girando em volta do Ryker (não mira, fere quem tocar).

signal atirou(alvo: InimigoArena)

const COR_GOLPE: Color = Color("ffb347")
## Cor do projétil de cada arma (ART-01 §3: tiro do jogador sem contorno).
const CORES_PROJETIL: Dictionary = {
	"mordida": Color("dff8ff"), "bramido": Color("ff5a2e"), "ferrao": Color("a3e23c"),
	"liquidacao": Color("eba35c"),
}
const COR_ESFERA: Color = Color("4fb0a6")
const RAIO_ESFERA: float = 4.0
## Altura do peito do Ryker em relação aos pés (centro da órbita).
const ALTURA_PEITO: float = 10.0

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
var _angulo: float = 0.0
## Orbital: chave "id do inimigo:esfera" → segundos até poder ferir de novo.
var _toques: Dictionary = {}


func configurar(id_: String, nivel_: int) -> void:
	id = id_
	nivel = nivel_
	dados = ConfigArena.arma(id)
	tipo = String(dados["tipo"])
	dano = roundi(float(dados["dano"]) * ConfigArena.multiplicador_dano(nivel))
	recarga = ConfigArena.recarga(id, nivel)
	alcance = float(dados["alcance"])


func _physics_process(delta: float) -> void:
	if tipo == "orbital":
		_orbitar(delta)
		return
	_espera = maxf(_espera - delta, 0.0)
	if _golpe_visivel > 0.0:
		_golpe_visivel -= delta
		queue_redraw()
	if _espera > 0.0:
		return
	var alvo: InimigoArena = alvo_mais_perto()
	if alvo == null:
		return
	_espera = recarga_atual()
	match tipo:
		"corpo":
			_golpear(alvo)
		"area":
			_lancar_granada(alvo)
		"invocacao":
			_soltar_larvas()
		_:
			_disparar(alvo)
	atirou.emit(alvo)


## Dono da arma (o Ryker) ou null nos testes de arma solta.
func dono() -> JogadorArena:
	var p: Node = get_parent()
	return p.get_parent() as JogadorArena if p != null else null


func _atributo(nome: String) -> float:
	var j := dono()
	return j.atributos.valor(nome) if j != null else 0.0


## Recarga, alcance e dano com os atributos do dono (GD-09 §6.3).
func recarga_atual() -> float:
	var j := dono()
	return j.atributos.recarga(recarga) if j != null else recarga


func alcance_atual() -> float:
	var j := dono()
	return j.atributos.alcance(alcance, tipo) if j != null else alcance


## Dano de um acerto (sorteia o crítico).
func dano_do_acerto() -> int:
	var j := dono()
	if j == null:
		return dano
	return j.atributos.dano(dano, tipo, j.atributos.sorteia_critico(j.rng))


## O inimigo vivo mais perto do Ryker (o dono) dentro do alcance, ou null.
func alvo_mais_perto() -> InimigoArena:
	var origem: Vector2 = _origem()
	var melhor: InimigoArena = null
	var melhor_d: float = alcance_atual()
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		var d: float = origem.distance_to(inimigo.global_position) - inimigo.raio
		if d <= melhor_d:
			melhor_d = d
			melhor = inimigo
	return melhor


func _origem() -> Vector2:
	var j := dono()
	return j.global_position if j != null else global_position


func _mundo() -> Node:
	var mundo: Node = get_tree().get_first_node_in_group(ArenaJogo.GRUPO_MUNDO)
	return mundo if mundo != null else get_tree().current_scene


## Vesh com 4 armas da família: +1 projétil ou larva (GD-09 §5.3).
func _extra_vesh() -> int:
	return int(_atributo("projeteis_extra")) if String(dados["familia"]) == "vesh" else 0


func _disparar(alvo: InimigoArena) -> void:
	var base: Vector2 = (alvo.global_position - global_position).normalized()
	var balins: int = int(dados.get("balins", 1)) + _extra_vesh()
	var abertura: float = deg_to_rad(float(dados.get("dispersao_graus", 10.0 if balins > 1 else 0.0)))
	var empurrados: Array = []  # o empurrão vale uma vez por disparo, não por balim
	for i in balins:
		var p := ProjetilArena.new()
		var giro: float = 0.0 if balins == 1 else lerpf(-abertura * 0.5, abertura * 0.5, float(i) / (balins - 1))
		p.preparar(base.rotated(giro), float(dados["velocidade_projetil"]), dano_do_acerto(), alcance_atual() + 16.0)
		p.dono = dono()
		p.cor = CORES_PROJETIL.get(id, ProjetilArena.COR_PADRAO)
		if dados.has("chance_acido"):
			p.chance_acido = float(dados["chance_acido"]) + _atributo("acido_chance_pct")
			p.acido_duracao_extra = _atributo("acido_duracao")
		if dados.has("empurrao"):
			p.empurrao = float(dados["empurrao"]) * (1.0 + _atributo("empurrao_pct") / 100.0)
			p.empurrados = empurrados
		p.ricochetes = int(dados.get("ricochetes", 0))
		p.chance_lucro = float(dados.get("chance_lucro", 0.0))
		p.position = global_position
		_mundo().add_child(p)


func _lancar_granada(alvo: InimigoArena) -> void:
	var g := GranadaArena.new()
	g.dano = dano_do_acerto()
	g.raio_explosao = float(dados["raio_explosao"])
	g.dono = dono()
	_mundo().add_child(g)
	g.preparar(global_position, alvo.global_position, float(dados["tempo_voo"]), float(dados["altura_arco"]))


func _soltar_larvas() -> void:
	for i in int(dados["larvas"]) + _extra_vesh():
		var l := LarvaArena.new()
		l.dano = dano_do_acerto()
		l.velocidade = float(dados["velocidade_larva"])
		l.duracao = float(dados["duracao_larva"])
		l.dono = dono()
		l.position = _origem() + Vector2.RIGHT.rotated(TAU * i / 3.0) * 6.0
		_mundo().add_child(l)


func _golpear(alvo: InimigoArena) -> void:
	var origem: Vector2 = _origem()
	_golpe_direcao = (alvo.global_position - origem).normalized()
	var meio_arco: float = deg_to_rad(float(dados["arco_graus"]) * 0.5)
	var puxao: float = float(dados["puxao"])
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		var para: Vector2 = inimigo.global_position - origem
		if para.length() - inimigo.raio > alcance_atual():
			continue
		if absf(_golpe_direcao.angle_to(para)) > meio_arco:
			continue
		# Puxa para perto antes do dano (o golpe pode matar).
		inimigo.global_position -= para.normalized() * minf(puxao, maxf(para.length() - 12.0, 0.0))
		inimigo.levar_dano(dano_do_acerto())
		if dono() != null:
			dono().ao_acertar()
	_golpe_visivel = 0.15
	queue_redraw()


## Orbital: as esferas giram em volta do peito do Ryker e ferem quem tocam, cada esfera no máximo
## uma vez por "recarga" no mesmo inimigo.
func quantidade_de_esferas() -> int:
	return int(dados.get("esferas", 1)) + int(_atributo("esferas_extra"))


func posicoes_das_esferas() -> Array[Vector2]:
	var centro: Vector2 = _origem() - Vector2(0, ALTURA_PEITO)
	var n: int = quantidade_de_esferas()
	var lista: Array[Vector2] = []
	for i in n:
		lista.append(centro + Vector2.RIGHT.rotated(_angulo + TAU * i / n) * alcance)
	return lista


func _orbitar(delta: float) -> void:
	_angulo = fposmod(_angulo + TAU * float(dados["voltas_por_segundo"]) * delta, TAU)
	for k in _toques.keys():
		_toques[k] = float(_toques[k]) - delta
		if float(_toques[k]) <= 0.0:
			_toques.erase(k)
	var esferas: Array[Vector2] = posicoes_das_esferas()
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		var inimigo := no as InimigoArena
		for i in esferas.size():
			var chave: String = "%d:%d" % [inimigo.get_instance_id(), i]
			if _toques.has(chave):
				continue
			if esferas[i].distance_to(inimigo.global_position) <= RAIO_ESFERA + inimigo.raio:
				_toques[chave] = recarga_atual()
				inimigo.levar_dano(dano_do_acerto())
				if dono() != null:
					dono().ao_acertar()
				atirou.emit(inimigo)
				if not is_instance_valid(inimigo) or inimigo.vida <= 0:
					break
	queue_redraw()


func _draw() -> void:
	if tipo == "orbital":
		for p in posicoes_das_esferas():
			draw_circle(p - global_position, RAIO_ESFERA, COR_ESFERA)
		return
	if _golpe_visivel <= 0.0:
		return
	var centro: Vector2 = -position  # desenha o arco em volta do Ryker
	var meio_arco: float = deg_to_rad(float(dados["arco_graus"]) * 0.5)
	var a: float = _golpe_direcao.angle()
	draw_arc(centro, alcance * 0.8, a - meio_arco, a + meio_arco, 12, COR_GOLPE, 2.0)
