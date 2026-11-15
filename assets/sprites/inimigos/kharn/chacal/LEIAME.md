# Chacal de Clã (Kharn, enxame) — sprites v0.1 (ART-4, GD-08 §2)

Gerado por `ferramentas/arte/horda_v01.py`. **Desenhado olhando para a direita** (para a esquerda, `flip_h`).
- **Quadro 24×16**, origem **nos pés (12, 16)**. Com `centered = true`: `offset = Vector2(0, -8)`. Corpo de ~19×11, para a forma de 14×10 do GD.

| Arquivo | Quadros | Uso |
|---|---|---|
| `chacal_correr.png` | 6, 14 qps | correndo |
| `chacal_aviso.png` | 2 | aviso do salto (0,3 s): **quadro 0** agachado com o olho em brasa; **quadro 1** (contorno AVISO `#fff3a0`) só nos **últimos 0,2 s**, como em todo inimigo |
| `chacal_salto.png` | 2 | quadro 0 subindo, quadro 1 descendo (troca quando a velocidade vertical fica positiva) |
| `chacal_recuo.png` | 1 | os 0,5 s parado depois de tocar o jogador |
| `chacal_morte.png` | 4, 12 qps | cai e vira poeira de osso |

Cores: pele Kharn (2 tons + luz), osso (2), brasa no olho e contorno.
