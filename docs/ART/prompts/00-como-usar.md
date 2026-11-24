# ART/prompts — como usar (D-039, D-045, D-046, D-047)

Pacotes de prompt para gerar as peças principais no ChatGPT. **Todos em português** (D-045). Cada pacote é independente. A ART também cola cada prompt **direto na conversa de Arte**, pronto para copiar.

## O fluxo
1. **Uma vez só, no começo:** cole o **pacote 00, Briefing visual** no ChatGPT, nas instruções de um projeto do ChatGPT chamado "No Rest – Arte" (se você usa esse recurso) ou como primeira mensagem da conversa.
2. **Dono:** copia o bloco de prompt **inteiro** (da conversa de Arte ou do pacote) e cola no ChatGPT.
3. **Dono:** gera o número de variações que o pacote pede. Se uma imagem sair claramente errada, manda a frase de correção da tabela "Quando pedir de novo".
4. **Dono:** baixa as imagens **no tamanho original** (sem print de tela, sem recortar) e anexa **todas** na conversa de Arte, dizendo o número do pacote.
5. **ART:** escolhe a melhor, trata com `ferramentas/arte/tratar_ia.py`, retoca os detalhes de 1 px e mostra o resultado. Se nenhuma servir, devolve um prompt corrigido.
6. **ART:** a imagem aprovada vira a **folha de referência** do personagem, e a **descrição fixa** dela (`descricoes-fixas.md`) entra igual em todos os prompts seguintes dele. A ART integra por PR e marca a imagem em `assets/CREDITS.md` (D-039).

## O que vai para a IA e o que não vai (D-047)
- **IA:** o que é **grande**: retratos 144×208, armas do Arsenal, referências de personagem, poses de referência, arte-chave, capa.
- **Código (ART):** os **sprites de jogo** (~28 px de altura), tiles, efeitos, interface, molduras e a fonte. A ART desenha **copiando as referências da IA**, porque, reduzidos a esse tamanho, os detalhes da IA viram ruído.

## Pacotes
| # | Pacote | Status |
|---|---|---|
| 00 | **Briefing visual de No Rest** (v2) | colar uma vez |
| 01 | Ryker: folha de referência | ✔ **aprovado (v2, "campeão")**, visual oficial (D-046) |
| 02 | Ryker: retrato, 4 expressões | ✔ aprovado |
| 03 | ECO: referência (3A) + retrato (3B) | ✔ **aprovados (v2)**, visual oficial (D-046) |
| 04 | Mordida e Bramido | ✔ aprovado |
| 05 | Ryker com a Mordida: 8 poses | ✔ aprovado (referência dos sprites) |
| 06 | Garrak: referência + retrato | pronto para gerar |
| 07 | Sete: referência + retrato | pronto para gerar |
| 08 | Vossa Margem: referência + retrato | pronto para gerar |
| — | Guerreiro de Clã, Ur-Kesh (andador e a pé), Tor-Ama, Colmeia | próximas sessões |

## Regras que todo prompt segue (já vêm escritas nos blocos)
- **Em português** (D-045). Os códigos de cor (#16111c…), os tamanhos e o fundo magenta ficam iguais.
- **Nunca** cita outros jogos, filmes, séries ou artistas, nem "no estilo de" (D-021, D-039).
- **Nenhum segredo da história** em prompt nenhum (D-045).
- **Fundo magenta liso (#FF00FF)**, sem chão, sombra ou cenário.
- **Paleta fechada** com os códigos da paleta oficial (ART-01). A ferramenta corrige o resto.
- **Figuras separadas** por espaço vazio quando há mais de uma na imagem.
- **Retratos sempre virados para a direita**; o jogo espelha os do lado direito (D-032).
- **Nada de texto na imagem.** O nome do personagem aparece no jogo, na placa (só o nome, D-046).
- **ECO:** o visual oficial é o da v2 aprovada pelo dono: **sensual e glamourosa** (vestido de festa de luz justo, tomara-que-caia, com fenda), **sem nudez, sem pose sexual e sem conteúdo sexual explícito** (D-023, D-046, D-047). Nada de teias, fios irradiando ou patas (D-021).
- **Ryker:** o visual oficial é o **"campeão"** da v2 (D-046). Use sempre a descrição fixa.
