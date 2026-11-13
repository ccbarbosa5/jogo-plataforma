class_name Boneco
extends Inimigo
## Boneco de treino da arena: não anda nem ataca.
## Serve para testes automáticos e para treinar o Grilhão e os pontos fracos na sala de teste.
## O peso, a armadura e o tamanho vêm dos exports de Inimigo.


func _draw() -> void:
	var cor: Color = Color("6b5b4b")
	match peso:
		Peso.LEVE:
			cor = Color("9c8a6e")
		Peso.PESADO:
			cor = Color("4a3f35")
	if _timer_flash > 0.0:
		cor = Color.WHITE
	draw_rect(Rect2(Vector2(-tamanho.x * 0.5, -tamanho.y), tamanho), cor)
	if armadura_frontal:
		draw_rect(Rect2(Vector2(olhando * tamanho.x * 0.5 - (4.0 if olhando > 0 else 0.0), -tamanho.y + 4.0), Vector2(4.0, tamanho.y - 8.0)), Color("c0c5ce"))
	_desenhar_status()
