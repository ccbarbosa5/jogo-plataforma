class_name ControleArma
extends RefCounted
## Comportamento da arma do jogador durante a run (GD-05 §4): quando e como dispara,
## as assinaturas (Embalo da Mordida, Coice do Bramido) e os 18 marcadores da árvore.
## O Jogador chama processar() todo frame; o Projetil chama antes/depois_do_acerto().

## Cada disparo (cada bala da rajada) conta `peso` tiros (GD-05 §2.3).
signal disparou(peso: float)
signal acertou(inimigo: Inimigo, info: InfoDano, matou: bool)

const PASTA_PROJETEIS: String = "res://assets/sprites/armas/projeteis/"

var jogador: Jogador
var p: ParametrosArmas
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Embalo (Mordida): 0 até o máximo.
var embalo: float = 0.0
## Carga do Bramido (Artilharia), em segundos.
var carga: float = 0.0
## Disparos no carregador (Cano Duplo).
var balas: int = 0
## Alvos marcados pelo Grilhão (Marca do Escravo): Inimigo -> segundos restantes.
var marcas: Dictionary = {}
## Tiros dados com o Embalo cheio (Golpe do Campeão a cada 10).
var tiros_embalo_cheio: int = 0

var _cooldown: float = 0.0
var _sem_acertar: float = 999.0
var _rajada_restantes: int = 0
var _timer_rajada: float = 0.0
var _rajada: Disparo
var _carregando: bool = false
var _recuo_no_ar_usado: bool = false
var _texturas: Dictionary = {}


func _init(jogador_: Jogador, parametros: ParametrosArmas = null) -> void:
	jogador = jogador_
	p = parametros if parametros != null else ParametrosArmas.new()
	rng.randomize()
	reiniciar()


func arma() -> ArmaEquipada:
	return jogador.arma_equipada


func tem(marcador: StringName) -> bool:
	return arma() != null and arma().tem_marcador(marcador)


func assinatura() -> StringName:
	return arma().base.assinatura if arma() != null and arma().base != null else &""


## Começo de sala ou troca de arma.
func reiniciar() -> void:
	embalo = 0.0
	carga = 0.0
	_carregando = false
	_cooldown = 0.0
	_rajada_restantes = 0
	balas = p.carregador_tamanho
	tiros_embalo_cheio = 0


# --- Embalo ---

func embalo_maximo() -> float:
	return p.embalo_maximo_estendido if tem(&"embalo_estendido") else p.embalo_maximo


func embalo_cheio() -> bool:
	return assinatura() == &"embalo" and embalo >= embalo_maximo()


func fracao_embalo() -> float:
	return embalo / embalo_maximo() if assinatura() == &"embalo" else 0.0


## Cadência efetiva: base × modificadores × Embalo (+1,25% por ponto).
func cadencia() -> float:
	var c: float = arma().cadencia() * jogador.efeitos.mult_cadencia()
	if assinatura() == &"embalo":
		c *= 1.0 + embalo * p.embalo_cadencia_por_ponto
	return c


func carregando() -> bool:
	return _carregando


func fracao_carga() -> float:
	return clampf(carga / p.carga_s, 0.0, 1.0) if _carregando else 0.0


# --- Ganchos chamados pelo Jogador ---

func ao_levar_dano() -> void:
	if assinatura() != &"embalo":
		return
	embalo = floorf(embalo * 0.5) if tem(&"embalo_estendido") else 0.0


func ao_dash() -> void:
	if tem(&"recarga_no_dash"):
		_cooldown = 0.0
		balas = p.carregador_tamanho


## O Grilhão acertou: Marca do Escravo.
func marcar(inimigo: Inimigo) -> void:
	if tem(&"marca_grilhao") and inimigo != null:
		marcas[inimigo] = p.marca_duracao


func esta_marcado(inimigo: Inimigo) -> bool:
	return marcas.get(inimigo, 0.0) > 0.0


## `manual`: botão de tiro segurado. `automatico`: o tiro automático quer atirar (sem o botão).
func processar(delta: float, manual: bool, automatico: bool) -> void:
	_atualizar_timers(delta)
	if arma() == null or arma().base == null or arma().base.cena_projetil == null:
		return
	if _rajada_restantes > 0:
		_timer_rajada -= delta
		if _timer_rajada <= 0.0:
			_disparar(&"", _rajada, p.rajada_balas - _rajada_restantes + 1)
			_rajada_restantes -= 1
			_timer_rajada = p.rajada_intervalo
		return
	if tem(&"carga_explosiva"):
		_processar_carga(delta, manual, automatico)
		return
	if not (manual or automatico):
		_cooldown = maxf(_cooldown, 0.0)
		return
	if _cooldown > 0.0:
		return
	_puxar_gatilho(delta)


