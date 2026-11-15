class_name Inimigo
extends CharacterBody2D
## Base de todos os inimigos (GD-02, seção 4).
## Cuida de: vida, peso (para o Grilhão), armadura frontal, Abalo, Ácido, atordoamento,
## puxão, empurrão, dano de contato, escolha de alvo e fichas de ataque.
## Cada inimigo concreto estende esta classe e implementa _comportamento().

signal morreu(inimigo: Inimigo)
## Últimos instantes antes de um golpe anunciado (pedido de ART: flash na cor AVISO).
signal aviso_final(inimigo: Inimigo)

## Cor reservada para ataques anunciados (D-033). Nada mais no jogo usa esta cor.
const COR_AVISO: Color = Color("fff3a0")
## Duração do flash final do aviso (ART-01, seção 4).
const DURACAO_AVISO_FINAL: float = 0.2

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
## Redução do dano pela frente com armadura (−1 = a das regras, 50%; a Muralha usa 1,0 = 100%).
@export var reducao_frontal: float = -1.0
## Atordoamento quando o Grilhão acerta (−1 = o cambaleio padrão; a Ceifadora usa 1,0 s).
@export var atordoamento_grilhao: float = -1.0
## Voa: sem gravidade (Zangão).
@export var voa: bool = false
## Créditos que dá ao morrer (GD-02 §6.5: 2 a 5 por comum, 25 por elite).
@export var creditos: Vector2i = Vector2i(2, 5)
## Chance de soltar os Créditos (o enxame tem 10%, GD-08 §4).
@export var chance_creditos: float = 1.0

@export_group("Pulo e perseguição (D-071)")
## Altura que o inimigo vence pulando (tiles). 0 = não pula.
@export var pulo_tiles: float = 2.0
## Sobe em plataformas atrás do jogador (o enxame); os pesados ficam embaixo, rondando.
@export var sobe_plataformas: bool = false
## Buracos que pula (tiles); 0 = para na beira.
@export var vao_maximo_tiles: float = 0.0
## Sem progresso por este tempo (s): tenta pular; depois muda de rota (volta um pouco).
@export var tempo_preso_pular: float = 1.0
@export var tempo_preso_mudar_rota: float = 2.0
## Duração da volta ao mudar de rota (s).
@export var duracao_desvio: float = 1.2

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
var _timer_entrada: float = 0.0
## Armadura quebrada por um tempo (Bramido B2); volta quando o timer acaba.
var _timer_armadura_quebrada: float = 0.0
## D-071: anti-travamento.
var tempo_sem_progresso: float = 0.0
var _x_anterior: float = INF
var _timer_desvio: float = 0.0
var _direcao_desvio: float = 0.0
var _pulou_preso: bool = false
## Velocidade para a frente mantida no ar depois de um pulo de navegação.
var _impulso_x: float = 0.0


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
	_timer_entrada = Combate.regras.tempo_entrada_inimigo
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
		if not is_on_floor() and not voa:
			velocity.y += _gravidade() * delta
		if esta_entrando():
			_timer_entrada -= delta
		if esta_atordoado() or _timer_empurrao > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, Unidades.px(30.0) * delta)
		elif esta_entrando():
			velocity.x = 0.0
		else:
			_comportamento(delta)
			_navegar(delta)
		move_and_slide()
		if not esta_atordoado() and not esta_entrando():
			_causar_dano_contato()
	queue_redraw()


# --- Pulo e perseguição (D-071) ---

## Depois da IA de cada inimigo: pula obstáculos, degraus e buracos pequenos, sobe atrás do
## jogador (quem `sobe_plataformas`) e não fica preso (pula; depois volta um pouco e tenta de novo).
func _navegar(delta: float) -> void:
	if voa:
		return
	if _timer_desvio > 0.0:
		_timer_desvio -= delta
		velocity.x = _direcao_desvio * maxf(absf(velocity.x), Unidades.px(2.0))
		olhando = int(_direcao_desvio)
	if _impulso_x != 0.0:
		if is_on_floor() and velocity.y >= 0.0:
			_impulso_x = 0.0
		else:
			velocity.x = _impulso_x  # no ar, o pulo leva para a frente (a IA de chão zera o x)
	var quer_andar: bool = absf(velocity.x) > 1.0
	_medir_progresso(delta, quer_andar)
	if pulo_tiles <= 0.0 or not is_on_floor():
		return
	var sentido: float = signf(velocity.x)
	if quer_andar and is_on_wall() and signf(get_wall_normal().x) == -sentido:
		var altura: float = altura_do_obstaculo(sentido)
		if altura <= Unidades.px(pulo_tiles):
			pular(altura + 6.0)
			return
	if quer_andar and vao_maximo_tiles > 0.0 and not _chao_logo_a_frente(sentido):
		pular(Unidades.px(minf(pulo_tiles, 1.5)), true)
		return
	if sobe_plataformas:
		var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(12.0), Unidades.px(10.0)))
		if alvo != null:
			var subida: float = global_position.y - alvo.global_position.y
			if subida > Unidades.px(1.0) and subida <= Unidades.px(pulo_tiles) \
					and absf(alvo.global_position.x - global_position.x) <= Unidades.px(4.0):
				pular(subida + 10.0)
				return
	if tempo_sem_progresso >= tempo_preso_pular and not _pulou_preso:
		_pulou_preso = true
		pular(Unidades.px(pulo_tiles))


