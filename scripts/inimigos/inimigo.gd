class_name Inimigo
extends CharacterBody2D
## Base de todos os inimigos (GD-02, seção 4).
## Cuida de: vida, peso (para o Grilhão), armadura frontal, Abalo, Ácido, atordoamento,
## puxão, empurrão, dano de contato, escolha de alvo e fichas de ataque.
## Cada inimigo concreto estende esta classe e implementa _comportamento().

signal morreu(inimigo: Inimigo)

## Como o Grilhão reage a este inimigo (GD-02, 1.1).
enum Peso { LEVE, MEDIO, PESADO }
## Decide a duração do atordoamento por Abalo.
enum Categoria { COMUM, ELITE, CHEFE }

@export var peso: Peso = Peso.MEDIO
@export var categoria: Categoria = Categoria.COMUM
@export var faccao: StringName = &"kharn"
## Reduz o dano que vem pela frente (não reduz explosão, corpo a corpo nem dano pelas costas).
@export var armadura_frontal: bool = false
## Tamanho do corpo em px (hitbox e desenho provisório).
@export var tamanho: Vector2 = Vector2(32, 64)
## Blocos de vida tirados ao encostar no jogador (0 = não machuca).
@export var dano_contato: int = 1
## Sala 5 (zona de guerra): também ataca a facção rival (GD-02, 4.4).
@export var ataca_faccao_rival: bool = false

@onready var vida: Vida = $Vida
@onready var forma: CollisionShape2D = $Forma

var olhando: int = -1
var container_projeteis: Node
var abalo: float = 0.0
var acidos: int = 0

var _timer_acido: float = 0.0
var _relogio_acido: float = 0.0
var _autor_acido: Node
var _timer_atordoado: float = 0.0
var _atordoado_por_abalo: bool = false
var _timer_sem_golpe: float = 999.0
var _timer_empurrao: float = 0.0
var _timer_flash: float = 0.0
var _puxado_por: Node2D
var _velocidade_puxao: float = 0.0
var _contato: Area2D


func _ready() -> void:
	add_to_group("inimigos")
	collision_layer = Camadas.INIMIGOS
	collision_mask = Camadas.MUNDO | Camadas.PLATAFORMAS
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	forma.shape = retangulo
	forma.position = Vector2(0.0, -tamanho.y * 0.5)
	_criar_area_contato()
	vida.morreu.connect(_ao_morrer)
	tree_exiting.connect(func() -> void: Combate.devolver_ficha(self))


func _physics_process(delta: float) -> void:
	_atualizar_status(delta)
	if _puxado_por != null:
		if is_instance_valid(_puxado_por):
			velocity = (_puxado_por.global_position - global_position).normalized() * _velocidade_puxao
		else:
			terminar_puxao()
		move_and_slide()
	else:
		if not is_on_floor():
			velocity.y += _gravidade() * delta
		if esta_atordoado() or _timer_empurrao > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, Unidades.px(30.0) * delta)
		else:
			_comportamento(delta)
		move_and_slide()
		if not esta_atordoado():
			_causar_dano_contato()
	queue_redraw()


# --- Para as subclasses ---

## IA do inimigo. Só é chamada quando ele não está atordoado, puxado nem empurrado.
func _comportamento(_delta: float) -> void:
	pass


## O inimigo perdeu o controle (atordoado, puxado): cancela o ataque em andamento.
func _cancelar_ataque() -> void:
	Combate.devolver_ficha(self)


## true enquanto o aviso de um ataque está na tela.
func esta_anunciando() -> bool:
	return false


# --- Consultas ---

func centro() -> Vector2:
	return global_position + Vector2(0.0, -tamanho.y * 0.5)


func esta_atordoado() -> bool:
	return _timer_atordoado > 0.0


func esta_sendo_puxado() -> bool:
	return _puxado_por != null


func esta_vivo() -> bool:
	return vida.esta_vivo() and not is_queued_for_deletion()


# --- Receber golpes ---

