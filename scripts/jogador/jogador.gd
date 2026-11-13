class_name Jogador
extends CharacterBody2D
## Personagem jogável: corre, pula, dá dash, mira em 8 direções, atira, golpeia de perto e lança granadas.
## A habilidade própria fica num filho do tipo Ferramenta (Ryker: Grilhão).
## Balanceamento em ParametrosJogador, DadosArma, DadosGranada e Assistencias (.tres).
## Os comandos vêm de um EntradaJogador; o Jogador nunca lê o Input direto
## (isso deixa a porta aberta para co-op local e permite testes automáticos).

signal morreu(jogador: Jogador)
signal atirou(projetil: Projetil)
signal golpeou(alvos: Array[Inimigo])
signal lancou_granada(granada: Granada)

## Hitbox (o sprite do Ryker tem 16×32 px; GD-01 3.2).
const LARGURA: float = 12.0
const ALTURA_EM_PE: float = 28.0
const ALTURA_AGACHADO: float = 18.0
const TEMPO_ATRAVESSAR_PLATAFORMA: float = 0.25

@export var parametros: ParametrosJogador
@export var arma: DadosArma
@export var granada: DadosGranada
@export var assistencias: Assistencias

@onready var vida: Vida = $Vida
@onready var forma: CollisionShape2D = $Forma

var entrada: EntradaJogador
## Onde os projéteis e granadas são criados. Se vazio, usa o pai do jogador.
var container_projeteis: Node
var arma_principal: DadosArma
var municao: int = -1
var granadas: int = 0
## 0 a 100 (Combate.regras.chamado_maximo).
var barra_chamado: float = 0.0
var upgrades: UpgradesJogador = UpgradesJogador.new()
var olhando: int = 1
var mira: Vector2i = Vector2i(1, 0)
var agachado: bool = false
var mira_travada: bool = false
var cargas_dash: int = 0
var ferramenta: Ferramenta
var mira_automatica: MiraAutomatica = MiraAutomatica.new()

var _altura_atual: float = ALTURA_EM_PE
var _timer_coyote: float = 0.0
var _timer_buffer_pulo: float = 0.0
var _subindo_por_pulo: bool = false
var _dash_restante_px: float = 0.0
var _direcao_dash: int = 1
var _timer_recarga_dash: float = 0.0
var _dashes_no_ar: int = 0
var _cooldown_tiro: float = 0.0
var _cooldown_golpe: float = 0.0
var _timer_golpe_visual: float = 0.0
var _timer_atravessar: float = 0.0
var _timer_pisca: float = 0.0
var _timer_golpe_arena: float = 0.0
var _morto: bool = false
var _puxao_destino: Vector2 = Vector2.ZERO
var _puxao_velocidade: float = 0.0
var _puxao_invulneravel: bool = false
var _timer_puxao: float = 0.0


func _ready() -> void:
	add_to_group("jogadores")
	if parametros == null:
		parametros = ParametrosJogador.new()
	if entrada == null:
		entrada = EntradaLocal.new()
	if assistencias == null:
		assistencias = Assistencias.new()
	for filho in get_children():
		if filho is Ferramenta:
			ferramenta = filho
			ferramenta.jogador = self
	forma.shape = forma.shape.duplicate()
	collision_layer = Camadas.JOGADOR
	collision_mask = Camadas.MUNDO | Camadas.PLATAFORMAS
	vida.maxima = parametros.vida_maxima
	vida.invulnerabilidade_pos_dano = parametros.invulnerabilidade_dano
	vida.reiniciar()
	vida.dano_recebido.connect(_ao_levar_dano)
	vida.morreu.connect(_ao_morrer)
	cargas_dash = parametros.cargas_dash
	_dashes_no_ar = parametros.dashes_no_ar
	arma_principal = arma
	if arma != null:
		municao = arma.municao
	reabastecer_granadas()
	_aplicar_altura(ALTURA_EM_PE)