func pular(altura_px: float, avancar: bool = false) -> void:
	velocity.y = -sqrt(2.0 * _gravidade() * maxf(altura_px, 4.0))
	var sentido: float = signf(velocity.x if velocity.x != 0.0 else float(olhando))
	var rapidez: float = maxf(absf(velocity.x), Unidades.px(3.0 if avancar else 2.0))
	_impulso_x = sentido * rapidez
	velocity.x = _impulso_x


func _medir_progresso(delta: float, quer_andar: bool) -> void:
	if not quer_andar or absf(global_position.x - _x_anterior) > Unidades.px(1.0) * delta:
		tempo_sem_progresso = 0.0
		_pulou_preso = false
	else:
		tempo_sem_progresso += delta
		if tempo_sem_progresso >= tempo_preso_mudar_rota and _timer_desvio <= 0.0:
			# Muda de rota: volta um pouco e tenta de novo.
			_timer_desvio = duracao_desvio
			_direcao_desvio = -signf(velocity.x) if velocity.x != 0.0 else float(-olhando)
			tempo_sem_progresso = 0.0
			_pulou_preso = false
			_ao_ficar_preso()
	_x_anterior = global_position.x


## Ficou preso de verdade (pulou e não saiu do lugar). O enxame fora da tela volta ao pool.
func _ao_ficar_preso() -> void:
	pass


func esta_na_tela() -> bool:
	var p: Vector2 = get_global_transform_with_canvas().origin
	return get_viewport_rect().grow(16.0).has_point(p)


