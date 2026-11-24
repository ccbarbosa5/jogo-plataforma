# CENTRAL — No Rest (versão curta, modo econômico)

> **Migração para o Claude Code (2026-11-24, D-076).** Os documentos do estúdio saíram do Projeto "No Rest" do claude.ai e agora moram **neste repositório, na pasta `docs/`**. O caminho de cada doc é o mesmo de antes, com `docs/` na frente (ex.: `docs/GD/08-horda-e-ritmo.md`). **A versão do repositório é a oficial**; o Projeto do claude.ai fica só como arquivo antigo.

## 1. Regras (todas as sessões)
0. **AVISE ANTES DE FAZER (D-059):** toda vez que receber uma mensagem do dono, **a primeira coisa da resposta** é dizer em 2 a 4 linhas, em português simples, **o que vai fazer** (qual tarefa, o que vai criar ou mudar, o que vai entregar). **Não espere confirmação:** avise e comece logo em seguida.
1. **Papéis (D-076):** no Claude Code, uma sessão pode fazer o trabalho de qualquer departamento (DIR, GD, NAR, ART, DEV). Quando o dono disser "como Arte", "como Game Design" etc., siga as regras daquele departamento e atualize o doc dele. Os agentes de cada departamento estão em `.claude/agents/`. Dúvida que só o dono pode decidir: pergunte direto a ele, com uma proposta padrão.
2. **Modo econômico (D-048):** faça **só a tarefa da mensagem do dono**. Leia só o que ela pedir. Para decisões, veja a seção 3 abaixo (decisões novas) e **procure** em `docs/00-DIRETORIA/DECISOES.md` pelo número ou assunto (`grep`); não leia o arquivo inteiro.
3. Nunca contradiga uma decisão oficial; para mudá-la, peça ao dono e registre a decisão nova aqui e em `DECISOES.md`.
4. Código e docs: branch `<depto>/<descricao>` a partir da `main` mais recente, PR com testes passando. Ninguém faz commit direto na `main`. **Não empilhe um PR em cima de outro ainda aberto.** Mudanças em `docs/` também vão por PR.
5. Ao terminar, atualize o `docs/departamentos/<CÓDIGO>.md` do departamento **de forma curta** e marque ✔ na tarefa na seção 5.
6. Antes de salvar, confira a seção 2 (Últimas mudanças).
7. **AUTO-MERGE (D-050):** o PR é integrado quando: workflow `Testes` verde + testes locais sem falha; sem conflito com a `main`; não muda decisão oficial sem o dono. Merge: `gh api -X PUT repos/<REPO>/pulls/<N>/merge -f merge_method=squash` (ou o botão no GitHub).
8. **Erro que não consegue resolver, ou decisão a mudar:** pare e explique ao dono (o que tentou, o que falhou, o que decidir).
9. **"continue"** = pegue o próximo item não marcado da lista na seção 5.
10. **Repositório (D-051):** `<REPO>` = `ccbarbosa5/no-rest` (o nome antigo `ccbarbosa5/jogo-plataforma` redireciona). itch.io: `ccbarbosa/no-rest`, Secret `BUTLER_API_KEY`. **Nunca** colar chaves em conversa, doc ou commit.

