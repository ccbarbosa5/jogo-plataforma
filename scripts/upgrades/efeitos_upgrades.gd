class_name EfeitosUpgrades
extends RefCounted
## O que cada upgrade de facção FAZ (GD-02 §6.1 e §6.2). Um por jogador.
## O Jogador, a ControleArma e os inimigos chamam os ganchos abaixo; cada gancho olha
## os upgrades que o jogador tem agora (UpgradesJogador) e aplica o valor da raridade.
##
## Slots: Tiro (efeito do acerto), Granada, Dash, Ferramenta, Chamado, Passivo (GD-01 §6.1).
## Nenhum upgrade mexe em cadência, carga ou dispersão, exceto Calibre Pesado (GD-05 §2.3).

## Um Passivo ou Chamado acabou de agir (HUD, testes).
signal ativou(id: StringName)

var jogador: Jogador
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Munição de Clã
var _gatilho_municao: GatilhoTiros = GatilhoTiros.new(5.0)
var _proximo_explode: bool = false
var _explosao_usada: bool = false
# Couro de Arena
var _couro_carregado: bool = true
var _couro_recarga: float = 0.0
# Dash
var _estava_em_dash: bool = false
var _atingidos_no_dash: Array[Inimigo] = []
var _ultimo_rastro: Vector2 = Vector2.INF


func _init(jogador_: Jogador) -> void:
	jogador = jogador_
	rng.randomize()


## Liga os sinais. Chamado pelo Jogador no _ready (já dentro da árvore).
func conectar() -> void:
	jogador.controle_arma.disparou.connect(_ao_disparar)
	var grilhao := jogador.ferramenta as Grilhao
	if grilhao != null:
		grilhao.acertou.connect(_ao_acertar_ferramenta)
	jogador.lancou_granada.connect(_ao_lancar_granada)
	jogador.get_tree().node_added.connect(_ao_entrar_no_jogo)
	for no in jogador.get_tree().get_nodes_in_group("inimigos"):
		_vigiar(no as Inimigo)


func up(id: StringName) -> DadosUpgrade:
	for u in jogador.upgrades.todos():
		if u.id == id:
			return u
	return null


func valor(id: StringName) -> float:
	var u: DadosUpgrade = up(id)
	return u.valor() if u != null else 0.0


func no_slot(slot: DadosUpgrade.Slot) -> DadosUpgrade:
	return jogador.upgrades.no_slot(slot)


func _pai() -> Node:
	return jogador.container_projeteis if jogador.container_projeteis != null else jogador.get_parent()


# --- Todo frame (dentro do _physics_process do Jogador, antes de zerar a entrada) ---

func processar(delta: float) -> void:
	_processar_couro(delta)
	_processar_dash()
	if jogador.entrada.chamado_pressionado:
		ativar_chamado()


## Nova sala: Couro de Arena volta a valer para o 1º acerto.
func entrar_na_sala() -> void:
	_couro_carregado = true
	_couro_recarga = 0.0


# --- TIRO ---

## Calibre Pesado: −15% de cadência (a única exceção do GD-05 §2.3).
func mult_cadencia() -> float:
	var u: DadosUpgrade = up(&"calibre_pesado")
	return 1.0 + u.extra("cadencia", -0.15) if u != null else 1.0


## Cada projétil novo da arma. `indice` 0 = o primeiro do disparo.
func ao_criar_projetil(projetil: Projetil, indice: int) -> void:
	var calibre: DadosUpgrade = up(&"calibre_pesado")
	if calibre != null:
		projetil.info.multiplicador *= 1.0 + calibre.valor()
		projetil.info.abalo += calibre.extra("abalo", 10.0)  # × fator_efeito no Inimigo
		projetil.info.empurrao = projetil.velocidade.normalized() * Unidades.px(calibre.extra("empurrao", 6.0))
	var municao: DadosUpgrade = up(&"municao_de_cla")
	if municao != null and _proximo_explode and indice == 0:
		projetil.raio_explosao = maxf(projetil.raio_explosao, municao.extra("raio", 24.0))
		projetil.dano_explosao = maxi(projetil.dano_explosao, roundi(municao.valor()))
		projetil.abalo_explosao = municao.extra("abalo", 25.0)
		_explosao_usada = true


## Munição de Clã: conta tiros pelo peso_disparo; o disparo SEGUINTE ao 5º explode.
func _ao_disparar(peso: float) -> void:
	var municao: DadosUpgrade = up(&"municao_de_cla")
	if _explosao_usada:
		_proximo_explode = false
		_explosao_usada = false
	if municao == null:
		return
	_gatilho_municao.a_cada = municao.extra("a_cada", 5.0)
	if _gatilho_municao.alimentar(peso):
		_proximo_explode = true


