class_name Cuspidor
extends Inimigo
## Cuspidor (GD-02 §4.2): 20×14, 25 de vida, peso Leve. Rasteja (sobe paredes baixas) e
## mantém média distância. Ataque: o corpo infla (aviso 0,5 s) e cospe em arco; a cusparada
## deixa uma poça de ácido no chão por 3 s.

enum Estado { RASTEJAR, AVISO, DESCANSO }

@export var velocidade: float = 1.75
@export var distancia_preferida: Vector2 = Vector2(6.0, 10.0)
@export var alcance: Vector2 = Vector2(14.0, 6.0)
@export var tempo_aviso: float = 0.5
@export var tempo_voo: float = 0.7
@export var descanso: float = 1.8
## Sobe paredes até esta altura (tiles).
@export var subida_maxima: float = 3.0

var estado: Estado = Estado.RASTEJAR
var _timer: float = 0.0
var _alvo: Node2D
var _subindo: float = 0.0


func _comportamento(delta: float) -> void:
	_timer -= delta
	_alvo = escolher_alvo(Vector2(Unidades.px(alcance.x), Unidades.px(alcance.y)))
	match estado:
		Estado.RASTEJAR:
			_rastejar(delta)
			if _alvo != null and is_on_floor() and Combate.pedir_ficha(self):
				olhar_para(_alvo)
				estado = Estado.AVISO
				_timer = tempo_aviso
		Estado.AVISO:
			velocity.x = 0.0
			if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
				aviso_final.emit(self)
			if _timer <= 0.0:
				_cuspir()
				Combate.devolver_ficha(self)
				estado = Estado.DESCANSO
				_timer = descanso
		Estado.DESCANSO:
			_rastejar(delta)
			if _timer <= 0.0:
				estado = Estado.RASTEJAR


## Fica entre 6 e 10 tiles do alvo; numa parede baixa, sobe por ela.
func _rastejar(delta: float) -> void:
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(30.0), Unidades.px(17.0)))
	velocity.x = 0.0
	if alvo == null:
		return
	olhar_para(alvo)
	var d: float = absf(alvo.global_position.x - global_position.x)
	var sentido: float = 0.0
	if d > Unidades.px(distancia_preferida.y):
		sentido = float(olhando)
	elif d < Unidades.px(distancia_preferida.x):
		sentido = -float(olhando)
	if sentido == 0.0:
		return
	velocity.x = sentido * Unidades.px(velocidade)
	if is_on_wall() and _subindo < Unidades.px(subida_maxima):
		velocity.y = -Unidades.px(velocidade) * 2.0
		_subindo += Unidades.px(velocidade) * 2.0 * delta
	elif is_on_floor():
		_subindo = 0.0


func _cuspir() -> void:
	if _alvo == null or not is_instance_valid(_alvo):
		return
	var pai: Node = container_projeteis if container_projeteis != null else get_parent()
	var p := ProjetilArco.lancar(pai, ProjetilArco.Tipo.CUSPARADA, self, centro() + Vector2(olhando * 8.0, -2.0),
			_alvo.global_position, tempo_voo, 40.0)
	p.raio = 12.0


func esta_anunciando() -> bool:
	return estado == Estado.AVISO and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO:
		estado = Estado.DESCANSO
		_timer = descanso


func _draw() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	var infla: float = 0.0
	if estado == Estado.AVISO:
		infla = 3.0 * (1.0 - clampf(_timer / tempo_aviso, 0.0, 1.0))
	draw_rect(Rect2(-w * 0.5 - infla * 0.5, -h - infla, w + infla, h + infla - 2), Color("4c2c5e"))
	draw_rect(Rect2(-w * 0.5 + 2, -h + 2 - infla, w - 4, 4), Color("7d4c90"))
	var boca: Color = Inimigo.cor_do_aviso(_timer) if estado == Estado.AVISO else Color("a3e23c")
	draw_rect(Rect2(olhando * (w * 0.5 - 3) - 2, -h * 0.6, 4, 3), boca)
	for i in 3:
		draw_rect(Rect2(-w * 0.5 + 2 + i * 6, -2, 2, 2), Color("2b1838"))
	if _timer_flash > 0.0:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 1, 1, 0.5))
	_desenhar_status()
