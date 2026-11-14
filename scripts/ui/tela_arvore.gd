class_name TelaArvore
extends CanvasLayer
## Tela da mini árvore da arma (GD-05 §2, layout do mockup v03 da ART, moldura humana pela D-047).
## Abre ao ganhar um Ponto de Aprimoramento (jogo pausado) ou pela tecla da árvore fora de combate.
## Setas escolhem o nó; Atirar ou Interagir compra; Pular ou a tecla da árvore fecha e guarda os pontos.

signal fechou

const PASTA: String = "res://assets/sprites/ui/arvore/"
const PAINEL: Rect2 = Rect2(40, 18, 400, 236)
const COLUNAS: Array[float] = [130.0, 240.0, 350.0]
const LINHAS: Array[float] = [90.0, 129.0, 168.0]
const COR_TITULO: Color = Color("e8742c")
const COR_TEXTO: Color = Color("eceff4")
const COR_APAGADO: Color = Color("6b6f7a")
const COR_BLOQUEADO: Color = Color("3f4250")
const COR_COMPRADO: Color = Color("e8742c")

var entrada: EntradaJogador
var jogador: Jogador
## Nó escolhido.
var ramo: int = 0
var nivel: int = 0

var escurecer: ColorRect
var painel: MolduraDialogo
var desenho: Control
var descricao: Label
var mensagem: String = ""

var _no: Texture2D = FolhaSprite.carregar(PASTA + "no.png")
var _no_apice: Texture2D = FolhaSprite.carregar(PASTA + "no_apice.png")
var _destaque: Texture2D = FolhaSprite.carregar(PASTA + "destaque.png")
var _destaque_apice: Texture2D = FolhaSprite.carregar(PASTA + "destaque_apice.png")
var _conector: Texture2D = FolhaSprite.carregar(PASTA + "conector.png")
var _custo: Texture2D = FolhaSprite.carregar(PASTA + "custo.png")
var _ponto: Texture2D = FolhaSprite.carregar(PASTA + "ponto_aprimoramento.png")
var _aberta: bool = false
var _pausou: bool = false
var _direcao_anterior: Vector2i = Vector2i.ZERO
var _trava: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	escurecer = ColorRect.new()
	escurecer.color = Color(0.03, 0.02, 0.05, 0.7)
	escurecer.size = Vector2(480, 270)
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escurecer)
	painel = MolduraDialogo.new()
	painel.moldura = "humano"
	painel.mostrar_seta = false
	painel.position = PAINEL.position
	painel.size = PAINEL.size
	add_child(painel)
	desenho = Control.new()
	desenho.size = Vector2(480, 270)
	desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desenho.draw.connect(_desenhar)
	add_child(desenho)
	descricao = Label.new()
	descricao.add_theme_font_override("font", Fontes.texto())
	descricao.add_theme_font_size_override("font_size", Fontes.TAMANHO_TEXTO)
	descricao.add_theme_color_override("font_color", COR_TEXTO)
	descricao.add_theme_constant_override("line_spacing", 0)
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.position = Vector2(PAINEL.position.x + 14.0, 200.0)
	descricao.size = Vector2(PAINEL.size.x - 28.0, 30.0)
	descricao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(descricao)
	_mostrar(false)


func esta_aberta() -> bool:
	return _aberta


func abrir(jogador_: Jogador) -> void:
	jogador = jogador_
	if jogador == null or jogador.arvore == null or jogador.arvore.dados() == null:
		return
	_aberta = true
	_trava = 0.2
	mensagem = ""
	_escolher_primeiro_disponivel()
	_mostrar(true)
	if not get_tree().paused:
		get_tree().paused = true
		_pausou = true
	_atualizar_descricao()


func fechar() -> void:
	if not _aberta:
		return
	_aberta = false
	_mostrar(false)
	if _pausou:
		get_tree().paused = false
		_pausou = false
	fechou.emit()


func selecionar(ramo_: int, nivel_: int) -> void:
	ramo = clampi(ramo_, 0, DadosArvore.RAMOS - 1)
	nivel = clampi(nivel_, 0, DadosArvore.NOS_POR_RAMO - 1)
	mensagem = ""
	_atualizar_descricao()


