class_name AberturaHistoria
extends Control
## D-073B: abertura da história (roteiro NAR-07, quadros da ART-5 em assets/sprites/abertura/).
## 9 quadros em sequência (~48 s), cada um montado por código com camadas, câmera e animações
## curtas; as falas AB_01 a AB_06 aparecem na caixa de diálogo em modo "narração".
## Toca no primeiro Novo jogo e termina na nave (onde entra o diálogo ABER). Pelo menu
## ("Ver abertura") termina com tela preta e o logo e volta ao menu.
## Pular: segurar Esc (ou o botão Pausa do controle) ou clicar em "Pular".

signal terminou

const PASTA: String = "res://assets/sprites/abertura/"
const POSES_RYKER: String = "res://assets/sprites/personagens/ryker/ryker_poses_chave.png"
const BRASA: String = "res://assets/sprites/ui/titulo/brasa.png"
const LOGO: String = "res://assets/sprites/ui/titulo/logo_no_rest.png"
const PASTA_VARREK: String = "res://assets/sprites/cenarios/varrek/"
const CAMADAS_VARREK: Array[String] = [
	"varrek_parallax_0_ceu_anel.png", "varrek_parallax_1_cascos_longe.png",
	"varrek_parallax_2_cascos_meio.png", "varrek_parallax_3_primeiro_plano.png"]
const TELA: Vector2 = Vector2(480, 270)
const CENTRO: Vector2 = Vector2(240, 135)
const COR_PRETO: Color = Color("16111c")
const ID_CENA: String = "abertura_historia"

## Duração de cada quadro (NAR-07 §3), em segundos.
const DURACOES: Array[float] = [6.0, 5.0, 6.0, 6.0, 4.0, 6.0, 5.0, 5.0, 5.0]
## Quando cada fala entra (segundos desde o início da abertura) e quanto fica.
## AB_01 espera a legenda da arena sair; AB_04 entra no clarão; AB_05 depois do impacto.
const AGENDA_FALAS: Dictionary = {
	"AB_01": [2.6, 3.3],
	"AB_02": [6.4, 4.4],
	"AB_03": [18.2, 4.6],
	"AB_04": [25.8, 2.4],
	"AB_05": [29.8, 1.5],
	"AB_06": [31.4, 3.4],
}
## Legendas de lugar (D-073: canto de baixo à esquerda, 2 s), por quadro.
const LEGENDAS: Dictionary = {0: "GRANDE ARENA DO DOMÍNIO KHARN", 5: "VARREK"}
const LEGENDA_INICIO: float = 0.5
const LEGENDA_DURACAO: float = 2.0
## Fim pelo menu: tela preta com o logo.
const DURACAO_LOGO_FINAL: float = 2.0

## Segurar Esc por este tempo pula (evita pular sem querer).
@export var segurar_para_pular: float = 0.6
## true = "Ver abertura" pelo menu: não muda o save e volta ao menu.
@export var rever: bool = false

var tempo: float = 0.0
var indice: int = -1
var acabou: bool = false
var pulou: bool = false
var falas_mostradas: Array[String] = []
var caixa: CaixaDialogo
var palco: Node2D
var legenda: Label
var botao_pular: Button
var dica_pular: Label
var barra_pular: ColorRect
var clarao: ColorRect
var cortina: ColorRect
var _logo_final: TextureRect
var _t: float = 0.0
var _q: Dictionary = {}
var _falas: Dictionary = {}
var _segurando: float = 0.0
var _no_logo_final: bool = false
var _tempo_logo: float = 0.0


func _ready() -> void:
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Ciclo.abertura_rever:
		rever = true
	var fundo := ColorRect.new()
	fundo.color = COR_PRETO
	fundo.size = TELA
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	palco = Node2D.new()
	palco.name = "Palco"
	add_child(palco)
	caixa = (load("res://scenes/ui/caixa_dialogo.tscn") as PackedScene).instantiate()
	add_child(caixa)
	_montar_interface()
	for f: Dictionary in Dialogos.banco.cena(ID_CENA).get("falas", []):
		_falas[String(f.get("id", ""))] = f
	_entrar_no_quadro(0)


