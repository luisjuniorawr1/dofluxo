# AGENTS.md — regras obrigatórias para qualquer agente no DOFLUXO

Leia **antes** de editar código. Complementa `PROJECT_CONTEXT.md`, `TECHNICAL_DOC.md` e `NEXT_STEPS.md`.

---

## Política central (não negociável)

1. **O que já foi entregue e documentado como decisão NÃO deve ser desfeito.**
2. Escopo da tarefa = **apenas o pedido atual**. Não “aproveitar” para reescrever layout, UX ou arquitetura de outras partes.
3. Se a mudança **precisa** tocar um arquivo com decisão fechada, **preserve o comportamento já definido** (não volte ao padrão antigo).
4. Reverter decisão só com **pedido explícito do dono do produto** (ex.: “volte o título para fora”).
5. Em caso de dúvida: **não mexa** e registre em `NEXT_STEPS.md` como pergunta — não invente.

---

## Checklist antes de abrir PR / sugerir deploy

- [ ] Li `NEXT_STEPS.md` → seção **Decisões tomadas**
- [ ] Diff não reintroduz layout/comportamento já rejeitado
- [ ] Arquivos fora do escopo da tarefa **não** foram reescritos “por limpeza”
- [ ] Se alterei `kanban_column.dart` / board: confirmei títulos **dentro** do bloco colorido

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

---

## Como trabalhar em cima de código já pronto

**Certo:** alterar só a lógica pedida (ex.: drag/hover) **mantendo** o wrapper visual/decisão existente.

**Errado:** reescrever o `build` inteiro da coluna e “voltar” o header para fora porque o exemplo antigo estava assim.

Se um refactor for inevitável: copiar a decisão fechada para a nova estrutura **no mesmo PR**, e citar a decisão (ex.: D7) na descrição.

---

## Ordem de leitura

1. Este arquivo (`AGENTS.md`)
2. `PROJECT_CONTEXT.md`
3. `TECHNICAL_DOC.md`
4. `NEXT_STEPS.md` (decisões + bugs abertos + roadmap)
