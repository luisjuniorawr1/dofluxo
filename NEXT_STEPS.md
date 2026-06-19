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
| Kanban 6 colunas + status | UI custom; sync Firestore leitura/escrita |
| Drag-and-drop | Persiste `status`; handle Web / long-press mobile |
| Criar projeto | Cliente obrigatório, atividades, data entrega |
| Detalhe do projeto | Edição completa, fase, atividades, links |
| Progresso de produção | % no painel Status do Projeto |
| CRUD clientes | Formulário completo + redes sociais + delete confirmado |
| Settings agência | Nome + cor; `SettingsService`; nome na UI |
| Tema claro/escuro | `AppTheme` com contraste em todas as telas |
| Layout mobile | Carrossel com chips, setas e bolinhas |
| Calendário de entregas | Sidebar: grade mensal, entregas por dia, tap → detalhe |
| Data entrega nos projetos | Criar/editar via `ExpectedDeliveryDateField`; exibida no card |
| Configurações na sidebar | Link para `ProfilePage` |
| Testes unitários | `dashboard_board_mapper_test`, `delivery_calendar_mapper_test`, `client_social_link_test` |
| Testes widget | Login, tema, dashboard smoke |

---

## O que está parcialmente pronto 🟡

| Item | Funciona | Falta | Prioridade |
|------|----------|-------|------------|
| **Auth mobile** | Estrutura Android Firebase | `google_sign_in` em `AuthService` | 🟠 P1 |
| **Projetos** | Criar, mover, editar detalhes | Excluir projeto; editar cliente após criação | 🟡 P2 |
| **Tema escuro/claro** | Toggle em sessão | Persistir em Firestore ou `shared_preferences` | 🟢 P3 |
| **Equipe** | Placeholder navegável | Qualquer feature real | 🟢 P3 |
| **Publicação** | App roda local (`flutter run`) | Firebase Hosting ou loja | 🟡 P2 (quando for vender) |
| **Arquitetura** | Services funcionais | Repository layer; entidades domain | 🟢 P3 |
| **Dependências** | Pacotes core em uso | Remover `appflowy_board`, `flutter_bloc`, etc. | 🟡 P2 |
| **Testes** | Unit + smoke widget | Firebase mock; E2E auth/CRUD | 🟡 P2 |

---

## Decisões tomadas (para não reverter sem motivo)

1. **Kanban custom** em vez de `appflowy_board` — drag via `Draggable`/`LongPressDraggable` + `DragTarget`.
2. **Auth guard** no `home` do `MaterialApp` (`AuthGate`), não `Navigator` pós-login.
3. **Settings centralizados** em `SettingsService`; tema em `ThemeProvider.applySettings`.
4. **Cliente obrigatório** na criação de projeto — `clientName` denormalizado no doc.
5. **Progresso** calculado de `productionTasks`, salvo em `progress` no Firestore.
6. **Firestore multi-tenant** por `agencyId`; rules no repositório.
7. **Mobile Kanban** — navegação explícita (chips/setas), não só swipe (conflito de gestos com listas).
8. **Visibilidade de fontes** — `ColorScheme` + `ThemeUtils`; evitar `Color(0x...)` em textos de UI.
9. **Calendário lateral** — reutiliza `getProjectsStream()`; não duplicar query; datas via `DateFormatUtils`.
10. **`expectedDeliveryDate`** — gravado como `Timestamp` no Firestore; leitura tolera formatos legados (string).

---

## Bugs corrigidos ✅

| ID | Descrição | Onde |
|----|-----------|------|
| B1 | Projetos não reapareciam ao recarregar | `getProjectsStream` no Dashboard |
| B2 | Drag não persistia status | `updateProjectStatus` no workflow board |
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

---

## Próximas tarefas (ordem sugerida)

### Sprint 1 — Vender / entregar MVP Web 🟠

| # | Tarefa | Esforço |
|---|--------|---------|
| 1 | Login Google Android (`google_sign_in` + `AuthService`) | Médio |
| 2 | Excluir projeto (UI + `ProjectService.deleteProject`) | Baixo |
| 3 | Persistir `ThemeMode` (settings ou local) | Baixo |
| 4 | Remover dependências mortas do `pubspec.yaml` | Baixo |
| 5 | Corrigir warnings analyzer (RadioGroup, `initialValue` em dropdown) | Baixo |

### Sprint 2 — Publicação (quando for ao ar) 🟡

| # | Tarefa | Esforço |
|---|--------|---------|
| 6 | Firebase Hosting (`flutter build web` + deploy) | Médio |
| 7 | README de setup para novos devs | Baixo |
| 8 | CI: `flutter analyze` + `flutter test` | Baixo |

### Sprint 3 — Produto 🟢

| # | Tarefa | Esforço |
|---|--------|---------|
| 9 | Tela Equipe | Alto |
| 10 | Camada repository | Alto |
| 11 | `go_router` + deep links | Médio |
| 12 | Firebase iOS | Baixo |
| 13 | Testes integração com Firebase emulator | Médio |

---

## Critérios de MVP pronto (atualizado)

- [x] Usuário loga (Web) e permanece logado ao recarregar
- [x] Projetos persistem e aparecem no Kanban após reload
- [x] Arrastar card atualiza status no Firestore
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
3. Kanban: `dashboard_workflow_board.dart` + `dashboard_board_mapper.dart`.
4. Projetos: `project_service.dart`, `project_detail_page.dart`, `new_project_dialog.dart`.
5. Não reintroduza `appflowy_board` sem decisão explícita — o board atual é custom.
6. Qualquer query `agencyId + orderBy(createdAt)` exige índice em `firestore.indexes.json`.
7. Calendário: `sidebar_delivery_calendar.dart` + `delivery_calendar_mapper.dart` — mesma stream de projetos.
8. Datas: sempre usar `DateFormatUtils` para ler/gravar `expectedDeliveryDate`.

---

*Atualizar este arquivo ao concluir tarefas ou descobrir novos bugs.*