static func duracao_total() -> float:
	var total: float = 0.0
	for d in DURACOES:
		total += d
	return total


static func inicio_do_quadro(i: int) -> float:
	var total: float = 0.0
	for k in i:
		total += DURACOES[k]
	return total


func _process(delta: float) -> void:
	if acabou:
		return
	if _no_logo_final:
		_tempo_logo += delta
		_logo_final.modulate.a = clampf(_tempo_logo / 0.5, 0.0, 1.0) * clampf((DURACAO_LOGO_FINAL - _tempo_logo) / 0.4, 0.0, 1.0)
		if _tempo_logo >= DURACAO_LOGO_FINAL:
			_sair()
		return
	_atualizar_pular(delta)
	if acabou or _no_logo_final:
		return
	tempo += delta
	var i: int = _quadro_no_tempo(tempo)
	if i >= DURACOES.size():
		_terminar()
		return
	if i != indice:
		_entrar_no_quadro(i)
	_t = tempo - inicio_do_quadro(indice)
	_animar(indice, _t)
	_agendar_falas()
	_atualizar_legenda()


func _quadro_no_tempo(t: float) -> int:
	var soma: float = 0.0
	for k in DURACOES.size():
		soma += DURACOES[k]
		if t < soma:
			return k
	return DURACOES.size()


# --- Pular ---

func _atualizar_pular(delta: float) -> void:
	var segurando: bool = Input.is_key_pressed(KEY_ESCAPE) or Input.is_action_pressed("pausa")
	_segurando = _segurando + delta if segurando else 0.0
	barra_pular.size.x = 60.0 * clampf(_segurando / segurar_para_pular, 0.0, 1.0)
	if _segurando >= segurar_para_pular:
		pular()


## Esc segurado ou o botão "Pular": encerra a abertura.
func pular() -> void:
	if acabou:
		return
	pulou = true
	_terminar()


func _terminar() -> void:
	if acabou or _no_logo_final:
		return
	if caixa.esta_ativa():
		caixa.avancar()  # narração: a fala some junto
	if rever and not pulou:
		_mostrar_logo_final()
		return
	_sair()


func _mostrar_logo_final() -> void:
	_no_logo_final = true
	_limpar_palco()
	legenda.visible = false
	botao_pular.visible = false
	dica_pular.visible = false
	barra_pular.visible = false
	clarao.visible = false
	cortina.visible = false
	_logo_final = TextureRect.new()
	_logo_final.texture = FolhaSprite.carregar(LOGO)
	_logo_final.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_logo_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _logo_final.texture != null:
		_logo_final.size = _logo_final.texture.get_size()
		_logo_final.position = ((TELA - _logo_final.size) * 0.5).round()
	_logo_final.modulate.a = 0.0
	add_child(_logo_final)


func _sair() -> void:
	acabou = true
	if rever:
		Ciclo.abertura_rever = false
		terminou.emit()
		Ciclo.ir_para_titulo()
		return
	Config.marcar_abertura_vista()
	terminou.emit()
	Ciclo.ir_para_nave_do_titulo()  # a nave toca o ABER (a ECO se apresenta)


# --- Falas e legendas ---

func _agendar_falas() -> void:
	# A fala some no tempo da agenda (o relógio é o da abertura, não o da caixa).
	if caixa.esta_ativa():
		var atual: Array = AGENDA_FALAS.get(String(caixa.fala_atual().get("id", "")), [])
		if not atual.is_empty() and tempo >= float(atual[0]) + float(atual[1]):
			caixa.avancar()
	for id: String in AGENDA_FALAS:
		if falas_mostradas.has(id) or not _falas.has(id):
			continue
		var agenda: Array = AGENDA_FALAS[id]
		if tempo >= float(agenda[0]):
			falas_mostradas.append(id)
			var fala: Dictionary = (_falas[id] as Dictionary).duplicate()
			fala["duracao"] = float(agenda[1])
			var lista: Array[Dictionary] = [fala]
			caixa.mostrar(ID_CENA, lista, "narracao", Dialogos.banco)


