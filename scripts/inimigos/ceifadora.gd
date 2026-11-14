class_name Ceifadora
extends Inimigo
## Ceifadora Vesh, elite (GD-02 §4.3): 32×40, 250 de vida, rápida, peso Médio.
## (a) Sequência de 3 cortes em avanço: aviso 0,5 s (as lâminas brilham).
## (b) Some na parede e reaparece do lado oposto do alvo: um sinal no chão dura 0,6 s antes.
## Puxada pelo Grilhão, fica atordoada por 1,0 s (atordoamento_grilhao na cena).

enum Estado { PERSEGUIR, AVISO_CORTES, CORTES, SUMIDA, DESCANSO }

@export var velocidade: float = 3.0
@export var alcance_cortes: float = 5.0
@export var tempo_aviso: float = 0.5
@export var cortes: int = 3
@export var duracao_corte: float = 0.22
## px por corte
@export var avanco_corte: float = 22.0
@export var sinal_reaparecer: float = 0.6
@export var descanso: float = 1.0
## Chance de sumir na parede em vez de cortar, quando longe.
@export var chance_sumir: float = 0.5

var estado: Estado = Estado.PERSEGUIR
var ponto_reaparecer: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _cortes_restantes: int = 0
var _atingidos_corte: Array[Node] = []


func _comportamento(delta: float) -> void:
	_timer -= delta
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(30.0), Unidades.px(17.0)))
	match estado:
		Estado.PERSEGUIR:
			velocity.x = 0.0
			if alvo == null:
				return
			olhar_para(alvo)
			var d: float = absf(alvo.global_position.x - global_position.x)
			if d <= Unidades.px(alcance_cortes) and is_on_floor() and Combate.pedir_ficha(self):
				_comecar_cortes()
				return
			if d > Unidades.px(10.0) and is_on_floor() and randf() < chance_sumir * delta:
				sumir(alvo)
				return
			if is_on_floor() and ha_chao_a_frente():
				velocity.x = olhando * Unidades.px(velocidade)
		Estado.AVISO_CORTES:
			velocity.x = 0.0
			if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
				aviso_final.emit(self)
			if _timer <= 0.0:
				estado = Estado.CORTES
				_cortes_restantes = cortes
				_proximo_corte()
		Estado.CORTES:
			velocity.x = olhando * avanco_corte / duracao_corte
			_ferir_no_corte()
			if _timer <= 0.0:
				_cortes_restantes -= 1
				if _cortes_restantes <= 0 or not ha_chao_a_frente():
					_terminar()
				else:
					_proximo_corte()
		Estado.SUMIDA:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_reaparecer(alvo)
		Estado.DESCANSO:
			velocity.x = 0.0
			if _timer <= 0.0:
				estado = Estado.PERSEGUIR


func _comecar_cortes() -> void:
	estado = Estado.AVISO_CORTES
	_timer = tempo_aviso


func _proximo_corte() -> void:
	_timer = duracao_corte
	_atingidos_corte.clear()


func _ferir_no_corte() -> void:
	var area := Rect2(global_position + Vector2(-tamanho.x * 0.5 + olhando * 12.0, -tamanho.y), Vector2(tamanho.x + 12.0, tamanho.y))
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j == null or j.esta_morto() or j in _atingidos_corte:
			continue
		if area.intersects(Rect2(j.global_position - Vector2(6, 28), Vector2(12, 28))):
			_atingidos_corte.append(j)
			j.receber_ataque(InfoDano.criar(1, self, Vector2(olhando, 0)))


func _terminar() -> void:
	velocity.x = 0.0
	Combate.devolver_ficha(self)
	estado = Estado.DESCANSO
	_timer = descanso


## Some e marca no chão onde vai reaparecer: do outro lado do alvo.
func sumir(alvo: Node2D) -> void:
	var lado: float = signf(global_position.x - alvo.global_position.x)
	if lado == 0.0:
		lado = 1.0
	ponto_reaparecer = Vector2(alvo.global_position.x - lado * Unidades.px(4.0), alvo.global_position.y)
	estado = Estado.SUMIDA
	_timer = sinal_reaparecer
	collision_layer = 0
	if _contato != null:
		_contato.monitoring = false


func esta_sumida() -> bool:
	return estado == Estado.SUMIDA


func _reaparecer(alvo: Node2D) -> void:
	global_position = ponto_reaparecer
	collision_layer = Camadas.INIMIGOS
	if _contato != null:
		_contato.monitoring = true
	if alvo != null:
		olhar_para(alvo)
	estado = Estado.DESCANSO
	_timer = 0.3


func receber_ataque(info: InfoDano) -> bool:
	if estado == Estado.SUMIDA:
		return false
	return super(info)


func esta_anunciando() -> bool:
	return estado in [Estado.AVISO_CORTES, Estado.CORTES] and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO_CORTES or estado == Estado.CORTES:
		estado = Estado.DESCANSO
		_timer = descanso


func _draw() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	if estado == Estado.SUMIDA:
		# Sinal no chão onde ela vai reaparecer.
		var p: Vector2 = ponto_reaparecer - global_position
		var cor: Color = Inimigo.cor_do_aviso(_timer)
		draw_rect(Rect2(p.x - 12, p.y - 2, 24, 2), cor)
		draw_rect(Rect2(p.x - 2, p.y - 6, 4, 4), cor)
		return
	draw_rect(Rect2(-w * 0.5 + 6, -h + 6, w - 12, h - 10), Color("4c2c5e"))
	draw_rect(Rect2(-6, -h, 12, 9), Color("7d4c90"))
	draw_rect(Rect2(olhando * 3 - 1, -h + 3, 2, 2), Color("a3e23c"))
	var lamina: Color = Color("b8d4e0")
	if estado == Estado.AVISO_CORTES:
		lamina = Inimigo.cor_do_aviso(_timer)
	var x: float = olhando * (w * 0.5 - 2)
	draw_line(Vector2(x, -h + 12), Vector2(x + olhando * 12, -h + 2), lamina, 2.0)
	draw_line(Vector2(x, -h + 20), Vector2(x + olhando * 14, -h + 26), lamina, 2.0)
	if _timer_flash > 0.0:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 1, 1, 0.4))
	_desenhar_status()