## Altura (px) do obstáculo logo à frente, medindo de cima para baixo.
func altura_do_obstaculo(sentido: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var x: float = global_position.x + sentido * (tamanho.x * 0.5 + 4.0)
	var topo: float = global_position.y - Unidades.px(pulo_tiles) - 8.0
	# O começo do raio dentro da parede: ela é mais alta que o pulo.
	var ponto := PhysicsPointQueryParameters2D.new()
	ponto.position = Vector2(x, topo)
	ponto.collision_mask = Camadas.MUNDO
	if not espaco.intersect_point(ponto, 1).is_empty():
		return INF
	var consulta := PhysicsRayQueryParameters2D.create(Vector2(x, topo), Vector2(x, global_position.y - 1.0),
			Camadas.MUNDO, [get_rid()])
	var r: Dictionary = espaco.intersect_ray(consulta)
	if r.is_empty():
		return Unidades.px(pulo_tiles)  # parede baixa (cabe no pulo)
	return global_position.y - (r["position"] as Vector2).y


func _chao_logo_a_frente(sentido: float) -> bool:
	var inicio: Vector2 = global_position + Vector2(sentido * (tamanho.x * 0.5 + 2.0), -2.0)
	var consulta := PhysicsRayQueryParameters2D.create(inicio, inicio + Vector2(0, 40),
			Camadas.MUNDO | Camadas.PLATAFORMAS, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


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


## Animação de entrada (D-036): não ataca nem machuca por contato.
func esta_entrando() -> bool:
	return _timer_entrada > 0.0


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
		var base_reducao: float = reducao_frontal if reducao_frontal >= 0.0 else r.reducao_armadura_frontal
		if base_reducao >= 1.0 and acidos == 0:
			return false  # escudo-torre (Muralha): bloqueia tudo pela frente
		var reducao: float = base_reducao * maxf(0.0, 1.0 - r.acido_reducao_armadura * acidos)
		mult *= 1.0 - reducao
	var autor: Node = info.autor if info.autor != null and is_instance_valid(info.autor) else null
	if esta_atordoado() and _atordoado_por_abalo:
		var bonus: float = r.bonus_dano_atordoado
		if autor != null and autor.has_method("bonus_atordoado_extra"):
			bonus += autor.bonus_atordoado_extra()  # Inabalável soma ao bônus base
		mult *= 1.0 + bonus
	if autor != null and autor.has_method("mult_dano_contra"):
		mult *= autor.mult_dano_contra(self)  # Passivos do jogador (Honra, Carne Mole...)
	var dano: int = roundi(info.valor * mult)
	if info.valor > 0:
		dano = maxi(dano, 1)
	if not vida.receber_dano(dano):
		return false
	_timer_flash = 0.08
	if info.autor != null and is_instance_valid(info.autor):
		set_meta("ultimo_golpe_de", info.autor)
	_timer_sem_golpe = 0.0
	if info.autor != null and is_instance_valid(info.autor) and info.autor.has_method("registrar_dano_causado"):
		info.autor.registrar_dano_causado(dano)
	if not vida.esta_vivo():
		return true
	# fator_efeito (GD-05 §2.3): o Bramido divide os efeitos "ao acertar" entre os balins.
	if info.abalo > 0.0:
		adicionar_abalo(info.abalo * info.fator_efeito)
	if info.acidos > 0 and randf() < info.fator_efeito:
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


## Coice do Bramido: desloca na hora `deslocamento` px (leves e médios; pesados não se mexem).
func deslocar(deslocamento: Vector2) -> void:
	if peso == Peso.PESADO or deslocamento == Vector2.ZERO:
		return
	move_and_collide(deslocamento)


## Abre-Couraça (Bramido B2): a armadura frontal some por `segundos` e depois volta.
func quebrar_armadura(segundos: float) -> void:
	if not armadura_frontal and _timer_armadura_quebrada <= 0.0:
		return  # não tinha armadura (ou o Grilhão já arrancou)
	armadura_frontal = false
	_timer_armadura_quebrada = maxf(_timer_armadura_quebrada, segundos)


func armadura_quebrada() -> bool:
	return _timer_armadura_quebrada > 0.0


## Grilhão em alvo Médio com proteção: arranca a armadura (GD-02, 1.1).
func arrancar_protecao() -> bool:
	if not armadura_frontal and _timer_armadura_quebrada <= 0.0:
		return false
	armadura_frontal = false
	_timer_armadura_quebrada = 0.0  # arrancada de vez
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
	# D-071: desce degraus de até ~2 tiles (o chão logo abaixo também conta); buraco não.
	var consulta := PhysicsRayQueryParameters2D.create(inicio, inicio + Vector2(0, 36),
			Camadas.MUNDO | Camadas.PLATAFORMAS, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


# --- Interno ---

func _atualizar_status(delta: float) -> void:
	var r: RegrasCombate = Combate.regras
	_timer_flash = maxf(_timer_flash - delta, 0.0)
	_timer_empurrao = maxf(_timer_empurrao - delta, 0.0)
	if _timer_armadura_quebrada > 0.0:
		_timer_armadura_quebrada -= delta
		if _timer_armadura_quebrada <= 0.0:
			armadura_frontal = true
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
	if dano_contato <= 0 or _contato == null or not _contato.monitoring:
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
	_criar_efeito_morte()
	morreu.emit(self)
	queue_free()


## Flash do aviso (D-043): brasa durante o aviso e a cor AVISO só nos últimos 0,2 s.
const COR_BRASA: Color = Color("ff5a2e")


static func cor_do_aviso(restante: float) -> Color:
	return COR_AVISO if restante <= DURACAO_AVISO_FINAL else COR_BRASA


## Máscara dos ataques deste inimigo: jogadores e, na zona de guerra, a facção rival.
func mascara_ataque() -> int:
	return Camadas.MUNDO | Camadas.JOGADOR | (Camadas.INIMIGOS if ataca_faccao_rival else 0)


## Acerta um alvo de ataque (jogador, ou inimigo da facção rival na zona de guerra).
func pode_ferir(alvo: Node) -> bool:
	if alvo is Jogador:
		return true
	var outro := alvo as Inimigo
	return ataca_faccao_rival and outro != null and outro != self and outro.faccao != faccao and outro.esta_vivo()


## Subclasses com sprite criam aqui a animação de morte (ela continua depois que o inimigo some).
func _criar_efeito_morte() -> void:
	pass


# --- Desenho provisório (status visíveis, pedido de GD a ART) ---

func _desenhar_status() -> void:
	# Entrada: o corpo pisca meio transparente (o sprite de ART substitui isso).
	modulate.a = 0.4 + 0.3 * float(int(_timer_entrada * 20.0) % 2) if esta_entrando() else 1.0
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