func _atualizar_legenda() -> void:
	var texto: String = LEGENDAS.get(indice, "")
	legenda.visible = not texto.is_empty() and _t >= LEGENDA_INICIO and _t < LEGENDA_INICIO + LEGENDA_DURACAO
	legenda.text = texto


# --- Montagem da interface ---

func _montar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.name = "Interface"
	camada.layer = 11
	add_child(camada)
	clarao = ColorRect.new()
	clarao.name = "Clarao"
	clarao.color = Color.WHITE
	clarao.size = TELA
	clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clarao.modulate.a = 0.0
	camada.add_child(clarao)
	cortina = ColorRect.new()
	cortina.name = "Cortina"
	cortina.color = COR_PRETO
	cortina.size = TELA
	cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cortina.modulate.a = 0.0
	camada.add_child(cortina)
	legenda = Label.new()
	legenda.name = "Legenda"
	legenda.add_theme_font_override("font", Fontes.placa())
	legenda.add_theme_font_size_override("font_size", Fontes.TAMANHO_PLACA)
	legenda.add_theme_color_override("font_color", Color("fff6ea"))
	legenda.add_theme_color_override("font_outline_color", COR_PRETO)
	legenda.add_theme_constant_override("outline_size", 3)
	legenda.position = Vector2(14, TELA.y - 30)
	legenda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legenda.visible = false
	camada.add_child(legenda)
	var raiz := Control.new()
	raiz.size = TELA
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(raiz)
	botao_pular = EstiloMenu.botao(raiz, "Pular", Rect2(TELA.x - 56, 6, 50, 14), pular, Fontes.TAMANHO_TEXTO)
	botao_pular.name = "Pular"
	botao_pular.focus_mode = Control.FOCUS_NONE  # Enter/Espaço não pulam sem querer
	dica_pular = Label.new()
	dica_pular.text = "Segure Esc para pular"
	dica_pular.add_theme_font_override("font", Fontes.pequena())
	dica_pular.add_theme_font_size_override("font_size", Fontes.TAMANHO_PEQUENA)
	dica_pular.add_theme_color_override("font_color", Color("a7a1ae"))
	dica_pular.add_theme_color_override("font_outline_color", COR_PRETO)
	dica_pular.add_theme_constant_override("outline_size", 2)
	dica_pular.position = Vector2(TELA.x - 124, 8)
	dica_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(dica_pular)
	barra_pular = ColorRect.new()
	barra_pular.color = Color("ffb347")
	barra_pular.position = Vector2(TELA.x - 124, 18)
	barra_pular.size = Vector2(0, 1)
	barra_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(barra_pular)


# --- Ajudas de montagem ---

func _sprite(pai: Node, arquivo: String, colunas: int = 1, linhas: int = 1) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = FolhaSprite.carregar(arquivo if arquivo.begins_with("res://") else PASTA + arquivo)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.hframes = colunas
	s.vframes = linhas
	pai.add_child(s)
	return s


## Anima uma folha: quadro pelo tempo (qps); sem repetir, para no último.
static func _quadro(s: Sprite2D, t: float, qps: float, repetir: bool = true) -> void:
	var n: int = s.hframes * s.vframes
	var q: int = int(t * qps)
	s.frame = q % n if repetir else mini(q, n - 1)


## A câmera de cada quadro mexe no nó-base: o ponto "foco" do mundo fica no centro da tela.
static func _camera(no: Node2D, foco: Vector2, zoom: float = 1.0, tremor: Vector2 = Vector2.ZERO) -> void:
	no.scale = Vector2(zoom, zoom)
	no.position = (CENTRO - foco * zoom + tremor).round()


static func _suave(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)  # ease out


func _brasas(pai: Node, quantidade: int = 20) -> CPUParticles2D:
	var b := CPUParticles2D.new()
	b.texture = FolhaSprite.carregar(BRASA)
	var m := CanvasItemMaterial.new()
	m.particles_animation = true
	m.particles_anim_h_frames = 3
	m.particles_anim_v_frames = 1
	b.material = m
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.amount = quantidade
	b.lifetime = 5.0
	b.preprocess = 5.0
	b.position = Vector2(CENTRO.x, TELA.y + 4)
	b.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	b.emission_rect_extents = Vector2(TELA.x * 0.5, 4)
	b.direction = Vector2(0, -1)
	b.spread = 20.0
	b.gravity = Vector2(0, -3)
	b.initial_velocity_min = 18.0
	b.initial_velocity_max = 36.0
	b.anim_offset_max = 1.0
	pai.add_child(b)
	return b


