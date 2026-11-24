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
- 2026-11-24 — **D-076 (dono): migração para o Claude Code.** Todos os docs do Projeto copiados para `docs/`; regras adaptadas; agentes por departamento em `.claude/agents/`. — TODOS
- 2026-11-16 20:40 — **DEV 31 ✔** (PR #55): Códice na nave, dentro do terminal "Arquivo da Ponte": 9 personagens e 2 armas do VS (NAR-05 §5), destravando por encontros; parágrafo extra das armas com 10 runs. 356 testes. — DEV, NAR
- 2026-11-16 19:00 — **DEV 30 ✔** (PR #54): no pico da horda, parte dos Roedores sai de tocas no chão (buraco brilha 1,0 s antes, nunca a menos de 6 tiles, ~5% do pico). 351 testes. — DEV, GD, ART
- 2026-11-16 03:15 — **NAR-5 ✔** (`NAR/07-abertura.md` v2: 12 quadros, 18 falas, ~95 s). **O DEV 32 usa o NAR-07 v2 como está.** Legenda de Varrek segue a D-035 (cemitério de naves), aprovado. — DEV, NAR
- 2026-11-16 00:15 — **D-075 (dono): abertura mais lenta, falas legíveis e história fácil para quem nunca viu o mundo.** NAR-5 → ART-8 → DEV 32. — NAR, ART, DEV

## 3. Decisões novas (também copiadas no fim de DECISOES.md)
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
- **No Rest:** shooter de plataforma 2D (Metal Slug) + roguelike (Hades), pixel art 480×270, Godot 4. **Horda de inimigos vindo da frente (D-062), que pula e persegue (D-071).**
- **Ryker Vale**, gladiador fugitivo; habilidades **Granada** e **Grilhão**; arma **Mordida**; universal do VS: **Bramido**.
- Atos: **Varrek** (Ur-Kesh) → Tarvo → Zhinn → **Vigília**. Run atravessa vários planetas.
- Nave **Eco**; a **ECO** é a máscara secreta da Rainha **Vasha** (final verdadeiro). ⚠ Segredo.
- Facções: **Kharn**, **Vesh**; mágica: **Vigílios**; mercador: **Ilo**. As facções dão **Ofertas** (D-072).
- Progressão: árvore Passiva + árvore de Combate (permanentes) + Gambiarras (na run) + Ofertas de facção (na run).
- Pilares: **caos controlado** · **toda run conta** · **pequeno no meio de gigantes**.
- Repositório: https://github.com/ccbarbosa5/no-rest · itch.io: https://ccbarbosa.itch.io/no-rest (rascunho)

## 5. Listas de trabalho (uma tarefa por vez, em ordem; marque ✔ ao integrar)
**Concluídos:** Fase 2 itens 1–7 ✔ · DEV 8–31 ✔ (PRs #19–#55; itch `dev-f2af5da`, 356 testes) · GD-1 a GD-3 ✔ · ART-1 a ART-8 ✔ · NAR-1 a NAR-5 ✔ (NAR-06, NAR-07 v2).

**DEV:**
32. **D-075 — abertura v2** (**pronto para começar:** roteiro `docs/NAR/07-abertura.md` v2 como está + peças do ART-8 em `assets/sprites/abertura/LEIAME.md`, seção v0.3): trocar `DURACOES`, `AGENDA_FALAS` e `LEGENDAS` pelos valores do NAR-07 v2; tempo mínimo de leitura por fala; quadro não troca com fala na tela; clique/E/Espaço avança fala; legendas de 3 s; logo final de 2 s também no 1º Novo jogo; teste que confere o tempo mínimo de cada fala. Publicar no itch ao terminar 29–32.

**GD (pequeno, quando o dono mandar):**
- GD-4. Conferir os valores de pulo e a mistura do enxame que o DEV usou (ver `docs/departamentos/DEV.md`, Pedidos) e acrescentar ao GD-08; decidir se as arenas passam de 1 para 1,5 tela.

**Perguntas abertas nos docs dos departamentos** (responder com o dono quando ele quiser): DEV — Códice como ponto próprio na nave; GD — Zangão só de contato e −20% de vida nos pesados (já em uso); ART — símbolo Vesh roxo/verde no mapa, Mordida laranja e preta, apagar a fonte Atkinson.

**Pausados:** AUD (som do logo e música da abertura), QA e MKT ainda não abertos.
