class_name UrKesh
extends Inimigo
## Chefe do Ato 1 — Ur-Kesh, Campeão do Clã Kesh (GD-02 §5). Três fases num só nó:
## 1. Andador de guerra (vida 1500, Pesado): varredura do Bramido (laser 0,8 s), salto com
##    pisão [PESADO] (sombra 1,0 s + onda de choque), saraivada de mísseis (5 alvos, 1,2 s).
##    Ponto fraco: o radiador nas costas.
## 2. Andador danificado (a partir de 66%): ataques 15% mais rápidos (os avisos NÃO diminuem);
##    a cada 12 s ajoelha por 3 s e expõe o núcleo (dano ×3); uma nave deixa 2 Guerreiros.
## 3. A pé (vida 600, Médio): avanço com machado [PESADO] (ergue 0,7 s), machado bumerangue
##    (gira 0,8 s), rugido do clã (bate no peito 1,0 s, chama 4 Zangões).
##    Contra-ataque: o Grilhão enquanto ele ergue o machado quebra a guarda (2,0 s atordoado,
##    dano dobrado).
## As falas são as do NAR-01 (urkesh_*, ryker_*, contra_ataque).

signal fase_mudou(fase: int)
signal derrotado(chefe: UrKesh)

enum Estado {
	ESCOLHER, DESCANSO,
	AVISO_VARREDURA, VARREDURA, SALTO, AVISO_MISSEIS, AJOELHADO,
	AVISO_AVANCO, AVANCO, AVISO_ARREMESSO, AVISO_RUGIDO,
}

@export_group("Fase 1 e 2: andador")
@export var vida_andador: int = 1500
@export var tamanho_andador: Vector2 = Vector2(80, 112)
@export var velocidade_andador: float = 0.75
@export var tempo_aviso_varredura: float = 0.8
@export var tiros_varredura: int = 8
@export var intervalo_varredura: float = 0.1
@export var altura_varredura: float = 22.0
@export var tempo_salto: float = 1.0
@export var dano_pisao: int = 2
@export var tempo_aviso_misseis: float = 1.2
@export var espaco_misseis: float = 64.0
@export var descanso_andador: float = 1.6
## Fase 2 a partir desta fração da vida do andador.
@export var limite_fase_2: float = 0.66
## Fase 2: ataques mais rápidos (o descanso e os intervalos encolhem; os avisos não).
@export var acelerar_fase_2: float = 0.85
@export var intervalo_ajoelhar: float = 12.0
@export var tempo_ajoelhado: float = 3.0
@export var intervalo_reforcos: float = 20.0
@export_group("Fase 3: a pé")
@export var vida_a_pe: int = 600
@export var tamanho_a_pe: Vector2 = Vector2(32, 70)
@export var velocidade_a_pe: float = 2.5
@export var tempo_aviso_avanco: float = 0.7
@export var distancia_avanco: float = 160.0
@export var velocidade_avanco: float = 360.0
@export var tempo_aviso_arremesso: float = 0.8
@export var tempo_aviso_rugido: float = 1.0
@export var zangoes_rugido: int = 4
@export var guarda_quebrada: float = 2.0
@export_group("Cenas")
@export var cena_projetil: PackedScene
@export var cena_guerreiro: PackedScene
@export var cena_zangao: PackedScene

var fase: int = 1
var estado: Estado = Estado.DESCANSO
var radiador: PontoFraco
var nucleo: PontoFraco
var alvo_salto: Vector2 = Vector2.ZERO
var alvos_misseis: Array[Vector2] = []
var reforcos: Array[Inimigo] = []
var _timer: float = 1.0
var _tiros: int = 0
var _timer_ajoelhar: float = 0.0
var _timer_reforcos: float = 0.0
var _timer_guarda: float = 0.0
var _timer_bark: float = 8.0
var _salto_origem: Vector2 = Vector2.ZERO
var _salto_t: float = 0.0
var _percorrido: float = 0.0
var _direcao: float = 1.0
var _atingidos: Array[Node] = []
var _ataque: int = 0
var _pouca_vida_falada: bool = false
var _ponto_fraco_falado: bool = false
var _rugido_cooldown: float = 0.0