func _limpar_palco() -> void:
	for filho in palco.get_children():
		filho.queue_free()
	_q.clear()


func _ryker_retrato(expressao: String) -> Texture2D:
	return RetratoDialogo.carregar_textura("RYKER", expressao, Dialogos.banco.expressoes_do_falante("RYKER"))


# --- Quadros ---

func _entrar_no_quadro(i: int) -> void:
	indice = i
	_limpar_palco()
	var base := Node2D.new()
	base.name = "Quadro%d" % (i + 1)
	palco.add_child(base)
	_q["base"] = base
	match i:
		0: _montar_arena(base)
		1: _montar_premio(base)
		2: _montar_fuga(base)
		3: _montar_portao(base)
		4: _montar_dentro(base)
		5, 6: _montar_varrek(base, i == 6)
		7: _montar_nave_eco(base)
		8: _montar_reconstrutor(base)
	_animar(i, 0.0)


func _animar(i: int, t: float) -> void:
	match i:
		0: _animar_arena(t)
		1: _animar_premio(t)
		2: _animar_fuga(t)
		3: _animar_portao(t)
		4: _animar_dentro(t)
		5: _animar_queda(t)
		6: _animar_silencio(t)
		7: _animar_nave_eco(t)
		8: _animar_reconstrutor(t)


# Quadro 1 — A Grande Arena: a câmera desce da plateia até o Ryker sob o holofote.
func _montar_arena(base: Node2D) -> void:
	var mundo := Node2D.new()
	base.add_child(mundo)
	_q["mundo"] = mundo
	_q["fundo"] = _sprite(mundo, "q1_fundo_ia.png")
	var urkesh := _sprite(mundo, "q1_urkesh_caido.png")
	urkesh.position = Vector2(310 - 48, 456 - 80)
	var ryker := _sprite(mundo, POSES_RYKER, 8)
	ryker.frame = 0
	ryker.position = Vector2(238 - 24, 456 - 48)
	_brasas(base, 18)


func _animar_arena(t: float) -> void:
	var y: float = lerpf(0.0, 270.0, _suave(t / 4.5))
	_camera(_q["mundo"], Vector2(240, 135 + y))
	# O holofote pisca uma vez.
	var pisca: float = 1.25 if t > 3.6 and t < 3.75 else 1.0
	(_q["fundo"] as Sprite2D).modulate = Color(pisca, pisca, pisca)


# Quadro 2 — O prêmio: zoom no Ryker, os guardas entram pelas bordas.
func _montar_premio(base: Node2D) -> void:
	var fundo := _sprite(base, "q1_fundo_ia.png")
	fundo.position = Vector2(0, -270)
	fundo.modulate = Color(0.5, 0.5, 0.5)
	var g1 := _sprite(base, "q2_guarda.png", 2)
	var g2 := _sprite(base, "q2_guarda.png", 2)
	g2.flip_h = true
	_q["guardas"] = [g1, g2]
	var mundo := Node2D.new()
	base.add_child(mundo)
	_q["mundo"] = mundo
	var r := Sprite2D.new()
	r.texture = _ryker_retrato("neutro")
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.centered = false
	r.position = Vector2(CENTRO.x - RetratoDialogo.TAMANHO.x * 0.5, TELA.y - RetratoDialogo.TAMANHO.y)
	mundo.add_child(r)
	_q["retrato"] = r
	_q["deboche"] = false


