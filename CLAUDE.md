# Regras do repositório — No Rest

Este repositório é o jogo **e** o estúdio: o código, a arte e todos os documentos de design ficam aqui.

## Comece por aqui (toda sessão)
1. Leia **`docs/00-DIRETORIA/CENTRAL.md`**: regras do estúdio, últimas mudanças, decisões novas e a lista de tarefas. "continue" = pegar o próximo item não marcado da seção 5.
2. Faça **só a tarefa da mensagem do dono** (modo econômico, D-048). Leia só os docs que a tarefa pede.
3. Decisões antigas: procure em `docs/00-DIRETORIA/DECISOES.md` pelo número ou assunto (`grep -n "D-0xx" ...`); não leia o arquivo inteiro.
4. **Antes de começar, diga ao dono em 2 a 4 linhas o que vai fazer e comece em seguida, sem esperar confirmação** (D-059).
5. Responda ao dono sempre em **português**, de forma simples.

## Onde fica cada coisa
| Pasta | Conteúdo |
|---|---|
| `docs/00-DIRETORIA/` | CENTRAL (regras e tarefas) e DECISOES (todas as decisões) |
| `docs/departamentos/` | status curto de cada departamento (GD, NAR, ART, DEV) |
| `docs/GD/` | game design (números, sistemas) |
| `docs/NAR/` | narrativa (história, falas, Códice). ⚠ `NAR/02` tem spoilers |
| `docs/ART/` | guia de estilo e pacotes de prompt para gerar imagens no ChatGPT |
| `.claude/agents/` | um agente por departamento, para delegar tarefas |

## Departamentos
Uma sessão pode trabalhar como qualquer departamento: Diretoria (DIR), Game Design (GD), Narrativa (NAR), Arte (ART) ou Programação (DEV). Quando o dono disser "como Arte", "faça ART-3" etc., siga as regras daquele departamento e, no fim, atualize `docs/departamentos/<CÓDIGO>.md` de forma curta e marque ✔ na CENTRAL. Decisão que muda o jogo é do dono: pergunte com uma proposta padrão e registre na CENTRAL (seção 3) e no fim de `DECISOES.md`.

## Fluxo de trabalho (git)
- Ninguém faz commit direto na `main`. A `main` deve estar sempre jogável.
- Branch por departamento: `<depto>/<descricao-curta>`. Exemplos: `dev/movimento-jogador`, `art/sprites-protagonista`, `dir/decisao-d077`.
- Mudanças em `docs/` também vão por PR.
- PR integrado quando o workflow `Testes` está verde e não há conflito (auto-merge, D-050). Não empilhe PR em cima de outro ainda aberto.
- Mensagens de commit em português, curtas e no imperativo. Exemplo: "Adiciona pulo duplo ao jogador".

## Código (Godot 4 / GDScript)
- Use GDScript com tipagem estática (`var vida: int = 3`, `func atirar() -> void:`).
- Arquivos e pastas em `snake_case` (`player_controller.gd`). Classes (`class_name`) em `PascalCase`.
- Nomes de variáveis e funções podem ser em português ou inglês, mas mantenha o mesmo padrão dentro de cada arquivo.
- Valores de balanceamento (dano, vida, velocidade) ficam em `@export` ou em recursos (`.tres`/`.json` em `data/`), nunca escritos direto no meio da lógica.
- Uma cena por entidade (jogador, inimigo, arma, sala), com o script na mesma pasta lógica.
- Antes de abrir o PR, confirme que o projeto abre e roda sem erros.

## Testes automáticos
- Todo PR roda o workflow `Testes` (GitHub Actions). Ele importa o projeto no Godot 4.5.1 headless e executa `tests/run_tests.gd`. Um PR com teste falhando não é aceito.
- Para rodar localmente: `godot --headless --path . --import` e depois `godot --headless --path . -s res://tests/run_tests.gd`.
- Para escrever um teste: crie `tests/<area>/test_<nome>.gd` com `extends TestCase` e métodos `func test_algo() -> void:`. Use `afirmar`, `afirmar_igual`, `afirmar_proximo`, `instanciar("res://...tscn")` e `await esperar_frames(n)`.
- Toda mecânica nova chega com pelo menos um teste.
- O teste `test_todas_as_cenas_carregam` verifica automaticamente se todas as cenas em `scenes/` carregam.

## Publicação
- Workflow `Publicar no itch.io` (manual ou tag `v*`), destino `ccbarbosa/no-rest`, canais `windows` e `html5`.

## Arte e áudio
- Pixel art com resolução interna de 480×270 e filtro *Nearest* (já configurado no `project.godot`).
- Sprites em PNG, áudio em OGG (música) ou WAV (efeitos curtos).
- Arte com IA: o ART escreve o prompt em `docs/ART/prompts/` (sempre em português), o dono gera no ChatGPT, o ART trata com `ferramentas/arte/tratar_ia.py` e integra por PR.
- Todo asset de terceiros ou de IA precisa estar registrado em `assets/CREDITS.md`.

## Segurança
- Nunca faça commit de chaves de API, senhas ou tokens, incluindo a chave do butler/itch.io. Credenciais ficam somente nos *Secrets* do GitHub.
