class_name ControleArma
extends RefCounted
## Comportamento da arma do jogador durante a run (GD-07). No nível 1 a arma só atira; os
## marcadores dos ModificadorArma (ramo da arma na árvore de Combate e Gambiarras) ligam os
## comportamentos abaixo. Números em ParametrosArmas. O Jogador chama processar() todo frame;
## o Projetil chama antes/depois_do_acerto(). A Marca do Grilhão também mora aqui.
##
## Marcadores:
##  tres_golpes · grande_arena · rebite_duplo (acumula) · incandescente · leque · cacador_marca
##  tiro_aviso · guiado · prego_do_rato · abre_couraca · cano_duplo · carregador_arena
##  recuo · bala_central · empurrao · estilhaco_vivo (acumula) · queima_roupa · artilharia

## Cada disparo conta `peso` tiros para os efeitos de facção (GD-05 §2.3).
signal disparou(peso: float)
signal acertou(inimigo: Inimigo, info: InfoDano, matou: bool)

const PASTA_PROJETEIS: String = "res://assets/sprites/armas/projeteis/"

var jogador: Jogador
var p: ParametrosArmas
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Carga da Artilharia, em segundos.
var carga: float = 0.0
## Disparos no carregador (Cano Duplo / Carregador de Arena).
var balas: int = 0
## Alvos marcados pelo Grilhão: Inimigo -> {"tempo": s, "bonus": fração}.
var marcas: Dictionary = {}
## Tiros dados nesta sala (Grande Arena, Prego do Rato, Rebite Duplo).
var tiros: int = 0

var _cooldown: float = 0.0
var _carregando: bool = false
var _recuo_no_ar_usado: bool = false
var _ultimo_alvo: Inimigo
var _seguidos: int = 0
var _bonus_proximo: float = 0.0
var _timer_bonus_proximo: float = 0.0
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


func contar(marcador: StringName) -> int:
	return arma().contar_marcador(marcador) if arma() != null else 0


## Começo de sala ou troca de arma.
func reiniciar() -> void:
	carga = 0.0
	_carregando = false
	_cooldown = 0.0
	tiros = 0
	_ultimo_alvo = null
	_seguidos = 0
	balas = tamanho_carregador()


## Uma Gambiarra nova pode mudar o tamanho do carregador: começa cheio.
func reiniciar_carregador() -> void:
	balas = tamanho_carregador()


## 1 = sem carregador. Cano Duplo ou Carregador de Arena: 2; os dois juntos: 3.
func tamanho_carregador() -> int:
	return 1 + contar(&"cano_duplo") + contar(&"carregador_arena")


## Cadência efetiva: arma × modificadores × efeitos de facção.
func cadencia() -> float:
	return arma().cadencia() * jogador.efeitos.mult_cadencia()


func carregando() -> bool:
	return _carregando


func fracao_carga() -> float:
	return clampf(carga / p.carga_s, 0.0, 1.0) if _carregando else 0.0


# --- Ganchos chamados pelo Jogador e pelo Grilhão ---

func ao_levar_dano() -> void:
	pass


func ao_dash() -> void:
	pass


## O próximo tiro (em até `segundos`) causa `bonus` a mais (Esquiva de Arena, ramo do Dash).
func armar_bonus_proximo_tiro(bonus: float, segundos: float) -> void:
	_bonus_proximo = bonus
	_timer_bonus_proximo = segundos


## Marca do Grilhão (GD-07 §2): +25% de dano dos tiros por 4 s (Marca Funda: +40% por 6 s).
func marcar(inimigo: Inimigo) -> void:
	if inimigo == null:
		return
	var funda: bool = jogador.tem_no(&"grilhao_marca_funda")
	marcas[inimigo] = {
		"tempo": p.marca_funda_duracao if funda else p.marca_duracao,
		"bonus": p.marca_funda_bonus if funda else p.marca_bonus_dano,
	}


func esta_marcado(inimigo: Inimigo) -> bool:
	return marcas.has(inimigo) and marcas[inimigo]["tempo"] > 0.0


func bonus_da_marca(inimigo: Inimigo) -> float:
	return marcas[inimigo]["bonus"] if esta_marcado(inimigo) else 0.0


## `manual`: botão de tiro segurado. `automatico`: o tiro automático quer atirar (sem o botão).
func processar(delta: float, manual: bool, automatico: bool) -> void:
	_atualizar_timers(delta)
	if arma() == null or arma().base == null or arma().base.cena_projetil == null:
		return
	if tem(&"artilharia"):
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
	_timer_bonus_proximo -= delta
	if _timer_bonus_proximo <= 0.0:
		_bonus_proximo = 0.0
	for alvo in marcas.keys():
		marcas[alvo]["tempo"] -= delta
		if marcas[alvo]["tempo"] <= 0.0 or not is_instance_valid(alvo):
			marcas.erase(alvo)
	if jogador.is_on_floor():
		_recuo_no_ar_usado = false
	# Carregador: volta cheio quando a recarga longa termina.
	if balas <= 0 and _cooldown <= 0.0:
		balas = tamanho_carregador()