func _animar_premio(t: float) -> void:
	var guardas: Array = _q["guardas"]
	var entra: float = _suave(t / 3.0)
	(guardas[0] as Sprite2D).position = Vector2(lerpf(-40.0, 40.0, entra), 186 - 48).round()
	(guardas[1] as Sprite2D).position = Vector2(lerpf(480.0, 400.0, entra), 186 - 48).round()
	for g: Sprite2D in guardas:
		_quadro(g, t, 6.0)
	# Zoom lento no rosto (1,0 → 1,25×), olhando o alto do retrato.
	var zoom: float = lerpf(1.0, 1.25, clampf(t / 5.0, 0.0, 1.0))
	_camera(_q["mundo"], Vector2(240, lerpf(135.0, 120.0, t / 5.0)), zoom)
	if t >= 2.4 and not _q["deboche"]:
		_q["deboche"] = true
		(_q["retrato"] as Sprite2D).texture = _ryker_retrato("deboche")


# Quadro 3 — A fuga: travelling para a direita, paralaxe forte, o Ryker pula para a nave.
const CHAO_FUGA: float = 216.0


func _montar_fuga(base: Node2D) -> void:
	for camada: Array in [["q3_fundo.png", 0.2], ["q3_tunel.png", 1.0]]:
		var par: Array = []
		for k in 2:
			par.append(_sprite(base, camada[0]))
		_q[camada[0]] = [par, camada[1]]
	var hangar := _sprite(base, "q3_hangar.png")
	hangar.visible = false
	_q["hangar"] = hangar
	var nave := _sprite(base, "nave_ryker_ia.png", 3)
	nave.visible = false
	_q["nave"] = nave
	var guardas: Array = []
	for k in 2:
		guardas.append(_sprite(base, "q2_guarda.png", 2))
	_q["guardas"] = guardas
	var caido := _sprite(base, "q2_guarda.png", 2)
	caido.flip_h = true
	_q["guarda_frente"] = caido
	var ryker := _sprite(base, POSES_RYKER, 8)
	_q["ryker"] = ryker
	var faiscas := _brasas(base, 10)
	faiscas.preprocess = 0.0
	faiscas.lifetime = 0.6
	faiscas.emission_rect_extents = Vector2(2, 1)
	faiscas.direction = Vector2(-1, -0.5)
	faiscas.gravity = Vector2(0, 60)
	_q["faiscas"] = faiscas
	var par_frente: Array = []
	for k in 2:
		par_frente.append(_sprite(base, "q3_frente.png"))
	_q["q3_frente.png"] = [par_frente, 1.6]


func _animar_fuga(t: float) -> void:
	var cam: float = 240.0 * minf(t, 4.2)
	for chave in ["q3_fundo.png", "q3_tunel.png", "q3_frente.png"]:
		var dados: Array = _q[chave]
		var x: float = -fposmod(cam * float(dados[1]), TELA.x)
		(dados[0][0] as Sprite2D).position = Vector2(roundf(x), 0)
		(dados[0][1] as Sprite2D).position = Vector2(roundf(x) + TELA.x, 0)
	var ryker: Sprite2D = _q["ryker"]
	var rx: float = 190.0
	var ry: float = CHAO_FUGA - 48.0
	if t < 1.8:
		ryker.frame = 1 if int(t * 8.0) % 2 == 0 else 2
	elif t < 2.6:
		ryker.frame = 6  # lança a corrente (Grilhão) no guarda da frente
	elif t < 4.4:
		ryker.frame = 1 if int(t * 8.0) % 2 == 0 else 2
	else:
		# Pulo para dentro da nave.
		var p: float = clampf((t - 4.4) / 0.8, 0.0, 1.0)
		ryker.frame = 2
		rx = lerpf(190.0, 318.0, p)
		ry = CHAO_FUGA - 48.0 - sin(p * PI) * 40.0
		ryker.visible = p < 1.0
	ryker.position = Vector2(rx, ry).round()
	var faiscas: CPUParticles2D = _q["faiscas"]
	faiscas.position = ryker.position + Vector2(10, 44)
	faiscas.emitting = ryker.visible and t < 4.4
	var guardas: Array = _q["guardas"]
	for k in guardas.size():
		var g: Sprite2D = guardas[k]
		g.position = Vector2(roundf(lerpf(-60.0, 40.0 + k * 50.0, _suave(t / 2.0)) - k * 40.0), CHAO_FUGA - 48)
		_quadro(g, t + k * 0.3, 6.0)
		g.visible = t < 4.6
	# O guarda da frente é puxado pela corrente e cai.
	var frente: Sprite2D = _q["guarda_frente"]
	var gx: float = lerpf(480.0, 260.0, t / 1.8) if t < 1.8 else lerpf(260.0, 230.0, clampf((t - 1.8) / 0.4, 0.0, 1.0))
	var tomba: float = clampf((t - 2.2) / 0.3, 0.0, 1.0)
	frente.rotation = -PI * 0.5 * tomba
	# Girando pelo canto de cima, o corpo deitado fica com a base no chão.
	frente.position = Vector2(roundf(gx), roundf(CHAO_FUGA - 48.0 + 48.0 * tomba))
	frente.visible = t > 0.4 and t < 4.2
	# No fim do túnel, o hangar com a nave.
	var hangar: Sprite2D = _q["hangar"]
	var nave: Sprite2D = _q["nave"]
	var entra: float = clampf((t - 3.6) / 0.6, 0.0, 1.0)
	hangar.visible = entra > 0.0
	hangar.position = Vector2(roundf(lerpf(TELA.x, 0.0, entra)), 0)
	nave.visible = hangar.visible
	nave.position = hangar.position + Vector2(300, CHAO_FUGA - 30)
	# A porta fecha: corte para o Portão.
	cortina.modulate.a = clampf((t - 5.4) / 0.5, 0.0, 1.0)


