class_name DadosArvore
extends Resource
## Mini árvore de uma arma (D-040, GD-05 §2): 3 ramos com 3 nós cada.
## `nos` em ordem: A1, A2, A3, B1, B2, B3, C1, C2, C3 (o 3º de cada ramo é o Ápice).

const RAMOS: int = 3
const NOS_POR_RAMO: int = 3
## Custo por posição no ramo: nó 1 = 1 ponto, nó 2 = 2, Ápice = 3.
const CUSTOS: Array[int] = [1, 2, 3]

@export var ramos: Array[String] = ["", "", ""]
@export var nos: Array[ModificadorArma] = []


static func indice(ramo: int, nivel: int) -> int:
	return ramo * NOS_POR_RAMO + nivel


static func custo(nivel: int) -> int:
	return CUSTOS[nivel]


func no(ramo: int, nivel: int) -> ModificadorArma:
	var i: int = indice(ramo, nivel)
	return nos[i] if i < nos.size() else null
