# DEV — Programação · Status

Última atualização: 2026-11-16 (sessão 28). Formato curto (D-048).

## Status
- **Item 31 ✔ (PR #55): Códice na nave.**
  - **Onde:** 1ª opção do terminal "Arquivo da Ponte" (mostra "N/11 · ABRIR"). Tela `TelaCodice`: lista à esquerda, texto à direita; "???" até encontrar; mouse, setas, roda, Esc ou clique fora (D-065).
  - **Textos:** `data/codice.json`, copiados do NAR-05 §5 sem mudança: 9 personagens + Mordida e Bramido.
  - **Destrava:** Ryker, ECO e Mordida desde o começo; Garrak, Sete e Vossa quando chegam à nave; Mercador na 1ª loja; Tor-Ama na 1ª Oferta Kharn; a Colmeia na 1ª Oferta Vesh; Ur-Kesh no 1º encontro; Bramido ao ser liberado.
  - **Parágrafo extra das armas:** 10 runs com a arma (contador novo `runs_<arma>`, soma no começo da run; saves antigos começam em 0).
- Item 30 ✔ (PR #54): Roedores por tocas no pico. Item 29 ✔ (PR #53): Zangão.
- Ainda não publicados (29, 30 e 31): vão juntos ao fim do item 32. Itch atual: `dev-f2af5da`.
- Testes: **356, 0 falhas**.
- Próximo: item 32 (abertura v2, D-075).

## Pendências
- **Códice:** as 4 armas da Fase 3 (Liquidação, Lanterna, Arpão, Lança) não entraram; a 2ª entrada dos personagens espera a NAR (NAR-08).
- **Gambiarra depois do chefe:** só vale em runs de vários atos.
- **Ainda não feitos:** os Terminais dos Antigos.
- **Horda:** Chacais e Vesh do enxame ainda não brigam entre si na sala 5.
- **NAR-06:** a flag `garrak_chama_ryker` ainda não existe; até lá, o nível 25 usa "Krat'zu".
- **Versões com nome** (ex.: v0.2.0): esta sessão não cria tags no GitHub. O dono cria a tag em GitHub → Releases, e o workflow publica com esse nome.

## Pedidos
- [PARA: NAR] Códice: faltam entradas para os inimigos (Roedor, Chacal de Clã, Zangão e os pesados; o GD já tinha pedido Roedor e Chacal). Basta acrescentar em `data/codice.json` (campos: grupo, nome, titulo, condicao, texto); o DEV liga a condição de encontro.
- [PARA: ART] A toca dos Roedores é desenhada por código (retângulo escuro de 12×3 px com borda piscando). Se quiser, um sprite de buraco abrindo/fechando (~16×8, 4 quadros) substitui em `scripts/run/aviso_entrada.gd`.
- [PARA: GD] Tocas: `fracao_toca_no_cima` = 0,5 (metade dos 10% "de cima" do pico). Ajuste em `horda_varrek.json`.
- [PARA: AUD] Som do logo no quadro 30 (`LogoAnimado.QUADRO_QUEBRA`). Abertura: batimento no quadro do reconstrutor, música por cima de tudo; os tempos dos quadros estão em `AberturaHistoria.DURACOES`.
- [PARA: GD] **D-071 (GD-4):** valores de pulo usados — Roedor 2 tiles (vão 2), Chacal 3,5 (vão 3), pesados 2, Ur-Kesh 0; preso 1 s → pula, 2 s → muda de rota. Ajuste em `@export` de cada cena.
- [PARA: GD] **Mistura do enxame por bioma (em `horda_varrek.json`):** Carcaça Roedor 40/Zangão 30/Chacal 30; Zona de guerra Chacal 50/Roedor 25/Zangão 25; Elite Chacal 40/Roedor 30/Zangão 30; 1ª queda 0,5/s, teto 8.
- [PARA: GD] As arenas têm 1 tela (30 tiles); o GD-08 pede 1,5 tela.
- [PARA: NAR] 3 falas só de narração (GARR_01, VITO_W1, VITO_FIM) aparecem como texto principal; pode trocar por fala.
- [PARA: NAR] Ajuste no NAR-06: COMB_A2 só com pontos livres; PASS_X1 toca ao tentar comprar no máximo.
- [PARA: ART] Arquivos da Atkinson em `assets/fonts/` sem uso; apagar ou guardar fica com a ART.

## Perguntas
- [PARA: DIR] PERGUNTA: o Códice ficou dentro do terminal "Arquivo da Ponte", sem um ponto próprio na nave. **Proposta padrão:** manter assim até a ART desenhar um objeto para ele (um livro ou painel); aí vira um ponto próprio.
