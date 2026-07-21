# NEXT_STEPS — DOFLUXO

Roadmap prático para continuidade do projeto.  
Complementa [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) e [`TECHNICAL_DOC.md`](TECHNICAL_DOC.md).

**Última atualização:** junho/2026

**Legenda:**

| Nível | Significado |
|-------|-------------|
| 🔴 **P0** | Bloqueador para produção ou venda do produto |
| 🟠 **P1** | Alta — funcionalidade core incompleta |
| 🟡 **P2** | Média — melhoria importante |
| 🟢 **P3** | Baixa — polish, dívida técnica |

---

## O que está pronto ✅

| Item | Detalhe |
|------|---------|
| Bootstrap Firebase | Web + Android; `AuthGate` no `main.dart` |
| Login Google (Web) | `signInWithPopup` + loading + erro |
| Auth guard + logout | `authStateChanges`; botão Sair na sidebar |
| Firestore rules + índices | `firestore.rules`, `firestore.indexes.json` versionados e deployados |
| **Kanban unificado 5 colunas** | Incêndios, Planejamento, Produção, Aprovação, Concluído |
| **Job + Planejamento no mesmo board** | Filtros `Exibir:` Job / Planejamento digital |
| **Categorias de projeto** | `NewProjectDialog` + `ProjectDetailPage` condicionais |
| **Status planejamento colorido** | `planningStatus` + chips; sync ao arrastar no Kanban |
| **Coluna Incêndios destacada** | Borda, sombra, label "Prioridade máxima" |
| Drag-and-drop | Persiste `status` (+ `planningStatus`); Web drag / mobile long-press |
| Criar projeto | Cliente obrigatório; Job (atividades) ou Planejamento (data, formato, etc.) |
| Detalhe do projeto | Edição completa por categoria; etapa Kanban (5 radios) |
| Progresso de produção | % no card Kanban (Job) |
| CRUD clientes | Formulário completo + redes sociais + delete confirmado |
| Settings agência | Nome + cor; `SettingsService`; nome na UI |
| Tema claro/escuro | `AppTheme` com contraste em todas as telas |
| Layout mobile | Carrossel 5 colunas: chips, setas e bolinhas |
| Calendário de entregas | Sidebar: grade mensal, entregas por dia, tap → detalhe |
| Data entrega nos projetos | Job: `expectedDeliveryDate`; Planejamento: `scheduledDate` (+ espelho) |
| Configurações na sidebar | Link para `ProfilePage` |
| Testes unitários | `dashboard_board_mapper_test` (incl. legado + filtros), calendário, social links |
| Testes widget | Login, tema, dashboard smoke (5 colunas + filtros) |

---

## O que está parcialmente pronto 🟡

| Item | Funciona | Falta | Prioridade |
|------|----------|-------|------------|
| **Auth mobile** | Estrutura Android Firebase | `google_sign_in` em `AuthService` | 🟠 P1 |
| **Projetos** | Criar, mover, editar detalhes | Excluir projeto; editar cliente após criação | 🟡 P2 |
| **Kanban** | 5 colunas + drag manual | Regra automática Incêndios (itens atrasados); migrar docs legados em massa | 🟡 P2 |
| **Dashboard filtros** | Job/Planejamento em memória | Persistir preferência entre sessões | 🟢 P3 |
| **Tema escuro/claro** | Toggle em sessão | Persistir em Firestore ou `shared_preferences` | 🟢 P3 |
| **Equipe** | Placeholder navegável | Qualquer feature real | 🟢 P3 |
| **Publicação** | App roda local (`flutter run`) | Firebase Hosting ou loja | 🟡 P2 (quando for vender) |
| **Arquitetura** | Services funcionais | Repository layer; entidades domain | 🟢 P3 |
| **Dependências** | Pacotes core em uso | Remover `appflowy_board`, `flutter_bloc`, etc. | 🟡 P2 |
| **Código morto** | — | Remover `project_status_panel.dart` (não referenciado) | 🟢 P3 |
| **Testes** | Unit + smoke widget | Firebase mock; E2E auth/CRUD | 🟡 P2 |

---

## Decisões tomadas (para não reverter sem motivo)

