# Regras do repositório — Jogo Plataforma

Este repositório é o código do jogo do estúdio. A visão do jogo e as decisões oficiais ficam no documento `00-DIRETORIA/CENTRAL.md` do projeto "Jogo Plataforma" no Claude. Leia esse documento antes de começar qualquer mudança de design.

## Fluxo de trabalho (git)
- Ninguém faz commit direto na `main`. A `main` deve estar sempre jogável.
- Cada departamento trabalha em um branch próprio: `<depto>/<descricao-curta>`. Exemplos: `dev/movimento-jogador`, `art/sprites-protagonista`, `aud/sfx-tiros`.
- Quando o trabalho estiver pronto, abra um Pull Request para a `main`. A Diretoria (DIR) revisa e faz o merge.
- Mensagens de commit em português, curtas e no imperativo. Exemplo: "Adiciona pulo duplo ao jogador".

## Código (Godot 4 / GDScript)
- Use GDScript com tipagem estática (`var vida: int = 3`, `func atirar() -> void:`).
- Arquivos e pastas em `snake_case` (`player_controller.gd`). Classes (`class_name`) em `PascalCase`.
- Nomes de variáveis e funções podem ser em português ou inglês, mas mantenha o mesmo padrão dentro de cada arquivo.
- Valores de balanceamento (dano, vida, velocidade) ficam em `@export` ou em recursos (`.tres`), nunca escritos direto no meio da lógica. Assim GD e QA conseguem ajustar sem mexer no código.
- Uma cena por entidade (jogador, inimigo, arma, sala), com o script na mesma pasta lógica.
- Antes de abrir o PR, confirme que o projeto abre e roda sem erros.

## Arte e áudio
- Pixel art com resolução interna de 480×270 e filtro *Nearest* (já configurado no `project.godot`).
- Sprites em PNG, áudio em OGG (música) ou WAV (efeitos curtos).
- Todo asset de terceiros precisa ter a licença registrada em `assets/CREDITS.md`.

## Segurança
- Nunca faça commit de chaves de API, senhas ou tokens, incluindo a chave do butler/itch.io. Credenciais ficam somente nos *Secrets* do GitHub.
