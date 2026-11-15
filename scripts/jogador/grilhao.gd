class_name Grilhao
extends Ferramenta
## Ferramenta do Ryker (D-016): a corrente das algemas da arena, virada gancho. GD-07 §2.
## Não interrompe o tiro: lança na direção da mira (botão direito, mouse) e o Ryker continua
## atirando, inclusive durante a puxada. Todo alvo acertado fica Marcado (ControleArma.marcar).
##  - Leve: puxado até 24 px do Ryker e atordoado por 1,0 s.
##  - Médio com escudo ou placa: perde a proteção e cambaleia 0,6 s.
##  - Médio sem proteção: cambaleia 0,6 s; numa plataforma acima do Ryker, é derrubado.
##  - Pesado, elite ou ponto de ancoragem: puxa o Ryker até lá (gancho), invulnerável na puxada
##    e por 0,2 s depois. O chefe ainda aceita o contra-ataque (arrancar_protecao).
##  - Nada no alcance (ou parede): a corrente volta e a recarga é menor.
## Ramo do Grilhão na árvore de Combate (Jogador.tem_no): Corrente Longa, Marca Funda (na
## ControleArma), Duas Cargas, Arrastão e Corrente Explosiva.

signal acertou(alvo: Node)
signal lancou

enum Estado { PRONTO, LANCANDO, PUXANDO_INIMIGO, PUXANDO_JOGADOR, RECOLHENDO }

## tiles (96 px). Corrente Longa: `alcance_longo`.
@export var alcance: float = 6.0
@export var alcance_longo: float = 8.0
## Segundos até a ponta chegar ao alcance máximo.
@export var tempo_ate_alvo: float = 0.12
@export var dano: int = 10
## Recarga de uma carga depois de acertar algo; conta quando a corrente volta.
@export var recarga: float = 3.0
## Recarga quando a corrente não pega nada.
@export var recarga_erro: float = 1.0
@export var atordoamento_leve: float = 1.0
@export var cambaleio_medio: float = 0.6
## Médio numa plataforma acima do Ryker é puxado esta distância na direção dele (tiles).
@export var derrubar_tiles: float = 2.0
## Altura mínima (px) para contar como "numa plataforma acima".
@export var derrubar_altura_px: float = 12.0
## Invulnerabilidade extra depois de chegar ao alvo pesado.
@export var invulneravel_ao_chegar: float = 0.2
@export_group("Ramo do Grilhão (GD-07 §4.3)")
## Arrastão: até este número de leves perto do alvo também são puxados.
@export var arrastao_extras: int = 3
@export var arrastao_raio_px: float = 32.0
@export var arrastao_cambaleio_elite: float = 0.4
## Corrente Explosiva.
@export var explosao_dano: int = 40
@export var explosao_raio_px: float = 40.0
@export_group("Movimento")
## tiles/s
@export var velocidade_recolher: float = 60.0
## tiles/s
@export var velocidade_puxar_inimigo: float = 20.0
## tiles/s
@export var velocidade_puxar_jogador: float = 22.0
## Segundos máximos de puxão (evita ficar preso em quinas).
@export var tempo_max_puxao: float = 0.6
## O inimigo puxado para a esta distância do Ryker (tiles): 24 px.
@export var distancia_parada_inimigo: float = 1.5

var estado: Estado = Estado.PRONTO
var ponta: Vector2 = Vector2.ZERO
var cargas: int = 1

var _direcao: Vector2 = Vector2.RIGHT
var _percorrido: float = 0.0
## Inimigos sendo puxados -> se ficam atordoados ao chegar.
var _puxados: Dictionary = {}
var _ponto_preso: Vector2 = Vector2.ZERO
var _timer_recarga: float = 0.0
var _timer_puxao: float = 0.0
var _errou: bool = false


func cargas_maximas() -> int:
	return 2 if _no(&"grilhao_duas_cargas") else 1


func alcance_tiles() -> float:
	return alcance_longo if _no(&"grilhao_corrente_longa") else alcance


func esta_pronto() -> bool:
	return estado == Estado.PRONTO and cargas > 0


func reduzir_recarga(segundos: float) -> void:
	_timer_recarga = maxf(_timer_recarga - segundos, 0.0)


## Tempo até a próxima carga (0 = todas cheias).
func recarga_restante() -> float:
	return maxf(_timer_recarga, 0.0) if cargas < cargas_maximas() else 0.0


