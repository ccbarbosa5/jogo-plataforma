class_name Grilhao
extends Ferramenta
## Ferramenta do Ryker (D-016): a corrente das algemas da arena, virada gancho.
## Números oficiais: GD-02, seção 1.1 (D-027). Lança na direção da mira (inclusive a automática).
##  - Leve: leva dano, é puxado até o Ryker e fica atordoado.
##  - Médio com proteção: leva dano, perde a armadura e cambaleia.
##  - Pesado ou ponto de ancoragem: puxa o Ryker até lá. Ele fica invulnerável durante
##    a puxada e um pouco depois, e ganha o Golpe de Arena (dano dobrado em pontos fracos).
##  - Nada no alcance (ou parede): a corrente volta e a recarga é menor.

signal acertou(alvo: Node)
signal lancou

enum Estado { PRONTO, LANCANDO, PUXANDO_INIMIGO, PUXANDO_JOGADOR, RECOLHENDO }

## tiles (96 px)
@export var alcance: float = 6.0
## Segundos até a ponta chegar ao alcance máximo.
@export var tempo_ate_alvo: float = 0.12
@export var dano: int = 15
## Recarga depois de acertar algo; conta quando a corrente volta.
@export var recarga: float = 3.0
## Recarga quando a corrente não pega nada.
@export var recarga_erro: float = 1.0
@export var atordoamento_leve: float = 1.0
@export var cambaleio_medio: float = 0.6
## Invulnerabilidade extra depois de chegar ao alvo pesado.
@export var invulneravel_ao_chegar: float = 0.2
@export var duracao_golpe_de_arena: float = 1.5
## tiles/s
@export var velocidade_recolher: float = 60.0
## tiles/s
@export var velocidade_puxar_inimigo: float = 20.0
## tiles/s
@export var velocidade_puxar_jogador: float = 22.0
## Segundos máximos de puxão (evita ficar preso em quinas).
@export var tempo_max_puxao: float = 0.6
## O inimigo puxado para a esta distância do Ryker (tiles).
@export var distancia_parada_inimigo: float = 1.5

var estado: Estado = Estado.PRONTO
var ponta: Vector2 = Vector2.ZERO

var _direcao: Vector2 = Vector2.RIGHT
var _percorrido: float = 0.0
var _alvo: Inimigo
var _ponto_preso: Vector2 = Vector2.ZERO
var _timer_recarga: float = 0.0
var _timer_puxao: float = 0.0
var _errou: bool = false


func esta_pronto() -> bool:
	return estado == Estado.PRONTO and _timer_recarga <= 0.0


## Caçada (Mordida C2): devolve parte da recarga.
func reduzir_recarga(segundos: float) -> void:
	_timer_recarga = maxf(_timer_recarga - segundos, 0.0)


func recarga_restante() -> float:
	return maxf(_timer_recarga, 0.0)


func controla_movimento() -> bool:
	return estado == Estado.PUXANDO_JOGADOR


func processar(delta: float) -> void:
	if estado == Estado.PRONTO and _timer_recarga > 0.0:
		_timer_recarga -= delta
	match estado:
		Estado.PRONTO:
			if jogador.entrada.ferramenta_pressionada and _timer_recarga <= 0.0:
				_lancar()
		Estado.LANCANDO:
			_avancar_ponta(delta)
		Estado.PUXANDO_INIMIGO:
			_atualizar_puxao_inimigo(delta)
		Estado.PUXANDO_JOGADOR:
			ponta = _ponto_preso
			if not jogador.esta_sendo_puxado():
				_chegou_ao_alvo_pesado()
		Estado.RECOLHENDO:
			ponta = ponta.move_toward(jogador.ponto_de_tiro(), Unidades.px(velocidade_recolher) * delta)
			if ponta.distance_to(jogador.ponto_de_tiro()) < 2.0:
				_terminar()
	queue_redraw()


## Solta a corrente (ex.: o jogador morreu ou deu dash).
func cancelar() -> void:
	if _alvo != null and is_instance_valid(_alvo):
		_alvo.terminar_puxao()
	_alvo = null
	if estado == Estado.PUXANDO_JOGADOR:
		jogador.cancelar_puxao()
	if estado != Estado.PRONTO:
		estado = Estado.RECOLHENDO


func _lancar() -> void:
	_direcao = Vector2(jogador.mira).normalized()
	ponta = jogador.ponto_de_tiro()
	_percorrido = 0.0
	_errou = false
	estado = Estado.LANCANDO
	lancou.emit()
	_avancar_ponta(get_physics_process_delta_time())


