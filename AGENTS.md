# AGENTS.md — regras obrigatórias para qualquer agente no DOFLUXO

Leia **antes** de editar código. Complementa `PROJECT_CONTEXT.md`, `TECHNICAL_DOC.md` e `NEXT_STEPS.md`.

O dono do produto **não** vai relembrar o que já foi feito a cada tarefa. Cabe ao agente **não desfazer** e **não expandir** o escopo.

---

## Regra #1 — só o que foi pedido

1. Altere **somente** o necessário para cumprir o pedido atual.
2. **Proibido:**
   - “aproveitar” para polish, limpeza, rename, refactor, redesign
   - reescrever o `build` / layout de um widget só porque você tocou nele
   - mudar UX, copy, cores, estrutura visual **não pedidas**
   - editar arquivos fora do caminho crítico da tarefa
3. Se precisar tocar um arquivo grande: faça o **menor diff possível** (patch cirúrgico). Não reescreva o arquivo.
4. Se achar algo quebrado fora do escopo: anote em `NEXT_STEPS.md` / comente na PR — **não corrija agora**.
5. Em dúvida: **não mexa**. Pergunte ou pare.

---

## Regra #2 — o que já foi entregue fica

1. Decisões em **Decisões travadas** (abaixo) e em `NEXT_STEPS.md` são **imutáveis** sem pedido explícito do dono.
2. “Pedido explícito” = frase clara do usuário (ex.: “volte o título para fora”). Silêncio ≠ autorização.
3. Ao editar um arquivo com decisão travada: **preserve** o comportamento. Não restaure o padrão antigo.
4. Refactor só é aceitável se a decisão travada continuar verdadeira **no mesmo commit**.

---

## Checklist antes de commit / PR / deploy

- [ ] Diff resolve **só** o pedido atual
- [ ] Nenhum arquivo “extra” por limpeza ou polish
- [ ] Nenhuma decisão travada foi revertida
- [ ] Se toquei em `kanban_column.dart`: títulos ainda **dentro** do bloco colorido
- [ ] Se toquei em update web: ainda é banner 5 min, não overlay fullscreen
- [ ] Se abri tela de ver/editar/criar/confirmar: usa `showAppModal` / `showAppModalPage` (não `push` / `AlertDialog` / bottom sheet) — exceto páginas da sidebar
- [ ] Modal novo encolhe ao conteúdo (`AppModalShell` padrão); altura fixa só se o layout exigir `Expanded` (ex.: Novo Projeto `wide`)

---

## Decisões travadas (não reverter)

| ID | Decisão | Arquivo(s) típicos |
|----|---------|-------------------|
| D1 | Kanban **custom** — não usar `appflowy_board` | `kanban_*.dart`, `dashboard_board_layout.dart` |
| D2 | **Uma** Dashboard — sem abas Job vs Planejamento | `dashboard_page.dart` |
| D3 | Filtros `Exibir:` controlam Job / Planejamento no mesmo board | `dashboard_display_filter.dart` |
| D4 | Planejamento vive em `projects` (`category`) — **não** coleção `planning_posts` | services / mapper |
| D5 | Auth via `AuthGate` no `home` do `MaterialApp` | `main.dart` |
| D6 | Multi-tenant por `agencyId` / memberships | `lib/core/agency/` |
| D7 | **Títulos das colunas Kanban ficam DENTRO do bloco colorido** (header + cards no mesmo `DecoratedBox`). Não voltar título flutuando acima do fundo cinza. | `kanban_column.dart` |
| D8 | Aviso de atualização web: banner canto inferior direito com graça de 5 min — **não** overlay fullscreen bloqueante | `app_update_gate.dart` |
| D9 | Convite por código `DFX-XXXX-XXXX` (Membro/Admin) — não forçar criar agência no 1º login | agency / team / invite |
| D10 | **Tudo que abre para ver/editar/criar/confirmar é JANELA modal** (`showAppModal` / `showAppModalPage` / `showAppConfirmModal`) com blur — **não** `Navigator.push`, `showDialog`/`AlertDialog` solto nem bottom sheet. **Exceção:** páginas da sidebar (Dashboard, Clientes, Equipe, Conta) no `MainShell`. **Altura:** acompanha o conteúdo por padrão; altura fixa só quando o layout precisa de `Expanded` (ex.: Novo Projeto `wide`). Páginas reutilizadas detectam modal via `AppModalScope`. | `app_modal.dart` + qualquer abertura interna |
| D11 | **Grupo de Planejamento multi-card:** vários posts no Novo Projeto = vários docs em `projects` (`category: planejamento`) com o mesmo `groupId` + `groupTitle` (= `title`). **Não** coleção `planning_posts`. 1 card no board = 1 projeto. | `new_project_dialog.dart`, `project_service.dart` |

Ao travar uma nova decisão: atualize esta tabela **e** `NEXT_STEPS.md` no mesmo PR.

---

## Exemplo do que deu errado (não repetir)

Pedido: melhorar drag/hover do Kanban.  
Errado: reescrever o `build` da coluna e colocar o título **fora** de novo.  
Certo: mudar só a lógica de drag/drop, **mantendo** o header dentro do `DecoratedBox`.

---

## Ordem de leitura

1. Este arquivo (`AGENTS.md`) — **obrigatório**
2. `PROJECT_CONTEXT.md`
3. `TECHNICAL_DOC.md`
4. `NEXT_STEPS.md` (decisões + bugs + roadmap)
