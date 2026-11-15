class_name DiretorHorda
extends Node
## Ondas contínuas de enxame (GD-08 §3, D-062). Um por sala de combate (filho da SalaRun).
## - Trecho: enxame contínuo pela direita enquanto o jogador avança (+50% se ele parar 4 s).
## - Arena: fluxo de enxame durante a duração + pesados (as ondas do plano) a cada 8–10 s
##   + 1 pico aos 60% (tremor 1,5 s antes; é o único momento com entradas por trás e de cima,
##   sempre com aviso de 1,0 s).
## - Teto de inimigos vivos: novas entradas esperam.
## - Fim: as entradas param; os pesados precisam morrer; 8 s depois o enxame que sobrou foge
##   pela direita (sem XP) e a sala termina.
## Números em data/salas/horda_varrek.json.

signal pico_anunciado
signal pico_comecou
## Uma entrada por trás ou de cima vai acontecer em `aviso_excecao` segundos.
signal aviso_entrada(posicao: Vector2, origem: StringName)
signal entrou(inimigo: Inimigo, origem: StringName)
signal terminou

const ARQUIVO: String = "res://data/salas/horda_varrek.json"
const DIREITA: StringName = &"direita"
const ATRAS: StringName = &"atras"
const CIMA: StringName = &"cima"

enum Fase { PARADO, TRECHO, ARENA, ESPERA_PESADOS, ESPERA_FUGA, FUGA, FIM }

var sala: SalaRun
var pool: PoolEnxame
var geral: Dictionary = {}
var config: Dictionary = {}
var rng := RandomNumberGenerator.new()

var fase: Fase = Fase.PARADO
var tempo_arena: float = 0.0
## Ondas de pesados que ainda vão entrar.
var pesados_pendentes: Array[Dictionary] = []
var pesados: Array[Inimigo] = []
var em_pico: bool = false
## Contagem por origem (para o teste de ~80% pela direita).
var entradas: Dictionary = {DIREITA: 0, ATRAS: 0, CIMA: 0}

var _acumulado: float = 0.0
var _timer_pesados: float = 0.0
var _timer: float = 0.0
var _pico_feito: bool = false
var _pico_anunciado: bool = false
var _pico_restante: int = 0
var _pico_relogio: float = 0.0
var _parado_ref_x: float = 0.0
var _parado_tempo: float = 0.0
var _avisos: Array[Dictionary] = []  # {tempo, tipo, posicao, origem}


static func carregar_dados() -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	return d if d is Dictionary else {}


func _init(sala_: SalaRun = null) -> void:
	sala = sala_
	name = "DiretorHorda"
	process_physics_priority = -1


func configurar(chave_bioma: String, ondas_pesadas: Array) -> void:
	var dados: Dictionary = carregar_dados()
	geral = dados.get("geral", {})
	var biomas: Dictionary = dados.get("biomas", {})
	config = biomas.get(chave_bioma, biomas.get("carcaca", {})).duplicate(true)
	for o: Dictionary in ondas_pesadas:
		pesados_pendentes.append(o)
	rng.randomize()


func _g(chave: String, padrao: Variant) -> Variant:
	return config.get(chave, geral.get(chave, padrao))


func teto() -> int:
	return int(geral.get("teto_pico", 40)) if em_pico else int(config.get("teto", 20))


func vivos() -> int:
	var n: int = 0
	for no in sala.inimigos.get_children():
		var i := no as Inimigo
		if i != null and i.esta_vivo():
			n += 1
	return n


## Vivos + os que já foram avisados e vão entrar.
func ocupados() -> int:
	return vivos() + _avisos.size()


func vivos_enxame() -> int:
	var n: int = 0
	for no in sala.inimigos.get_children():
		var i := no as InimigoEnxame
		if i != null and i.esta_vivo():
			n += 1
	return n


func pesados_vivos() -> int:
	var n: int = 0
	for no in sala.inimigos.get_children():
		var i := no as Inimigo
		if i != null and i.esta_vivo() and not i is InimigoEnxame:
			n += 1
	return n


# --- Controle pela sala ---

func comecar_trecho() -> void:
	if fase == Fase.PARADO:
		fase = Fase.TRECHO
		_parado_ref_x = sala.jogador.global_position.x


