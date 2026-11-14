class_name InfoDano
extends RefCounted
## Tudo o que um golpe carrega. Quem recebe implementa receber_ataque(info) -> bool.
## Contra o jogador, `valor` é em blocos de vida (1 comum, 2 [PESADO]).
## Contra inimigos, `valor` é em pontos de vida (GD-02).

var valor: int = 0
## Quem causou (para a barra de Chamado e para o Golpe de Arena).
var autor: Node
## Direção em que o golpe viaja (decide se acertou a armadura pela frente).
var direcao: Vector2 = Vector2.ZERO
var explosao: bool = false
var corpo_a_corpo: bool = false
var abalo: float = 0.0
var acidos: int = 0
var empurrao: Vector2 = Vector2.ZERO
var multiplicador: float = 1.0
var ponto_fraco: bool = false
## Multiplica chance e acúmulo dos efeitos "ao acertar" (GD-05 §2.3; Bramido: 0,35 por balim).
var fator_efeito: float = 1.0
## Crítico (Mordida, ramo Rajada).
var critico: bool = false


static func criar(valor_: int, autor_: Node = null, direcao_: Vector2 = Vector2.ZERO) -> InfoDano:
	var info := InfoDano.new()
	info.valor = valor_
	info.autor = autor_
	info.direcao = direcao_
	return info


func copiar() -> InfoDano:
	var c := InfoDano.new()
	c.valor = valor
	c.autor = autor
	c.direcao = direcao
	c.explosao = explosao
	c.corpo_a_corpo = corpo_a_corpo
	c.abalo = abalo
	c.acidos = acidos
	c.empurrao = empurrao
	c.multiplicador = multiplicador
	c.ponto_fraco = ponto_fraco
	c.fator_efeito = fator_efeito
	c.critico = critico
	return c
