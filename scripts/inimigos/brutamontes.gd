class_name Brutamontes
extends Inimigo
## Brutamontes Kharn, elite (GD-02 §4.3): 48×72, 400 de vida, armadura frontal, peso Pesado
## (o Grilhão puxa o Ryker até ele). Ponto fraco: o tanque de munição nas costas.
## (a) Metralhadora giratória em varredura: o laser de mira mostra a linha 0,8 s antes; os tiros
##     passam na altura do peito (passa-se por baixo com dash ou agachado, ou pulando por cima).
## (b) Pisão [PESADO]: aviso de 0,7 s e onda de choque no chão para os dois lados (pula-se).

enum Estado { AVANCAR, AVISO_METRALHADORA, METRALHADORA, AVISO_PISAO, DESCANSO }

@export var velocidade: float = 0.75
@export var alcance: Vector2 = Vector2(18.0, 6.0)
@export var tempo_aviso_metralhadora: float = 0.8
@export var tiros_metralhadora: int = 10
@export var intervalo_metralhadora: float = 0.1
## Altura dos tiros acima do chão (px): acerta quem está em pé, não quem está agachado.
@export var altura_tiro: float = 22.0
## tiles/s
@export var velocidade_tiro: float = 15.0
@export var tempo_aviso_pisao: float = 0.7
@export var descanso: float = 1.4
@export var cena_projetil: PackedScene

var estado: Estado = Estado.AVANCAR
var ponto_fraco: PontoFraco
var _timer: float = 0.0
var _tiros: int = 0
var _proximo_e_pisao: bool = false


func _ready() -> void:
	super()
	ponto_fraco = PontoFraco.new()
	ponto_fraco.name = "Tanque"
	ponto_fraco.tamanho = Vector2(12, 16)
	add_child(ponto_fraco)
	_posicionar_tanque()


func _posicionar_tanque() -> void:
	if ponto_fraco != null:
		ponto_fraco.position = Vector2(-olhando * (tamanho.x * 0.5 - 2.0), -tamanho.y * 0.62)


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
			var perto: bool = absf(d.x) <= Unidades.px(alcance.x) and absf(d.y) <= Unidades.px(alcance.y)
			if perto and is_on_floor() and Combate.pedir_ficha(self):
				if _proximo_e_pisao or absf(d.x) < Unidades.px(4.0):
					estado = Estado.AVISO_PISAO
					_timer = tempo_aviso_pisao
				else:
					estado = Estado.AVISO_METRALHADORA
					_timer = tempo_aviso_metralhadora
				_proximo_e_pisao = not _proximo_e_pisao
				return
			if is_on_floor() and ha_chao_a_frente() and absf(d.x) > Unidades.px(6.0):
				velocity.x = olhando * Unidades.px(velocidade)
		Estado.AVISO_METRALHADORA, Estado.AVISO_PISAO:
			velocity.x = 0.0
			if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
				aviso_final.emit(self)
			if _timer <= 0.0:
				if estado == Estado.AVISO_PISAO:
					_pisar()
					_terminar()
				else:
					estado = Estado.METRALHADORA
					_tiros = tiros_metralhadora
					_timer = 0.0
		Estado.METRALHADORA:
			velocity.x = 0.0
			if _timer <= 0.0:
				_atirar()
				_tiros -= 1
				_timer = intervalo_metralhadora
				if _tiros <= 0:
					_terminar()
		Estado.DESCANSO:
			velocity.x = 0.0
			if _timer <= 0.0:
				estado = Estado.AVANCAR
	_posicionar_tanque()


func _terminar() -> void:
	Combate.devolver_ficha(self)
	estado = Estado.DESCANSO
	_timer = descanso


func ponto_do_cano() -> Vector2:
	return global_position + Vector2(olhando * (tamanho.x * 0.5 + 4.0), -altura_tiro)


func _atirar() -> void:
	if cena_projetil == null:
		return
	var p: Projetil = cena_projetil.instantiate()
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	destino.add_child(p)
	p.faccao_autor = faccao
	p.configurar(ponto_do_cano(), Vector2(olhando, 0), Unidades.px(velocidade_tiro), InfoDano.criar(1, self), 2.0,
			Camadas.PROJETEIS_INIMIGO, mascara_ataque())


func _pisar() -> void:
	var pai: Node = container_projeteis if container_projeteis != null else get_parent()
	for lado: float in [-1.0, 1.0]:
		OndaChoque.criar(pai, global_position + Vector2(lado * tamanho.x * 0.5, 0), lado, self)


func esta_anunciando() -> bool:
	return estado in [Estado.AVISO_METRALHADORA, Estado.METRALHADORA, Estado.AVISO_PISAO] and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado != Estado.AVANCAR and estado != Estado.DESCANSO:
		estado = Estado.DESCANSO
		_timer = descanso


func _draw() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	var levanta: float = 6.0 if estado == Estado.AVISO_PISAO else 0.0
	draw_rect(Rect2(-w * 0.5 + 4, -h + 10, w - 8, h - 24), Color("56604a"))
	draw_rect(Rect2(-w * 0.5 + 6, -14 - levanta, 12, 14), Color("363d30"))
	draw_rect(Rect2(w * 0.5 - 18, -14, 12, 14), Color("363d30"))
	draw_rect(Rect2(-9, -h, 18, 14), Color("7c8a6c"))
	draw_rect(Rect2(olhando * (w * 0.5 - 8) - 6, -h + 12, 12, 30), Color("dccfae"))  # placa frontal
	draw_rect(Rect2(-olhando * (w * 0.5 - 2) - 6, -h * 0.62 - 8, 12, 16), Color("9c3527"))  # tanque
	var cano: Vector2 = ponto_do_cano() - global_position
	var cor_cano: Color = Color("4b4753")
	if estado == Estado.AVISO_METRALHADORA:
		cor_cano = Inimigo.cor_do_aviso(_timer)
		draw_line(cano, cano + Vector2(olhando * 480.0, 0), Color(cor_cano, 0.8), 1.0)  # laser de mira
	elif estado == Estado.AVISO_PISAO:
		draw_rect(Rect2(-w * 0.5 + 6, -2, w - 12, 2), Inimigo.cor_do_aviso(_timer))
	draw_rect(Rect2(cano.x - (14 if olhando > 0 else 0), cano.y - 3, 14, 6), cor_cano)
	if _timer_flash > 0.0:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 1, 1, 0.4))
	_desenhar_status()
