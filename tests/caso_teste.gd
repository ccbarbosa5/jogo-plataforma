class_name TestCase
extends Node
## Base para os testes. Crie tests/<area>/test_<nome>.gd estendendo TestCase
## e escreva métodos "func test_algo() -> void:". Métodos podem usar await
## (por exemplo, await esperar_frames(10)) para testar física e movimento.

var tree: SceneTree
var falhas: Array[String] = []


func afirmar(condicao: bool, mensagem: String = "condição falsa") -> void:
	if not condicao:
		falhas.append(mensagem)


func afirmar_igual(obtido: Variant, esperado: Variant, mensagem: String = "") -> void:
	if obtido != esperado:
		falhas.append("%s esperado=%s obtido=%s" % [mensagem, str(esperado), str(obtido)])


func afirmar_proximo(obtido: float, esperado: float, tolerancia: float = 0.01, mensagem: String = "") -> void:
	if absf(obtido - esperado) > tolerancia:
		falhas.append("%s esperado≈%s obtido=%s" % [mensagem, str(esperado), str(obtido)])


## Instancia uma cena dentro do teste (é liberada junto com o teste).
func instanciar(caminho_cena: String) -> Node:
	var cena: PackedScene = load(caminho_cena)
	if cena == null:
		falhas.append("cena não encontrada: %s" % caminho_cena)
		return null
	var no := cena.instantiate()
	add_child(no)
	return no


func esperar_frames(n: int) -> void:
	for i in n:
		await tree.physics_frame