func _atualizar_timers(delta: float) -> void:
	_cooldown -= delta
	_sem_acertar += delta
	if assinatura() == &"embalo" and _sem_acertar > p.embalo_atraso_queda:
		embalo = maxf(embalo - p.embalo_queda_por_segundo * delta, 0.0)
	for alvo in marcas.keys():
		marcas[alvo] -= delta
		if marcas[alvo] <= 0.0 or not is_instance_valid(alvo):
			marcas.erase(alvo)
	if jogador.is_on_floor():
		_recuo_no_ar_usado = false
	# Cano Duplo: recarrega o carregador quando a recarga longa termina.
	if tem(&"carregador_2") and balas <= 0 and _cooldown <= 0.0:
		balas = p.carregador_tamanho


## Artilharia: segurar carrega; soltar antes de 1 s = tiro normal; carga cheia = explosivo.
## Com o tiro automático (botão solto), dispara sozinho quando a carga completa (GD-05 §2.4).
func _processar_carga(delta: float, manual: bool, automatico: bool) -> void:
	if _cooldown > 0.0:
		return
	if manual or automatico:
		_carregando = true
		carga += delta
		if automatico and not manual and carga >= p.carga_s:
			_soltar_carga(delta)
		return
	if _carregando:
		_soltar_carga(delta)


func _soltar_carga(delta: float) -> void:
	var cheia: bool = carga >= p.carga_s
	_carregando = false
	carga = 0.0
	if cheia:
		_disparar(&"carregado", Disparo.new())
		_depois_do_disparo(delta)
	else:
		_puxar_gatilho(delta)


func _puxar_gatilho(delta: float) -> void:
	if tem(&"rajada_3"):
		_rajada = Disparo.new()
		_disparar(&"", _rajada, 1)
		_rajada_restantes = p.rajada_balas - 1
		_timer_rajada = p.rajada_intervalo
		# Pausa entre rajadas, mais curta com Embalo.
		var bonus: float = 1.0 + embalo * p.embalo_cadencia_por_ponto
		_cooldown = maxf(_cooldown, -delta) + (p.rajada_intervalo * (p.rajada_balas - 1) + p.rajada_pausa / bonus)
		return
	var especial: StringName = &""
	if tem(&"golpe_do_campeao") and embalo_cheio():
		tiros_embalo_cheio += 1
		if tiros_embalo_cheio % p.campeao_a_cada == 0:
			especial = &"campeao"
	_disparar(especial, Disparo.new())
	_depois_do_disparo(delta)


func _depois_do_disparo(delta: float) -> void:
	if tem(&"carregador_2"):
		balas -= 1
		var espera: float = p.carregador_intervalo if balas > 0 else p.carregador_recarga
		_cooldown = maxf(_cooldown, -delta) + espera
	else:
		_cooldown = maxf(_cooldown, -delta) + 1.0 / cadencia()


## Cria os projéteis de um disparo (ou de uma bala da rajada).
func _disparar(especial: StringName, disparo: Disparo, ordem_rajada: int = 0) -> void:
	var a: ArmaEquipada = arma()
	var base: DadosArma = a.base
	var direcao: Vector2 = Vector2(jogador.mira).normalized()
	var origem: Vector2 = jogador.ponto_de_tiro() + direcao * 10.0
	var destino: Node = jogador.container_projeteis if jogador.container_projeteis != null else jogador.get_parent()
	var unica: bool = tem(&"bala_unica")
	var quantos: int = 1 if especial == &"campeao" else a.projeteis_por_tiro()
	var espalhamento: float = 0.0 if especial == &"campeao" else a.espalhamento_graus()
	for i in quantos:
		var desvio: float = deg_to_rad(rng.randf_range(-espalhamento, espalhamento))
		var projetil: Projetil = base.cena_projetil.instantiate()
		destino.add_child(projetil)
		var dano: int = p.campeao_dano if especial == &"campeao" else a.dano()
		var info := InfoDano.criar(dano, jogador)
		info.fator_efeito = 1.0 if unica else base.fator_efeito
		projetil.configurar(origem, direcao.rotated(desvio), Unidades.px(a.velocidade_projetil()), info,
				a.duracao_projetil(), Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS | Camadas.PONTOS_FRACOS)
		projetil.controle = self
		projetil.disparo = disparo
		projetil.ordem_rajada = ordem_rajada
		projetil.especial = especial
		projetil.textura = _textura_do_projetil(especial, unica, ordem_rajada > 0)
		if not unica:
			projetil.queda_dano_px = base.queda_dano_px
			projetil.mult_queda_dano = base.mult_queda_dano
		if tem(&"perfura_com_embalo_cheio") and embalo_cheio():
			projetil.perfuracoes = 1
		projetil.perfura_leves = tem(&"perfura_leves")
		if especial == &"carregado":
			projetil.raio_explosao = p.explosao_raio
			projetil.dano_explosao = p.explosao_dano
		jogador.efeitos.ao_criar_projetil(projetil, i)
		jogador.atirou.emit(projetil)
	disparou.emit(base.peso_disparo)
	if tem(&"recuo_jogador"):
		_recuar(direcao)