func _physics_process(delta: float) -> void:
	entrada.atualizar()
	if _morto:
		velocity.x = move_toward(velocity.x, 0.0, parametros.frenagem_px() * delta)
		_aplicar_gravidade(delta)
		move_and_slide()
	else:
		_atualizar_timers(delta)
		var no_chao: bool = is_on_floor()
		if no_chao:
			_timer_coyote = parametros.coyote_time
			_dashes_no_ar = parametros.dashes_no_ar
			if velocity.y >= 0.0:
				_subindo_por_pulo = false
		if entrada.pular_pressionado:
			_timer_buffer_pulo = parametros.buffer_pulo
		_atualizar_mira(no_chao)
		if ferramenta != null:
			ferramenta.processar(delta)
		_tentar_iniciar_dash(no_chao)
		if esta_em_dash():
			_mover_dash(delta)
		elif esta_sendo_puxado():
			_mover_puxao(delta)
		else:
			_mover_horizontal(delta)
			_aplicar_gravidade(delta)
			_tentar_pular(no_chao)
			move_and_slide()
		_atualizar_ataque(delta)
		if entrada.granada_pressionada:
			lancar_granada()
	entrada.fim_do_frame()
	queue_redraw()


# --- Consultas públicas (HUD, testes, inimigos) ---

func esta_em_dash() -> bool:
	return _dash_restante_px > 0.0


func esta_morto() -> bool:
	return _morto


func esta_sendo_puxado() -> bool:
	return _timer_puxao > 0.0


func golpe_de_arena_ativo() -> bool:
	return _timer_golpe_arena > 0.0


## Ponto de onde saem os tiros e o Grilhão (altura do peito).
func ponto_de_tiro() -> Vector2:
	return global_position + Vector2(0.0, -_altura_atual * 0.6)


func receber_ataque(info: InfoDano) -> bool:
	return vida.receber_dano(info.valor)


## Atalho: `quantidade` em blocos de vida.
func receber_dano(quantidade: int, _origem: Node = null) -> bool:
	return vida.receber_dano(quantidade)


## Chamado pelos inimigos quando este jogador causa dano: enche a barra de Chamado (GD-02, 6).
func registrar_dano_causado(quantidade: int) -> void:
	var r: RegrasCombate = Combate.regras
	barra_chamado = minf(barra_chamado + quantidade / r.chamado_dano_por_ponto, r.chamado_maximo)


func chamado_pronto() -> bool:
	return barra_chamado >= Combate.regras.chamado_maximo


func ativar_golpe_de_arena(segundos: float) -> void:
	_timer_golpe_arena = maxf(_timer_golpe_arena, segundos)


## Puxa o jogador em linha reta até `destino` (pés). Usado pelo Grilhão.
func iniciar_puxao(destino: Vector2, velocidade_px: float, tempo_max: float, invulneravel: bool = false) -> void:
	_puxao_destino = destino
	_puxao_velocidade = velocidade_px
	_timer_puxao = tempo_max
	_puxao_invulneravel = invulneravel
	_subindo_por_pulo = false
	if invulneravel:
		vida.tornar_invulneravel(2.0 / Engine.physics_ticks_per_second)  # renovada a cada frame do puxão


func cancelar_puxao() -> void:
	_timer_puxao = 0.0


## Troca a arma (ex.: pickup pesado). Quando a munição acaba, volta para a principal.
func equipar(nova_arma: DadosArma) -> void:
	arma = nova_arma
	municao = nova_arma.municao
	_cooldown_tiro = 0.0


## Granadas voltam ao máximo a cada sala nova (GD-02, 1.3).
func reabastecer_granadas() -> void:
	granadas = granada.por_sala if granada != null else 0


func lancar_granada() -> Granada:
	if granada == null or granada.cena == null or granadas <= 0 or _morto:
		return null
	granadas -= 1
	var g: Granada = granada.cena.instantiate()
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	destino.add_child(g)
	var lancamento: Vector2 = Vector2(olhando * Unidades.px(granada.velocidade_lancamento.x),
			-Unidades.px(granada.velocidade_lancamento.y))
	if mira.y < 0 and mira.x == 0:
		lancamento = Vector2(olhando * lancamento.x * 0.3, lancamento.y * 1.3)  # mais para cima
	g.lancar(ponto_de_tiro(), lancamento + Vector2(velocity.x * 0.5, 0.0), granada, self)
	lancou_granada.emit(g)
	return g


# --- Movimento ---