# Quadro 4 — O Portão quebrado: zoom out; a nave Kharn para antes do anel, a do Ryker entra.
func _montar_portao(base: Node2D) -> void:
	cortina.modulate.a = 0.0
	var mundo := Node2D.new()
	base.add_child(mundo)
	_q["mundo"] = mundo
	_sprite(mundo, "q4_fundo_ia.png")
	var redemoinho := Sprite2D.new()
	redemoinho.texture = FolhaSprite.carregar(PASTA + "q4_redemoinho_ia.png")
	redemoinho.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	redemoinho.position = CENTRO
	mundo.add_child(redemoinho)
	_q["redemoinho"] = redemoinho
	_q["kharn"] = _sprite(mundo, "nave_kharn_ia.png")
	_q["nave"] = _sprite(mundo, "nave_ryker_ia.png", 3)


func _animar_portao(t: float) -> void:
	var zoom: float = lerpf(1.6, 1.0, _suave(t / 3.5))
	_camera(_q["mundo"], CENTRO, zoom)
	(_q["redemoinho"] as Sprite2D).rotation = deg_to_rad(20.0) * t
	# A nave do Ryker atravessa da esquerda para o centro e some no anel.
	var nave: Sprite2D = _q["nave"]
	var p: float = clampf(t / 5.0, 0.0, 1.0)
	var pos: Vector2 = Vector2(-60, 200).lerp(CENTRO - Vector2(26, 12), p * p)
	nave.position = pos.round()
	var some: float = clampf((t - 4.2) / 0.8, 0.0, 1.0)
	nave.scale = Vector2.ONE * (1.0 - 0.8 * some)
	nave.modulate.a = 1.0 - some
	# A nave Kharn hesita antes do anel.
	var kharn: Sprite2D = _q["kharn"]
	var k: float = _suave(clampf(t / 3.0, 0.0, 1.0))
	kharn.position = Vector2(lerpf(-200.0, -40.0, k), 190.0 + sin(t * 2.0) * 1.0).round()


# Quadro 5 — Dentro do Portão: faixas cada vez mais rápidas, a nave racha, clarão branco.
func _montar_dentro(base: Node2D) -> void:
	var faixas: Array = [_sprite(base, "q5_faixas.png"), _sprite(base, "q5_faixas.png")]
	_q["faixas"] = faixas
	var mundo := Node2D.new()
	base.add_child(mundo)
	_q["mundo"] = mundo
	var nave := _sprite(mundo, "nave_ryker_ia.png", 3)
	nave.scale = Vector2(3, 3)
	nave.position = CENTRO - Vector2(26, 12) * 3.0
	_q["nave"] = nave


