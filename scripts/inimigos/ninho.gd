class_name Ninho
extends Inimigo
## Ninho Vesh (GD-02 §4.2): 48×48, fixo, 200 de vida, peso Pesado (o Grilhão puxa o Ryker até
## ele). Não ataca: gera 1 Zangão a cada 4 s, até 6 vivos. Tem um ponto fraco pulsante que leva
## o dobro de dano. Os Zangões do Ninho não dão Créditos.

@export var cena_zangao: PackedScene
@export var intervalo: float = 4.0
@export var maximo_vivos: int = 6

var filhos: Array[Inimigo] = []
var _timer: float = 0.0


func _ready() -> void:
	super()
	_timer = intervalo
	dano_contato = 0


func _comportamento(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	if _timer <= 0.0:
		_timer = intervalo
		gerar_zangao()


func vivos() -> int:
	var lista: Array[Inimigo] = []
	for f in filhos:
		if is_instance_valid(f) and f.esta_vivo():
			lista.append(f)
	filhos = lista
	return filhos.size()


func gerar_zangao() -> Inimigo:
	if cena_zangao == null or vivos() >= maximo_vivos or get_parent() == null:
		return null
	var z: Inimigo = cena_zangao.instantiate()
	z.position = global_position + Vector2(randf_range(-10, 10), -tamanho.y - 8.0)
	z.container_projeteis = container_projeteis
	z.ataca_faccao_rival = ataca_faccao_rival
	z.creditos = Vector2i.ZERO
	get_parent().add_child(z)
	filhos.append(z)
	return z


func _draw() -> void:
	var w: float = tamanho.x
	var h: float = tamanho.y
	var pulso: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.35, -h * 0.8), Vector2(0, -h),
			Vector2(w * 0.35, -h * 0.8), Vector2(w * 0.5, 0)]), Color("4c2c5e"))
	for i in 4:
		draw_rect(Rect2(-w * 0.3 + i * 9, -h * 0.6 + (i % 2) * 8, 5, 4), Color("2b1838"))
	draw_rect(Rect2(-w * 0.5 + 4, -6, w - 8, 6), Color("7d4c90"))
	draw_circle(Vector2(0, -h * 0.45), 4.0 + pulso, Color(0.64, 0.89, 0.24, 0.6 + 0.4 * pulso))
	if _timer_flash > 0.0:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 1, 1, 0.4))
	_desenhar_status()