1. **Kanban custom** em vez de `appflowy_board` — drag via `Draggable`/`LongPressDraggable` + `DragTarget`.
2. **Uma única Dashboard** — **não** criar abas ou telas separadas Job vs Planejamento digital.
3. **Categorias só em criar/editar** — campos de planejamento (data, formato, referência, status) não têm tela própria na navegação.
4. **Filtros `Exibir:`** na Dashboard controlam visibilidade de Job e Planejamento **dentro das mesmas colunas**.
5. **5 colunas Kanban fixas:** Incêndios → Planejamento → Produção → Aprovação → Concluído.
6. **Incêndios** é coluna de prioridade visual máxima (borda/sombra).
7. **Planejamento digital** usa coleção `projects` (`category: planejamento`) — **não** usar coleção `planning_posts`.
8. **Auth guard** no `home` do `MaterialApp` (`AuthGate`), não `Navigator` pós-login.
9. **Settings centralizados** em `SettingsService`; tema em `ThemeProvider.applySettings`.
10. **Cliente obrigatório** na criação de projeto — `clientName` denormalizado no doc.
11. **Progresso** calculado de `productionTasks`, salvo em `progress` no Firestore.
12. **Firestore multi-tenant** por `agencyId`; rules no repositório.
13. **Mobile Kanban** — navegação explícita (chips/setas), não só swipe (conflito de gestos com listas).
14. **Status default** ao criar: `Planejamento` (coluna Planejamento).
15. **Mapeamento legado** de status antigos (Postagens, Criação, etc.) em `DashboardBoardMapper` — manter compatibilidade.

---

## Bugs corrigidos ✅

| ID | Descrição | Onde |
|----|-----------|------|
| B1 | Projetos não reapareciam ao recarregar | `getProjectsStream` no Dashboard |
| B2 | Drag não persistia status | `updateProject` no workflow board |
| B3 | Sempre mostrava login | `AuthGate` |
| B4 | Índice Firestore ausente | `firestore.indexes.json` + deploy |
| B5 | Sem rules de segurança | `firestore.rules` + deploy |
| B6 | Não abria detalhe do projeto ao clicar | `ProjectDetailPage` + tap no card |
| B7 | Compiler Web crash (imports) | `project_board_item.dart` |
| B8 | Mobile não navegava entre colunas | `DashboardBoardLayout` mobile controls |
| B9 | Textos invisíveis no dark mode | `AppTheme` + ajustes por tela |
| B10 | `agencyName` ignorado na UI | `ThemeProvider` + `MainShell` |
| B11 | Clientes sem criar/editar | `ClientFormPage` |
| B12 | Login sem feedback de erro | SnackBar + loading em `LoginPage` |
| B21 | Projetos com data string legada não apareciam no calendário | `DateFormatUtils.fromFirestore` multi-formato |
| B23 | Abas Job/Planejamento rejeitadas pelo produto | Revertido; uma Dashboard + filtros |
| B24 | Cards soltos acima do Kanban | Removidos; fluxo unificado |
| B25 | Kanban 6 colunas + painel status obsoleto | Redesign 5 colunas sem painel lateral |

---

## Bugs / limitações conhecidas (abertas)

| ID | Descrição | Severidade | Prioridade |
|----|-----------|------------|------------|
| B13 | Login mobile retorna `null` | Alta | 🟠 P1 |
| B14 | `ThemeMode` não persiste ao fechar app | Baixa | 🟢 P3 |
| B15 | Projetos criados antes do vínculo cliente sem `clientName` | Baixa | 🟡 P2 |
| B16 | `RadioListTile` / `DropdownButtonFormField.value` deprecated (analyzer info) | Baixa | 🟡 P2 |
| B17 | `deleteClient` sem validação client-side de ownership (rules protegem no servidor) | Baixa | 🟢 P3 |
| B18 | `BlockPicker` (color picker) pode ter contraste ruim no dark | Baixa | 🟢 P3 |
| B19 | Testes widget não inicializam Firebase real | Média | 🟡 P2 |
| B20 | `appflowy_board` no pubspec sem uso | Baixa | 🟡 P2 |
| B22 | Calendário só na sidebar — sem vista full-screen | Baixa | 🟢 P3 |
| B26 | Filtros Job/Planejamento não persistem entre sessões | Baixa | 🟢 P3 |
| B27 | `project_status_panel.dart` órfão no repo | Baixa | 🟢 P3 |
| B28 | Incêndios depende de drag manual — sem auto-move por data | Média | 🟡 P2 |

