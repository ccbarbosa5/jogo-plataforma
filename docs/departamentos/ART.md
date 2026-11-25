# ART — Departamento de Arte · Status

Última atualização: 2026-11-24 (ART-9)

## Status
- **ART-9 ✔: guia da arena vista de cima** (`docs/ART/02-guia-visao-de-cima.md`, D-077).
  - **Proposta em uso:** chão visto de cima, personagens de lado (como hoje) com sombra e `flip_h`. Todos os sprites atuais servem na arena; só o chão e os destroços são novos.
  - **Pacote 11 ✔ integrado (2026-11-25):** 11A → `assets/sprites/arena/varrek_chao.png` (só cores escuras de cenário, `ferramentas/arte/arena_chao.py`); 11B → `varrek_destrocos.png` (5 quadros 56×32, **provisório**, tratado direto; redesenhar por código depois). Prévia: `conceito/mockup_v16_arena_varrek.png`.
  - Escala, Sucata 8×8, ícones de arma 24×24, cores de nível I–IV, HUD e loja definidos.
- **ART-8 ✔ (PR #52): abertura v2** (D-075, NAR-07 v2, 12 quadros). Script: `ferramentas/arte/abertura_v2.py`. Arquivos em `assets/sprites/abertura/v2_*`; tabela quadro a quadro no LEIAME da pasta (seção v0.3).
  - **Novos:**
    - Q1, galáxia em guerra: fundo 640×360, frotas, 3 símbolos (Kharn, Vesh, Ilo), clarões e o pontinho humano;
    - Q10, rota dos planetas + nave Eco pequena + cápsula;
    - Q11, `v2_q11_ryker_vira_luz` (cai, vira luz e sobe);
    - Q12, `v2_capsula` (inteira, em chamas, no chão).
  - **Ajustados:**
    - Q8, `v2_q8_subida` (480×810, de Varrek até o espaço);
    - Q9, `v2_q9_ryker_formando` (linhas de luz montam o corpo; a silhueta só observa).
  - **Ryker em destaque:** `v2_ryker_poses_destaque.png` (contorno claro, quadros 50×50).
  - **Legendas:** `v2_legenda_faixa.png` + especificação (Open Sans Bold 34 em 1080p, nome novo em laranja `#eba35c`, faixa escura com filete laranja). Telas: `mockup_v14_abertura_v2.png` e `mockup_v15_legenda_1080p.png`.
  - Tudo por código; não precisou de pacote de prompt novo.
- Antes: ART-1 a ART-6 ✔; pacote 10 (IA) na abertura (PR #47, também atende o ART-7).
- Sem Godot nesta máquina: o teste local do Godot não rodou; o teste automático passou.

## Propostas (aguardando a DIR)
- ⚑ **Arena: personagens de lado sobre chão visto de cima** (ART-02 §1). Padrão em uso.
- ⚑ **Símbolo dos Vesh no mapa em roxo e verde-ácido, não em âmbar** (o NAR-07 v2 pedia "colmeia âmbar"). Motivo: o âmbar é a cor da ECO, e as duas coisas juntas ligariam a ECO aos insetos (D-045). Padrão em uso: roxo e verde.
- ⚑ **Mordida em laranja e preto** (pedido aberto para a NAR trocar o NAR-03).
- ⚑ Apagar a Atkinson Hyperlegible (`assets/fonts/atkinson_hyperlegible/`), sem uso desde a D-060. Padrão: apagar junto com a próxima entrega.

## Pendências (próximas sessões)
1. Garrak, Sete e Vossa em `descricoes-fixas.md`; quadros de piscar dos retratos.
2. Animações do Ryker que faltam (corrente, granada); efeitos; Vigílios; pacotes do Guerreiro de Clã, Ur-Kesh, Tor-Ama e Colmeia.
3. Se o dono quiser, a galáxia do Q1 e a rota do Q10 podem ganhar versão IA (pacote 11); hoje são por código.

## Pedidos para outros departamentos
- [PARA: DEV] **Item 32:** `assets/sprites/abertura/LEIAME.md`, seção v0.3 (peças, posições e câmera de cada um dos 12 quadros; legenda em 1080p). Use `v2_ryker_poses_destaque.png` no lugar de `ryker_poses_chave.png` na abertura.
- [PARA: DEV] Continuam abertos: peças do ART-3 nas árvores e nas Gambiarras; retratos `garrak`, `sete`, `vossa`.
- [PARA: NAR] No NAR-07 v2, Q1: trocar "colmeia âmbar dos Vesh" por "colmeia roxa dos Vesh" (D-045). Nome e linha do Códice do Roedor e do Chacal; "laranja e preta" na Mordida (NAR-03).

## Perguntas
- (nenhuma em aberto; o quadro 10 da cápsula entrou no roteiro v2)
