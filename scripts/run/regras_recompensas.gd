class_name RegrasRecompensas
extends RefCounted
## Sorteio das recompensas nas portas de saída (GD-03 §2.6, GD-01 §7.4):
## - salas 1 e 2 (e a sala 0) têm 2 portas; as demais, 3;
## - nunca duas portas com o mesmo tipo de recompensa;
## - garantia de facção: nunca mais de 2 saídas seguidas sem porta Kharn ou Vesh;
## - Aprimoramento de Arma: no máximo 3 por ato, nunca na sala 1, garantida até a sala 5;
## - +1 bloco de vida máximo: no máximo 1 por ato, só a partir da sala 3.

const TIPOS: Array[String] = ["kharn", "vesh", "aprimoramento", "creditos", "nucleos", "dados", "vida_maxima"]
const NOMES: Dictionary = {
	"kharn": "Dádiva Kharn", "vesh": "Dádiva Vesh", "aprimoramento": "Aprimoramento de Arma",
	"creditos": "Créditos", "nucleos": "Núcleos", "dados": "Dados de Inteligência",
	"vida_maxima": "+1 bloco de vida", "chefe": "Ur-Kesh", "seguir": "Seguir",
}


static func quantas_portas(numero: int) -> int:
	return 2 if numero <= 2 else 3


## Sorteia os tipos das portas da saída da sala `numero` e registra no estado.
static func sortear(numero: int, estado: EstadoAto, rng: RandomNumberGenerator, pesos: Dictionary,
		quantas: int = -1, vida_a_partir: int = 3) -> Array[String]:
	if quantas < 0:
		quantas = quantas_portas(numero)
	var portas: Array[String] = []
	if numero == 0 and estado.primeira_run:
		portas.assign(["kharn", "vesh"])  # GD-03 §1.2: garante o 1º upgrade e a 1ª patrona
	else:
		if RegrasPortas.aprimoramento_obrigatorio(numero, estado.aprimoramentos):
			portas.append("aprimoramento")
		if estado.salas_sem_faccao >= 2:
			portas.append("kharn" if rng.randf() < 0.5 else "vesh")
		while portas.size() < quantas:
			var tipo: String = _sortear_tipo(numero, estado, rng, pesos, portas, vida_a_partir)
			if tipo.is_empty():
				break
			portas.append(tipo)
	estado.registrar_portas(portas)
	return portas


static func _sortear_tipo(numero: int, estado: EstadoAto, rng: RandomNumberGenerator, pesos: Dictionary,
		ja: Array[String], vida_a_partir: int) -> String:
	var candidatos: Array[String] = []
	var total: float = 0.0
	for tipo in TIPOS:
		if tipo in ja or not permitido(tipo, numero, estado, vida_a_partir):
			continue
		candidatos.append(tipo)
		total += float(pesos.get(tipo, 1.0))
	var x: float = rng.randf() * total
	for tipo in candidatos:
		x -= float(pesos.get(tipo, 1.0))
		if x <= 0.0:
			return tipo
	return candidatos.back() if not candidatos.is_empty() else ""


static func permitido(tipo: String, numero: int, estado: EstadoAto, vida_a_partir: int = 3) -> bool:
	match tipo:
		"aprimoramento":
			return RegrasPortas.aprimoramento_permitido(numero, estado.aprimoramentos)
		"vida_maxima":
			return numero >= vida_a_partir and not estado.vida_maxima_dada
	return true