func _ready() -> void:
	tamanho = tamanho_andador
	super()
	vida.reiniciar(vida_andador)
	radiador = _ponto_fraco("Radiador", Vector2(14, 20), 2.0)
	nucleo = _ponto_fraco("Nucleo", Vector2(18, 18), 3.0)
	_ativar_nucleo(false)
	_posicionar_pontos()
	vida.mudou.connect(_ao_mudar_vida)


func _ponto_fraco(nome: String, tam: Vector2, mult: float) -> PontoFraco:
	var p := PontoFraco.new()
	p.name = nome
	p.tamanho = tam
	p.multiplicador = mult
	add_child(p)
	return p


func _ativar_nucleo(sim: bool) -> void:
	nucleo.visible = sim
	nucleo.collision_layer = Camadas.PONTOS_FRACOS if sim else 0


func _posicionar_pontos() -> void:
	if fase < 3:
		radiador.position = Vector2(-olhando * (tamanho.x * 0.5 - 6.0), -tamanho.y * 0.62)
		nucleo.position = Vector2(olhando * 6.0, -tamanho.y * 0.35)


func esta_ajoelhado() -> bool:
	return estado == Estado.AJOELHADO


func andador() -> bool:
	return fase < 3


func fator_velocidade() -> float:
	return acelerar_fase_2 if fase == 2 else 1.0


# --- Vida e fases ---

func _ao_mudar_vida(atual: int, maxima: int) -> void:
	if fase == 1 and atual > 0 and atual <= roundi(maxima * limite_fase_2):
		_entrar_fase_2()
	if fase == 3 and not _pouca_vida_falada and atual > 0 and atual <= roundi(maxima * 0.2):
		_pouca_vida_falada = true
		Dialogos.tocar("urkesh_pouca_vida")


func _entrar_fase_2() -> void:
	fase = 2
	_timer_ajoelhar = intervalo_ajoelhar
	_timer_reforcos = 0.0
	fase_mudou.emit(2)
	Dialogos.tocar("urkesh_fase2")


## O andador cai: Ur-Kesh sai da cabine (fase 3). Na fase 3, aí sim morre.
func _ao_morrer() -> void:
	if fase < 3:
		_entrar_fase_3()
		return
	derrotado.emit(self)
	super()


func _entrar_fase_3() -> void:
	_cancelar_ataque()
	fase = 3
	_ativar_nucleo(false)
	radiador.queue_free()
	peso = Peso.MEDIO
	armadura_frontal = false
	tamanho = tamanho_a_pe
	var r := RectangleShape2D.new()
	r.size = tamanho
	forma.shape = r
	forma.position = Vector2(0, -tamanho.y * 0.5)
	if _contato != null:
		var c := _contato.get_child(0) as CollisionShape2D
		c.shape = r
		c.position = forma.position
	vida.reiniciar(vida_a_pe)
	estado = Estado.DESCANSO
	_timer = 1.0
	fase_mudou.emit(3)
	Dialogos.tocar("urkesh_fase3")


# --- Golpes recebidos ---

func receber_ataque(info: InfoDano) -> bool:
	var golpe: InfoDano = info
	if _timer_guarda > 0.0:
		golpe = info.copiar()
		golpe.multiplicador *= 2.0  # guarda quebrada: dano dobrado
	var acertou: bool = super(golpe)
	if acertou and info.ponto_fraco and not _ponto_fraco_falado:
		_ponto_fraco_falado = true
		Dialogos.tocar("ryker_bark_ponto_fraco")
	return acertou


## O Grilhão em Ur-Kesh a pé (Médio): se ele está erguendo o machado, a guarda quebra.
func arrancar_protecao() -> bool:
	if fase == 3 and estado == Estado.AVISO_AVANCO:
		_cancelar_ataque()
		_timer_guarda = guarda_quebrada
		atordoar(guarda_quebrada)
		Dialogos.tocar("contra_ataque")
		return true
	return false