## Compra o nó escolhido. Retorna true se comprou.
func comprar_selecionado() -> bool:
	var arvore: ArvoreRun = jogador.arvore
	if arvore.comprar(ramo, nivel):
		mensagem = ""
		Progresso.definir_run("usou_arvore")  # a ECO comenta na reconstrução (CAMP_A3)
		if nivel < DadosArvore.NOS_POR_RAMO - 1:
			nivel += 1  # já aponta para o próximo do ramo
		_atualizar_descricao()
		return true
	match arvore.estado(ramo, nivel):
		ArvoreRun.Estado.COMPRADO:
			mensagem = "Já comprado."
		ArvoreRun.Estado.BLOQUEADO:
			mensagem = "Outro Ápice já foi escolhido nesta run."
		ArvoreRun.Estado.TRANCADO:
			mensagem = "Compre os nós de cima primeiro."
		_:
			mensagem = "Pontos insuficientes."
	_atualizar_descricao()
	return false


func _escolher_primeiro_disponivel() -> void:
	for r in DadosArvore.RAMOS:
		var n: int = jogador.arvore.niveis[r]
		if n < DadosArvore.NOS_POR_RAMO and jogador.arvore.pode_comprar(r, n):
			ramo = r
			nivel = n
			return
	nivel = mini(jogador.arvore.niveis[ramo], DadosArvore.NOS_POR_RAMO - 1)


func _mostrar(sim: bool) -> void:
	escurecer.visible = sim
	painel.visible = sim
	desenho.visible = sim
	descricao.visible = sim


func _process(delta: float) -> void:
	if not _aberta:
		return
	_trava = maxf(_trava - delta, 0.0)
	desenho.queue_redraw()
	var direcao: Vector2i
	var comprar: bool
	var sair: bool
	if entrada != null:
		entrada.atualizar()
		direcao = entrada.direcao
		comprar = entrada.atirar_pressionado or entrada.interagir_pressionado
		sair = entrada.pular_pressionado
		entrada.fim_do_frame()
	else:
		direcao = Vector2i(roundi(Input.get_axis("mover_esquerda", "mover_direita")), roundi(Input.get_axis("mirar_cima", "mirar_baixo")))
		comprar = Input.is_action_just_pressed("atirar") or Input.is_action_just_pressed("interagir")
		sair = Input.is_action_just_pressed("pular")
	sair = sair or Input.is_action_just_pressed("arvore")
	var novo: Vector2i = direcao if direcao != _direcao_anterior else Vector2i.ZERO
	_direcao_anterior = direcao
	if _trava > 0.0:
		return
	if novo.x != 0:
		selecionar(wrapi(ramo + novo.x, 0, DadosArvore.RAMOS), nivel)
	elif novo.y != 0:
		selecionar(ramo, nivel + novo.y)
	if comprar:
		comprar_selecionado()
	elif sair:
		fechar()


func _atualizar_descricao() -> void:
	var no: ModificadorArma = jogador.arvore.dados().no(ramo, nivel)
	var texto: String = no.descricao if no != null else ""
	if nivel == DadosArvore.NOS_POR_RAMO - 1:
		texto += " Ápice: só 1 por run."
	if not mensagem.is_empty():
		texto = mensagem
	descricao.text = texto
	descricao.add_theme_color_override("font_color", Color("ff8a6a") if not mensagem.is_empty() else COR_TEXTO)