func controla_movimento() -> bool:
	return estado == Estado.PUXANDO_JOGADOR


func _no(id: StringName) -> bool:
	return jogador != null and jogador.tem_no(id)


func processar(delta: float) -> void:
	_recarregar(delta)
	match estado:
		Estado.PRONTO:
			if jogador.entrada.ferramenta_pressionada and cargas > 0:
				_lancar()
		Estado.LANCANDO:
			_avancar_ponta(delta)
		Estado.PUXANDO_INIMIGO:
			_atualizar_puxao_inimigos(delta)
		Estado.PUXANDO_JOGADOR:
			ponta = _ponto_preso
			if not jogador.esta_sendo_puxado():
				_chegou_ao_alvo_pesado()
		Estado.RECOLHENDO:
			ponta = ponta.move_toward(jogador.ponto_de_tiro(), Unidades.px(velocidade_recolher) * delta)
			if ponta.distance_to(jogador.ponto_de_tiro()) < 2.0:
				_terminar()
	queue_redraw()


## Recarga carga a carga; só corre com a corrente recolhida (conta a partir da volta).
func _recarregar(delta: float) -> void:
	var maximo: int = cargas_maximas()
	cargas = mini(cargas, maximo)
	if cargas >= maximo or estado != Estado.PRONTO:
		return
	_timer_recarga -= delta
	if _timer_recarga <= 0.0:
		cargas += 1
		_timer_recarga = recarga if cargas < maximo else 0.0


## Solta a corrente (ex.: o jogador morreu ou deu dash).
func cancelar() -> void:
	for alvo in _puxados.keys():
		if is_instance_valid(alvo):
			(alvo as Inimigo).terminar_puxao()
	_puxados.clear()
	if estado == Estado.PUXANDO_JOGADOR:
		jogador.cancelar_puxao()
	if estado != Estado.PRONTO:
		estado = Estado.RECOLHENDO


func _lancar() -> void:
	cargas -= 1
	_direcao = jogador.direcao_mira()  # D-052: mesma direção exata do tiro (e da mira Total)
	ponta = jogador.ponto_de_tiro()
	_percorrido = 0.0
	_errou = false
	estado = Estado.LANCANDO
	lancou.emit()
	_avancar_ponta(get_physics_process_delta_time())


func _avancar_ponta(delta: float) -> void:
	var alcance_px: float = Unidades.px(alcance_tiles())
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
	acertou.emit(inimigo)  # o Jogador marca o alvo (ControleArma.marcar)
	if _no(&"grilhao_corrente_explosiva"):
		_explodir(ponta)
	var info := InfoDano.criar(dano, jogador, _direcao)
	info.corpo_a_corpo = true  # a corrente não é bloqueada pela armadura
	estado = Estado.RECOLHENDO
	var gancho: bool = inimigo.peso == Inimigo.Peso.PESADO or inimigo.categoria == Inimigo.Categoria.ELITE
	if inimigo.categoria == Inimigo.Categoria.CHEFE:
		# Chefe: o contra-ataque (ex.: Ur-Kesh erguendo o machado) tem prioridade sobre o gancho.
		if inimigo.arrancar_protecao():
			inimigo.receber_ataque(info)
			return
		gancho = true
	if gancho:
		inimigo.receber_ataque(info)
		if inimigo.esta_vivo():
			if _no(&"grilhao_arrastao") and inimigo.categoria == Inimigo.Categoria.ELITE:
				inimigo.atordoar(arrastao_cambaleio_elite)
			_puxar_jogador(ponta - _direcao * 10.0)
		return
	match inimigo.peso:
		Inimigo.Peso.MEDIO:
			var tinha_protecao: bool = inimigo.arrancar_protecao()
			inimigo.receber_ataque(info)
			if not inimigo.esta_vivo():
				return
			if _no(&"grilhao_arrastao"):
				_comecar_puxao(inimigo, false)  # médios passam a ser puxados, sem atordoar
			else:
				inimigo.atordoar(inimigo.atordoamento_grilhao if inimigo.atordoamento_grilhao >= 0.0 else cambaleio_medio)
				if not tinha_protecao and _esta_acima(inimigo):
					var lado: float = signf(jogador.global_position.x - inimigo.global_position.x)
					inimigo.deslocar(Vector2(lado * Unidades.px(derrubar_tiles), 0.0))
		Inimigo.Peso.LEVE:
			inimigo.receber_ataque(info)
			if inimigo.esta_vivo():
				_comecar_puxao(inimigo, true)
	if _no(&"grilhao_arrastao") and not _puxados.is_empty():
		_arrastar_vizinhos(inimigo)