func receber_ataque(info: InfoDano) -> bool:
	if not esta_vivo():
		return false
	var r: RegrasCombate = Combate.regras
	var mult: float = info.multiplicador
	if armadura_frontal and not info.explosao and not info.corpo_a_corpo and _veio_pela_frente(info.direcao):
		var reducao: float = r.reducao_armadura_frontal * maxf(0.0, 1.0 - r.acido_reducao_armadura * acidos)
		mult *= 1.0 - reducao
	if esta_atordoado() and _atordoado_por_abalo:
		mult *= 1.0 + r.bonus_dano_atordoado
	var dano: int = roundi(info.valor * mult)
	if info.valor > 0:
		dano = maxi(dano, 1)
	if not vida.receber_dano(dano):
		return false
	_timer_flash = 0.08
	_timer_sem_golpe = 0.0
	if info.autor != null and is_instance_valid(info.autor) and info.autor.has_method("registrar_dano_causado"):
		info.autor.registrar_dano_causado(dano)
	if not vida.esta_vivo():
		return true
	if info.abalo > 0.0:
		adicionar_abalo(info.abalo)
	if info.acidos > 0:
		adicionar_acido(info.acidos, info.autor)
	if info.empurrao != Vector2.ZERO:
		empurrar(info.empurrao)
	return true


## Atalho para golpes simples (sem armadura, status nem autor).
func receber_dano(quantidade: int, _origem: Node = null) -> bool:
	return receber_ataque(InfoDano.criar(quantidade))


func adicionar_abalo(pontos: float) -> void:
	var r: RegrasCombate = Combate.regras
	abalo += pontos
	_timer_sem_golpe = 0.0
	if abalo >= r.abalo_limite:
		abalo = 0.0
		var duracao: float = r.atordoamento_abalo_comum
		match categoria:
			Categoria.ELITE:
				duracao = r.atordoamento_abalo_elite
			Categoria.CHEFE:
				duracao = r.atordoamento_abalo_chefe
		atordoar(duracao)
		_atordoado_por_abalo = true


func adicionar_acido(acumulos: int, autor: Node = null) -> void:
	var r: RegrasCombate = Combate.regras
	acidos = mini(acidos + acumulos, r.acido_maximo)
	_timer_acido = r.acido_duracao
	if autor != null:
		_autor_acido = autor


func atordoar(segundos: float) -> void:
	if segundos <= 0.0:
		return
	if not esta_atordoado():
		_cancelar_ataque()
	_timer_atordoado = maxf(_timer_atordoado, segundos)
	_atordoado_por_abalo = false


## Inimigos pesados não são empurrados.
func empurrar(impulso: Vector2) -> void:
	if peso == Peso.PESADO:
		return
	velocity += impulso
	_timer_empurrao = 0.2


## Grilhão em alvo Médio com proteção: arranca a armadura (GD-02, 1.1).
func arrancar_protecao() -> bool:
	if not armadura_frontal:
		return false
	armadura_frontal = false
	return true


func receber_puxao(puxador: Node2D, velocidade_px: float) -> void:
	_cancelar_ataque()
	_puxado_por = puxador
	_velocidade_puxao = velocidade_px


func terminar_puxao() -> void:
	_puxado_por = null
	velocity = Vector2.ZERO


# --- Alvos ---

## Escolhe o alvo mais próximo da lista: jogadores e, na zona de guerra, a facção rival.
## Jogadores contam com peso 2 (a distância é dividida por 2), para continuarem sendo o alvo principal.
func escolher_alvo(alcance_px: Vector2) -> Node2D:
	var melhor: Node2D = null
	var melhor_nota: float = INF
	for no in get_tree().get_nodes_in_group("jogadores"):
		var jogador := no as Jogador
		if jogador == null or jogador.esta_morto():
			continue
		var nota: float = _nota_alvo(jogador.global_position, alcance_px) * 0.5
		if nota < melhor_nota:
			melhor_nota = nota
			melhor = jogador
	if ataca_faccao_rival:
		for no in get_tree().get_nodes_in_group("inimigos"):
			var outro := no as Inimigo
			if outro == null or outro == self or outro.faccao == faccao or not outro.esta_vivo():
				continue
			var nota: float = _nota_alvo(outro.global_position, alcance_px)
			if nota < melhor_nota:
				melhor_nota = nota
				melhor = outro
	return melhor


