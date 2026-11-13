class_name DadosProgresso
extends Node
## Progresso permanente: flags e contadores que sobrevivem à morte e ao fechar o jogo
## (NAR-01: "1ª vez", mortes_total, urkesh_encontros...). Salvo em user://progresso.cfg.
## O autoload "Progresso" é uma instância desta classe; os testes criam a sua própria.

signal mudou

const CAMINHO_PADRAO: String = "user://progresso.cfg"

var caminho: String = CAMINHO_PADRAO
var flags: Dictionary = {}
var contadores: Dictionary = {}


func _ready() -> void:
	carregar()


func tem_flag(nome: String) -> bool:
	return flags.get(nome, false)


func definir_flag(nome: String, valor: bool = true) -> void:
	flags[nome] = valor
	mudou.emit()


func valor(nome: String) -> int:
	return contadores.get(nome, 0)


func incrementar(nome: String, quantidade: int = 1) -> int:
	contadores[nome] = valor(nome) + quantidade
	mudou.emit()
	return contadores[nome]


## Condições usadas no arquivo de diálogos:
##   "flag"        → a flag está ligada
##   "!flag"       → a flag está desligada
##   "contador>=3" → também aceita >, <, <=, ==, !=
##   "a e b"       → todas as partes precisam ser verdadeiras
func avaliar(condicao: String) -> bool:
	if condicao.strip_edges().is_empty():
		return true
	for parte in condicao.split(" e "):
		if not _avaliar_parte(parte.strip_edges()):
			return false
	return true


func _avaliar_parte(parte: String) -> bool:
	for operador: String in [">=", "<=", "==", "!=", ">", "<"]:
		var i: int = parte.find(operador)
		if i > 0:
			var esquerda: int = valor(parte.substr(0, i).strip_edges())
			var direita: int = parte.substr(i + operador.length()).strip_edges().to_int()
			match operador:
				">=": return esquerda >= direita
				"<=": return esquerda <= direita
				"==": return esquerda == direita
				"!=": return esquerda != direita
				">": return esquerda > direita
				"<": return esquerda < direita
	if parte.begins_with("!"):
		return not tem_flag(parte.substr(1))
	return tem_flag(parte)


func salvar() -> Error:
	var arquivo := ConfigFile.new()
	for nome: String in flags:
		arquivo.set_value("flags", nome, flags[nome])
	for nome: String in contadores:
		arquivo.set_value("contadores", nome, contadores[nome])
	return arquivo.save(caminho)


func carregar() -> void:
	flags.clear()
	contadores.clear()
	var arquivo := ConfigFile.new()
	if arquivo.load(caminho) != OK:
		return
	if arquivo.has_section("flags"):
		for nome in arquivo.get_section_keys("flags"):
			flags[nome] = arquivo.get_value("flags", nome)
	if arquivo.has_section("contadores"):
		for nome in arquivo.get_section_keys("contadores"):
			contadores[nome] = arquivo.get_value("contadores", nome)


## Apaga tudo (novo jogo / atalho de depuração).
func apagar() -> void:
	flags.clear()
	contadores.clear()
	salvar()
	mudou.emit()