func comecar_arena() -> void:
	# O enxame do trecho que ficou fora da arena não consegue entrar: some (sem XP).
	for no in sala.inimigos.get_children():
		var e := no as InimigoEnxame
		if e != null and e.esta_vivo() and not sala.arena.has_point(e.global_position - Vector2(0, 1)):
			e.sumir()
	fase = Fase.ARENA
	tempo_arena = 0.0
	_acumulado = 0.0
	_timer_pesados = float(geral.get("primeiro_pesado", 2.0))
	if float(config.get("duracao", 0.0)) <= 0.0:
		_timer_pesados = 0.0  # chefe: entra na hora
	_pico_feito = int(config.get("pico", 0)) <= 0
	if duracao() <= 0.0:
		# Chefe: as ondas entram já (o jogo pode estar pausado pela fala de entrada).
		while not pesados_pendentes.is_empty():
			_soltar_onda_pesada(pesados_pendentes.pop_front())


## Para as entradas agora (testes e atalhos): o que estava pendente não entra mais.
func encerrar_entradas() -> void:
	pesados_pendentes.clear()
	_avisos.clear()
	if fase in [Fase.TRECHO, Fase.ARENA]:
		fase = Fase.ESPERA_PESADOS


func duracao() -> float:
	return float(config.get("duracao", 0.0))


func _physics_process(delta: float) -> void:
	if sala == null or sala.jogador == null or not is_instance_valid(sala.jogador):
		return
	_processar_avisos(delta)
	match fase:
		Fase.TRECHO:
			_trecho(delta)
		Fase.ARENA:
			_arena(delta)
		Fase.ESPERA_PESADOS:
			if pesados_vivos() == 0 and _avisos.is_empty():
				if vivos_enxame() == 0:
					_terminar()
				else:
					fase = Fase.ESPERA_FUGA
					_timer = float(geral.get("fuga_depois", 8.0))
		Fase.ESPERA_FUGA:
			_timer -= delta
			if vivos_enxame() == 0:
				_terminar()
			elif _timer <= 0.0:
				fase = Fase.FUGA
				for no in sala.inimigos.get_children():
					var e := no as InimigoEnxame
					if e != null and e.esta_vivo():
						e.fugir()
		Fase.FUGA:
			if vivos_enxame() == 0:
				_terminar()


func _terminar() -> void:
	fase = Fase.FIM
	terminou.emit()


# --- Trecho ---

func _trecho(delta: float) -> void:
	var taxa: float = float(config.get("trecho", 0.0))
	if taxa <= 0.0:
		return
	var j: Jogador = sala.jogador
	if absf(j.global_position.x - _parado_ref_x) > 8.0:
		_parado_ref_x = j.global_position.x
		_parado_tempo = 0.0
	else:
		_parado_tempo += delta
	if _parado_tempo > float(geral.get("parado_segundos", 4.0)):
		taxa *= float(geral.get("parado_mult", 1.5))  # a horda alcança quem fica parado
	_acumulado += taxa * delta
	_soltar_fluxo(sala.area_trecho())


# --- Arena ---

func _arena(delta: float) -> void:
	tempo_arena += delta
	var dur: float = duracao()
	# Pesados (as ondas do plano) a cada 8 a 10 s, sempre pela direita.
	_timer_pesados -= delta
	if not pesados_pendentes.is_empty() and _timer_pesados <= 0.0:
		_soltar_onda_pesada(pesados_pendentes.pop_front())
		var intervalo: Vector2 = Vector2(geral.get("intervalo_pesados", [8.0, 10.0])[0], geral.get("intervalo_pesados", [8.0, 10.0])[1])
		_timer_pesados = rng.randf_range(intervalo.x, intervalo.y)
		if dur > 0.0 and not pesados_pendentes.is_empty():
			# Todas as ondas cabem na duração.
			_timer_pesados = minf(_timer_pesados, maxf(1.0, (dur - tempo_arena - 2.0) / pesados_pendentes.size()))
	# Pico aos 60%.
	if not _pico_feito and dur > 0.0:
		var hora: float = dur * float(geral.get("pico_em", 0.6))
		if not _pico_anunciado and tempo_arena >= hora - float(geral.get("aviso_pico", 1.5)):
			_pico_anunciado = true
			pico_anunciado.emit()
			if sala.camera != null and sala.camera.has_method("tremer"):
				sala.camera.tremer(2.0, float(geral.get("aviso_pico", 1.5)))
		if tempo_arena >= hora:
			_pico_feito = true
			em_pico = true
			_pico_restante = int(config.get("pico", 12))
			_pico_relogio = 0.0
			pico_comecou.emit()
	if em_pico:
		_processar_pico(delta)
	# Fluxo contínuo.
	_acumulado += float(config.get("taxa", 0.0)) * delta
	_soltar_fluxo(sala.arena)
	# Fim.
	var acabou: bool = dur <= 0.0 and pesados_pendentes.is_empty()
	if dur > 0.0:
		if config.get("ate_a_elite_morrer", false):
			acabou = (tempo_arena >= 3.0 and pesados_pendentes.is_empty() and not _elite_viva()) or tempo_arena >= dur
		else:
			acabou = tempo_arena >= dur
	if acabou:
		pesados_pendentes.clear()
		em_pico = false
		fase = Fase.ESPERA_PESADOS


