class_name Jogador
extends CharacterBody2D
## Personagem jogável (protótipo da Fase 1): corre, pula, dá dash, mira em 8 direções e atira.
## A habilidade própria fica num filho do tipo Ferramenta (Ryker: Grilhão).
## Balanceamento em ParametrosJogador (.tres), arma em DadosArma (.tres),
## acessibilidade em Assistencias (.tres).
## Os comandos vêm de um EntradaJogador; o Jogador nunca lê o Input direto
## (isso deixa a porta aberta para co-op local e permite testes automáticos).

signal morreu(jogador: Jogador)
signal atirou(projetil: Projetil)

const LARGURA: float = 12.0
const ALTURA_EM_PE: float = 22.0
const ALTURA_AGACHADO: float = 14.0
const TEMPO_ATRAVESSAR_PLATAFORMA: float = 0.25

@export var parametros: ParametrosJogador
@export var arma: DadosArma
@export var assistencias: Assistencias

@onready var vida: Vida = $Vida
@onready var forma: CollisionShape2D = $Forma

var entrada: EntradaJogador
## Onde os projéteis são criados. Se vazio, usa o pai do jogador.
var container_projeteis: Node
var arma_principal: DadosArma
var municao: int = -1
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
var _cooldown_tiro: float = 0.0
var _timer_atravessar: float = 0.0
var _timer_pisca: float = 0.0
var _morto: bool = false
var _puxao_destino: Vector2 = Vector2.ZERO
var _puxao_velocidade: float = 0.0
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
	arma_principal = arma
	if arma != null:
		municao = arma.municao
	_aplicar_altura(ALTURA_EM_PE)


func _physics_process(delta: float) -> void:
	entrada.atualizar()
	if _morto:
		velocity.x = move_toward(velocity.x, 0.0, parametros.aceleracao_px() * delta)
		_aplicar_gravidade(delta)
		move_and_slide()
	else:
		_atualizar_timers(delta)
		var no_chao: bool = is_on_floor()
		if no_chao:
			_timer_coyote = parametros.coyote_time
			if velocity.y >= 0.0:
				_subindo_por_pulo = false
		if entrada.pular_pressionado:
			_timer_buffer_pulo = parametros.buffer_pulo
		_atualizar_mira(no_chao)
		if ferramenta != null:
			ferramenta.processar(delta)
		_tentar_iniciar_dash()
		if esta_em_dash():
			_mover_dash(delta)
		elif esta_sendo_puxado():
			_mover_puxao(delta)
		else:
			_mover_horizontal(delta)
			_aplicar_gravidade(delta)
			_tentar_pular(no_chao)
			move_and_slide()
		_atualizar_tiro(delta)
	entrada.fim_do_frame()
	queue_redraw()


# --- Consultas públicas (HUD, testes, inimigos) ---

func esta_em_dash() -> bool:
	return _dash_restante_px > 0.0


func esta_morto() -> bool:
	return _morto


func esta_sendo_puxado() -> bool:
	return _timer_puxao > 0.0


## Ponto de onde saem os tiros e o Grilhão (altura do peito).
func ponto_de_tiro() -> Vector2:
	return global_position + Vector2(0.0, -_altura_atual * 0.6)


## Puxa o jogador em linha reta até `destino` (posição dos pés). Usado pelo Grilhão.
func iniciar_puxao(destino: Vector2, velocidade_px: float, tempo_max: float) -> void:
	_puxao_destino = destino
	_puxao_velocidade = velocidade_px
	_timer_puxao = tempo_max
	_subindo_por_pulo = false


func receber_dano(quantidade: int, _origem: Node = null) -> bool:
	return vida.receber_dano(quantidade)


## Troca a arma (ex.: pickup pesado). Quando a munição acaba, volta para a principal.
func equipar(nova_arma: DadosArma) -> void:
	arma = nova_arma
	municao = nova_arma.municao
	_cooldown_tiro = 0.0


# --- Movimento ---

func _atualizar_timers(delta: float) -> void:
	_timer_coyote -= delta
	_timer_buffer_pulo -= delta
	if _timer_pisca > 0.0:
		_timer_pisca -= delta
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
	velocity.x = move_toward(velocity.x, alvo, parametros.aceleracao_px() * delta)


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


func _tentar_iniciar_dash() -> void:
	if not entrada.dash_pressionado or cargas_dash <= 0 or esta_em_dash():
		return
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


func _aplicar_altura(altura: float) -> void:
	if is_equal_approx(altura, _altura_atual) and forma.position.y != 0.0:
		return
	_altura_atual = altura
	var retangulo := forma.shape as RectangleShape2D
	retangulo.size = Vector2(LARGURA, altura)
	forma.position = Vector2(0.0, -altura * 0.5)


# --- Tiro ---

func _atualizar_tiro(delta: float) -> void:
	_cooldown_tiro -= delta
	if arma == null or arma.cena_projetil == null or not _quer_atirar():
		_cooldown_tiro = maxf(_cooldown_tiro, 0.0)
		return
	if _cooldown_tiro > 0.0:
		return
	_disparar()
	_cooldown_tiro = maxf(_cooldown_tiro, -delta) + 1.0 / arma.cadencia


func _quer_atirar() -> bool:
	if entrada.atirar_segurado:
		return true
	if not assistencias.tiro_automatico:
		return false
	if arma.municao >= 0 and not assistencias.tiro_automatico_armas_pesadas:
		return false
	return mira_automatica.inimigo_na_direcao(ponto_de_tiro(), mira, assistencias, get_tree()) != null


func _disparar() -> void:
	var direcao: Vector2 = Vector2(mira).normalized()
	var origem: Vector2 = ponto_de_tiro() + direcao * 10.0
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	for i in arma.projeteis_por_tiro:
		var desvio: float = deg_to_rad(randf_range(-arma.espalhamento_graus, arma.espalhamento_graus))
		var projetil: Projetil = arma.cena_projetil.instantiate()
		destino.add_child(projetil)
		projetil.configurar(origem, direcao.rotated(desvio), Unidades.px(arma.velocidade_projetil),
				arma.dano, arma.duracao_projetil, Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS)
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
	if _morto:
		cor = Color("5c5c5c")
	draw_rect(Rect2(-LARGURA * 0.5, -h, LARGURA, h), cor)
	draw_rect(Rect2(olhando * 2.0 - 2.0, -h + 3.0, 4.0, 3.0), Color("2e3440"))  # visor
	var base: Vector2 = Vector2(0.0, -h * 0.6)
	draw_line(base, base + Vector2(mira).normalized() * 10.0, Color("eceff4"), 2.0)