func guarda_quebrada_ativa() -> bool:
	return _timer_guarda > 0.0


func esta_anunciando() -> bool:
	return estado in [Estado.AVISO_VARREDURA, Estado.VARREDURA, Estado.SALTO, Estado.AVISO_MISSEIS,
			Estado.AVISO_AVANCO, Estado.AVANCO, Estado.AVISO_ARREMESSO, Estado.AVISO_RUGIDO] and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.SALTO:
		global_position = Vector2(global_position.x, _salto_origem.y)
	if estado != Estado.AJOELHADO:
		estado = Estado.DESCANSO
		_timer = 1.0


# --- IA ---

func _physics_process(delta: float) -> void:
	_timer_guarda = maxf(_timer_guarda - delta, 0.0)
	_rugido_cooldown -= delta
	if estado == Estado.SALTO and not esta_atordoado():
		_processar_salto(delta)
		queue_redraw()
		return
	super(delta)


func _comportamento(delta: float) -> void:
	_timer -= delta
	_timer_bark -= delta
	if _timer_bark <= 0.0:
		_timer_bark = randf_range(10.0, 16.0)
		Dialogos.tocar("urkesh_barks" if randf() < 0.6 else "ryker_barks")
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(40.0), Unidades.px(17.0)))
	if fase == 2:
		_processar_fase_2(delta)
		if estado == Estado.AJOELHADO:
			velocity.x = 0.0
			if _timer <= 0.0:
				_ativar_nucleo(false)
				estado = Estado.DESCANSO
				_timer = 0.6
			return
	_posicionar_pontos()
	match estado:
		Estado.DESCANSO:
			_andar(alvo)
			if _timer <= 0.0:
				estado = Estado.ESCOLHER
		Estado.ESCOLHER:
			_andar(alvo)
			if alvo != null and is_on_floor() and Combate.pedir_ficha(self):
				olhar_para(alvo)
				_comecar_ataque(alvo)
		Estado.AVISO_VARREDURA:
			velocity.x = 0.0
			_emitir_aviso_final(delta)
			if _timer <= 0.0:
				estado = Estado.VARREDURA
				_tiros = tiros_varredura
				_timer = 0.0
		Estado.VARREDURA:
			velocity.x = 0.0
			if _timer <= 0.0:
				_atirar_varredura()
				_tiros -= 1
				_timer = intervalo_varredura * fator_velocidade()
				if _tiros <= 0:
					_terminar_ataque()
		Estado.AVISO_MISSEIS:
			velocity.x = 0.0
			_emitir_aviso_final(delta)
			if _timer <= 0.0:
				_terminar_ataque()
		Estado.AVISO_AVANCO:
			velocity.x = 0.0
			_emitir_aviso_final(delta)
			if _timer <= 0.0:
				estado = Estado.AVANCO
				_percorrido = 0.0
				_atingidos.clear()
		Estado.AVANCO:
			velocity.x = _direcao * velocidade_avanco
			_percorrido += velocidade_avanco * delta
			_ferir_no_contato(2)
			if _percorrido >= distancia_avanco or is_on_wall() or not ha_chao_a_frente():
				velocity.x = 0.0
				_terminar_ataque()
		Estado.AVISO_ARREMESSO:
			velocity.x = 0.0
			_emitir_aviso_final(delta)
			if _timer <= 0.0:
				Dialogos.tocar("urkesh_machado")
				var pai: Node = container_projeteis if container_projeteis != null else get_parent()
				MachadoBumerangue.lancar(pai, centro(), float(olhando), self)
				_terminar_ataque()
		Estado.AVISO_RUGIDO:
			velocity.x = 0.0
			_emitir_aviso_final(delta)
			if _timer <= 0.0:
				chamar_zangoes()
				_terminar_ataque()