## 2. Últimas mudanças (as 5 mais novas)
- 2026-11-24 — **GD-9 ✔**: `docs/GD/09-arena-e-ondas.md` (run de 4 planetas × 5 ondas, 8 armas em 5 famílias, Sucata, loja do Ilo, itens, inimigos de cima, progressão pequena). 5 perguntas ao dono na seção 12, com proposta "sim". — GD, DEV, ART, NAR
- 2026-11-24 — **D-077 (dono): o jogo muda para arena com visão de cima, no formato do Brotato** (ondas curtas, loja entre ondas, até 6 armas automáticas). História fica; progressão permanente pequena. Nova lista na seção 5; DEV 32 pausado. — TODOS
- 2026-11-24 — **D-076 (dono): migração para o Claude Code.** Todos os docs do Projeto copiados para `docs/`; regras adaptadas; agentes por departamento em `.claude/agents/`. — TODOS
- 2026-11-16 20:40 — **DEV 31 ✔** (PR #55): Códice na nave, dentro do terminal "Arquivo da Ponte": 9 personagens e 2 armas do VS (NAR-05 §5), destravando por encontros; parágrafo extra das armas com 10 runs. 356 testes. — DEV, NAR
- 2026-11-16 19:00 — **DEV 30 ✔** (PR #54): no pico da horda, parte dos Roedores sai de tocas no chão (buraco brilha 1,0 s antes, nunca a menos de 6 tiles, ~5% do pico). 351 testes. — DEV, GD, ART

## 3. Decisões novas (também copiadas no fim de DECISOES.md)
- **D-078 — Código do jogo novo separado.** *(dono, 2026-11-24)* O jogo de arena nasce em pastas próprias: `scenes/arena/`, `scripts/arena/`, `data/arena/`, `tests/arena/`. O código novo **nunca usa** código de plataforma (jogador, salas, run, portas, gravidade). Peças boas (menus, diálogo, nave, Códice, save, fontes, números de dano, testes) são **reaproveitadas** como estão; armas, itens, ondas e inimigos são **reescritos** mais simples na arena. Quando a arena estiver pronta, **um PR apaga todo o código antigo** de uma vez (nada comentado ou abandonado).
- **D-077 — Mudança total: arena com visão de cima (formato do Brotato).** *(dono, 2026-11-24)* Escolhida a opção **A** (total), não o híbrido.
  - **Jogo:** visão de cima, arena fechada; **ondas curtas** com chefe no fim; **até 6 armas** que atiram sozinhas (mira manual como opção); inimigos soltam material (dinheiro + experiência); **loja entre as ondas**; ao subir de nível, escolher 1 entre alguns atributos. Números: GD-09.
  - **Fica:** história, mundo e personagens (Ryker, Eco/ECO, Vasha, Kharn, Vesh, Ilo, Vigílios, planetas). Cada planeta vira uma arena. Segredos da D-045 continuam.
  - **Progressão permanente: versão pequena** (substitui as árvores da D-058; GD-09 define).
  - **Perdem o efeito:** D-062 (horda da esquerda para a direita), D-069, D-070, D-071, D-074 e as partes de pulo/plataforma da D-052. Revisar com o dono: D-058 (Gambiarras/Ofertas podem virar itens da loja), D-061, D-075 (abertura).
  - **Regras:** seguimos o **gênero**, sem copiar nome, personagens, arte ou visual do Brotato. A `main` continua jogável: o modo novo nasce ao lado do atual e só o substitui quando estiver pronto.
- **D-076 — Claude Code.** *(dono, 2026-11-24)* O estúdio passa a trabalhar no Claude Code. Docs em `docs/` (versão oficial), regras no `CLAUDE.md` da raiz, agentes por departamento em `.claude/agents/`. O Projeto "No Rest" do claude.ai vira arquivo; não editar mais lá.
- **D-075 — Abertura v2: ritmo calmo e história clara.** *(dono, 2026-11-16)* Revisa a D-073B. Roteiro final: **`docs/NAR/07-abertura.md` v2**.
  - **Ritmo:** ~75–100 s (o v2 tem ~95 s). Cada quadro fica o tempo das suas falas + ~1,5 s. Câmera mais lenta.
  - **Falas legíveis:** cada fala fica no mínimo **max(3 s, 1 s + 0,07 s por caractere)**; o quadro **não troca com fala na tela**; **clique, E ou Espaço avança**; segurar Esc ou "Pular" pula tudo.
  - **Clareza:** (1) onde — galáxia em guerra; (2) quem — o Ryker, o único humano, prisioneiro de arena; (3) a fuga; (4) a Eco o resgata; (5) objetivo — atravessar os planetas; morrer = voltar à nave; (6) a cápsula cai em Varrek.
  - **Apoio visual:** legendas curtas (1 nome novo por quadro); Ryker sempre destacado; quadro do mapa da galáxia; quadro "morrer = voltar". A legenda de **Varrek** segue a **D-035** (cemitério de naves).
  - ⚠ Sem spoiler da ECO/Vasha (D-045).
- **D-074 — Respostas da DIR ao DEV.** A queda `queda_tutorial_grilhao` fica como exceção marcada à D-070.
- **D-073 — Animação de entrada.** **A.** Logo animado toda vez que o jogo abre (≈ 6 s, pulável). **B.** Abertura da história no 1º Novo jogo — **revista pela D-075**; pulável segurando Esc ou "Pular"; "Ver abertura" nas Opções. Som e música entram quando o AUD abrir.
- **D-072 — "Dádiva" vira "Oferta"** em todo texto na tela. Nomes internos no código podem ficar.
- **D-070 — Toda plataforma alcançável** com o pulo base; só com dash/melhoria = exceção marcada. Teste automático.
- **D-071 — Inimigos pulam, perseguem e nunca ficam presos** (valores em `@export`; GD-4 ajusta).
- **D-067 — Números de dano na tela** (cores, soma por inimigo, limite ~30, opção para desligar).
- **D-068 — Recompensa com várias opções tem volta;** só a Gambiarra é obrigatória.
- **D-069 — Rastro de chão sempre no chão.**
- **D-066 — Recompensa de escolha só com E ou clique.**
- **D-065 — Menus: mouse sempre, Esc sempre volta.** Exceção: Gambiarra.
- **D-064 — Caixa de diálogo:** mais margem em cima; texto entre colchetes não aparece.
- **D-063 — Falas:** 32 px; limite de **160 caracteres por página**; NAR mira em 120; divisão automática.
- **D-062 — HORDA:** fase da esquerda para a direita, inimigos principalmente da frente; enxame; 15–25 na tela, picos de 30–40. Números: GD-08.
- **D-061 — Arma mais lenta;** mira e tiro automáticos continuam como opção completa.
- **D-060 — Propostas padrão aprovadas (DIR):** GD (Marca do Grilhão, máx. 2 Ápices, cobertura do Artilheiro/carapaça do Ninho); ART (logo variação 3, Ilo latão/cobre + gás azul-pálido, Vossa de frente, quem não fala ~55%, fonte Open Sans); DEV (abandonar run ≠ morte, loja Cura 40/Oferta 80, Esquiva de Arena, Recarga de Campo, saves antigos, sem Soldado Kharn); NAR (Códice na nave, piada fica).
- **D-059** avisar antes de fazer · **D-052** controles com mouse · **D-053** menu inicial · **D-054** sem barra de teclas · **D-056** texto nítido · **D-057** placa legível · **D-058** progressão (GD-07).

## 4. O jogo em 10 linhas
- **No Rest:** ⚠ **mudando (D-077)** para arena com visão de cima no formato do Brotato (ondas, loja, até 6 armas automáticas). Era: shooter de plataforma 2D + roguelike. Pixel art 480×270, Godot 4.
- **Ryker Vale**, gladiador fugitivo; habilidades **Granada** e **Grilhão**; arma **Mordida**; universal do VS: **Bramido**.
- Atos: **Varrek** (Ur-Kesh) → Tarvo → Zhinn → **Vigília**. Run atravessa vários planetas.
- Nave **Eco**; a **ECO** é a máscara secreta da Rainha **Vasha** (final verdadeiro). ⚠ Segredo.
- Facções: **Kharn**, **Vesh**; mágica: **Vigílios**; mercador: **Ilo**. As facções dão **Ofertas** (D-072).
- Progressão: árvore Passiva + árvore de Combate (permanentes) + Gambiarras (na run) + Ofertas de facção (na run).
- Pilares: **caos controlado** · **toda run conta** · **pequeno no meio de gigantes**.
- Repositório: https://github.com/ccbarbosa5/no-rest · itch.io: https://ccbarbosa.itch.io/no-rest (rascunho)

## 5. Listas de trabalho (uma tarefa por vez, em ordem; marque ✔ ao integrar)
**Concluídos:** Fase 2 itens 1–7 ✔ · DEV 8–31 ✔ (PRs #19–#55; itch `dev-f2af5da`, 356 testes) · GD-1 a GD-3 ✔ · ART-1 a ART-8 ✔ · NAR-1 a NAR-5 ✔ (NAR-06, NAR-07 v2).

**Nova direção (D-077), nesta ordem:**
- ✔ GD-9. **Documento do novo jogo** (`docs/GD/09-arena-e-ondas.md`): partida (quantas ondas, duração, chefes, planetas), armas (até 6, tipos, juntar iguais), materiais e loja (preços, rolar de novo, travar), atributos e níveis, itens (o que vira das Gambiarras/Ofertas), inimigos de cima, personagens jogáveis (só o Ryker ou vários?), progressão permanente pequena. Lista do que do jogo atual se aproveita.
- ART-9. **Guia de estilo visão de cima** (`docs/ART/`): tamanho dos sprites, perspectiva, arena de Varrek, Ryker e 3 inimigos de teste; pacote de prompt para o ChatGPT.
- NAR-6. **Ajustar a história ao formato** (pouco texto): onde entram falas (nave, entre ondas, chefes); abertura v2 vale ou encurta?
- DEV 33. **Protótipo jogável da arena** (em `scenes/arena/` e `scripts/arena/`, D-078; GD-09 §2–4, 5.2, 7, 9): Ryker de cima, 1 arma automática, 2 inimigos, 3 ondas, loja simples. Com testes.
- DEV 34+. Conforme o GD-9 (armas múltiplas, loja completa, níveis, chefes). Último: trocar o modo e **apagar o código antigo** (D-078).

**Pausados pela D-077:** DEV 32 (abertura v2) até o NAR-6 · GD-4 (pulo e enxame, perde o sentido).

**Perguntas abertas nos docs dos departamentos** (responder com o dono quando ele quiser): **GD — as 5 perguntas do GD-09 §12 (proposta: sim)**; DEV — Códice como ponto próprio na nave; ART — símbolo Vesh roxo/verde no mapa, Mordida laranja e preta, apagar a fonte Atkinson.

**Pausados:** AUD (som do logo e música da abertura), QA e MKT ainda não abertos.