func _atualizar_timers(delta: float) -> void:
	_timer_coyote -= delta
	_timer_buffer_pulo -= delta
	_timer_pisca = maxf(_timer_pisca - delta, 0.0)
	_timer_golpe_arena = maxf(_timer_golpe_arena - delta, 0.0)
	_timer_golpe_visual = maxf(_timer_golpe_visual - delta, 0.0)
	if _timer_atravessar > 0.0:
		_timer_atravessar -= delta
		if _timer_atravessar <= 0.0:
			collision_mask |= Camadas.PLATAFORMAS
	if cargas_dash < parametros.cargas_dash and not esta_em_dash():
		_timer_recarga_dash -= delta
		if _timer_recarga_dash <= 0.0:
			cargas_dash += 1
			_timer_recarga_dash = parametros.recarga_dash


func _atualizar_mira(no_chao: bool) -> void:
	var d: Vector2i = entrada.direcao
	mira_travada = entrada.travar_mira_segurado
	if d.x != 0 and not esta_em_dash():
		olhando = d.x
	agachado = no_chao and d.y > 0 and not mira_travada
	if agachado:
		mira = Vector2i(olhando, 0)
	elif d.y < 0:
		mira = Vector2i(d.x, -1)  # cima ou diagonal para cima
	elif d.y > 0 and (not no_chao or d.x != 0):
		mira = Vector2i(d.x, 1)  # no ar: baixo ou diagonal; travado no chão: só diagonal
	else:
		mira = Vector2i(olhando, 0)
	_aplicar_altura(ALTURA_AGACHADO if agachado else ALTURA_EM_PE)
	if not mira_travada:  # travar a mira sempre vence a assistência
		_aplicar_mira_automatica(no_chao)


func _aplicar_mira_automatica(no_chao: bool) -> void:
	match assistencias.modo_mira:
		Assistencias.ModoMira.TOTAL:
			var alvo: Node2D = mira_automatica.escolher_alvo(ponto_de_tiro(), assistencias, get_tree())
			if alvo == null:
				return
			var direcao: Vector2i = MiraAutomatica.direcao_8(MiraAutomatica.centro_de(alvo) - ponto_de_tiro())
			if agachado:
				direcao.y = 0
			if no_chao and direcao.y > 0 and direcao.x == 0:
				direcao.x = olhando  # no chão não dá para atirar reto para baixo
			if direcao != Vector2i.ZERO:
				mira = direcao
		Assistencias.ModoMira.ASSISTIDA:
			if mira_automatica.inimigo_na_direcao(ponto_de_tiro(), mira, assistencias, get_tree()) != null:
				return
			for passos: int in [1, -1]:
				var vizinha: Vector2i = MiraAutomatica.girar_8(mira, passos)
				if agachado and vizinha.y != 0:
					continue
				if no_chao and vizinha.y > 0 and vizinha.x == 0:
					continue
				if mira_automatica.inimigo_na_direcao(ponto_de_tiro(), vizinha, assistencias, get_tree()) != null:
					mira = vizinha
					return


func _mover_horizontal(delta: float) -> void:
	var alvo: float = 0.0
	if not mira_travada:
		alvo = entrada.direcao.x * parametros.velocidade_corrida_px()
		if agachado:
			alvo *= parametros.multiplicador_agachado
	var acelerando: bool = alvo != 0.0 and (velocity.x == 0.0 or signf(alvo) == signf(velocity.x))
	var taxa: float = parametros.aceleracao_px() if acelerando else parametros.frenagem_px()
	velocity.x = move_toward(velocity.x, alvo, taxa * delta)


func _aplicar_gravidade(delta: float) -> void:
	var g: float = parametros.gravidade_px()
	if velocity.y > 0.0:
		g *= parametros.multiplicador_gravidade_queda
	velocity.y = minf(velocity.y + g * delta, parametros.velocidade_queda_maxima_px())
	# Pulo variável: soltar o botão subindo corta o pulo.
	if _subindo_por_pulo and velocity.y < 0.0 and not entrada.pular_segurado:
		velocity.y *= parametros.corte_pulo
		_subindo_por_pulo = false


func _tentar_pular(no_chao: bool) -> void:
	if _timer_buffer_pulo <= 0.0:
		return
	# Baixo + pulo em cima de plataforma de mão única: desce por ela.
	if entrada.direcao.y > 0 and no_chao and _sobre_plataforma():
		_timer_buffer_pulo = 0.0
		_timer_atravessar = TEMPO_ATRAVESSAR_PLATAFORMA
		collision_mask &= ~Camadas.PLATAFORMAS
		return
	if _timer_coyote > 0.0:
		velocity.y = -parametros.velocidade_pulo_px()
		_timer_buffer_pulo = 0.0
		_timer_coyote = 0.0
		_subindo_por_pulo = true