## Artilharia: segurar carrega; soltar antes de 1 s = tiro normal; carga cheia = explosivo.
## Com o tiro automático (botão solto), dispara sozinho quando a carga completa.
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
		_disparar(&"carregado", false)
		_depois_do_disparo(delta)
	else:
		_puxar_gatilho(delta)


func _puxar_gatilho(delta: float) -> void:
	tiros += 1
	var especial: StringName = &""
	if tem(&"prego_do_rato") and tiros % p.prego_a_cada == 0:
		especial = &"prego"
	elif tem(&"grande_arena") and tiros % p.grande_arena_a_cada == 0:
		especial = &"arena"
	var duplo: bool = false
	var acumulos_duplo: int = contar(&"rebite_duplo")
	if acumulos_duplo > 0:
		var a_cada: int = maxi(p.rebite_duplo_a_cada - (acumulos_duplo - 1), 2)
		duplo = tiros % a_cada == 0
	_disparar(especial, duplo)
	_depois_do_disparo(delta)


func _depois_do_disparo(delta: float) -> void:
	if tamanho_carregador() > 1:
		balas -= 1
		var espera: float = p.carregador_intervalo if balas > 0 else p.carregador_recarga
		_cooldown = maxf(_cooldown, -delta) + espera
	else:
		_cooldown = maxf(_cooldown, -delta) + 1.0 / cadencia()


## Cria os projéteis de um disparo.
func _disparar(especial: StringName, duplo: bool) -> void:
	var a: ArmaEquipada = arma()
	var direcao: Vector2 = jogador.direcao_mira()
	var origem: Vector2 = jogador.ponto_de_tiro() + direcao * 10.0
	var disparo := Disparo.new()
	var bonus: float = _bonus_proximo
	_bonus_proximo = 0.0
	if especial == &"prego" or especial == &"arena":
		var dano: int = p.prego_dano if especial == &"prego" else p.grande_arena_dano
		var proj: Projetil = _criar(origem, direcao, dano, disparo, especial, bonus)
		proj.perfuracoes = 999
		proj.textura = _textura("golpe_do_campeao.png")
	elif especial == &"carregado":
		var proj: Projetil = _criar(origem, direcao, a.dano(), disparo, especial, bonus)
		proj.raio_explosao = p.explosao_raio
		proj.dano_explosao = p.explosao_dano
		proj.textura = _textura("bala_carregada.png")
	else:
		var espalhamento: float = a.espalhamento_graus()
		var lado: Vector2 = direcao.orthogonal()
		for i in a.projeteis_por_tiro():
			var dir: Vector2 = direcao.rotated(deg_to_rad(rng.randf_range(-espalhamento, espalhamento)))
			if duplo:  # Rebite Duplo: dois projéteis lado a lado
				for sinal: float in [-1.0, 1.0]:
					_criar(origem + lado * sinal * p.rebite_duplo_distancia_px, dir, a.dano(), disparo, &"", bonus, i)
			else:
				_criar(origem, dir, a.dano(), disparo, &"", bonus, i)
		if tem(&"leque"):
			for sinal: float in [-1.0, 1.0]:
				var dano_leque: int = maxi(roundi(a.dano() * p.leque_mult_dano), 1)
				_criar(origem, direcao.rotated(deg_to_rad(sinal * p.leque_graus)), dano_leque, disparo, &"", bonus)
		if tem(&"bala_central"):
			var central: Projetil = _criar(origem, direcao, p.bala_central_dano, disparo, &"central", bonus)
			central.tempo_restante = p.bala_central_alcance_px / maxf(Unidades.px(a.velocidade_projetil()), 1.0)
			central.queda_dano_px = 0.0
			central.textura = _textura("bala_cerco.png")
	disparou.emit(a.base.peso_disparo)
	if tem(&"recuo"):
		_recuar(direcao)


func _criar(origem: Vector2, direcao: Vector2, dano: int, disparo: Disparo, especial: StringName,
		bonus: float, indice: int = 0) -> Projetil:
	var a: ArmaEquipada = arma()
	var base: DadosArma = a.base
	var destino: Node = jogador.container_projeteis if jogador.container_projeteis != null else jogador.get_parent()
	var projetil: Projetil = base.cena_projetil.instantiate()
	destino.add_child(projetil)
	var info := InfoDano.criar(dano, jogador)
	info.fator_efeito = base.fator_efeito
	if bonus > 0.0:
		info.multiplicador *= 1.0 + bonus
	projetil.configurar(origem, direcao, Unidades.px(a.velocidade_projetil()), info, a.duracao_projetil(),
			Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS | Camadas.PONTOS_FRACOS)
	projetil.controle = self
	projetil.disparo = disparo
	projetil.especial = especial
	projetil.textura = base.textura_projetil
	projetil.queda_dano_px = a.queda_dano_px()
	projetil.mult_queda_dano = base.mult_queda_dano
	projetil.perfuracoes = a.perfuracoes()
	projetil.ricochetes = a.ricochetes()
	var tamanho: float = a.tamanho_projetil()
	if not is_equal_approx(tamanho, 1.0):
		projetil.scale = Vector2(tamanho, tamanho)
	if tem(&"guiado"):
		projetil.guiado_graus = p.guiado_graus
		projetil.guiado_graus_por_s = p.guiado_graus_por_s
		projetil.guiado_alcance_px = p.guiado_alcance_px
	jogador.efeitos.ao_criar_projetil(projetil, indice)
	jogador.atirou.emit(projetil)
	return projetil


