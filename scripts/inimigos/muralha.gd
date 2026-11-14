class_name Muralha
extends Inimigo
## Muralha (GD-02 §4.1): 40×64, 150 de vida, peso Médio + escudo-torre que bloqueia 100% pela
## frente (explosões e golpes corpo a corpo passam). Avança com o escudo erguido.
## Ataque: investida [PESADO] de 160 px, aviso de 0,8 s (rugido e pé raspando o chão).
## Ensina o Grilhão: arrancar o escudo a derruba, vulnerável por 1,5 s.

enum Estado { AVANCAR, AVISO, INVESTIDA, DESCANSO }

@export var velocidade: float = 1.0
@export var alcance_investida: Vector2 = Vector2(12.0, 2.0)
@export var tempo_aviso: float = 0.8
@export var distancia_investida: float = 160.0
## px/s
@export var velocidade_investida: float = 320.0
## [PESADO]: 2 blocos.
@export var dano_investida: int = 2
@export var descanso: float = 1.5
## Derrubada sem o escudo.
@export var vulneravel_sem_escudo: float = 1.5

var estado: Estado = Estado.AVANCAR
var _timer: float = 0.0
var _percorrido: float = 0.0
var _direcao: float = 1.0
var _atingidos: Array[Node] = []


func _comportamento(delta: float) -> void:
	_timer -= delta
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(30.0), Unidades.px(17.0)))
	match estado:
		Estado.AVANCAR:
			velocity.x = 0.0
			if alvo == null:
				return
			olhar_para(alvo)
			var d: Vector2 = alvo.global_position - global_position
			if absf(d.x) <= Unidades.px(alcance_investida.x) and absf(d.y) <= Unidades.px(alcance_investida.y) \
					and is_on_floor() and Combate.pedir_ficha(self):
				estado = Estado.AVISO
				_timer = tempo_aviso
				_direcao = float(olhando)
				return
			if is_on_floor() and ha_chao_a_frente():
				velocity.x = olhando * Unidades.px(velocidade)
		Estado.AVISO:
			velocity.x = 0.0
			if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
				aviso_final.emit(self)
			if _timer <= 0.0:
				estado = Estado.INVESTIDA
				_percorrido = 0.0
				_atingidos.clear()
		Estado.INVESTIDA:
			velocity.x = _direcao * velocidade_investida
			_percorrido += velocidade_investida * delta
			_ferir_na_investida()
			if _percorrido >= distancia_investida or is_on_wall() or not ha_chao_a_frente():
				_terminar_investida()
		Estado.DESCANSO:
			velocity.x = 0.0
			if _timer <= 0.0:
				estado = Estado.AVANCAR


func _ferir_na_investida() -> void:
	if _contato == null:
		return
	for corpo in _contato.get_overlapping_bodies():
		if corpo is Jogador and not corpo in _atingidos:
			_atingidos.append(corpo)
			corpo.receber_ataque(InfoDano.criar(dano_investida, self, Vector2(_direcao, 0)))


func _terminar_investida() -> void:
	velocity.x = 0.0
	Combate.devolver_ficha(self)
	estado = Estado.DESCANSO
	_timer = descanso


func esta_anunciando() -> bool:
	return (estado == Estado.AVISO or estado == Estado.INVESTIDA) and not esta_atordoado()


func esta_investindo() -> bool:
	return estado == Estado.INVESTIDA


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO or estado == Estado.INVESTIDA:
		estado = Estado.DESCANSO
		_timer = descanso


## Grilhão arranca o escudo: a Muralha cai e fica vulnerável.
func arrancar_protecao() -> bool:
	if not super():
		return false
	reducao_frontal = -1.0
	_cancelar_ataque()
	atordoar(vulneravel_sem_escudo)
	return true


func tem_escudo() -> bool:
	return armadura_frontal


func _draw() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	var tremor: float = (randf() - 0.5) * 2.0 if estado == Estado.AVISO else 0.0
	draw_rect(Rect2(-w * 0.5 + 6 + tremor, -h + 6, w - 12, h - 6), Color("56604a"))
	draw_rect(Rect2(-8 + tremor, -h, 16, 12), Color("7c8a6c"))
	if armadura_frontal:
		var x: float = olhando * (w * 0.5 - 6.0) - 5.0
		var cor: Color = Inimigo.cor_do_aviso(_timer) if estado == Estado.AVISO else Color("9d9175")
		draw_rect(Rect2(x + tremor, -h - 2, 10, h - 2), Color("dccfae"))
		draw_rect(Rect2(x + 2 + tremor, -h + 4, 6, h - 14), cor)
	if estado == Estado.AVISO:
		draw_rect(Rect2(-olhando * 14 - 3, -3, 6, 3), Inimigo.cor_do_aviso(_timer))  # pé raspando
	if _timer_flash > 0.0:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 1, 1, 0.5))
	_desenhar_status()