func _sobre_plataforma() -> bool:
	for i in get_slide_collision_count():
		var colisao: KinematicCollision2D = get_slide_collision(i)
		var outro := colisao.get_collider() as CollisionObject2D
		if outro != null and (outro.collision_layer & Camadas.PLATAFORMAS) != 0 and colisao.get_normal().y < -0.5:
			return true
	return false


func _tentar_iniciar_dash(no_chao: bool) -> void:
	if not entrada.dash_pressionado or cargas_dash <= 0 or esta_em_dash():
		return
	if not no_chao and not esta_sendo_puxado():
		if _dashes_no_ar <= 0:
			return  # dash no ar: 1 vez por pulo (GD-01 3.2)
		_dashes_no_ar -= 1
	if esta_sendo_puxado():  # o dash solta o Grilhão
		_timer_puxao = 0.0
		if ferramenta != null:
			ferramenta.cancelar()
	cargas_dash -= 1
	_timer_recarga_dash = parametros.recarga_dash
	_dash_restante_px = Unidades.px(parametros.distancia_dash)
	_direcao_dash = entrada.direcao.x if entrada.direcao.x != 0 else olhando
	olhando = _direcao_dash
	_subindo_por_pulo = false
	vida.tornar_invulneravel(parametros.invulnerabilidade_dash)


## Dash horizontal sem gravidade. Anda exatamente distancia_dash (o último passo é parcial).
func _mover_dash(delta: float) -> void:
	var passo: float = minf(parametros.velocidade_dash_px() * delta, _dash_restante_px)
	_dash_restante_px -= passo
	velocity = Vector2(_direcao_dash * passo / delta, 0.0)
	move_and_slide()
	if not esta_em_dash():
		velocity.x = _direcao_dash * parametros.velocidade_corrida_px()


func _mover_puxao(delta: float) -> void:
	_timer_puxao -= delta
	if _puxao_invulneravel:
		vida.tornar_invulneravel(delta * 2.0)
	var para: Vector2 = _puxao_destino - global_position
	var passo: float = _puxao_velocidade * delta
	if para.length() <= passo:
		velocity = para / delta
	else:
		velocity = para.normalized() * _puxao_velocidade
	var antes: Vector2 = global_position
	move_and_slide()
	var chegou: bool = global_position.distance_to(_puxao_destino) < 2.0
	var travou: bool = get_slide_collision_count() > 0 and global_position.distance_to(antes) < passo * 0.25
	if chegou or travou or _timer_puxao <= 0.0:
		_timer_puxao = 0.0
		velocity *= 0.25
		_timer_coyote = parametros.coyote_time  # dá para pular logo depois de chegar
		_dashes_no_ar = parametros.dashes_no_ar


func _aplicar_altura(altura: float) -> void:
	if is_equal_approx(altura, _altura_atual) and forma.position.y != 0.0:
		return
	_altura_atual = altura
	var retangulo := forma.shape as RectangleShape2D
	retangulo.size = Vector2(LARGURA, altura)
	forma.position = Vector2(0.0, -altura * 0.5)


# --- Ataque: tiro ou golpe corpo a corpo automático ---

func _atualizar_ataque(delta: float) -> void:
	_cooldown_tiro -= delta
	_cooldown_golpe = maxf(_cooldown_golpe - delta, 0.0)
	var perto: Array[Inimigo] = inimigos_ao_alcance_do_golpe()
	var quer: bool = entrada.atirar_segurado or (assistencias.tiro_automatico and not perto.is_empty())
	if not quer:
		quer = _tiro_automatico_quer_atirar()
	if not quer:
		_cooldown_tiro = maxf(_cooldown_tiro, 0.0)
		return
	# Inimigo colado: o botão de atirar vira golpe de corrente (GD-02, 1.2).
	if not perto.is_empty():
		_cooldown_tiro = maxf(_cooldown_tiro, 0.0)
		if _cooldown_golpe <= 0.0:
			_golpear(perto)
		return
	if arma == null or arma.cena_projetil == null:
		return
	if _cooldown_tiro > 0.0:
		return
	_disparar()
	_cooldown_tiro = maxf(_cooldown_tiro, -delta) + 1.0 / arma.cadencia


