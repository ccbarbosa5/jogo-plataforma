class_name RegrasPortas
extends RefCounted
## Quando a porta "Aprimoramento de Arma" pode aparecer (GD-05 §2.2, GD-03 §2.6):
## no máximo 3 por ato, nunca na sala 1, e uma garantida até a sala 5.
## O gerador de salas (Fase 2) consulta estas funções ao sortear as portas.

const MAXIMO_POR_ATO: int = 3
const SALA_GARANTIA: int = 5


## `sala`: número da sala no ato (1 = primeira). `ja_no_ato`: portas de Aprimoramento já oferecidas.
static func aprimoramento_permitido(sala: int, ja_no_ato: int) -> bool:
	return sala > 1 and ja_no_ato < MAXIMO_POR_ATO


## true quando esta sala TEM de oferecer a porta (garantia até a sala 5).
static func aprimoramento_obrigatorio(sala: int, ja_no_ato: int) -> bool:
	return ja_no_ato == 0 and sala >= SALA_GARANTIA