func _textura_do_projetil(especial: StringName, unica: bool, rajada: bool) -> Texture2D:
	var arquivo: String = ""
	match especial:
		&"campeao":
			arquivo = "golpe_do_campeao.png"
		&"carregado":
			arquivo = "bala_carregada.png"
		_:
			if unica:
				arquivo = "bala_cerco.png"
			elif rajada:
				arquivo = "rebite_rajada.png"
	if arquivo.is_empty():
		return arma().base.textura_projetil
	if not _texturas.has(arquivo):
		_texturas[arquivo] = FolhaSprite.carregar(PASTA_PROJETEIS + arquivo)
	return _texturas[arquivo]


## Recuo de Gladiador: empurra o Ryker para trás; no ar, um impulso para cima (1 vez por pulo).
func _recuar(direcao: Vector2) -> void:
	var lado: float = signf(direcao.x) if direcao.x != 0.0 else float(jogador.olhando)
	if direcao.x != 0.0 or direcao.y == 0.0:
		jogador.move_and_collide(Vector2(-lado * p.recuo_px, 0.0))
	if not jogador.is_on_floor() and not _recuo_no_ar_usado:
		_recuo_no_ar_usado = true
		jogador.velocity.y = minf(jogador.velocity.y, -p.recuo_impulso_ar)


func _devolver_disparo() -> void:
	_cooldown = 0.0
	if tem(&"carregador_2"):
		balas = mini(balas + 1, p.carregador_tamanho)


# --- Ganchos chamados pelo Projetil ---

func antes_do_acerto(projetil: Projetil, inimigo: Inimigo, golpe: InfoDano) -> void:
	var elite: bool = inimigo.categoria != Inimigo.Categoria.COMUM
	var distancia: float = projetil.global_position.distance_to(jogador.ponto_de_tiro())
	if projetil.especial == &"campeao" and elite:
		golpe.multiplicador *= p.campeao_mult_elite
	if tem(&"marca_grilhao") and esta_marcado(inimigo):
		golpe.multiplicador *= 1.0 + p.marca_bonus_dano
	if tem(&"bonus_perto") and distancia < p.perto_px:
		golpe.multiplicador *= 1.0 + p.perto_bonus_dano
	if tem(&"quebra_armadura_perto") and distancia <= p.quebra_armadura_px:
		inimigo.quebrar_armadura(p.quebra_armadura_s)
	# Três Golpes: a 3ª bala da rajada é crítica se as 3 acertarem o mesmo alvo.
	if tem(&"rajada_critico_3") and projetil.ordem_rajada == p.rajada_balas and projetil.disparo != null:
		var mesmos: bool = true
		for ordem in range(1, p.rajada_balas):
			if projetil.disparo.alvos_rajada.get(ordem) != inimigo:
				mesmos = false
		if mesmos:
			golpe.critico = true
			if tem(&"execucao") and elite:
				golpe.multiplicador *= p.critico_mult_execucao_elite
			elif tem(&"execucao") and inimigo.vida.atual < inimigo.vida.maxima * p.execucao_limite_vida:
				golpe.valor = inimigo.vida.atual
				golpe.multiplicador = 1000.0  # mata na hora, mesmo com armadura
			else:
				golpe.multiplicador *= p.critico_mult


func depois_do_acerto(projetil: Projetil, inimigo: Inimigo, golpe: InfoDano, matou: bool) -> void:
	_sem_acertar = 0.0
	if assinatura() == &"embalo":
		embalo = minf(embalo + 1.0, embalo_maximo())
	if projetil.ordem_rajada > 0 and projetil.disparo != null:
		projetil.disparo.alvos_rajada[projetil.ordem_rajada] = inimigo
	if not matou:
		# Coice: um empurrão por alvo por disparo (os balins não somam).
		if assinatura() == &"coice" and projetil.disparo != null and not inimigo in projetil.disparo.empurrados:
			projetil.disparo.empurrados.append(inimigo)
			var lado: float = signf(projetil.velocidade.x) if projetil.velocidade.x != 0.0 else float(jogador.olhando)
			inimigo.deslocar(Vector2(lado * p.coice_px, 0.0))
		# Algema Viva: chance de prender o alvo marcado (leves e médios comuns).
		if tem(&"algema_viva") and esta_marcado(inimigo) and inimigo.categoria == Inimigo.Categoria.COMUM \
				and inimigo.peso != Inimigo.Peso.PESADO and rng.randf() < p.algema_chance * golpe.fator_efeito:
			inimigo.atordoar(p.algema_leve_s if inimigo.peso == Inimigo.Peso.LEVE else p.algema_medio_s)
	else:
		if tem(&"marca_devolve_grilhao") and esta_marcado(inimigo):
			var grilhao := jogador.ferramenta as Grilhao
			if grilhao != null:
				grilhao.reduzir_recarga(p.cacada_devolve_s)
		if tem(&"devolve_disparo_ao_matar"):
			_devolver_disparo()
		marcas.erase(inimigo)
	jogador.efeitos.ao_acertar(projetil, inimigo, golpe, matou)
	acertou.emit(inimigo, golpe, matou)
