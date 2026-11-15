class_name NumerosDano
extends Node2D
## Números de dano na tela (D-067). Todo acerto mostra o dano por ~0,6 s, subindo um pouco:
## - branco: dano normal;
## - amarelo/laranja e maior: dano forte (ponto fraco, atordoado, golpes de 25+);
## - verde: veneno e efeitos (Ácido);
## - vermelho: dano no Ryker.
## Números do mesmo alvo se somam enquanto o anterior ainda está na tela. No máximo 30 ao mesmo
## tempo (os mais antigos saem). Desligável nas Opções (Config.numeros_dano, padrão ligado).
## Um único nó desenha todos: fica na raiz, no mesmo espaço do mundo (a câmera vale para ele).

enum Tipo { NORMAL, FORTE, EFEITO, JOGADOR }

const NOME: String = "NumerosDano"
const DURACAO: float = 0.6
## Tempo em que um número novo do mesmo alvo ainda se soma ao anterior.
const JANELA_SOMA: float = 0.35
const MAXIMO: int = 30
const SUBIDA_PX: float = 14.0
## A partir deste dano, o número é "forte".
const DANO_FORTE: int = 25
const CORES: Array[Color] = [Color("eceff4"), Color("ffb347"), Color("8fdc5a"), Color("ff4a4a")]
const TAMANHOS: Array[int] = [6, 8, 6, 7]

## {alvo_id, posicao (mundo), valor, tipo, tempo}
var numeros: Array[Dictionary] = []


## Mostra (ou soma) um número de dano sobre `alvo`.
static func mostrar(alvo: Node2D, valor: int, tipo: Tipo = Tipo.NORMAL) -> void:
	if valor <= 0 or alvo == null or not alvo.is_inside_tree():
		return
	var config: Node = alvo.get_tree().root.get_node_or_null("Config")
	if config != null and not config.numeros_dano:
		return
	instancia(alvo.get_tree()).adicionar(alvo, valor, tipo)


static func instancia(arvore: SceneTree) -> NumerosDano:
	var n := arvore.root.get_node_or_null(NOME) as NumerosDano
	if n == null:
		n = NumerosDano.new()
		n.name = NOME
		n.z_index = 100
		n.process_mode = Node.PROCESS_MODE_ALWAYS
		arvore.root.add_child(n)
	return n


static func tipo_do_acerto(dano: int, multiplicador: float) -> Tipo:
	return Tipo.FORTE if dano >= DANO_FORTE or multiplicador >= 1.5 else Tipo.NORMAL


func adicionar(alvo: Node2D, valor: int, tipo: Tipo) -> void:
	var id: int = alvo.get_instance_id()
	var topo: Vector2 = _topo(alvo)
	for n in numeros:
		if n["alvo_id"] == id and (n["tipo"] == Tipo.EFEITO) == (tipo == Tipo.EFEITO) \
				and DURACAO - float(n["tempo"]) < JANELA_SOMA:
			n["valor"] += valor
			n["tempo"] = DURACAO
			n["posicao"] = topo
			if tipo == Tipo.FORTE:
				n["tipo"] = Tipo.FORTE
			queue_redraw()
			return
	numeros.append({"alvo_id": id, "posicao": topo + Vector2(randf_range(-4.0, 4.0), 0.0), "valor": valor,
			"tipo": tipo, "tempo": DURACAO})
	while numeros.size() > MAXIMO:
		numeros.pop_front()
	queue_redraw()


func _topo(alvo: Node2D) -> Vector2:
	var altura: float = 24.0
	if alvo is Inimigo:
		altura = (alvo as Inimigo).tamanho.y
	elif alvo is Jogador:
		altura = 30.0
	return alvo.global_position - Vector2(0.0, altura + 4.0)


func _process(delta: float) -> void:
	if numeros.is_empty():
		return
	for i in range(numeros.size() - 1, -1, -1):
		numeros[i]["tempo"] -= delta
		if numeros[i]["tempo"] <= 0.0:
			numeros.remove_at(i)
	queue_redraw()


func _draw() -> void:
	var fonte: Font = Fontes.placa()
	for n in numeros:
		var t: float = float(n["tempo"]) / DURACAO
		var tipo: int = n["tipo"]
		var tam: int = TAMANHOS[tipo]
		var texto: String = ("-%d" if tipo == Tipo.JOGADOR else "%d") % n["valor"]
		var largura: float = fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var pos: Vector2 = n["posicao"] + Vector2(-largura * 0.5, -SUBIDA_PX * (1.0 - t))
		var cor: Color = CORES[tipo]
		cor.a = clampf(t * 2.5, 0.0, 1.0)
		draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 2, Color(0.05, 0.04, 0.08, cor.a))
		draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