func _tiro_automatico_quer_atirar() -> bool:
	if not assistencias.tiro_automatico or arma == null:
		return false
	if arma.municao >= 0 and not assistencias.tiro_automatico_armas_pesadas:
		return false
	return mira_automatica.inimigo_na_direcao(ponto_de_tiro(), mira, assistencias, get_tree()) != null


## Inimigos colados no Ryker (até alcance_golpe px), na frente ou sobrepostos.
func inimigos_ao_alcance_do_golpe() -> Array[Inimigo]:
	var lista: Array[Inimigo] = []
	var alcance: float = Unidades.px(parametros.alcance_golpe)
	for no in get_tree().get_nodes_in_group("inimigos"):
		var inimigo := no as Inimigo
		if inimigo == null or not inimigo.esta_vivo():
			continue
		var dx: float = inimigo.global_position.x - global_position.x
		var folga: float = absf(dx) - (inimigo.tamanho.x + LARGURA) * 0.5
		if folga > alcance:
			continue
		if folga > 0.0 and signf(dx) != olhando:
			continue  # está atrás
		var topo_inimigo: float = inimigo.global_position.y - inimigo.tamanho.y
		var topo_jogador: float = global_position.y - _altura_atual
		if topo_inimigo > global_position.y or topo_jogador > inimigo.global_position.y:
			continue  # sem sobreposição vertical
		lista.append(inimigo)
	return lista


func _golpear(alvos: Array[Inimigo]) -> void:
	_cooldown_golpe = parametros.intervalo_golpe
	_timer_golpe_visual = 0.12
	for inimigo in alvos:
		var info := InfoDano.criar(parametros.dano_golpe, self, Vector2(olhando, 0))
		info.corpo_a_corpo = true
		if inimigo.esta_atordoado():
			info.multiplicador = parametros.multiplicador_golpe_atordoado
		inimigo.receber_ataque(info)
	golpeou.emit(alvos)


func _disparar() -> void:
	var direcao: Vector2 = Vector2(mira).normalized()
	var origem: Vector2 = ponto_de_tiro() + direcao * 10.0
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	for i in arma.projeteis_por_tiro:
		var desvio: float = deg_to_rad(randf_range(-arma.espalhamento_graus, arma.espalhamento_graus))
		var projetil: Projetil = arma.cena_projetil.instantiate()
		destino.add_child(projetil)
		projetil.configurar(origem, direcao.rotated(desvio), Unidades.px(arma.velocidade_projetil),
				InfoDano.criar(arma.dano, self), arma.duracao_projetil,
				Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS | Camadas.PONTOS_FRACOS)
		atirou.emit(projetil)
	if municao > 0:
		municao -= 1
		if municao == 0 and arma_principal != null:
			equipar(arma_principal)


# --- Dano e morte ---

func _ao_levar_dano(_quantidade: int) -> void:
	_timer_pisca = parametros.invulnerabilidade_dano


func _ao_morrer() -> void:
	_morto = true
	_dash_restante_px = 0.0
	_timer_puxao = 0.0
	if ferramenta != null:
		ferramenta.cancelar()
	morreu.emit(self)


# --- Visual provisório (sem arte final) ---

func _draw() -> void:
	if _timer_pisca > 0.0 and int(_timer_pisca * 20.0) % 2 == 0:
		return
	var h: float = _altura_atual
	var cor: Color = Color("c8b273")
	if esta_em_dash():
		cor = Color("7fdcff")
	if golpe_de_arena_ativo():
		cor = Color("ffb347")
	if _morto:
		cor = Color("5c5c5c")
	draw_rect(Rect2(-LARGURA * 0.5, -h, LARGURA, h), cor)
	draw_rect(Rect2(olhando * 2.0 - 2.0, -h + 4.0, 4.0, 3.0), Color("2e3440"))  # visor
	var base: Vector2 = Vector2(0.0, -h * 0.6)
	draw_line(base, base + Vector2(mira).normalized() * 10.0, Color("eceff4"), 2.0)
	if _timer_golpe_visual > 0.0:
		var centro_golpe: Vector2 = base + Vector2(olhando * 14.0, 0.0)
		var inicio: float = -PI * 0.5 if olhando > 0 else PI * 0.5
		draw_arc(centro_golpe, 10.0, inicio, inicio + PI, 8, Color("a7adba"), 2.0)