---

## Próximas tarefas (ordem sugerida)

### Sprint 1 — Vender / entregar MVP Web 🟠

| # | Tarefa | Esforço |
|---|--------|---------|
| 1 | Login Google Android (`google_sign_in` + `AuthService`) | Médio |
| 2 | Excluir projeto (UI + `ProjectService.deleteProject`) | Baixo |
| 3 | Remover `project_status_panel.dart` e dependências mortas do `pubspec.yaml` | Baixo |
| 4 | Persistir `ThemeMode` (settings ou local) | Baixo |
| 5 | Corrigir warnings analyzer (RadioGroup, `initialValue` em dropdown) | Baixo |

### Sprint 2 — Kanban / produto 🟡

| # | Tarefa | Esforço |
|---|--------|---------|
| 6 | Regra automática: mover para Incêndios posts/jobs com entrega vencida | Médio |
| 7 | Persistir filtros Job/Planejamento (`shared_preferences` ou settings) | Baixo |
| 8 | Script/migração opcional: normalizar `status` legados no Firestore | Baixo |

### Sprint 3 — Publicação (quando for ao ar) 🟡

| # | Tarefa | Esforço |
|---|--------|---------|
| 9 | Firebase Hosting (`flutter build web` + deploy) | ✅ Feito — `.\deploy.ps1` |
| 9b | Atualização obrigatória web (`AppUpdateGate` + `version.json`) | ✅ Feito |
| 10 | README de setup para novos devs | Baixo |
| 11 | CI: `flutter analyze` + `flutter test` | Baixo |

> **Deploy web:** rode `.\deploy.ps1` na raiz. Ele incrementa a versão do `pubspec.yaml`, builda e publica. O bump de versão é o que dispara o aviso de atualização nos clientes com o app aberto.

### Sprint 4 — Produto 🟢

| # | Tarefa | Esforço |
|---|--------|---------|
| 12 | Tela Equipe | Alto |
| 13 | Camada repository | Alto |
| 14 | `go_router` + deep links | Médio |
| 15 | Firebase iOS | Baixo |
| 16 | Testes integração com Firebase emulator | Médio |

---

## Critérios de MVP pronto (atualizado)

- [x] Usuário loga (Web) e permanece logado ao recarregar
- [x] Projetos persistem e aparecem no Kanban após reload
- [x] Arrastar card atualiza status no Firestore
- [x] Job e Planejamento digital no mesmo Kanban com filtros
- [x] Categorias com formulários distintos em criar/editar
- [x] Clientes: criar, listar, editar, excluir (com confirmação)
- [x] Firestore rules impedem acesso entre agências
- [x] Índices Firestore criados e versionados
- [x] Logout funcional
- [x] Tema claro/escuro legível em todas as telas
- [x] Calendário de entregas na sidebar com navegação ao detalhe do projeto
- [ ] Login Android funcional
- [ ] Zero warnings relevantes em `flutter analyze`
- [ ] Testes passando em CI

---

## Comandos antes de começar

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
firebase deploy --only firestore   # se alterar rules/indexes
```

---

## Para outro agente continuar

1. Leia **`PROJECT_CONTEXT.md`** (visão geral) e **`TECHNICAL_DOC.md`** (detalhes técnicos).
2. Rode `flutter analyze` e `flutter test` para validar o ambiente.
3. Kanban: `dashboard_workflow_board.dart`, `dashboard_board_layout.dart`, `dashboard_board_mapper.dart`, `dashboard_stages.dart`.
4. Filtros: `dashboard_display_filter.dart` + `_showJobs` / `_showPlanning` em `dashboard_page.dart`.
5. Categorias: `project_category.dart`, `planning_status.dart`, `new_project_dialog.dart`, `project_detail_page.dart`.
6. **Não** reintroduza abas Job/Planejamento nem coleção `planning_posts`.
7. **Não** reintroduza `appflowy_board` sem decisão explícita.
8. Qualquer query `agencyId + orderBy(createdAt)` exige índice em `firestore.indexes.json`.
9. Calendário: `sidebar_delivery_calendar.dart` — mesma stream de projetos; datas via `DateFormatUtils`.
10. Status legados mapeados em `DashboardBoardMapper.stageIdForStatus` — preservar compatibilidade.

---

*Atualizar este arquivo ao concluir tarefas ou descobrir novos bugs.*
