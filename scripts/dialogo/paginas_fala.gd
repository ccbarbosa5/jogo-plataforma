class_name PaginasFala
## D-063: falas com tamanho padrão e limite.
## Toda caixa de fala usa Fontes.TAMANHO_FALA (8 = 32 px em 1080p) e mostra no máximo 3 linhas.
## Medição (Open Sans, caixa de conversa com 268 de largura): em texto comum do jogo cabem de
## 178 a ~200 caracteres em 3 linhas; o limite gravado na CENTRAL é LIMITE (folga para palavras
## longas e maiúsculas). Fala maior que o limite, ou que passe de 3 linhas, vira 2 ou mais páginas,
## cortando no fim de frase; se não der, na vírgula (ou ; : —); por último entre palavras.
## Nunca no meio da palavra.

## Limite de caracteres por página (D-063). A NAR escreve dentro dele.
const LIMITE: int = 160
## Linhas por página.
const LINHAS: int = 3
## Largura do texto na caixa de conversa (a mais estreita; a rápida é mais larga).
const LARGURA: float = 268.0

const _FIM_FRASE: String = ".!?…"
const _PAUSA: String = ",;:—"
const _FECHA: String = "\"”»)'"


static func linhas(texto: String, largura: float = LARGURA) -> int:
	if texto.is_empty():
		return 0
	var fonte: Font = Fontes.texto()
	var quebra: int = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var altura: float = fonte.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, largura,
			Fontes.TAMANHO_FALA, -1, quebra).y
	return roundi(altura / fonte.get_height(Fontes.TAMANHO_FALA))


static func cabe(texto: String) -> bool:
	return texto.length() <= LIMITE and linhas(texto) <= LINHAS


## Divide uma fala em páginas que cabem na caixa.
static func dividir(texto: String) -> PackedStringArray:
	return PackedStringArray(_dividir(texto.strip_edges(), 0))


static func _dividir(texto: String, nivel: int) -> Array[String]:
	if cabe(texto) or nivel > 2:
		return [texto]
	var pedacos: Array[String] = _cortar(texto, nivel)
	if pedacos.size() <= 1:
		return _dividir(texto, nivel + 1)
	var paginas: Array[String] = []
	var atual: String = ""
	for p in pedacos:
		var junto: String = (atual + " " + p) if not atual.is_empty() else p
		if cabe(junto):
			atual = junto
			continue
		if not atual.is_empty():
			paginas.append(atual)
		if cabe(p):
			atual = p
		else:
			paginas.append_array(_dividir(p, nivel + 1))
			atual = ""
	if not atual.is_empty():
		paginas.append(atual)
	return paginas


## nível 0 = frases; 1 = vírgulas e pausas; 2 = palavras.
static func _cortar(texto: String, nivel: int) -> Array[String]:
	var saida: Array[String] = []
	if nivel >= 2:
		for p in texto.split(" ", false):
			saida.append(p)
		return saida
	var marcas: String = _FIM_FRASE if nivel == 0 else _PAUSA
	var inicio: int = 0
	var i: int = 0
	while i < texto.length():
		if marcas.contains(texto[i]):
			var fim: int = i + 1
			while fim < texto.length() and (marcas.contains(texto[fim]) or _FECHA.contains(texto[fim])):
				fim += 1
			if fim < texto.length() and texto[fim] == " ":
				var p: String = texto.substr(inicio, fim - inicio).strip_edges()
				if not p.is_empty():
					saida.append(p)
				inicio = fim + 1
			i = fim
		else:
			i += 1
	var resto: String = texto.substr(inicio).strip_edges()
	if not resto.is_empty():
		saida.append(resto)
	return saida


## Transforma a lista de falas em páginas (cada página é uma cópia da fala com o texto cortado).
## A direção de cena fica só na primeira página.
static func paginar(falas: Array[Dictionary]) -> Array[Dictionary]:
	var saida: Array[Dictionary] = []
	for fala in falas:
		var campo: String = "texto" if not String(fala.get("falante", "")).is_empty() else "direcao"
		var paginas: PackedStringArray = dividir(String(fala.get(campo, "")))
		if paginas.size() <= 1:
			saida.append(fala)
			continue
		for i in paginas.size():
			var copia: Dictionary = fala.duplicate()
			copia[campo] = paginas[i]
			copia["pagina"] = i + 1
			copia["paginas"] = paginas.size()
			if i > 0 and campo == "texto":
				copia.erase("direcao")
			saida.append(copia)
	return saida