func _emitir_aviso_final(delta: float) -> void:
	if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
		aviso_final.emit(self)


func _andar(alvo: Node2D) -> void:
	velocity.x = 0.0
	if alvo == null:
		return
	olhar_para(alvo)
	var d: float = absf(alvo.global_position.x - global_position.x)
	var vel: float = velocidade_andador if andador() else velocidade_a_pe
	if d > Unidades.px(5.0) and is_on_floor() and ha_chao_a_frente():
		velocity.x = olhando * Unidades.px(vel)


## Escolhe o próximo ataque da fase, em rodízio.
func _comecar_ataque(alvo: Node2D) -> void:
	_ataque += 1
	_direcao = float(olhando)
	if andador():
		match _ataque % 3:
			0:
				estado = Estado.AVISO_VARREDURA
				_timer = tempo_aviso_varredura
			1:
				comecar_salto(alvo.global_position)
			2:
				comecar_misseis(alvo.global_position)
	else:
		var opcoes: Array[Estado] = [Estado.AVISO_AVANCO, Estado.AVISO_ARREMESSO]
		if _rugido_cooldown <= 0.0:
			opcoes.append(Estado.AVISO_RUGIDO)
		estado = opcoes[_ataque % opcoes.size()]
		match estado:
			Estado.AVISO_AVANCO:
				_timer = tempo_aviso_avanco
			Estado.AVISO_ARREMESSO:
				_timer = tempo_aviso_arremesso
			Estado.AVISO_RUGIDO:
				_timer = tempo_aviso_rugido
				_rugido_cooldown = 20.0
				Dialogos.tocar("urkesh_rugido")


func _terminar_ataque() -> void:
	Combate.devolver_ficha(self)
	estado = Estado.DESCANSO
	_timer = descanso_andador * fator_velocidade() if andador() else 1.2


# --- Fase 1 e 2 ---

## Salto com pisão: a sombra marca o pouso (1,0 s); ao cair, dano [PESADO] e ondas de choque.
func comecar_salto(destino: Vector2) -> void:
	estado = Estado.SALTO
	_salto_origem = global_position
	alvo_salto = Vector2(destino.x, global_position.y)
	_salto_t = 0.0
	_timer = tempo_salto


func _processar_salto(delta: float) -> void:
	_salto_t += delta
	_timer -= delta
	var u: float = clampf(_salto_t / tempo_salto, 0.0, 1.0)
	global_position = _salto_origem.lerp(alvo_salto, u) + Vector2(0, -4.0 * 90.0 * u * (1.0 - u))
	velocity = Vector2.ZERO
	if u >= 1.0:
		_pousar()


func _pousar() -> void:
	global_position = alvo_salto
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j != null and absf(j.global_position.x - alvo_salto.x) <= tamanho.x * 0.5 + 6.0 and j.global_position.y >= alvo_salto.y - 8.0:
			j.receber_ataque(InfoDano.criar(dano_pisao, self))
	var pai: Node = container_projeteis if container_projeteis != null else get_parent()
	for lado: float in [-1.0, 1.0]:
		OndaChoque.criar(pai, alvo_salto + Vector2(lado * tamanho.x * 0.5, 0), lado, self)
	_terminar_ataque()


## Saraivada: 5 alvos marcados no chão; os mísseis caem juntos depois de 1,2 s.
func comecar_misseis(centro_alvo: Vector2) -> void:
	estado = Estado.AVISO_MISSEIS
	_timer = tempo_aviso_misseis
	alvos_misseis.clear()
	var pai: Node = container_projeteis if container_projeteis != null else get_parent()
	for i in 5:
		var destino := Vector2(centro_alvo.x + (i - 2) * espaco_misseis, centro_alvo.y)
		alvos_misseis.append(destino)
		var m := ProjetilArco.lancar(pai, ProjetilArco.Tipo.MORTEIRO, self, centro() + Vector2(0, -tamanho.y * 0.4),
				destino, tempo_aviso_misseis, 110.0)
		m.raio = 16.0
		m.dano = 1


