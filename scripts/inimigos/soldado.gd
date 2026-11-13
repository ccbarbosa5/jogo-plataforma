class_name Soldado
extends CharacterBody2D
## Inimigo básico do protótipo: soldado alienígena que patrulha e atira na horizontal.
## Pilar 1 (caos controlado): todo tiro é anunciado antes por um aviso visual (tempo_aviso).
## Pilar 3: ele é maior que o protagonista.
## Reage ao Grilhão: leve é puxado e atordoado; pesado prende o Ryker nele.

signal morreu(inimigo: Soldado)

enum Estado { PATRULHA, AVISO, RECARGA }

const LARGURA: float = 18.0
const ALTURA: float = 30.0

## tiles/s
@export var velocidade_patrulha: float = 1.5
## tiles na horizontal
@export var alcance_visao: float = 14.0
## tiles na vertical (o jogador precisa estar mais ou menos na mesma altura)
@export var tolerancia_vertical: float = 2.5
## Segundos de aviso antes de cada tiro.
@export var tempo_aviso: float = 0.5
## Segundos entre um tiro e o próximo aviso.
@export var intervalo_tiros: float = 1.4
## tiles/s (lento de propósito: dá para desviar)
@export var velocidade_tiro: float = 8.0
@export var dano_tiro: int = 1
@export var dano_contato: int = 1
@export var cena_projetil: PackedScene
## Pesado: o Grilhão puxa o Ryker até ele, em vez de puxar o inimigo.
@export var pesado: bool = false

@onready var vida: Vida = $Vida
@onready var contato: Area2D = $Contato
@onready var sensor_borda: RayCast2D = $SensorBorda

var estado: Estado = Estado.PATRULHA
var olhando: int = -1
var container_projeteis: Node

var _timer_estado: float = 0.0
var _timer_flash: float = 0.0
var _timer_atordoado: float = 0.0
var _puxado_por: Node2D
var _velocidade_puxao: float = 0.0


func _ready() -> void:
	add_to_group("inimigos")
	collision_layer = Camadas.INIMIGOS
	collision_mask = Camadas.MUNDO | Camadas.PLATAFORMAS
	contato.collision_layer = 0
	contato.collision_mask = Camadas.JOGADOR
	sensor_borda.collision_mask = Camadas.MUNDO | Camadas.PLATAFORMAS
	vida.morreu.connect(_ao_morrer)
	vida.dano_recebido.connect(func(_q: int) -> void: _timer_flash = 0.08)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravidade() * delta
	if _timer_flash > 0.0:
		_timer_flash -= delta
	if _puxado_por != null:
		if is_instance_valid(_puxado_por):
			velocity = (_puxado_por.global_position - global_position).normalized() * _velocidade_puxao
		else:
			terminar_puxao()
		move_and_slide()
		queue_redraw()
		return
	if _timer_atordoado > 0.0:
		_timer_atordoado -= delta
		velocity.x = move_toward(velocity.x, 0.0, Unidades.px(40.0) * delta)
		move_and_slide()
		queue_redraw()
		return
	_timer_estado -= delta
	var alvo: Node2D = _alvo_visivel()
	match estado:
		Estado.PATRULHA:
			_patrulhar()
			if alvo != null:
				_mudar_estado(Estado.AVISO, alvo)
		Estado.AVISO:
			velocity.x = 0.0
			if _timer_estado <= 0.0:
				_atirar()
				_mudar_estado(Estado.RECARGA, alvo)
		Estado.RECARGA:
			velocity.x = 0.0
			if alvo != null and alvo.global_position.x != global_position.x:
				olhando = 1 if alvo.global_position.x > global_position.x else -1
			if _timer_estado <= 0.0:
				_mudar_estado(Estado.AVISO if alvo != null else Estado.PATRULHA, alvo)
	move_and_slide()
	_causar_dano_contato()
	queue_redraw()


func receber_dano(quantidade: int, _origem: Node = null) -> bool:
	return vida.receber_dano(quantidade)


func centro() -> Vector2:
	return global_position + Vector2(0.0, -ALTURA * 0.5)


## true durante o aviso antes do tiro (prioridade da mira automática).
func esta_anunciando() -> bool:
	return estado == Estado.AVISO and not esta_atordoado() and _puxado_por == null


func esta_atordoado() -> bool:
	return _timer_atordoado > 0.0