func proximo_disparo_explode() -> bool:
	return _proximo_explode


## Um projétil da arma acertou (depois do dano).
func ao_acertar(projetil: Projetil, inimigo: Inimigo, golpe: InfoDano, matou: bool) -> void:
	var partido: DadosUpgrade = up(&"ferrao_partido")
	if partido != null and not projetil.fragmento and rng.randf() < golpe.fator_efeito:
		_dividir.call_deferred(projetil.global_position, projetil.velocidade, roundi(projetil.info.valor * partido.valor()),
				inimigo, partido)
	var acido: DadosUpgrade = up(&"ferrao_acido")
	if acido != null and not matou and rng.randf() < acido.valor() * golpe.fator_efeito:
		inimigo.adicionar_acido(1, jogador)


## Ferrão Partido: 2 fragmentos em leque que não se dividem de novo.
func _dividir(posicao: Vector2, velocidade: Vector2, dano: int, ja_acertado: Inimigo,
		u: DadosUpgrade) -> void:
	var cena: PackedScene = jogador.arma_equipada.base.cena_projetil
	var n: int = int(u.extra("fragmentos", 2.0))
	var angulo: float = deg_to_rad(u.extra("angulo", 25.0))
	for i in n:
		var lado: float = -1.0 + 2.0 * i / maxf(n - 1, 1)
		var f: Projetil = cena.instantiate()
		_pai().add_child(f)
		var info := InfoDano.criar(maxi(dano, 1), jogador)
		f.configurar(posicao, velocidade.rotated(lado * angulo), velocidade.length(), info, 0.35,
				Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS | Camadas.PONTOS_FRACOS)
		f.fragmento = true
		f.tamanho = Vector2(4, 2)
		f.cor = Color("a3e23c")
		f.controle = jogador.controle_arma
		if is_instance_valid(ja_acertado):
			f.ignorar(ja_acertado)


# --- GRANADA ---

## Carga de Cerco: raio +50%, mais dano e 100 de Abalo.
func dados_da_granada(base: DadosGranada) -> DadosGranada:
	var cerco: DadosUpgrade = no_slot(DadosUpgrade.Slot.GRANADA)
	if cerco == null or cerco.id != &"carga_de_cerco":
		return base
	var d: DadosGranada = base.duplicate()
	d.raio = base.raio * (1.0 + cerco.extra("raio", 0.5))
	d.dano = roundi(base.dano * (1.0 + cerco.valor()))
	d.abalo = maxf(base.abalo, cerco.extra("abalo", 100.0))
	return d


func _ao_lancar_granada(g: Granada) -> void:
	var ovo: DadosUpgrade = up(&"ovo_de_ninhada")
	if ovo != null:
		g.explodiu.connect(func(_atingidos: Array) -> void: soltar_larvas(g.global_position, ovo))


## Ovo de Ninhada: larvas que perseguem inimigos (dano + Ácido).
func soltar_larvas(posicao: Vector2, ovo: DadosUpgrade) -> void:
	for i in roundi(ovo.valor()):
		var l := AliadoEnxame.criar(_pai(), posicao + Vector2(rng.randf_range(-8, 8), -2), AliadoEnxame.Tipo.LARVA,
				jogador, roundi(ovo.extra("dano", 10.0)), ovo.extra("duracao", 6.0), roundi(ovo.extra("acidos", 2.0)), &"ovo")
		l.velocidade = rng.randf_range(80.0, 110.0)
	ativou.emit(&"ovo_de_ninhada")


# --- DASH ---

func _processar_dash() -> void:
	var em_dash: bool = jogador.esta_em_dash()
	if em_dash and not _estava_em_dash:
		_atingidos_no_dash.clear()
		_ultimo_rastro = Vector2.INF
	_estava_em_dash = em_dash
	if not em_dash:
		return
	var dash: DadosUpgrade = no_slot(DadosUpgrade.Slot.DASH)
	if dash == null:
		return
	if dash.id == &"investida_do_cla":
		_investida(dash)
	elif dash.id == &"rastro_de_enxame":
		_rastro(dash)