func _elite_viva() -> bool:
	for i in pesados:
		if is_instance_valid(i) and i.esta_vivo() and i.categoria == Inimigo.Categoria.ELITE:
			return true
	return false


func _processar_pico(delta: float) -> void:
	var dur: float = float(geral.get("pico_duracao", 4.0))
	_pico_relogio += delta
	var total: int = int(config.get("pico", 12))
	var devidos: int = ceili(total * clampf(_pico_relogio / dur, 0.0, 1.0))
	while total - _pico_restante < devidos and _pico_restante > 0:
		if ocupados() >= teto():
			break
		_pico_restante -= 1
		var origem: StringName = DIREITA
		var r: float = rng.randf()
		var atras: float = float(_g("fracao_atras_pico", 0.1))
		if r < atras:
			origem = ATRAS
		elif r < atras + float(geral.get("fracao_cima_pico", 0.1)):
			origem = CIMA
		var tipo: String = _sortear_tipo() if origem != CIMA else "zangao"
		if origem == DIREITA:
			_entrar(tipo, DIREITA, sala.arena)
		else:
			_agendar_excecao(tipo, origem)
	if _pico_restante <= 0 and _pico_relogio >= dur:
		em_pico = false


# --- Entradas ---

func _soltar_fluxo(area: Rect2) -> void:
	var mistura: Dictionary = config.get("mistura", {})
	if mistura.is_empty():
		_acumulado = 0.0
		return
	while _acumulado >= 1.0:
		var tipo: String = _sortear_tipo()
		var grupo: int = int(geral.get("grupo", {}).get(tipo, 1))
		grupo = mini(grupo, int(_acumulado))
		if ocupados() + grupo > teto():
			_acumulado = minf(_acumulado, float(teto()))  # espera o teto baixar
			return
		var entrou_algum: bool = false
		for k in grupo:
			if _entrar(tipo, DIREITA, area, k) != null:
				entrou_algum = true
		if not entrou_algum:
			return  # sem lugar justo agora; tenta no próximo quadro
		_acumulado -= grupo


func _sortear_tipo() -> String:
	var mistura: Dictionary = config.get("mistura", {})
	var total: float = 0.0
	for t: String in mistura:
		total += float(mistura[t])
	var r: float = rng.randf() * total
	for t: String in mistura:
		r -= float(mistura[t])
		if r <= 0.0:
			return t
	return mistura.keys()[0] if not mistura.is_empty() else "roedor"


## Posição de entrada pela origem, ou Vector2.INF se não houver lugar justo.
func posicao_de_entrada(tipo: String, origem: StringName, area: Rect2, indice: int = 0) -> Vector2:
	var cam_x: float = sala.camera.global_position.x if sala.camera != null else sala.jogador.global_position.x
	var meia: float = 240.0
	var fora: float = Unidades.px(float(geral.get("fora_da_tela_tiles", 2)))
	var minimo: float = area.position.x + 12.0
	var maximo: float = area.end.x - 12.0
	var x: float
	match origem:
		ATRAS:
			x = clampf(cam_x - meia - fora - indice * 10.0, minimo, maximo)
		CIMA:
			var lado: float = 1.0 if rng.randf() < 0.5 else -1.0
			x = clampf(sala.jogador.global_position.x + lado * Unidades.px(rng.randf_range(6.5, 12.0)), minimo, maximo)
		_:
			x = clampf(cam_x + meia + fora + indice * 10.0, minimo, maximo)
	var y: float
	if origem == CIMA or tipo == "zangao":
		y = 24.0 + rng.randf_range(0.0, 40.0) if origem == CIMA else _chao(x) - rng.randf_range(40.0, 90.0)
		if is_inf(y):
			y = 120.0
	else:
		y = _chao(x)
		if is_inf(y):
			return Vector2.INF
		y -= 1.0
	var pos := Vector2(x, y)
	if pos.distance_to(sala.jogador.global_position) < Unidades.px(float(geral.get("distancia_minima_tiles", 6))):
		return Vector2.INF  # nunca a menos de 6 tiles do jogador
	return pos


