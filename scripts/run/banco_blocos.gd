class_name BancoBlocos
extends RefCounted
## Blocos de sala feitos à mão em ASCII (data/salas/blocos_varrek.json), GD-03 §2.2 e §2.3.
## Cada bloco tem 17 linhas; a largura é múltiplo de meia tela (15 tiles).
## Legenda no próprio arquivo: '#' terreno, '=' plataforma, 'o' gancho, 'E' início,
## 'D' porta, 'G'/'S' inimigos colocados à mão, 'L'/'R'/'A'/'F'/'P' pontos de surgimento...

const ARQUIVO_VARREK: String = "res://data/salas/blocos_varrek.json"
const ALTURA: int = 17
const LINHA_CHAO: int = 14
const MEIA_TELA: int = 15
## Tiles livres acima do chão nas bordas.
const LIVRES_NA_BORDA: int = 4
const BURACO_MAXIMO: int = 4
## Teto (terreno com vazio embaixo) só até esta linha.
const TETO_MAIS_BAIXO: int = 6
const SURGIMENTOS: String = "LRAFP"

var blocos: Dictionary = {}  # id -> Dictionary
var legenda: Dictionary = {}


func carregar(caminho: String = ARQUIVO_VARREK) -> Error:
	var texto: String = FileAccess.get_file_as_string(caminho)
	if texto.is_empty():
		return ERR_FILE_NOT_FOUND
	var dados: Variant = JSON.parse_string(texto)
	if typeof(dados) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	legenda = dados.get("legenda", {})
	blocos.clear()
	for b: Dictionary in dados.get("blocos", []):
		blocos[b["id"]] = b
	return OK


func bloco(id: String) -> Dictionary:
	return blocos.get(id, {})


static func largura(b: Dictionary) -> int:
	var linhas: Array = b.get("linhas", [])
	return String(linhas[0]).length() if not linhas.is_empty() else 0


static func celula(b: Dictionary, x: int, y: int) -> String:
	return String(b["linhas"][y])[x]


## Liberado pelos desbloqueios (Rotas de Varrek I e II, GD-03 §3.3)?
static func liberado(b: Dictionary, progresso: DadosProgresso) -> bool:
	var flag: String = b.get("liberado_por", "")
	return flag.is_empty() or (progresso != null and progresso.tem_flag(flag))


## Blocos de um bioma e tipo, liberados e fora de `usados`.
func disponiveis(bioma: String, tipo: String, progresso: DadosProgresso, usados: Array = []) -> Array[String]:
	var lista: Array[String] = []
	for id: String in blocos:
		var b: Dictionary = blocos[id]
		if b["bioma"] == bioma and b["tipo"] == tipo and liberado(b, progresso) and not id in usados:
			lista.append(id)
	lista.sort()
	return lista


## Confere as regras de encaixe do GD-03 §2.2. Retorna a lista de problemas (vazia = válido).
static func validar(b: Dictionary) -> Array[String]:
	var erros: Array[String] = []
	var id: String = b.get("id", "?")
	var linhas: Array = b.get("linhas", [])
	if linhas.size() != ALTURA:
		return ["%s: tem %d linhas (precisa de %d)" % [id, linhas.size(), ALTURA]]
	var w: int = largura(b)
	for l in linhas:
		if String(l).length() != w:
			return ["%s: linhas de tamanhos diferentes" % id]
	if w == 0 or w % MEIA_TELA != 0:
		erros.append("%s: largura %d não é múltiplo de %d" % [id, w, MEIA_TELA])
	for x: int in [0, w - 1]:
		if celula(b, x, LINHA_CHAO) != "#":
			erros.append("%s: sem chão na linha %d na borda x=%d" % [id, LINHA_CHAO, x])
		for y in range(LINHA_CHAO - LIVRES_NA_BORDA, LINHA_CHAO):
			if celula(b, x, y) in ["#", "="]:
				erros.append("%s: borda x=%d sem 4 tiles livres acima do chão" % [id, x])
				break
	# Buracos: só em trechos, até 4 tiles.
	var buraco: int = 0
	for x in w + 1:
		var vazio: bool = x < w and celula(b, x, LINHA_CHAO) != "#"
		if vazio:
			buraco += 1
			continue
		if buraco > 0:
			if b["tipo"] != "trecho":
				erros.append("%s: buraco numa %s (só trechos têm buraco)" % [id, b["tipo"]])
			elif buraco > BURACO_MAXIMO:
				erros.append("%s: buraco de %d tiles (máximo %d)" % [id, buraco, BURACO_MAXIMO])
		buraco = 0
	# Teto: terreno com vazio embaixo só até a linha 6.
	for y in range(TETO_MAIS_BAIXO + 1, LINHA_CHAO):
		for x in w:
			if celula(b, x, y) == "#" and celula(b, x, y + 1) != "#":
				erros.append("%s: teto na linha %d (x=%d)" % [id, y, x])
				return erros
	if b["tipo"] == "arena":
		var tem: bool = false
		for c in SURGIMENTOS:
			for l in linhas:
				tem = tem or String(l).contains(c)
		if not tem:
			erros.append("%s: arena sem pontos de surgimento" % id)
	return erros