## Investida do Clã: quem o dash atravessar leva dano, empurrão e Abalo (uma vez por dash).
func _investida(u: DadosUpgrade) -> void:
	var corpo := Rect2(jogador.global_position - Vector2(Jogador.LARGURA * 0.5 + 4.0, 28.0), Vector2(Jogador.LARGURA + 8.0, 28.0))
	for no in jogador.get_tree().get_nodes_in_group("inimigos"):
		var i := no as Inimigo
		if i == null or not i.esta_vivo() or i in _atingidos_no_dash:
			continue
		var r := Rect2(i.global_position - Vector2(i.tamanho.x * 0.5, i.tamanho.y), i.tamanho)
		if not corpo.intersects(r):
			continue
		_atingidos_no_dash.append(i)
		var direcao := Vector2(float(jogador.olhando), -0.3).normalized()
		var info := InfoDano.criar(roundi(u.valor()), jogador, direcao)
		info.corpo_a_corpo = true
		info.abalo = u.extra("abalo", 50.0)
		info.empurrao = direcao * Unidades.px(u.extra("empurrao", 10.0))
		i.receber_ataque(info)


## Rastro de Enxame: pedaços de trilha ácida por onde o dash passa.
func _rastro(u: DadosUpgrade) -> void:
	var pos: Vector2 = jogador.global_position
	if _ultimo_rastro != Vector2.INF and pos.distance_to(_ultimo_rastro) < 12.0:
		return
	_ultimo_rastro = pos
	var a := AreaAcido.criar(_pai(), pos, Vector2(14, 10), u.extra("duracao", 2.0), jogador)
	a.intervalo = u.extra("intervalo", 0.5)
	a.dano_por_segundo = u.valor()
	a.acidos = 1


# --- FERRAMENTA ---

func _ao_acertar_ferramenta(alvo: Node) -> void:
	var inimigo := alvo as Inimigo
	var u: DadosUpgrade = no_slot(DadosUpgrade.Slot.FERRAMENTA)
	if inimigo == null or u == null or not is_instance_valid(inimigo):
		return
	match u.id:
		&"corrente_rubra":
			Explosao.causar(_pai(), inimigo.centro(), u.extra("raio", 32.0), roundi(u.valor()), jogador)
		&"corrente_infestada":
			if inimigo.esta_vivo():
				inimigo.adicionar_acido(roundi(u.valor()), jogador)
	ativou.emit(u.id)


# --- CHAMADO ---

## Usa a barra cheia (GD-02 §6): a facção do slot Chamado intervém. Retorna true se ativou.
func ativar_chamado() -> bool:
	var u: DadosUpgrade = no_slot(DadosUpgrade.Slot.CHAMADO)
	if u == null or not jogador.chamado_pronto():
		return false
	jogador.barra_chamado = 0.0
	match u.id:
		&"bombardeio_de_artilharia":
			_bombardeio(u)
		&"nuvem_de_zangoes":
			for i in roundi(u.valor()):
				var origem: Vector2 = jogador.global_position + Vector2(rng.randf_range(-24, 24), rng.randf_range(-40, -20))
				AliadoEnxame.criar(_pai(), origem, AliadoEnxame.Tipo.ZANGAO, jogador, roundi(u.extra("dano", 8.0)),
						u.extra("duracao", 8.0), 0, &"chamado")
	ativou.emit(u.id)
	return true


## Bombardeio de Artilharia: projéteis caem do alto sobre os inimigos da tela, um por vez.
func _bombardeio(u: DadosUpgrade) -> void:
	var alvos: Array[Inimigo] = []
	var tela: Rect2 = _retangulo_da_tela()
	for no in jogador.get_tree().get_nodes_in_group("inimigos"):
		var i := no as Inimigo
		if i != null and i.esta_vivo() and tela.has_point(i.centro()):
			alvos.append(i)
	for n in roundi(u.valor()):
		var q := QuedaBombardeio.new()
		q.autor = jogador
		q.dano = roundi(u.extra("dano", 60.0))
		q.raio = u.extra("raio", 16.0)
		q.atraso = n * u.extra("intervalo", 0.12)
		if not alvos.is_empty():
			q.alvo = alvos[n % alvos.size()]
			q.destino = q.alvo.centro()
		else:
			q.destino = Vector2(tela.position.x + rng.randf() * tela.size.x, jogador.global_position.y - 8.0)
		q.position = Vector2(q.destino.x + rng.randf_range(-20, 20), maxf(tela.position.y, q.destino.y - 280.0) - 10.0)
		_pai().add_child(q)