func _desenhar() -> void:
	var c: Control = desenho
	var arvore: ArvoreRun = jogador.arvore
	var dados: DadosArvore = arvore.dados()
	var base: DadosArma = jogador.arma_equipada.base
	var fonte: Font = Fontes.texto()
	var pequena: Font = Fontes.pequena()
	var t: int = int(Time.get_ticks_msec() / 250.0) % 2
	# Cabeçalho: ícone, nome e assinatura.
	var x: float = PAINEL.position.x + 14.0
	if base.icone != null:
		c.draw_texture(base.icone, Vector2(x, 40.0 - base.icone.get_height() * 0.5))
		x += base.icone.get_width() + 8.0
	c.draw_string(fonte, Vector2(x, 38.0), base.nome.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO, COR_TITULO)
	c.draw_string(fonte, Vector2(x, 52.0), base.assinatura_descricao, HORIZONTAL_ALIGNMENT_LEFT, PAINEL.end.x - x - 50.0, Fontes.TAMANHO_TEXTO, COR_TEXTO)
	# Pontos guardados.
	var px: float = PAINEL.end.x - 16.0
	for i in mini(arvore.pontos, 4):
		px -= 14.0
		if _ponto != null:
			c.draw_texture(_ponto, Vector2(px, 28.0))
	c.draw_string(fonte, Vector2(px - 12.0, 38.0), str(arvore.pontos), HORIZONTAL_ALIGNMENT_RIGHT, 10, Fontes.TAMANHO_TEXTO, COR_TEXTO)
	# Ramos.
	for r in DadosArvore.RAMOS:
		var cx: float = COLUNAS[r]
		c.draw_string(fonte, Vector2(cx - 50.0, 74.0), dados.ramos[r].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 100, Fontes.TAMANHO_TEXTO, COR_TEXTO)
		for n in DadosArvore.NOS_POR_RAMO:
			var cy: float = LINHAS[n]
			var apice: bool = n == DadosArvore.NOS_POR_RAMO - 1
			var estado: ArvoreRun.Estado = arvore.estado(r, n)
			var folha: Texture2D = _no_apice if apice else _no
			var lado: float = 24.0 if apice else 20.0
			# Conector até o próximo nó do ramo.
			if n < DadosArvore.NOS_POR_RAMO - 1 and _conector != null:
				var aceso: int = 1 if estado == ArvoreRun.Estado.COMPRADO else 0
				# Entre o nome deste nó e o topo do próximo (não passa por cima do texto).
				var y0: float = cy + lado * 0.5 + 13.0
				var y1: float = LINHAS[n + 1] - (12.0 if n + 1 == DadosArvore.NOS_POR_RAMO - 1 else 10.0)
				c.draw_texture_rect_region(_conector, Rect2(cx - 2.0, y0, 4.0, y1 - y0), Rect2(aceso * 4.0, 0, 4, 10))
			var canto: Vector2 = Vector2(cx, cy) - Vector2(lado, lado) * 0.5
			if folha != null:
				c.draw_texture_rect_region(folha, Rect2(canto, Vector2(lado, lado)), Rect2(int(estado) * lado, 0, lado, lado))
			else:
				c.draw_rect(Rect2(canto, Vector2(lado, lado)), COR_COMPRADO if estado == ArvoreRun.Estado.COMPRADO else COR_APAGADO, false, 2.0)
			if _custo != null:
				c.draw_texture_rect_region(_custo, Rect2(cx + lado * 0.5 + 4.0, cy - 2.0, 12, 4), Rect2(n * 12.0, 0, 12, 4))
			if r == ramo and n == nivel:
				var destaque: Texture2D = _destaque_apice if apice else _destaque
				var l2: float = lado + 4.0
				if destaque != null:
					c.draw_texture_rect_region(destaque, Rect2(canto - Vector2(2, 2), Vector2(l2, l2)), Rect2(t * l2, 0, l2, l2))
				else:
					c.draw_rect(Rect2(canto - Vector2(2, 2), Vector2(l2, l2)), Color("bff3ff"), false, 1.0)
			var cor: Color = COR_TEXTO
			match estado:
				ArvoreRun.Estado.COMPRADO:
					cor = COR_COMPRADO
				ArvoreRun.Estado.TRANCADO:
					cor = COR_APAGADO
				ArvoreRun.Estado.BLOQUEADO:
					cor = COR_BLOQUEADO
			var no: ModificadorArma = dados.no(r, n)
			var cabe: bool = fonte.get_string_size(no.nome, HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO).x <= 108.0
			c.draw_string(fonte if cabe else pequena, Vector2(cx - 54.0, cy + lado * 0.5 + 11.0), no.nome,
					HORIZONTAL_ALIGNMENT_CENTER, 108, Fontes.TAMANHO_TEXTO if cabe else Fontes.TAMANHO_PEQUENA, cor)
	c.draw_string(pequena, Vector2(PAINEL.position.x + 14.0, PAINEL.end.y - 12.0),
			"Setas: escolher · Atirar ou E: comprar · Pular ou Tab: fechar e guardar os pontos",
			HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA, COR_APAGADO)
