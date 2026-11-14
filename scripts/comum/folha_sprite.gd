class_name FolhaSprite
extends Sprite2D
## Sprite que toca animações feitas de folhas em linha (formato das folhas da ART:
## quadros do mesmo tamanho lado a lado, origem nos pés, desenhado olhando para a direita).
## Uso: registrar("correr", textura, 8, 12.0) e depois tocar("correr").

signal terminou(animacao: StringName)

## nome -> { textura, quadros, fps, repetir }
var animacoes: Dictionary = {}
var atual: StringName = &""
var quadro_atual: int = 0
var _tempo: float = 0.0


func _init() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## fps = 0 deixa a animação parada no quadro escolhido por código (definir_quadro).
func registrar(nome: StringName, textura: Texture2D, quadros: int, fps: float = 0.0, repetir: bool = true) -> void:
	animacoes[nome] = {"textura": textura, "quadros": maxi(quadros, 1), "fps": fps, "repetir": repetir}


func tem(nome: StringName) -> bool:
	return animacoes.has(nome)


## Troca de animação (não reinicia se já está tocando a mesma, a menos que reiniciar = true).
func tocar(nome: StringName, reiniciar: bool = false) -> void:
	if not animacoes.has(nome):
		return
	if nome == atual and not reiniciar:
		return
	var a: Dictionary = animacoes[nome]
	atual = nome
	texture = a["textura"]
	hframes = a["quadros"]
	vframes = 1
	var altura: float = float(texture.get_height()) if texture != null else 0.0
	offset = Vector2(0.0, -altura * 0.5)  # origem nos pés
	_tempo = 0.0
	definir_quadro(0)


func definir_quadro(q: int) -> void:
	var total: int = animacoes.get(atual, {}).get("quadros", 1)
	quadro_atual = clampi(q, 0, total - 1)
	frame = quadro_atual


func _process(delta: float) -> void:
	if not animacoes.has(atual):
		return
	var a: Dictionary = animacoes[atual]
	var fps: float = a["fps"]
	if fps <= 0.0:
		return
	_tempo += delta
	var passo: float = 1.0 / fps
	while _tempo >= passo:
		_tempo -= passo
		var proximo: int = quadro_atual + 1
		if proximo >= a["quadros"]:
			if a["repetir"]:
				proximo = 0
			else:
				terminou.emit(atual)
				return
		definir_quadro(proximo)


## Carrega uma textura se existir (a arte pode ainda não ter chegado).
static func carregar(caminho: String) -> Texture2D:
	return load(caminho) as Texture2D if ResourceLoader.exists(caminho) else null