func _atirar_varredura() -> void:
	if cena_projetil == null:
		return
	var p: Projetil = cena_projetil.instantiate()
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	destino.add_child(p)
	p.faccao_autor = faccao
	p.configurar(global_position + Vector2(_direcao * (tamanho.x * 0.5 + 6.0), -altura_varredura), Vector2(_direcao, 0),
			Unidades.px(16.0), InfoDano.criar(1, self), 2.0, Camadas.PROJETEIS_INIMIGO, mascara_ataque())


func _processar_fase_2(delta: float) -> void:
	_timer_reforcos -= delta
	if _timer_reforcos <= 0.0:
		_timer_reforcos = intervalo_reforcos
		trazer_reforcos()
	if estado == Estado.AJOELHADO:
		return
	_timer_ajoelhar -= delta
	if _timer_ajoelhar <= 0.0 and estado in [Estado.DESCANSO, Estado.ESCOLHER]:
		ajoelhar()


## A cada 12 s o andador ajoelha por 3 s e expõe o núcleo (dano ×3).
func ajoelhar() -> void:
	_timer_ajoelhar = intervalo_ajoelhar
	Combate.devolver_ficha(self)
	estado = Estado.AJOELHADO
	_timer = tempo_ajoelhado
	_ativar_nucleo(true)
	_posicionar_pontos()
	Dialogos.tocar("urkesh_ajoelha")


## A nave Kharn deixa 2 Guerreiros (até haver 2 vivos). Param quando o andador cai.
func trazer_reforcos() -> int:
	var vivos: Array[Inimigo] = []
	for r in reforcos:
		if is_instance_valid(r) and r.esta_vivo():
			vivos.append(r)
	reforcos = vivos
	if cena_guerreiro == null or get_parent() == null or not andador():
		return 0
	var n: int = 0
	while reforcos.size() < 2:
		var g: Inimigo = cena_guerreiro.instantiate()
		g.position = global_position + Vector2((n * 2 - 1) * 120.0, -150.0)
		g.container_projeteis = container_projeteis
		g.creditos = Vector2i(2, 5)
		get_parent().add_child(g)
		reforcos.append(g)
		n += 1
	if n > 0:
		Dialogos.tocar("urkesh_reforcos")
	return n


# --- Fase 3 ---

func _ferir_no_contato(dano: int) -> void:
	if _contato == null:
		return
	for corpo in _contato.get_overlapping_bodies():
		if corpo is Jogador and not corpo in _atingidos:
			_atingidos.append(corpo)
			corpo.receber_ataque(InfoDano.criar(dano, self, Vector2(_direcao, 0)))


## Rugido do clã: 4 Zangões atraídos pelo barulho (não dão Créditos).
func chamar_zangoes() -> int:
	if cena_zangao == null or get_parent() == null:
		return 0
	for i in zangoes_rugido:
		var z: Inimigo = cena_zangao.instantiate()
		z.position = global_position + Vector2((i - 1.5) * 40.0, -120.0)
		z.container_projeteis = container_projeteis
		z.creditos = Vector2i.ZERO
		get_parent().add_child(z)
	Dialogos.tocar.call_deferred("ryker_rugido_zangoes")
	return zangoes_rugido


# --- Desenho provisório ---

func _draw() -> void:
	if andador():
		_desenhar_andador()
	else:
		_desenhar_a_pe()
	if _timer_flash > 0.0:
		draw_rect(Rect2(-tamanho.x * 0.5, -tamanho.y, tamanho.x, tamanho.y), Color(1, 1, 1, 0.35))
	_desenhar_status()


