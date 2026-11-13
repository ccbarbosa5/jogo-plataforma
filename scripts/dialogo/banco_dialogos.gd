class_name BancoDialogos
extends RefCounted
## Lê o arquivo de diálogos (data/dialogos/*.json), que é a cópia jogável do NAR-01.
## A NAR é dona do texto; o DEV atualiza o arquivo quando o NAR-01 muda.
##
## Formato:
## {
##   "falantes": { "RYKER": { "nome": "Ryker", "cor": "#c8b273" } },
##   "cenas": {
##     "<cena>": {
##       "modo": "conversa" | "rapida",   conversa pausa o jogo; rápida aparece por cima
##       "uma_vez": "<flag>",             toca só se a flag estiver desligada, e liga ao tocar
##       "condicao": "<condição>",        ver DadosProgresso.avaliar()
##       "duvida": 1,                     soma no contador "duvida" ao tocar (pistas, D-034)
##       "prioridade": [ { "condicao", "uma_vez", "duvida", "falas" } ],  a 1ª que valer toca; senão:
##       "falas": [ fala... ]             sequência fixa, OU
##       "sortear": true, "variantes": [ [fala...], [fala...] ]   sorteia uma, sem repetir a anterior
##     }
##   }
## }
## falante = { "nome" (o que aparece na placa, D-046), "cor", "moldura": humano|humano_danificada|eco|kharn|vesh|ilo,
##             "lado": esquerda|direita, "expressoes": [...] (a 1ª é a padrão), "retrato": retrato|estatica }
## fala = { "id": "ABER_01", "falante": "ECO", "texto": "...", "direcao": "...", "condicao": "...",
##          "expressao": "neutro", "aud": "zumbido" }
## "direcao" guarda a direção de cena (os [colchetes] do NAR-01): não é falada.
## "aud": marcação para o Áudio (ex.: o zumbido de colmeia na voz da ECO).

## Molduras por personagem ou facção (D-032).
const MOLDURAS: Array[String] = ["humano", "humano_danificada", "eco", "kharn", "vesh", "ilo", "antigos"]

var falantes: Dictionary = {}
var cenas: Dictionary = {}
var caminho: String = ""


func carregar(caminho_arquivo: String) -> Error:
	caminho = caminho_arquivo
	var texto: String = FileAccess.get_file_as_string(caminho_arquivo)
	if texto.is_empty():
		return ERR_FILE_NOT_FOUND
	var dados: Variant = JSON.parse_string(texto)
	if not dados is Dictionary:
		return ERR_PARSE_ERROR
	falantes = dados.get("falantes", {})
	cenas = dados.get("cenas", {})
	return OK


func tem_cena(id: String) -> bool:
	return cenas.has(id)


func cena(id: String) -> Dictionary:
	return cenas.get(id, {})


func nome_do_falante(codigo: String) -> String:
	return falantes.get(codigo, {}).get("nome", codigo)


func cor_do_falante(codigo: String) -> Color:
	return Color.from_string(falantes.get(codigo, {}).get("cor", "#ffffff"), Color.WHITE)


## Expressões do retrato, na ordem dos quadros da folha da ART (a 1ª é a padrão).
func expressoes_do_falante(codigo: String) -> Array:
	return falantes.get(codigo, {}).get("expressoes", [])


## "retrato" (padrão) ou "estatica" (SINAL e REGISTRO não têm retrato).
func retrato_do_falante(codigo: String) -> String:
	return falantes.get(codigo, {}).get("retrato", "retrato")


func moldura_do_falante(codigo: String) -> String:
	return falantes.get(codigo, {}).get("moldura", "humano")


## "esquerda" para os personagens jogáveis; "direita" para o interlocutor (D-032).
func lado_do_falante(codigo: String) -> String:
	return falantes.get(codigo, {}).get("lado", "direita")


## Todas as falas de uma cena (de todas as variantes).
func todas_as_falas(id_cena: String) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var c: Dictionary = cena(id_cena)
	for fala: Dictionary in c.get("falas", []):
		lista.append(fala)
	for variante: Array in c.get("variantes", []):
		for fala: Dictionary in variante:
			lista.append(fala)
	for entrada: Dictionary in c.get("prioridade", []):
		for fala: Dictionary in entrada.get("falas", []):
			lista.append(fala)
	return lista


## Confere o arquivo: IDs repetidos, falantes desconhecidos, cenas vazias, modos inválidos.
## Retorna a lista de problemas (vazia = tudo certo). Usado pelos testes automáticos.
func validar() -> Array[String]:
	var problemas: Array[String] = []
	var ids: Dictionary = {}
	for id_cena: String in cenas:
		var c: Dictionary = cenas[id_cena]
		if not c.get("modo", "conversa") in ["conversa", "rapida"]:
			problemas.append("%s: modo inválido" % id_cena)
		var tem_falas: bool = not c.get("falas", []).is_empty()
		var tem_variantes: bool = not c.get("variantes", []).is_empty()
		if tem_falas and tem_variantes:
			problemas.append("%s: 'falas' e 'variantes' ao mesmo tempo" % id_cena)
		if not tem_falas and not tem_variantes and c.get("prioridade", []).is_empty():
			problemas.append("%s: cena vazia" % id_cena)
		for entrada: Dictionary in c.get("prioridade", []):
			if entrada.get("falas", []).is_empty():
				problemas.append("%s: entrada de prioridade sem falas" % id_cena)
		if tem_variantes and not c.get("sortear", false):
			problemas.append("%s: 'variantes' sem 'sortear'" % id_cena)
		for fala in todas_as_falas(id_cena):
			var id_fala: String = fala.get("id", "")
			if id_fala.is_empty():
				problemas.append("%s: fala sem id" % id_cena)
			elif ids.has(id_fala):
				problemas.append("%s: id repetido %s" % [id_cena, id_fala])
			ids[id_fala] = true
			var falante: String = fala.get("falante", "")
			if not falante.is_empty() and not falantes.has(falante):
				problemas.append("%s: falante desconhecido %s" % [id_fala, falante])
			if falante.is_empty() and fala.get("direcao", "").is_empty():
				problemas.append("%s: fala sem falante e sem direção" % id_fala)
			if "[" in fala.get("texto", "") or "`" in fala.get("texto", ""):
				problemas.append("%s: direção de cena ou marcação dentro do texto" % id_fala)
	for codigo: String in falantes:
		var f: Dictionary = falantes[codigo]
		if not f.get("lado", "direita") in ["esquerda", "direita"]:
			problemas.append("falante %s: lado inválido" % codigo)
		if not f.get("moldura", "humano") in MOLDURAS:
			problemas.append("falante %s: moldura desconhecida" % codigo)
	return problemas
