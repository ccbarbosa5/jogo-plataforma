class_name LojaArena
extends CanvasLayer
## Loja do Ilo entre as ondas (GD-09 §7): 4 ofertas (armas e itens), reroll, cadeado e "Pronto".
## Comprar e rerolar gastam a Sucata da arena; a arma vai para o inventário do Ryker e o item soma
## os atributos dele. Uma oferta travada continua na próxima loja.

signal terminou

const NOMES_NIVEL: Array[String] = ["I", "II", "III", "IV"]
const TELA: Vector2 = Vector2(480, 270)

var arena: ArenaJogo
var onda: int = 1
## Cada oferta: {"tipo": "arma"|"item", "id": String, "nivel": int (1..4), "preco": int,
## "vendida": bool, "travada": bool}
var ofertas: Array[Dictionary] = []
var rerolls: int = 0
var rng := RandomNumberGenerator.new()

var _dados: Dictionary = ConfigArena.secao("loja")
var _raiz: Control
var _rotulo: Label
var _botoes: Array[Button] = []
var _cadeados: Array[Button] = []
var _botao_reroll: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	visible = false


## Abre a loja depois da onda `onda_` (1, 2, ...).
func abrir(onda_: int) -> void:
	onda = onda_
	rerolls = 0
	sortear_ofertas()
	visible = true
	_atualizar()
	_botoes[0].grab_focus.call_deferred()


func fechar() -> void:
	visible = false
	terminou.emit()


static func preco(nivel: int, onda_: int) -> int:
	var base: Array = ConfigArena.secao("niveis_arma")["preco_base"]
	var aumento: float = float(ConfigArena.secao("loja")["aumento_preco_por_onda"])
	return roundi(float(base[nivel - 1]) * (1.0 + aumento * (onda_ - 1)))


## Ilo com 4 armas: as primeiras trocas de cada loja são grátis (GD-09 §5.3).
func custo_reroll() -> int:
	var gratis: int = int(arena.jogador.atributos.valor("reroll_gratis")) if arena != null else 0
	return 0 if rerolls < gratis else 1 + onda + rerolls - gratis


static func preco_item(raridade: int, onda_: int) -> int:
	var base: Array = ConfigArena.secao("loja")["preco_item_base"]
	var aumento: float = float(ConfigArena.secao("loja")["aumento_preco_por_onda"])
	return roundi(float(base[raridade - 1]) * (1.0 + aumento * (onda_ - 1)))


## Chance de cada nível (I..IV) na onda: vai em linha reta da onda 1 à onda 20. A Sorte soma
## 1/3 de ponto em cada uma das três melhores por ponto.
static func chances(onda_: int, sorte: float = 0.0) -> Array[float]:
	var d: Dictionary = ConfigArena.secao("loja")
	var inicio: Array = d["raridade_onda_1"]
	var fim: Array = d["raridade_onda_20"]
	var t: float = clampf((onda_ - 1) / 19.0, 0.0, 1.0)
	var lista: Array[float] = []
	for i in 4:
		lista.append(lerpf(float(inicio[i]), float(fim[i]), t))
	for i in range(1, 4):
		lista[i] += sorte / 3.0
	if onda_ < int(d["lendaria_a_partir_da_onda"]):
		lista[3] = 0.0
	return lista


func sortear_ofertas() -> void:
	var antigas: Array[Dictionary] = ofertas.duplicate()
	ofertas.clear()
	var sorte: float = arena.jogador.atributos.valor("sorte") if arena != null else 0.0
	var pesos := PackedFloat32Array(chances(onda, sorte))
	for i in int(_dados["ofertas"]):
		# A oferta travada (e não vendida) fica no mesmo lugar, com o preço da onda nova.
		if i < antigas.size() and antigas[i].get("travada", false) and not antigas[i]["vendida"]:
			var o: Dictionary = antigas[i]
			o["preco"] = preco(o["nivel"], onda) if o["tipo"] == "arma" else preco_item(o["nivel"], onda)
			ofertas.append(o)
			continue
		var nivel: int = rng.rand_weighted(pesos) + 1
		if rng.randi() % 100 < int(_dados["chance_arma"]):
			var armas: Array = ConfigArena.secao("armas").keys()
			ofertas.append(_oferta("arma", armas[rng.randi() % armas.size()], nivel, preco(nivel, onda)))
		else:
			var item: String = sortear_item(nivel)
			nivel = int(ConfigArena.secao("itens")[item]["raridade"])
			ofertas.append(_oferta("item", item, nivel, preco_item(nivel, onda)))


func _oferta(tipo: String, id: String, nivel: int, valor: int) -> Dictionary:
	return {"tipo": tipo, "id": id, "nivel": nivel, "preco": valor, "vendida": false, "travada": false}


## Um item da raridade pedida (ou da mais perto abaixo dela).
func sortear_item(raridade: int) -> String:
	var itens: Dictionary = ConfigArena.secao("itens")
	for r in range(raridade, 0, -1):
		var lista: Array = itens.keys().filter(func(k: String) -> bool: return int(itens[k]["raridade"]) == r)
		if not lista.is_empty():
			return lista[rng.randi() % lista.size()]
	return itens.keys()[rng.randi() % itens.size()]


func travar(i: int) -> void:
	if i < ofertas.size() and not ofertas[i]["vendida"]:
		ofertas[i]["travada"] = not ofertas[i].get("travada", false)
		_atualizar()