func _animar_dentro(t: float) -> void:
	# Distância percorrida com velocidade crescente (200 → 1400 px/s).
	var x: float = 200.0 * t + 150.0 * t * t
	var faixas: Array = _q["faixas"]
	(faixas[0] as Sprite2D).position = Vector2(-fposmod(x, 960.0), 0).round()
	(faixas[1] as Sprite2D).position = (faixas[0] as Sprite2D).position + Vector2(960, 0)
	var nave: Sprite2D = _q["nave"]
	nave.frame = 0 if t < 1.4 else (1 if t < 2.4 else 2)
	var forca: float = 1.0 + t * 1.5
	var tremor := Vector2(randf_range(-forca, forca), randf_range(-forca, forca))
	_camera(_q["mundo"], CENTRO, lerpf(1.0, 1.4, t / 4.0), tremor)
	clarao.modulate.a = clampf((t - 2.8) / 0.5, 0.0, 1.0)


# Quadros 6 e 7 — Varrek: a queda (câmera de cima para baixo) e o silêncio com o feixe âmbar.
const POS_DESTROCOS: Array[Vector2] = [Vector2(150, 214), Vector2(250, 222), Vector2(330, 210)]


func _montar_varrek(base: Node2D, silencio: bool) -> void:
	var camadas: Array = []
	for arquivo in CAMADAS_VARREK:
		camadas.append(_sprite(base, PASTA_VARREK + arquivo))
	_q["camadas"] = camadas
	var destrocos: Array = []
	var poeiras: Array = []
	for k in POS_DESTROCOS.size():
		var d := _sprite(base, "q6_destroco_fogo.png", 2)
		destrocos.append(d)
		var p := _sprite(base, "q6_poeira.png", 4)
		p.visible = false
		poeiras.append(p)
	_q["destrocos"] = destrocos
	_q["poeiras"] = poeiras
	if silencio:
		clarao.modulate.a = 0.0
		var fumacas: Array = []
		for pos in POS_DESTROCOS:
			var f := _sprite(base, "q7_fumaca.png", 2)
			f.position = pos + Vector2(2, -64)
			fumacas.append(f)
		_q["fumacas"] = fumacas
		var feixe := _sprite(base, "q7_feixe_ambar.png", 2)
		feixe.position = Vector2(POS_DESTROCOS[1].x + 10 - 32, 0)
		feixe.modulate.a = 0.0
		_q["feixe"] = feixe
		var part := CPUParticles2D.new()
		part.texture = FolhaSprite.carregar(PASTA + "particula_ambar.png")
		var m := CanvasItemMaterial.new()
		m.particles_animation = true
		m.particles_anim_h_frames = 3
		m.particles_anim_v_frames = 1
		part.material = m
		part.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		part.amount = 30
		part.lifetime = 3.0
		part.emitting = false
		part.position = Vector2(POS_DESTROCOS[1].x + 10, 226)
		part.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		part.emission_rect_extents = Vector2(26, 6)
		part.direction = Vector2(0, -1)
		part.spread = 6.0
		part.gravity = Vector2.ZERO
		part.initial_velocity_min = 40.0
		part.initial_velocity_max = 70.0
		part.anim_offset_max = 1.0
		base.add_child(part)
		_q["particulas"] = part


const IMPACTO_QUEDA: float = 2.6


func _animar_queda(t: float) -> void:
	# O clarão do Portão se desfaz no céu de Varrek.
	clarao.modulate.a = 1.0 - clampf(t / 0.6, 0.0, 1.0)
	var desce: float = _suave(t / IMPACTO_QUEDA)
	var tremor: float = 2.0 if t > IMPACTO_QUEDA and t < IMPACTO_QUEDA + 0.3 else 0.0
	var camadas: Array = _q["camadas"]
	for k in camadas.size():
		# Paralaxe vertical: quanto mais perto, mais a camada sobe ao longo da queda.
		var fator: float = [0.15, 0.4, 0.7, 1.0][k]
		var dy: float = (1.0 - desce) * 160.0 * fator
		(camadas[k] as Sprite2D).position = Vector2(randf_range(-tremor, tremor), dy).round()
	var destrocos: Array = _q["destrocos"]
	var poeiras: Array = _q["poeiras"]
	for k in destrocos.size():
		var d: Sprite2D = destrocos[k]
		var alvo: Vector2 = POS_DESTROCOS[k] - Vector2(10, 28)
		var inicio: Vector2 = alvo + Vector2(-90.0 + k * 30.0, -260.0)
		var p: float = clampf((t - k * 0.15) / (IMPACTO_QUEDA - 0.3), 0.0, 1.0)
		d.position = inicio.lerp(alvo, p * p).round()
		_quadro(d, t, 8.0)
		var poeira: Sprite2D = poeiras[k]
		var tp: float = t - (k * 0.15 + IMPACTO_QUEDA - 0.3)
		poeira.visible = tp >= 0.0 and tp < 0.4
		poeira.position = POS_DESTROCOS[k] - Vector2(22, 26)
		_quadro(poeira, maxf(tp, 0.0), 10.0, false)


