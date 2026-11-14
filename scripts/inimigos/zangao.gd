class_name Zangao
extends Inimigo
## Zangão (GD-02 §4.2): 12×12, voa, 10 de vida, peso Leve (o Grilhão puxa).
## Chega em grupos e circula em volta do alvo. Ataque: para no ar e zumbe (aviso 0,4 s) e
## mergulha em linha reta até onde o alvo estava no fim do aviso.

enum Estado { CIRCULAR, AVISO, MERGULHO, VOLTAR }

@export var velocidade: float = 6.0
@export var raio_circulo: float = 56.0
@export var altura_circulo: float = 48.0
@export var tempo_aviso: float = 0.4
## px/s
@export var velocidade_mergulho: float = 220.0
@export var duracao_mergulho: float = 0.9
@export var intervalo_ataque: Vector2 = Vector2(1.5, 3.0)

var estado: Estado = Estado.CIRCULAR
var direcao_mergulho: Vector2 = Vector2.DOWN
var _timer: float = 0.0
var _angulo: float = 0.0
var _proximo_ataque: float = 1.0


func _ready() -> void:
	super()
	_angulo = randf() * TAU
	_proximo_ataque = randf_range(intervalo_ataque.x, intervalo_ataque.y)
	collision_mask = Camadas.MUNDO


func _comportamento(delta: float) -> void:
	_timer -= delta
	_proximo_ataque -= delta
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(30.0), Unidades.px(17.0)))
	match estado:
		Estado.CIRCULAR:
			if alvo == null:
				velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
				return
			_angulo += delta * 1.6
			var centro_alvo: Vector2 = MiraAutomatica.centro_de(alvo)
			var ponto: Vector2 = centro_alvo + Vector2(cos(_angulo) * raio_circulo, -altura_circulo + sin(_angulo) * 12.0)
			velocity = (ponto - global_position).limit_length(Unidades.px(velocidade)) * 4.0
			velocity = velocity.limit_length(Unidades.px(velocidade))
			olhar_para(alvo)
			if _proximo_ataque <= 0.0 and Combate.pedir_ficha(self):
				estado = Estado.AVISO
				_timer = tempo_aviso
		Estado.AVISO:
			velocity = Vector2.ZERO
			if alvo != null:
				olhar_para(alvo)
				direcao_mergulho = (MiraAutomatica.centro_de(alvo) - centro()).normalized()
			if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
				aviso_final.emit(self)
			if _timer <= 0.0:
				estado = Estado.MERGULHO
				_timer = duracao_mergulho
		Estado.MERGULHO:
			velocity = direcao_mergulho * velocidade_mergulho
			if _timer <= 0.0 or is_on_floor() or is_on_wall() or is_on_ceiling():
				_terminar_mergulho()
		Estado.VOLTAR:
			velocity = Vector2(0, -Unidades.px(velocidade))
			if _timer <= 0.0:
				estado = Estado.CIRCULAR


func _terminar_mergulho() -> void:
	Combate.devolver_ficha(self)
	estado = Estado.VOLTAR
	_timer = 0.5
	_proximo_ataque = randf_range(intervalo_ataque.x, intervalo_ataque.y)


func esta_anunciando() -> bool:
	return (estado == Estado.AVISO or estado == Estado.MERGULHO) and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO or estado == Estado.MERGULHO:
		estado = Estado.VOLTAR
		_timer = 0.5


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 40.0
	var asa: float = 2.0 + sin(t) * 2.0
	if estado == Estado.AVISO:
		asa = 4.0 + sin(t * 3.0) * 1.0  # zumbido
	var cor: Color = Inimigo.cor_do_aviso(_timer) if estado == Estado.AVISO else Color("7d4c90")
	draw_rect(Rect2(-5, -10 - asa, 4, asa), Color(0.72, 0.83, 0.88, 0.8))
	draw_rect(Rect2(1, -10 - asa, 4, asa), Color(0.72, 0.83, 0.88, 0.8))
	draw_rect(Rect2(-6, -10, 12, 7), Color("4c2c5e"))
	draw_rect(Rect2(-4, -9, 8, 4), cor)
	draw_rect(Rect2(olhando * 4 - 1, -8, 2, 2), Color("a3e23c"))
	if _timer_flash > 0.0:
		draw_rect(Rect2(-6, -12, 12, 12), Color(1, 1, 1, 0.5))
	_desenhar_status()