func _textura(arquivo: String) -> Texture2D:
	if not _texturas.has(arquivo):
		_texturas[arquivo] = FolhaSprite.carregar(PASTA_PROJETEIS + arquivo)
	return _texturas[arquivo]


## Recuo de Gladiador: empurra o Ryker para trás; no ar, um impulso para cima (1 vez por pulo).
func _recuar(direcao: Vector2) -> void:
	var lado: float = signf(direcao.x) if absf(direcao.x) > 0.01 else float(jogador.olhando)
	jogador.move_and_collide(Vector2(-lado * p.recuo_px, 0.0))
	if not jogador.is_on_floor() and not _recuo_no_ar_usado:
		_recuo_no_ar_usado = true
		jogador.velocity.y = minf(jogador.velocity.y, -p.recuo_impulso_ar)


# --- Ganchos chamados pelo Projetil ---

## Acertos seguidos neste alvo antes deste (Três Golpes, Incandescente).
func _seguidos_antes(inimigo: Inimigo) -> int:
	return _seguidos if inimigo == _ultimo_alvo else 0


func antes_do_acerto(projetil: Projetil, inimigo: Inimigo, golpe: InfoDano) -> void:
	if projetil.fragmento:
		return
	var elite: bool = inimigo.categoria != Inimigo.Categoria.COMUM
	var distancia: float = projetil.global_position.distance_to(jogador.ponto_de_tiro())
	if projetil.especial == &"arena" and elite:
		golpe.multiplicador *= p.grande_arena_mult_elite
	if esta_marcado(inimigo):
		golpe.multiplicador *= 1.0 + bonus_da_marca(inimigo)
		if tem(&"cacador_marca"):
			golpe.multiplicador *= 1.0 + p.cacador_marca_bonus
	if distancia <= p.perto_px:
		if tem(&"abre_couraca"):
			inimigo.quebrar_armadura(p.abre_couraca_s)
		if tem(&"queima_roupa"):
			golpe.multiplicador *= 1.0 + p.queima_roupa_bonus
	if tem(&"tiro_aviso") and inimigo.esta_anunciando():
		golpe.multiplicador *= 1.0 + p.tiro_aviso_bonus
	var antes: int = _seguidos_antes(inimigo)
	if tem(&"incandescente"):
		golpe.multiplicador *= 1.0 + minf(antes * p.incandescente_por_acerto, p.incandescente_maximo)
	if tem(&"tres_golpes") and (antes + 1) % 3 == 0:
		golpe.critico = true
		golpe.multiplicador *= p.critico_mult


func depois_do_acerto(projetil: Projetil, inimigo: Inimigo, golpe: InfoDano, matou: bool) -> void:
	if not projetil.fragmento:
		if inimigo == _ultimo_alvo:
			_seguidos += 1
		else:
			_ultimo_alvo = inimigo
			_seguidos = 1
	if not matou:
		# Empurrão de Campeão: um empurrão por alvo por disparo (os balins não somam).
		if tem(&"empurrao") and inimigo.peso != Inimigo.Peso.PESADO and projetil.disparo != null \
				and not inimigo in projetil.disparo.empurrados:
			projetil.disparo.empurrados.append(inimigo)
			var lado: float = signf(projetil.velocidade.x) if projetil.velocidade.x != 0.0 else float(jogador.olhando)
			inimigo.deslocar(Vector2(lado * p.empurrao_px, 0.0))
	else:
		marcas.erase(inimigo)
		if tem(&"estilhaco_vivo") and not projetil.fragmento:
			# Fora do callback de física: cria os estilhaços no próximo quadro ocioso.
			_soltar_estilhacos.call_deferred(projetil.get_parent(), inimigo.centro(), inimigo,
					contar(&"estilhaco_vivo") * p.estilhacos_por_acumulo)
	jogador.efeitos.ao_acertar(projetil, inimigo, golpe, matou)
	acertou.emit(inimigo, golpe, matou)


## Estilhaço Vivo: o balim que mata solta estilhaços em volta.
func _soltar_estilhacos(destino: Node, centro: Vector2, morto: Object, quantos: int) -> void:
	if destino == null or not is_instance_valid(destino) or arma() == null:
		return
	for i in quantos:
		var dir: Vector2 = Vector2.RIGHT.rotated(TAU * (float(i) + rng.randf()) / float(quantos))
		var e: Projetil = arma().base.cena_projetil.instantiate()
		destino.add_child(e)
		var info := InfoDano.criar(p.estilhaco_dano, jogador)
		e.configurar(centro, dir, 200.0, info, 0.25, Camadas.PROJETEIS_JOGADOR, Camadas.MUNDO | Camadas.INIMIGOS)
		e.fragmento = true
		e.controle = self
		if is_instance_valid(morto):
			e.ignorar(morto as Node)
