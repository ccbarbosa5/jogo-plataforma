class_name TelaRecompensa
extends CanvasLayer
## Tela de oferta de dádiva de facção (GD-01 §6.3): 3 opções da mesma facção, o jogador pega 1.
## Moldura da facção; cor do nome pela raridade; avisa quando a escolha substitui o upgrade
## do mesmo slot (GD-01 §6.1). Antes das opções, a patrona fala (NAR-01: KHAR_*, VESH_*);
## a parte marcada "[depois da escolha]" toca depois que o jogador escolhe.

signal escolheu(upgrade: DadosUpgrade, substituido: DadosUpgrade)
signal fechou

const GRUPO: StringName = &"tela_recompensa"
const PAINEL: Rect2 = Rect2(40, 14, 400, 242)
const CARTA_X: float = 54.0
const CARTA_LARGURA: float = 372.0
const CARTA_Y: float = 46.0
const CARTA_ALTURA: float = 56.0
const CARTA_PASSO: float = 62.0
const COR_TEXTO: Color = Color("eceff4")
const COR_APAGADO: Color = Color("a7adba")
const CORES_RARIDADE: Array[Color] = [Color("eceff4"), Color("6ab0ff"), Color("c58cff")]
const COR_SUBSTITUI: Color = Color("ff8a6a")

var entrada: EntradaJogador
var jogador: Jogador
var catalogo: CatalogoFaccao
var ofertas: Array[DadosUpgrade] = []
var selecionada: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var escurecer: ColorRect
var painel: MolduraDialogo
var desenho: Control
var _descricoes: Array[Label] = []
var _falas_depois: Array[Dictionary] = []
var _id_cena: String = ""
var _aberta: bool = false
var _escolhendo: bool = false
var _pausou: bool = false
var _direcao_anterior: Vector2i = Vector2i.ZERO
var _trava: float = 0.0


func _ready() -> void:
	add_to_group(GRUPO)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 9  # abaixo da caixa de diálogo (layer 10): as falas da patrona ficam por cima
	rng.randomize()
	escurecer = ColorRect.new()
	escurecer.color = Color(0.03, 0.02, 0.05, 0.7)
	escurecer.size = Vector2(480, 270)
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escurecer)
	painel = MolduraDialogo.new()
	painel.position = PAINEL.position
	painel.size = PAINEL.size
	painel.mostrar_seta = false
	add_child(painel)
	desenho = Control.new()
	desenho.size = Vector2(480, 270)
	desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desenho.draw.connect(_desenhar)
	add_child(desenho)
	for i in GeradorOfertas.OPCOES:
		var d := Label.new()
		d.add_theme_font_override("font", Fontes.texto())
		d.add_theme_font_size_override("font_size", Fontes.TAMANHO_TEXTO)
		d.add_theme_color_override("font_color", COR_TEXTO)
		d.add_theme_constant_override("line_spacing", -1)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.position = Vector2(CARTA_X + 8.0, CARTA_Y + i * CARTA_PASSO + 17.0)
		d.size = Vector2(CARTA_LARGURA - 16.0, 30.0)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		_descricoes.append(d)
	_mostrar(false)


func esta_aberta() -> bool:
	return _aberta


## true quando as 3 opções estão na tela (as falas de antes já acabaram).
func esta_escolhendo() -> bool:
	return _escolhendo


## Abre a oferta. Retorna false se não há nada para oferecer.
func abrir(jogador_: Jogador, catalogo_: CatalogoFaccao, elite: bool = false) -> bool:
	if _aberta or jogador_ == null or catalogo_ == null:
		return false
	jogador = jogador_
	catalogo = catalogo_
	ofertas = GeradorOfertas.gerar(catalogo, jogador.upgrades, rng, Progresso, elite)
	if ofertas.is_empty():
		return false
	_aberta = true
	selecionada = 0
	Progresso.incrementar("ofertas_%s_total" % catalogo.faccao)
	if not get_tree().paused:
		get_tree().paused = true
		_pausou = true
	painel.moldura = catalogo.moldura
	# Falas da patrona: 1ª oferta ou repetição (NAR-01).
	var falas: Array[Dictionary] = []
	_id_cena = catalogo.cena_falas + "_primeira"
	if Dialogos.diretor != null:
		falas = Dialogos.diretor.preparar(_id_cena)
		if falas.is_empty():
			_id_cena = catalogo.cena_falas + "_repeticao"
			falas = Dialogos.diretor.preparar(_id_cena)
	var antes: Array[Dictionary] = []
	_falas_depois.clear()
	for f in falas:
		if String(f.get("direcao", "")).contains("depois da escolha") or not _falas_depois.is_empty():
			_falas_depois.append(f)
		else:
			antes.append(f)
	_falar_e_mostrar(antes)
	return true


func _falar_e_mostrar(antes: Array[Dictionary]) -> void:
	var caixa := _caixa()
	if caixa != null and not antes.is_empty():
		caixa.mostrar(_id_cena, antes, "conversa", Dialogos.banco)
		await caixa.terminou
	_mostrar_opcoes()


func _mostrar_opcoes() -> void:
	_escolhendo = true
	_trava = 0.2
	_mostrar(true)
	_atualizar_textos()


## Pega a opção `indice`. Retorna o upgrade pego.
func escolher(indice: int) -> DadosUpgrade:
	if not _escolhendo or indice < 0 or indice >= ofertas.size():
		return null
	_escolhendo = false
	var u: DadosUpgrade = ofertas[indice]
	var tinha_outra: bool = _tem_outra_faccao(u.faccao)
	var antigo: DadosUpgrade = jogador.receber_upgrade(u)
	_mostrar(false)
	escolheu.emit(u, antigo)
	_falas_finais(tinha_outra)
	return u