func _avancar_ponta(delta: float) -> void:
	var alcance_px: float = Unidades.px(alcance)
	var passo: float = minf(alcance_px / tempo_ate_alvo * delta, alcance_px - _percorrido)
	var nova: Vector2 = ponta + _direcao * passo
	var consulta := PhysicsRayQueryParameters2D.create(ponta, nova,
			Camadas.MUNDO | Camadas.INIMIGOS | Camadas.GANCHOS, [jogador.get_rid()])
	consulta.collide_with_areas = true
	var resultado: Dictionary = get_world_2d().direct_space_state.intersect_ray(consulta)
	if not resultado.is_empty():
		ponta = resultado["position"]
		_ao_acertar(resultado["collider"])
		return
	ponta = nova
	_percorrido += passo
	if _percorrido >= alcance_px - 0.01:
		_errou = true
		estado = Estado.RECOLHENDO


func _ao_acertar(colisor: Object) -> void:
	if colisor is PontoGancho:
		_puxar_jogador((colisor as PontoGancho).global_position)
		return
	var inimigo := colisor as Inimigo
	if inimigo == null:
		_errou = true  # parede ou chão
		estado = Estado.RECOLHENDO
		return
	acertou.emit(inimigo)
	var info := InfoDano.criar(dano, jogador, _direcao)
	info.corpo_a_corpo = true  # a corrente não é bloqueada pela armadura
	match inimigo.peso:
		Inimigo.Peso.PESADO:
			inimigo.receber_ataque(info)
			if inimigo.esta_vivo():
				_puxar_jogador(ponta - _direcao * 10.0)
			else:
				estado = Estado.RECOLHENDO
		Inimigo.Peso.MEDIO:
			inimigo.arrancar_protecao()
			inimigo.receber_ataque(info)
			if inimigo.esta_vivo():
				inimigo.atordoar(inimigo.atordoamento_grilhao if inimigo.atordoamento_grilhao >= 0.0 else cambaleio_medio)
			estado = Estado.RECOLHENDO
		Inimigo.Peso.LEVE:
			inimigo.receber_ataque(info)
			if inimigo.esta_vivo():
				_alvo = inimigo
				inimigo.receber_puxao(jogador, Unidades.px(velocidade_puxar_inimigo))
				_timer_puxao = tempo_max_puxao
				estado = Estado.PUXANDO_INIMIGO
			else:
				estado = Estado.RECOLHENDO


func _puxar_jogador(ponto: Vector2) -> void:
	_ponto_preso = ponto
	# O destino é dos pés do Ryker: compensa a altura do ponto de tiro.
	var destino: Vector2 = ponto + (jogador.global_position - jogador.ponto_de_tiro())
	jogador.iniciar_puxao(destino, Unidades.px(velocidade_puxar_jogador), tempo_max_puxao, true)
	estado = Estado.PUXANDO_JOGADOR


func _chegou_ao_alvo_pesado() -> void:
	jogador.vida.tornar_invulneravel(invulneravel_ao_chegar)
	jogador.ativar_golpe_de_arena(duracao_golpe_de_arena)
	_terminar()


func _atualizar_puxao_inimigo(delta: float) -> void:
	_timer_puxao -= delta
	if _alvo == null or not is_instance_valid(_alvo) or not _alvo.esta_vivo():
		_alvo = null
		estado = Estado.RECOLHENDO
		return
	ponta = _alvo.centro()
	var perto: bool = _alvo.global_position.distance_to(jogador.global_position) <= Unidades.px(distancia_parada_inimigo)
	if perto or _timer_puxao <= 0.0:
		_alvo.terminar_puxao()
		_alvo.atordoar(atordoamento_leve)
		_alvo = null
		estado = Estado.RECOLHENDO


func _terminar() -> void:
	estado = Estado.PRONTO
	_timer_recarga = recarga_erro if _errou else recarga


func _draw() -> void:
	if estado == Estado.PRONTO or jogador == null:
		return
	var inicio: Vector2 = to_local(jogador.ponto_de_tiro())
	var fim: Vector2 = to_local(ponta)
	draw_line(inicio, fim, Color("a7adba"), 1.0)
	draw_rect(Rect2(fim - Vector2(2, 2), Vector2(4, 4)), Color("ebcb8b"))
