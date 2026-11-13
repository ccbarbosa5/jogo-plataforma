# Guerreiro de Clã (Kharn) — sprites v0.2 (ART) · PROVISÓRIOS

> **D-039:** a versão final vai ser gerada por IA e tratada pela ART. Estes sprites servem para o protótipo agora. **A especificação abaixo (quadro, origem, boca do canhão, nomes) vale também para a versão final.**

- **Quadro:** 64×64 px. **Origem: nos pés**, no ponto (32, 64). Com `centered = true`: `offset = Vector2(0, -32)`.
- **Desenhado olhando para a direita.** Para a esquerda, use `flip_h`.
- Corpo de ~32×60 px, igual à forma de 32×64 do DEV.
- **Boca do canhão** em (+26, −38) a partir da origem, que bate com `_ponto_canhao()` (±16 de largura + 10 do cano, 0,6 da altura).

| Arquivo | Quadros | Uso |
|---|---|---|
| `guerreiro_andar.png` | 6, 8 qps | Estado AVANCAR |
| `guerreiro_aviso.png` | 2 | Estado AVISO: quadro 0 (brasa carregando) durante o aviso; **quadro 1 (flash na cor AVISO) só nos últimos 0,2 s** |
| `guerreiro_tiro.png` | 2 | Cada tiro da RAJADA: quadro 0 (disparo) por 1/20 s, depois o 1 (recuo) |
| `guerreiro_morte.png` | 6, 10 qps | Cai de joelhos e vira poeira de osso |
| `*_sem_armadura.png` | iguais | Mesmas animações sem a placa de osso do peito. Trocar quando o Grilhão arrancar a armadura. |
| `guerreiro_placa_caida.png` | 16×12 | A placa arrancada, para soltar no chão como objeto (o jogador vê que ela saiu). |

O estado DESCANSO usa o quadro 0 de `guerreiro_andar.png`. Atordoado (Abalo) também, com as estrelas que o código já desenha por cima.

**O aviso atual do código** (exclamação vermelha) pode sair quando estes sprites entrarem. A regra do ART-01 é: brasa durante o aviso + flash amarelo-claro (#fff3a0) no fim, igual para todo inimigo.