func _falas_finais(dual: bool) -> void:
	var caixa := _caixa()
	if caixa != null and not _falas_depois.is_empty():
		caixa.mostrar(_id_cena, _falas_depois, "conversa", Dialogos.banco)
		await caixa.terminou
	# 1ª vez com dádivas das duas facções (NAR-01, DUAL_*).
	if dual and caixa != null and Dialogos.tocar("dual"):
		await caixa.terminou
	_fechar()


func _tem_outra_faccao(faccao: StringName) -> bool:
	for u in jogador.upgrades.todos():
		if u.faccao != faccao and u.faccao != &"":
			return true
	return false


func _fechar() -> void:
	_aberta = false
	_escolhendo = false
	_mostrar(false)
	if _pausou:
		get_tree().paused = false
		_pausou = false
	fechou.emit()


func _caixa() -> CaixaDialogo:
	return get_tree().get_first_node_in_group("caixa_dialogo") as CaixaDialogo


## Recalibrar (GD-01 §9.2): sorteia as 3 opções de novo, gastando 1 reroll da run.
func recalibrar() -> bool:
	if not _escolhendo or jogador.rerolls <= 0:
		return false
	var novas: Array[DadosUpgrade] = GeradorOfertas.gerar(catalogo, jogador.upgrades, rng, Progresso)
	if novas.is_empty():
		return false
	jogador.rerolls -= 1
	ofertas = novas
	selecionada = 0
	_mostrar(true)
	_atualizar_textos()
	return true


## Upgrade que esta opção substituiria (mesmo slot; Passivos acumulam).
func substituiria(u: DadosUpgrade) -> DadosUpgrade:
	if u.slot == DadosUpgrade.Slot.PASSIVO:
		return null
	return jogador.upgrades.no_slot(u.slot)


func _mostrar(sim: bool) -> void:
	escurecer.visible = sim
	painel.visible = sim
	desenho.visible = sim
	for d in _descricoes:
		d.visible = false
	if sim:
		for i in ofertas.size():
			_descricoes[i].visible = true


func _atualizar_textos() -> void:
	for i in ofertas.size():
		_descricoes[i].text = ofertas[i].texto()


func _process(delta: float) -> void:
	if not _escolhendo:
		return
	_trava = maxf(_trava - delta, 0.0)
	desenho.queue_redraw()
	var direcao: Vector2i
	var pegar: bool
	var reroll: bool = false
	if entrada != null:
		entrada.atualizar()
		direcao = entrada.direcao
		pegar = entrada.atirar_pressionado or entrada.interagir_pressionado
		reroll = entrada.pular_pressionado
		entrada.fim_do_frame()
	else:
		direcao = Vector2i(0, roundi(Input.get_axis("mirar_cima", "mirar_baixo")))
		pegar = Input.is_action_just_pressed("atirar") or Input.is_action_just_pressed("interagir")
	var novo: int = direcao.y if direcao != _direcao_anterior else 0
	_direcao_anterior = direcao
	if _trava > 0.0:
		return
	if novo != 0:
		selecionada = wrapi(selecionada + novo, 0, ofertas.size())
	if reroll:
		recalibrar()
	elif pegar:
		escolher(selecionada)


func _desenhar() -> void:
	var c: Control = desenho
	var fonte: Font = Fontes.texto()
	var pequena: Font = Fontes.pequena()
	c.draw_string(fonte, Vector2(PAINEL.position.x + 14.0, 34.0), "DÁDIVA · " + catalogo.nome.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO, catalogo.cor)
	c.draw_string(pequena, Vector2(PAINEL.end.x - 214.0, 34.0), "Escolha 1",
			HORIZONTAL_ALIGNMENT_RIGHT, 200, Fontes.TAMANHO_PEQUENA, COR_APAGADO)
	for i in ofertas.size():
		var u: DadosUpgrade = ofertas[i]
		var r := Rect2(CARTA_X, CARTA_Y + i * CARTA_PASSO, CARTA_LARGURA, CARTA_ALTURA)
		var escolhida: bool = i == selecionada
		c.draw_rect(r, Color(1, 1, 1, 0.06) if escolhida else Color(0, 0, 0, 0.25))
		if escolhida:
			c.draw_rect(r.grow(1.0), catalogo.cor, false, 1.0)
			c.draw_rect(Rect2(r.position.x - 6.0, r.position.y + r.size.y * 0.5 - 3.0, 3, 6), catalogo.cor)
		var y: float = r.position.y + 13.0
		c.draw_string(pequena, Vector2(r.position.x + 8.0, y), DadosUpgrade.NOMES_SLOT[u.slot].to_upper(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_APAGADO)
		c.draw_string(fonte, Vector2(r.position.x + 70.0, y), u.nome, HORIZONTAL_ALIGNMENT_LEFT, -1,
				Fontes.TAMANHO_TEXTO, CORES_RARIDADE[u.raridade])
		c.draw_string(pequena, Vector2(r.end.x - 108.0, y), DadosUpgrade.NOMES_RARIDADE[u.raridade],
				HORIZONTAL_ALIGNMENT_RIGHT, 100, Fontes.TAMANHO_PEQUENA, CORES_RARIDADE[u.raridade])
		var antigo: DadosUpgrade = substituiria(u)
		if antigo != null:
			c.draw_string(pequena, Vector2(r.position.x + 8.0, r.end.y - 3.0), "Substitui: " + antigo.nome,
					HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_SUBSTITUI)
	c.draw_string(pequena, Vector2(PAINEL.position.x + 14.0, PAINEL.end.y - 15.0),
			"Setas: escolher · Atirar ou E: pegar a dádiva" + ("  ·  Pular: recalibrar (%d)" % jogador.rerolls if jogador.rerolls > 0 else ""),
			HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_APAGADO)