func _chao(x: float) -> float:
	var espaco := sala.get_world_2d().direct_space_state
	var consulta := PhysicsRayQueryParameters2D.create(Vector2(x, 8.0), Vector2(x, sala.limites().end.y),
			Camadas.MUNDO | Camadas.PLATAFORMAS)
	var r: Dictionary = espaco.intersect_ray(consulta)
	return r["position"].y if not r.is_empty() else INF


func _entrar(tipo: String, origem: StringName, area: Rect2, indice: int = 0, pos: Vector2 = Vector2.INF) -> Inimigo:
	if is_inf(pos.x):
		pos = posicao_de_entrada(tipo, origem, area, indice)
	if is_inf(pos.x):
		return null
	var i: InimigoEnxame = pool.pegar(tipo) if pool != null else null
	if i == null:
		return null
	i.position = pos
	i.container_projeteis = sala.projeteis
	i.olhando = -1 if origem == DIREITA else 1
	sala.inimigos.add_child(i)
	entradas[origem] = int(entradas.get(origem, 0)) + 1
	entrou.emit(i, origem)
	return i


## Entrada por trás ou de cima: o aviso aparece 1,0 s antes (GD-08 §3.1).
func _agendar_excecao(tipo: String, origem: StringName) -> void:
	var pos: Vector2 = posicao_de_entrada(tipo, origem, sala.arena)
	if is_inf(pos.x):
		_entrar(tipo, DIREITA, sala.arena)
		return
	var aviso := AvisoEntrada.new()
	aviso.origem = origem
	sala.add_child(aviso)
	aviso.global_position = pos
	_avisos.append({"tempo": float(geral.get("aviso_excecao", 1.0)), "tipo": tipo, "posicao": pos,
			"origem": origem, "no": aviso})
	aviso_entrada.emit(pos, origem)


func _processar_avisos(delta: float) -> void:
	for k in range(_avisos.size() - 1, -1, -1):
		var a: Dictionary = _avisos[k]
		a["tempo"] -= delta
		if a["tempo"] <= 0.0:
			_avisos.remove_at(k)
			if is_instance_valid(a["no"]):
				a["no"].queue_free()
			var pos: Vector2 = a["posicao"]
			if pos.distance_to(sala.jogador.global_position) < Unidades.px(float(geral.get("distancia_minima_tiles", 6))):
				_entrar(a["tipo"], DIREITA, sala.arena)  # o jogador chegou perto: entra pela frente
			else:
				_entrar(a["tipo"], a["origem"], sala.arena, 0, pos)


## Ondas de pesados: sempre pela direita, com os 0,5 s de entrada sem atacar.
func _soltar_onda_pesada(onda: Dictionary) -> void:
	var n: int = 0
	var jogadores: Array[Vector2] = [sala.jogador.global_position]
	var limite := Vector2(sala.arena.position.x + 16.0, sala.arena.end.x - 16.0)
	for item: Dictionary in onda.get("inimigos", []):
		var tipo: String = item["tipo"]
		if MontadorSala.e_enxame(tipo):
			continue
		var pontos: Array = sala.surgimentos.get("R", [])
		var base: Vector2
		if tipo == "urkesh" or pontos.is_empty():
			var ponto: Array = sala.surgimentos.get(item.get("ponto", "R"), sala.surgimentos.get("R", [sala.arena.get_center()]))
			base = ponto[n % ponto.size()]
		else:
			base = pontos[n % pontos.size()]
		var desejada: Vector2 = base + Vector2(-36.0 * (n / maxi(1, pontos.size())), 0)
		var pos: Vector2 = RegrasSurgimento.posicao_justa(desejada, jogadores, limite)
		var inimigo := sala._criar_inimigo(tipo, pos, true)
		inimigo.set_meta("custo", sala.banco_ondas.custo_inimigo(tipo) if sala.banco_ondas != null else 0)
		pesados.append(inimigo)
		sala.vivos_da_onda.append(inimigo)
		if inimigo is UrKesh:
			sala.chefe_apareceu.emit(inimigo)
		n += 1
	sala.onda_atual += 1