func pode_comprar(i: int) -> bool:
	var o: Dictionary = ofertas[i]
	if o["vendida"] or arena.sucata < int(o["preco"]):
		return false
	return o.get("tipo", "arma") != "arma" or arena.jogador.inventario.pode_receber(String(o["id"]), int(o["nivel"]))


func comprar(i: int) -> bool:
	if not pode_comprar(i):
		return false
	var o: Dictionary = ofertas[i]
	arena.gastar_sucata(int(o["preco"]))
	if o.get("tipo", "arma") == "arma":
		arena.jogador.adicionar_arma(String(o["id"]), int(o["nivel"]))
	else:
		arena.jogador.aplicar_efeitos(ConfigArena.secao("itens")[o["id"]]["efeitos"])
	o["vendida"] = true
	o["travada"] = false
	_atualizar()
	return true


func rerolar() -> bool:
	var custo: int = custo_reroll()
	if arena.sucata < custo:
		return false
	arena.gastar_sucata(custo)
	rerolls += 1
	sortear_ofertas()
	_atualizar()
	return true


func _montar() -> void:
	_raiz = Control.new()
	_raiz.size = TELA
	_raiz.theme = EstiloMenu.tema()
	add_child(_raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.05, 0.8)
	fundo.size = TELA
	_raiz.add_child(fundo)
	var titulo := Label.new()
	titulo.text = "LOJA DO ILO"
	titulo.add_theme_font_override("font", Fontes.placa())
	titulo.add_theme_font_size_override("font_size", Fontes.TAMANHO_TITULO)
	titulo.position = Vector2(20, 16)
	_raiz.add_child(titulo)
	_rotulo = Label.new()
	_rotulo.add_theme_font_size_override("font_size", Fontes.TAMANHO_TEXTO)
	_rotulo.position = Vector2(20, 36)
	_raiz.add_child(_rotulo)
	for i in int(_dados["ofertas"]):
		var ret := Rect2(20 + i * 112, 70, 104, 60)
		_botoes.append(EstiloMenu.botao(_raiz, "", ret, func() -> void: comprar(i), Fontes.TAMANHO_TEXTO))
		_cadeados.append(EstiloMenu.botao(_raiz, "", Rect2(ret.position.x, 134, 104, 14), func() -> void: travar(i), Fontes.TAMANHO_TEXTO))
	_botao_reroll = EstiloMenu.botao(_raiz, "", Rect2(20, 220, 140, 16), func() -> void: rerolar())
	EstiloMenu.botao(_raiz, "Pronto", Rect2(360, 220, 100, 16), fechar)


func _atualizar() -> void:
	if arena == null:
		return
	_rotulo.text = "Sucata: %d    Onda %d terminada    Armas: %d/%d    %s" % [
		arena.sucata, onda, arena.jogador.inventario.armas.size(), arena.jogador.inventario.slots,
		texto_das_familias(arena.jogador.inventario.armas)]
	for i in _botoes.size():
		var b: Button = _botoes[i]
		if i >= ofertas.size():
			b.visible = false
			continue
		var o: Dictionary = ofertas[i]
		var arma: bool = o.get("tipo", "arma") == "arma"
		var nome: String = String((ConfigArena.arma(o["id"]) if arma else ConfigArena.secao("itens")[o["id"]])["nome"])
		var detalhe: String = NOMES_NIVEL[int(o["nivel"]) - 1] if arma else _efeitos_em_texto(o["id"])
		var etiqueta: String = "(%s)" % ConfigArena.secao("familias")[ConfigArena.arma(o["id"])["familia"]]["nome"] if arma else ""
		b.text = "Vendida" if o["vendida"] else "%s %s\n%s\n%d Sucata" % [nome, etiqueta, detalhe, o["preco"]]
		b.add_theme_color_override("font_color", TelaNivelArena.CORES_RARIDADE[int(o["nivel"]) - 1])
		b.disabled = not pode_comprar(i)
		_cadeados[i].visible = not o["vendida"]
		_cadeados[i].text = "Travada" if o.get("travada", false) else "Travar"
	_botao_reroll.text = "Trocar ofertas (%d)" % custo_reroll()
	_botao_reroll.disabled = arena.sucata < custo_reroll()


static func _efeitos_em_texto(id: String) -> String:
	var partes: Array[String] = []
	var efeitos: Dictionary = ConfigArena.secao("itens")[id]["efeitos"]
	for k in efeitos:
		var nome: String = String(ConfigArena.secao("atributos").get(k, {"nome": "Sucata %"})["nome"])
		partes.append("%s %+d" % [nome, int(efeitos[k])])
	return ", ".join(partes)


## "Famílias: Arena 2 · Vesh 1" (armas diferentes de cada família; 2+ dá bônus).
static func texto_das_familias(armas: Array[Dictionary]) -> String:
	var contagem: Dictionary = {}
	var vistos: Dictionary = {}
	for item in armas:
		if vistos.has(item["id"]):
			continue
		vistos[item["id"]] = true
		var f: String = ConfigArena.arma(item["id"])["familia"]
		contagem[f] = int(contagem.get(f, 0)) + 1
	var partes: Array[String] = []
	for f in contagem:
		partes.append("%s %d" % [ConfigArena.secao("familias")[f]["nome"], contagem[f]])
	return "Famílias: " + " · ".join(partes)