func _desenhar_andador() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	var baixa: float = 24.0 if estado == Estado.AJOELHADO else 0.0
	var dano_visual: bool = fase == 2
	# Pernas e corpo do andador
	draw_rect(Rect2(-w * 0.5 + 6, -40 + baixa * 0.5, 16, 40 - baixa * 0.5), Color("4b4753"))
	draw_rect(Rect2(w * 0.5 - 22, -40 + baixa * 0.5, 16, 40 - baixa * 0.5), Color("4b4753"))
	draw_rect(Rect2(-w * 0.5, -h + baixa, w, h - 40), Color("5e6370"))
	draw_rect(Rect2(-w * 0.5 + 4, -h + 4 + baixa, w - 8, 10), Color("9c3527"))
	# Cabine com Ur-Kesh
	draw_rect(Rect2(-12, -h - 10 + baixa, 24, 16), Color("56604a"))
	draw_rect(Rect2(-6 + olhando * 3, -h - 16 + baixa, 12, 8), Color("7c8a6c"))
	# Bramido no braço
	var cor_arma: Color = Color("4b4753")
	if estado == Estado.AVISO_VARREDURA:
		cor_arma = Inimigo.cor_do_aviso(_timer)
		var y: float = -altura_varredura
		draw_line(Vector2(olhando * w * 0.5, y), Vector2(olhando * 520.0, y), Color(cor_arma, 0.85), 1.0)
	draw_rect(Rect2(olhando * (w * 0.5) - (24 if olhando > 0 else 0), -altura_varredura - 4, 24, 8), cor_arma)
	# Radiador nas costas
	draw_rect(Rect2(-olhando * (w * 0.5 - 6) - 7, -h * 0.62 - 10 + baixa, 14, 20), Color("ff5a2e"))
	if dano_visual:
		draw_line(Vector2(-w * 0.3, -h * 0.7 + baixa), Vector2(-w * 0.1, -h * 0.5 + baixa), Color("16111c"), 2.0)
		draw_line(Vector2(w * 0.2, -h * 0.8 + baixa), Vector2(w * 0.3, -h * 0.55 + baixa), Color("16111c"), 2.0)
	# Sombra do pouso (aviso do salto) e marca dos mísseis
	if estado == Estado.SALTO:
		var s: Vector2 = alvo_salto - global_position
		draw_rect(Rect2(s.x - w * 0.5, s.y - 3, w, 3), Inimigo.cor_do_aviso(_timer))
	if estado == Estado.AVISO_MISSEIS:
		draw_rect(Rect2(-8, -h - 22, 16, 6), Inimigo.cor_do_aviso(_timer))


func _desenhar_a_pe() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	draw_rect(Rect2(-w * 0.5 + 2, -h + 14, w - 4, h - 26), Color("56604a"))
	draw_rect(Rect2(-w * 0.5 + 4, -12, 10, 12), Color("363d30"))
	draw_rect(Rect2(w * 0.5 - 14, -12, 10, 12), Color("363d30"))
	draw_rect(Rect2(-8, -h, 16, 14), Color("7c8a6c"))
	draw_rect(Rect2(-8, -h + 2, 16, 3), Color("9c3527"))  # pintura de guerra
	var cor: Color = Color("ff5a2e")
	var ergue: float = 0.0
	if estado in [Estado.AVISO_AVANCO, Estado.AVISO_ARREMESSO, Estado.AVISO_RUGIDO]:
		cor = Inimigo.cor_do_aviso(_timer)
		ergue = 18.0 if estado != Estado.AVISO_RUGIDO else 0.0
	if estado == Estado.AVISO_RUGIDO:
		draw_rect(Rect2(-10, -h + 20, 20, 6), cor)  # bate no peito
	elif estado != Estado.AVISO_ARREMESSO or int(_timer * 20.0) % 2 == 0:
		draw_line(Vector2(olhando * 10, -h * 0.55), Vector2(olhando * 18, -h * 0.55 - 14 - ergue), Color("4b4753"), 3.0)
		draw_rect(Rect2(olhando * 18 - 5, -h * 0.55 - 20 - ergue, 10, 8), cor)
	if _timer_guarda > 0.0:
		draw_arc(Vector2(0, -h - 6), 8.0, 0.0, TAU, 12, Color("fff3a0"), 1.0)
