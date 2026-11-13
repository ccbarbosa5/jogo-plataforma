class_name Granada
extends Area2D
## Granada em arco: explode ao bater em inimigo, parede ou chão, ou depois de tempo_maximo.
## Atravessa plataformas de mão única subindo, mas explode nelas se estiver caindo.
## Não fere o jogador (sem fogo amigo).

signal explodiu(atingidos: Array[Node])

const DURACAO_VISUAL: float = 0.2

var dados: DadosGranada
var autor: Node
var velocidade: Vector2 = Vector2.ZERO
var _tempo: float = 0.0
var _explodiu: bool = false
var _timer_visual: float = 0.0


func lancar(posicao: Vector2, velocidade_inicial: Vector2, dados_: DadosGranada, autor_: Node) -> void:
	global_position = posicao
	velocidade = velocidade_inicial
	dados = dados_
	autor = autor_


func _ready() -> void:
	collision_layer = 0
	collision_mask = Camadas.MUNDO | Camadas.INIMIGOS | Camadas.PLATAFORMAS
	monitorable = false
	body_entered.connect(_ao_tocar)


func _physics_process(delta: float) -> void:
	if _explodiu:
		_timer_visual -= delta
		queue_redraw()
		if _timer_visual <= 0.0:
			queue_free()
		return
	velocidade.y += Unidades.px(dados.gravidade) * delta
	position += velocidade * delta
	_tempo += delta
	if _tempo >= dados.tempo_maximo:
		explodir()
	queue_redraw()


func _ao_tocar(corpo: Node2D) -> void:
	if _explodiu:
		return
	var objeto := corpo as CollisionObject2D
	if objeto != null and (objeto.collision_layer & Camadas.PLATAFORMAS) != 0 and velocidade.y < 0.0:
		return  # subindo por baixo da plataforma de mão única
	explodir.call_deferred()


func explodir() -> Array[Node]:
	var atingidos: Array[Node] = []
	if _explodiu:
		return atingidos
	_explodiu = true
	_timer_visual = DURACAO_VISUAL
	set_deferred("monitoring", false)
	var raio_px: float = Unidades.px(dados.raio)
	var circulo := CircleShape2D.new()
	circulo.radius = raio_px
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = circulo
	consulta.transform = Transform2D(0.0, global_position)
	consulta.collision_mask = Camadas.INIMIGOS
	for resultado in get_world_2d().direct_space_state.intersect_shape(consulta, 32):
		var alvo: Node = resultado["collider"]
		if alvo in atingidos or not alvo.has_method("receber_ataque"):
			continue
		var para: Vector2 = (alvo as Node2D).global_position - global_position
		var direcao: Vector2 = Vector2(signf(para.x) if para.x != 0.0 else 1.0, -0.5).normalized()
		var info := InfoDano.criar(dados.dano, autor, direcao)
		info.explosao = true
		info.abalo = dados.abalo
		info.empurrao = direcao * Unidades.px(dados.empurrao)
		alvo.receber_ataque(info)
		atingidos.append(alvo)
	explodiu.emit(atingidos)
	return atingidos


func _draw() -> void:
	if _explodiu:
		var t: float = 1.0 - _timer_visual / DURACAO_VISUAL
		var raio_px: float = Unidades.px(dados.raio)
		draw_circle(Vector2.ZERO, raio_px * (0.4 + 0.6 * t), Color(1.0, 0.6, 0.2, 0.7 * (1.0 - t)))
		draw_arc(Vector2.ZERO, raio_px, 0.0, TAU, 24, Color(1.0, 0.9, 0.5, 1.0 - t), 1.0)
	else:
		draw_rect(Rect2(-2.5, -2.5, 5, 5), Color("6c8a3e"))