## A tela vista pela câmera (sem câmera, como nos testes: tudo vale).
func _retangulo_da_tela() -> Rect2:
	var vp: Viewport = jogador.get_viewport()
	var camera: Camera2D = vp.get_camera_2d()
	if camera == null:
		return Rect2(-100000, -100000, 200000, 200000)
	var tamanho: Vector2 = vp.get_visible_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - tamanho * 0.5, tamanho)


# --- PASSIVOS ---

## Couro de Arena: anula o 1º acerto recebido em cada sala (Raro e Épico recarregam).
## Retorna true se o acerto foi anulado.
func anular_acerto() -> bool:
	var u: DadosUpgrade = up(&"couro_de_arena")
	if u == null or not _couro_carregado:
		return false
	_couro_carregado = false
	_couro_recarga = u.valor()  # 0 = só na próxima sala
	ativou.emit(&"couro_de_arena")
	return true


func couro_carregado() -> bool:
	return up(&"couro_de_arena") != null and _couro_carregado


func _processar_couro(delta: float) -> void:
	if _couro_carregado or _couro_recarga <= 0.0:
		return
	_couro_recarga -= delta
	if _couro_recarga <= 0.0:
		_couro_carregado = true


## Multiplicador do dano deste jogador contra `inimigo` (Inimigo.receber_ataque).
## Honra do Campeão (elites e chefes), Carne Mole (5 Ácidos), Nós Somos Muitos (aliados).
func mult_dano_contra(inimigo: Inimigo) -> float:
	var m: float = 1.0
	var honra: DadosUpgrade = up(&"honra_do_campeao")
	if honra != null and inimigo.categoria != Inimigo.Categoria.COMUM:
		m *= 1.0 + honra.valor()
	var carne: DadosUpgrade = up(&"carne_mole")
	if carne != null and inimigo.acidos >= roundi(carne.extra("acidos", 5.0)):
		m *= 1.0 + carne.valor()
	var muitos: DadosUpgrade = up(&"nos_somos_muitos")
	if muitos != null:
		m *= 1.0 + muitos.valor() * aliados_ativos()
	return m


## Inabalável: soma ao bônus base de dano em atordoados (25%).
func bonus_atordoado_extra() -> float:
	return valor(&"inabalavel")


func aliados_ativos(origem: StringName = &"") -> int:
	var n: int = 0
	for no in jogador.get_tree().get_nodes_in_group(AliadoEnxame.GRUPO):
		var a := no as AliadoEnxame
		if a != null and not a.is_queued_for_deletion() and (origem == &"" or a.origem == origem):
			n += 1
	return n


## Todo inimigo que entra no jogo: Grito de Guerra e os efeitos "ao matar".
func _ao_entrar_no_jogo(no: Node) -> void:
	var inimigo := no as Inimigo
	if inimigo == null:
		return
	_vigiar(inimigo)
	var grito: DadosUpgrade = up(&"grito_de_guerra")
	if grito != null:
		(func() -> void:
			if is_instance_valid(inimigo):
				inimigo.adicionar_abalo(grito.valor())).call_deferred()


func _vigiar(inimigo: Inimigo) -> void:
	if inimigo != null and not inimigo.morreu.is_connected(_ao_morrer_inimigo):
		inimigo.morreu.connect(_ao_morrer_inimigo)


func _ao_morrer_inimigo(inimigo: Inimigo) -> void:
	if jogador == null or not is_instance_valid(jogador) or jogador.esta_morto():
		return
	var pos: Vector2 = inimigo.global_position
	var solto: DadosUpgrade = up(&"corpo_solto")
	if solto != null and aliados_ativos(&"corpo_solto") < roundi(solto.extra("maximo", 3.0)) and rng.randf() < solto.valor():
		AliadoEnxame.criar.call_deferred(_pai(), pos + Vector2(0, -16), AliadoEnxame.Tipo.ZANGAO, jogador,
				roundi(solto.extra("dano", 8.0)), solto.extra("duracao", 10.0), 0, &"corpo_solto")
		ativou.emit(&"corpo_solto")
	var colmeia: DadosUpgrade = up(&"colmeia_faminta")
	if colmeia != null and inimigo.acidos > 0:
		var raio: float = colmeia.extra("raio", 24.0)
		_criar_poca.call_deferred(pos, raio, colmeia)
		ativou.emit(&"colmeia_faminta")


func _criar_poca(pos: Vector2, raio: float, u: DadosUpgrade) -> void:
	var poca := AreaAcido.criar(_pai(), pos, Vector2(raio * 2.0, 10.0), u.extra("duracao", 3.0), jogador)
	poca.uma_vez_por_inimigo = true
	poca.acidos = roundi(u.valor())