func atordoar(segundos: float) -> void:
	_timer_atordoado = maxf(_timer_atordoado, segundos)
	estado = Estado.PATRULHA  # o aviso em andamento é cancelado


func receber_puxao(puxador: Node2D, velocidade_px: float) -> void:
	_puxado_por = puxador
	_velocidade_puxao = velocidade_px
	estado = Estado.PATRULHA


func terminar_puxao() -> void:
	_puxado_por = null
	velocity = Vector2.ZERO


func _mudar_estado(novo: Estado, alvo: Node2D) -> void:
	estado = novo
	match novo:
		Estado.AVISO:
			_timer_estado = tempo_aviso
			if alvo != null and alvo.global_position.x != global_position.x:
				olhando = 1 if alvo.global_position.x > global_position.x else -1
		Estado.RECARGA:
			_timer_estado = intervalo_tiros


func _patrulhar() -> void:
	sensor_borda.position.x = olhando * (LARGURA * 0.5 + 2.0)
	sensor_borda.force_raycast_update()
	if is_on_floor() and (is_on_wall() or not sensor_borda.is_colliding()):
		olhando = -olhando
	velocity.x = olhando * Unidades.px(velocidade_patrulha)


func _alvo_visivel() -> Node2D:
	var melhor: Node2D = null
	var melhor_dist: float = Unidades.px(alcance_visao)
	for no in get_tree().get_nodes_in_group("jogadores"):
		var jogador := no as Jogador
		if jogador == null or jogador.esta_morto():
			continue
		var delta_pos: Vector2 = jogador.global_position - global_position
		if absf(delta_pos.y) > Unidades.px(tolerancia_vertical):
			continue
		if absf(delta_pos.x) <= melhor_dist:
			melhor = jogador
			melhor_dist = absf(delta_pos.x)
	return melhor


func _atirar() -> void:
	if cena_projetil == null:
		return
	var projetil: Projetil = cena_projetil.instantiate()
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	destino.add_child(projetil)
	var origem: Vector2 = global_position + Vector2(olhando * (LARGURA * 0.5 + 4.0), -ALTURA * 0.55)
	projetil.configurar(origem, Vector2(olhando, 0.0), Unidades.px(velocidade_tiro), dano_tiro,
			4.0, Camadas.PROJETEIS_INIMIGO, Camadas.MUNDO | Camadas.JOGADOR)


func _causar_dano_contato() -> void:
	if esta_atordoado():
		return
	for corpo in contato.get_overlapping_bodies():
		if corpo.has_method("receber_dano"):
			corpo.receber_dano(dano_contato, self)


func _gravidade() -> float:
	return ProjectSettings.get_setting("physics/2d/default_gravity") as float


func _ao_morrer() -> void:
	morreu.emit(self)
	queue_free()


func _draw() -> void:
	var cor: Color = Color("5e3a99") if pesado else Color("8f5bd6")
	if _timer_flash > 0.0:
		cor = Color.WHITE
	draw_rect(Rect2(-LARGURA * 0.5, -ALTURA, LARGURA, ALTURA), cor)
	draw_rect(Rect2(olhando * 4.0 - 3.0, -ALTURA + 5.0, 6.0, 4.0), Color("a3ff6b"))  # olho
	if esta_atordoado():
		# Estrelinhas girando: atordoado pelo Grilhão.
		var t: float = Time.get_ticks_msec() / 150.0
		for i in 3:
			var angulo: float = t + i * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(angulo) * 7.0 - 1.0, -ALTURA - 5.0 + sin(angulo) * 2.0), Vector2(2, 2)), Color("ebcb8b"))
	elif estado == Estado.AVISO:
		# Aviso piscando antes do tiro: "!" acima da cabeça e cano aceso.
		if int(_timer_estado * 16.0) % 2 == 0:
			draw_rect(Rect2(-2.0, -ALTURA - 14.0, 4.0, 8.0), Color("ff3b3b"))
			draw_rect(Rect2(-2.0, -ALTURA - 4.0, 4.0, 2.0), Color("ff3b3b"))
		var cano: Vector2 = Vector2(olhando * (LARGURA * 0.5), -ALTURA * 0.55)
		draw_rect(Rect2(cano + Vector2(minf(olhando * 6.0, 0.0), -2.0), Vector2(6.0, 4.0)), Color("ff3b3b"))