func _animar_silencio(t: float) -> void:
	var camadas: Array = _q["camadas"]
	for c: Sprite2D in camadas:
		c.position = Vector2.ZERO
	var feixe: Sprite2D = _q["feixe"]
	feixe.modulate.a = clampf((t - 1.2) / 1.0, 0.0, 1.0)
	_quadro(feixe, t, 6.0)
	var part: CPUParticles2D = _q["particulas"]
	part.emitting = t > 2.0
	# Os destroços sobem com a luz e somem no céu.
	var sobe: float = clampf((t - 2.8) / 2.0, 0.0, 1.0)
	var destrocos: Array = _q["destrocos"]
	for k in destrocos.size():
		var d: Sprite2D = destrocos[k]
		d.position = (POS_DESTROCOS[k] - Vector2(10, 28) - Vector2(0, sobe * sobe * 200.0)).round()
		d.modulate.a = 1.0 - sobe
		d.frame = 1
	for f: Sprite2D in _q["fumacas"]:
		_quadro(f, t, 3.0)
		f.modulate.a = 1.0 - sobe


# Quadro 8 — A nave Eco: pan lento; o feixe volta para dentro e as luzes pulsam uma vez.
func _montar_nave_eco(base: Node2D) -> void:
	var mundo := Node2D.new()
	base.add_child(mundo)
	_q["mundo"] = mundo
	_q["fundo"] = _sprite(mundo, "q8_fundo_ia.png")
	var feixe := _sprite(mundo, "q7_feixe_ambar.png", 2)
	feixe.position = Vector2(360 - 32, 180)
	_q["feixe"] = feixe


func _animar_nave_eco(t: float) -> void:
	var p: float = _suave(t / 5.0)
	var mundo: Node2D = _q["mundo"]
	mundo.position = Vector2(-240.0 * p, -90.0 * p).round()
	var feixe: Sprite2D = _q["feixe"]
	var recolhe: float = clampf(t / 2.0, 0.0, 1.0)
	feixe.scale = Vector2(1.0 - recolhe * 0.5, 1.0 - recolhe)
	feixe.position.x = 360.0 - 32.0 * feixe.scale.x
	feixe.visible = recolhe < 1.0
	_quadro(feixe, t, 6.0)
	var pulso: float = clampf(1.0 - absf(t - 2.6) / 0.4, 0.0, 1.0)
	(_q["fundo"] as Sprite2D).modulate = Color(1.0 + 0.25 * pulso, 1.0 + 0.18 * pulso, 1.0 + 0.05 * pulso)


# Quadro 9 — O Reconstrutor: tela preta, a luz âmbar forma a silhueta; depois, o ABER.
func _montar_reconstrutor(base: Node2D) -> void:
	var mundo := Node2D.new()
	base.add_child(mundo)
	_q["mundo"] = mundo
	_sprite(mundo, "q9_fundo_ia.png")
	var s := _sprite(mundo, "q9_silhueta.png", 6)
	s.position = Vector2(196, 62)
	_q["silhueta"] = s


func _animar_reconstrutor(t: float) -> void:
	cortina.modulate.a = 1.0 - clampf((t - 0.5) / 0.5, 0.0, 1.0)
	_camera(_q["mundo"], CENTRO, lerpf(1.0, 1.15, clampf(t / 5.0, 0.0, 1.0)))
	_quadro(_q["silhueta"], maxf(t - 0.5, 0.0), 1.2, false)