func _nota_alvo(posicao: Vector2, alcance_px: Vector2) -> float:
	var d: Vector2 = posicao - global_position
	if absf(d.x) > alcance_px.x or absf(d.y) > alcance_px.y:
		return INF
	return d.length()


func olhar_para(alvo: Node2D) -> void:
	if alvo != null and not is_equal_approx(alvo.global_position.x, global_position.x):
		olhando = 1 if alvo.global_position.x > global_position.x else -1


## true se existe chão logo à frente (para não cair de plataformas).
func ha_chao_a_frente() -> bool:
	var inicio: Vector2 = global_position + Vector2(olhando * (tamanho.x * 0.5 + 2.0), -2.0)
	var consulta := PhysicsRayQueryParameters2D.create(inicio, inicio + Vector2(0, 12),
			Camadas.MUNDO | Camadas.PLATAFORMAS, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


# --- Interno ---

func _atualizar_status(delta: float) -> void:
	var r: RegrasCombate = Combate.regras
	_timer_flash = maxf(_timer_flash - delta, 0.0)
	_timer_empurrao = maxf(_timer_empurrao - delta, 0.0)
	if _timer_atordoado > 0.0:
		_timer_atordoado -= delta
		if _timer_atordoado <= 0.0:
			_atordoado_por_abalo = false
	_timer_sem_golpe += delta
	if abalo > 0.0 and _timer_sem_golpe > r.abalo_atraso_queda:
		abalo = maxf(abalo - r.abalo_queda_por_segundo * delta, 0.0)
	if acidos > 0:
		_timer_acido -= delta
		_relogio_acido += delta
		if _relogio_acido >= 1.0:
			_relogio_acido -= 1.0
			var dano: int = roundi(r.acido_dano_por_segundo * acidos)
			if vida.receber_dano(dano) and _autor_acido != null and is_instance_valid(_autor_acido) \
					and _autor_acido.has_method("registrar_dano_causado"):
				_autor_acido.registrar_dano_causado(dano)
		if _timer_acido <= 0.0:
			acidos = 0
			_relogio_acido = 0.0


func _veio_pela_frente(direcao: Vector2) -> bool:
	# O golpe vem pela frente quando viaja em direção à "cara" do inimigo.
	return direcao.x * olhando < 0.0


func _causar_dano_contato() -> void:
	if dano_contato <= 0 or _contato == null:
		return
	for corpo in _contato.get_overlapping_bodies():
		if corpo.has_method("receber_ataque"):
			corpo.receber_ataque(InfoDano.criar(dano_contato, self, Vector2(signf(corpo.global_position.x - global_position.x), 0)))


func _criar_area_contato() -> void:
	_contato = Area2D.new()
	_contato.name = "Contato"
	_contato.collision_layer = 0
	_contato.collision_mask = Camadas.JOGADOR
	_contato.monitorable = false
	var f := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = tamanho
	f.shape = r
	f.position = Vector2(0.0, -tamanho.y * 0.5)
	_contato.add_child(f)
	add_child(_contato)


func _gravidade() -> float:
	return ProjectSettings.get_setting("physics/2d/default_gravity") as float


func _ao_morrer() -> void:
	Combate.devolver_ficha(self)
	morreu.emit(self)
	queue_free()


# --- Desenho provisório (status visíveis, pedido de GD a ART) ---

func _desenhar_status() -> void:
	var topo: float = -tamanho.y
	if esta_atordoado():
		var t: float = Time.get_ticks_msec() / 150.0
		for i in 3:
			var angulo: float = t + i * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(angulo) * 8.0 - 1.0, topo - 6.0 + sin(angulo) * 2.0), Vector2(2, 2)), Color("ebcb8b"))
	if abalo > 0.0:
		var largura: float = tamanho.x * clampf(abalo / Combate.regras.abalo_limite, 0.0, 1.0)
		draw_rect(Rect2(Vector2(-tamanho.x * 0.5, topo - 3.0), Vector2(largura, 2.0)), Color("ffa94d"))
	for i in acidos:
		draw_rect(Rect2(Vector2(-tamanho.x * 0.5 + i * 4.0, 2.0), Vector2(3, 3)), Color("8ce99a"))