## O inimigo está numa plataforma acima do Ryker (dá para derrubar).
func _esta_acima(inimigo: Inimigo) -> bool:
	return inimigo.global_position.y < jogador.global_position.y - derrubar_altura_px


func _comecar_puxao(inimigo: Inimigo, atordoar_ao_chegar: bool) -> void:
	_puxados[inimigo] = atordoar_ao_chegar
	inimigo.receber_puxao(jogador, Unidades.px(velocidade_puxar_inimigo))
	_timer_puxao = tempo_max_puxao
	estado = Estado.PUXANDO_INIMIGO


## Arrastão: puxa também até 3 leves a até 32 px do alvo.
func _arrastar_vizinhos(alvo: Inimigo) -> void:
	var extras: int = 0
	for no in get_tree().get_nodes_in_group("inimigos"):
		var outro := no as Inimigo
		if outro == null or outro == alvo or not outro.esta_vivo() or outro.peso != Inimigo.Peso.LEVE:
			continue
		if outro.centro().distance_to(alvo.centro()) > arrastao_raio_px or _puxados.has(outro):
			continue
		_comecar_puxao(outro, true)
		extras += 1
		if extras >= arrastao_extras:
			return


## Corrente Explosiva: dano em área e arranca escudos e placas.
func _explodir(centro: Vector2) -> void:
	for no in get_tree().get_nodes_in_group("inimigos"):
		var inimigo := no as Inimigo
		if inimigo == null or not inimigo.esta_vivo():
			continue
		if inimigo.centro().distance_to(centro) <= explosao_raio_px + inimigo.tamanho.x * 0.5:
			if inimigo.categoria != Inimigo.Categoria.CHEFE:
				inimigo.arrancar_protecao()
			var golpe := InfoDano.criar(explosao_dano, jogador, inimigo.centro() - centro)
			golpe.explosao = true
			inimigo.receber_ataque(golpe)


func _puxar_jogador(ponto: Vector2) -> void:
	_ponto_preso = ponto
	# O destino é dos pés do Ryker: compensa a altura do ponto de tiro.
	var destino: Vector2 = ponto + (jogador.global_position - jogador.ponto_de_tiro())
	jogador.iniciar_puxao(destino, Unidades.px(velocidade_puxar_jogador), tempo_max_puxao, true)
	estado = Estado.PUXANDO_JOGADOR


func _chegou_ao_alvo_pesado() -> void:
	jogador.vida.tornar_invulneravel(invulneravel_ao_chegar)
	_terminar()


func _atualizar_puxao_inimigos(delta: float) -> void:
	_timer_puxao -= delta
	var parada: float = Unidades.px(distancia_parada_inimigo)
	for alvo in _puxados.keys():
		if not is_instance_valid(alvo) or not (alvo as Inimigo).esta_vivo():
			_puxados.erase(alvo)
			continue
		var inimigo := alvo as Inimigo
		if inimigo.global_position.distance_to(jogador.global_position) <= parada or _timer_puxao <= 0.0:
			inimigo.terminar_puxao()
			if _puxados[inimigo]:
				inimigo.atordoar(atordoamento_leve)
			_puxados.erase(inimigo)
	if _puxados.is_empty():
		estado = Estado.RECOLHENDO
		return
	ponta = (_puxados.keys()[0] as Inimigo).centro()


func _terminar() -> void:
	estado = Estado.PRONTO
	if cargas < cargas_maximas() and _timer_recarga <= 0.0:
		_timer_recarga = recarga_erro if _errou else recarga


func _draw() -> void:
	if estado == Estado.PRONTO or jogador == null:
		return
	var inicio: Vector2 = to_local(jogador.ponto_de_tiro())
	var fim: Vector2 = to_local(ponta)
	draw_line(inicio, fim, Color("a7adba"), 1.0)
	draw_rect(Rect2(fim - Vector2(2, 2), Vector2(4, 4)), Color("ebcb8b"))
