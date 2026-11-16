class_name Codice
## Códice (D-060, NAR-05 §5): o livro de registros consultado na nave. Cada entrada destrava
## quando o jogador encontra a coisa pela primeira vez; algumas ganham um parágrafo extra
## depois (ex.: 10 runs com a arma). Os textos ficam em data/codice.json.

const ARQUIVO: String = "res://data/codice.json"


static func carregar() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	if d is Dictionary:
		for e: Dictionary in (d as Dictionary).get("entradas", []):
			lista.append(e)
	return lista


## Entradas prontas para a tela: {id, grupo, nome, titulo, liberada, texto, extra, aviso}.
## "extra" = parágrafo extra já destravado; "aviso" = como destravar o extra que falta.
static func entradas(progresso: DadosProgresso) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for e in carregar():
		var liberada: bool = progresso.avaliar(String(e.get("condicao", "")))
		var extra: Dictionary = e.get("extra", {})
		var tem_extra: bool = liberada and not extra.is_empty() and progresso.avaliar(String(extra.get("condicao", "")))
		lista.append({
			"id": e["id"], "grupo": e["grupo"], "nome": e["nome"], "titulo": e["titulo"], "liberada": liberada,
			"texto": e["texto"],
			"extra": String(extra.get("texto", "")) if tem_extra else "",
			"aviso": String(extra.get("aviso", "")) if liberada and not extra.is_empty() and not tem_extra else "",
		})
	return lista


static func liberadas(progresso: DadosProgresso) -> int:
	var n: int = 0
	for e in entradas(progresso):
		if e["liberada"]:
			n += 1
	return n
