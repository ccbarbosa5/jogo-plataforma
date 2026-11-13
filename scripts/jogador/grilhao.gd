class_name Grilhao
extends Ferramenta
## Ferramenta do Ryker (D-016): a corrente das algemas da arena, virada gancho.
## Lança na direção da mira.
##  - Inimigo leve: leva dano, é puxado até o Ryker e fica atordoado.
##  - Inimigo pesado ou PontoGancho: puxa o Ryker até lá.
##  - Parede ou nada: a corrente volta.
## Os números são padrão do DEV até GD definir (ver departamentos/DEV.md).

signal acertou(alvo: Node)

enum Estado { PRONTO, LANCANDO, PUXANDO_INIMIGO, PUXANDO_JOGADOR, RECOLHENDO }

## tiles
@export var alcance: float = 7.0
## tiles/s
@export var velocidade_lancamento: float = 45.0
## tiles/s
@export var velocidade_recolher: float = 60.0
## tiles/s
@export var velocidade_puxar_inimigo: float = 20.0
## tiles/s
@export var velocidade_puxar_jogador: float = 22.0
## Segundos máximos de puxão (evita ficar preso em quinas).
@export var tempo_max_puxao: float = 0.6
@export var dano: int = 1
@export var atordoamento: float = 1.0
@export var recarga: float = 1.2
## O inimigo puxado para a esta distância do Ryker (tiles).
@export var distancia_parada_inimigo: float = 1.5

var estado: Estado = Estado.PRONTO
var ponta: Vector2 = Vector2.ZERO

var _direcao: Vector2 = Vector2.RIGHT
var _percorrido: float = 0.0
var _alvo: Node2D
var _ponto_preso: Vector2 = Vector2.ZERO
var _timer_recarga: float = 0.0
var _timer_puxao: float = 0.0


func esta_pronto() -> bool:
	return estado == Estado.PRONTO and _timer_recarga <= 0.0


func controla_movimento() -> bool:
	return estado == Estado.PUXANDO_JOGADOR


func processar(delta: float) -> void:
	if _timer_recarga > 0.0:
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
				_terminar()
		Estado.RECOLHENDO:
			ponta = ponta.move_toward(jogador.ponto_de_tiro(), Unidades.px(velocidade_recolher) * delta)
			if ponta.distance_to(jogador.ponto_de_tiro()) < 2.0:
				_terminar()
	queue_redraw()


## Solta a corrente (ex.: o jogador morreu ou deu dash).
func cancelar() -> void:
	if _alvo != null and is_instance_valid(_alvo) and _alvo.has_method("terminar_puxao"):
		_alvo.terminar_puxao()
	_alvo = null
	if estado != Estado.PRONTO:
		estado = Estado.RECOLHENDO


func _lancar() -> void:
	_direcao = Vector2(jogador.mira).normalized()
	ponta = jogador.ponto_de_tiro()
	_percorrido = 0.0
	estado = Estado.LANCANDO


func _avancar_ponta(delta: float) -> void:
	var alcance_px: float = Unidades.px(alcance)
	var passo: float = minf(Unidades.px(velocidade_lancamento) * delta, alcance_px - _percorrido)
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
		estado = Estado.RECOLHENDO


func _ao_acertar(colisor: Object) -> void:
	if colisor is PontoGancho:
		_puxar_jogador((colisor as PontoGancho).global_position)
		return
	if colisor is Node2D and colisor.has_method("receber_puxao"):
		var inimigo := colisor as Node2D
		acertou.emit(inimigo)
		if inimigo.has_method("receber_dano"):
			inimigo.receber_dano(dano, self)
		if not is_instance_valid(inimigo) or inimigo.is_queued_for_deletion():
			estado = Estado.RECOLHENDO
			return
		if inimigo.get("pesado") == true:
			_puxar_jogador(ponta - _direcao * 10.0)
		else:
			_alvo = inimigo
			inimigo.receber_puxao(jogador, Unidades.px(velocidade_puxar_inimigo))
			_timer_puxao = tempo_max_puxao
			estado = Estado.PUXANDO_INIMIGO
		return
	estado = Estado.RECOLHENDO  # parede ou chão


func _puxar_jogador(ponto: Vector2) -> void:
	_ponto_preso = ponto
	# O destino é dos pés do Ryker: compensa a altura do ponto de tiro.
	var destino: Vector2 = ponto + (jogador.global_position - jogador.ponto_de_tiro())
	jogador.iniciar_puxao(destino, Unidades.px(velocidade_puxar_jogador), tempo_max_puxao)
	estado = Estado.PUXANDO_JOGADOR


func _atualizar_puxao_inimigo(delta: float) -> void:
	_timer_puxao -= delta
	if _alvo == null or not is_instance_valid(_alvo) or _alvo.is_queued_for_deletion():
		_alvo = null
		estado = Estado.RECOLHENDO
		return
	ponta = MiraAutomatica.centro_de(_alvo)
	var perto: bool = _alvo.global_position.distance_to(jogador.global_position) <= Unidades.px(distancia_parada_inimigo)
	if perto or _timer_puxao <= 0.0:
		_alvo.terminar_puxao()
		if _alvo.has_method("atordoar"):
			_alvo.atordoar(atordoamento)
		_alvo = null
		estado = Estado.RECOLHENDO


func _terminar() -> void:
	estado = Estado.PRONTO
	_timer_recarga = recarga


func _draw() -> void:
	if estado == Estado.PRONTO or jogador == null:
		return
	var inicio: Vector2 = to_local(jogador.ponto_de_tiro())
	var fim: Vector2 = to_local(ponta)
	draw_line(inicio, fim, Color("a7adba"), 1.0)
	draw_rect(Rect2(fim - Vector2(2, 2), Vector2(4, 4)), Color("ebcb8b"))
