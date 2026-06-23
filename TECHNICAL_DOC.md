# TECHNICAL_DOC — DOFLUXO

Documentação técnica para desenvolvedores continuarem o projeto **DOFLUXO** sem contexto prévio.

Complementos: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) (visão produto), [`NEXT_STEPS.md`](NEXT_STEPS.md) (roadmap e bugs).

**Última atualização:** junho/2026

---

## Índice

1. [Decisões técnicas](#decisões-técnicas)
2. [Arquitetura](#arquitetura)
3. [Gerenciamento de estado](#gerenciamento-de-estado)
4. [Firebase](#firebase)
5. [Modelos de dados](#modelos-de-dados)
6. [Kanban e projetos](#kanban-e-projetos)
7. [Clientes](#clientes)
8. [Tema e acessibilidade visual](#tema-e-acessibilidade-visual)
9. [Calendário de entregas](#calendário-de-entregas)
10. [Rotas e navegação](#rotas-e-navegação)
11. [Tratamento de erros](#tratamento-de-erros)
12. [Testes](#testes)
13. [Guia rápido: onde alterar o quê](#guia-rápido-onde-alterar-o-quê)

---

## Decisões técnicas

### Flutter + Firebase

Stack MVP: Flutter + Firebase Auth + Firestore. Sem API REST. Services na `presentation/` acessam SDK diretamente.

**Trade-off:** migração futura exige camada de repositório.

### Auth Web nativa (sem `google_sign_in`)

`AuthService.signInWithGoogle()` usa `signInWithPopup(GoogleAuthProvider())` na Web.

Mobile: retorna `null` — `google_sign_in` está no `pubspec.yaml` mas **não implementado**.

### Auth guard centralizado

`AuthGate` em `main.dart` escuta `authStateChanges` e define `home` do `MaterialApp`. Login **não** usa `pushReplacement` para `MainShell`.

### Provider (não BLoC)

`ThemeProvider` global. `flutter_bloc` e classes `AuthState` / `ClientsState` existem mas **não são usadas**.

### Kanban custom (não `appflowy_board`)

Board implementado em `dashboard_workflow_board.dart`:
- `DragTarget` por coluna (5 colunas unificadas)
- Web/desktop: `Draggable` no card inteiro
- Mobile: `LongPressDraggable` no card inteiro
- Tap no card → `ProjectDetailPage`
- Coluna **Incêndios** com destaque visual (`isPriority`: borda, sombra, label)

**Removido:** painel lateral "Status do Projeto" (`project_status_panel.dart` — arquivo ainda no repo, não referenciado).

Pacote `appflowy_board` no `pubspec.yaml` é **dependência morta**.

### Categorias Job vs Planejamento digital

Ambas usam a coleção `projects`. Campo `category`: `job` | `planejamento`.

- **Job:** fluxo de produção (atividades, progresso)
- **Planejamento digital:** posts (data, formato, descrição, referência, `planningStatus`)

**Não** existem abas ou telas separadas na navegação — filtros `DashboardDisplayFilter` na Dashboard.

### Filtros de exibição na Dashboard

`DashboardDisplayFilter`: checkboxes Job / Planejamento digital.

`DashboardBoardMapper.groupSnapshot(snapshot, includeJobs:, includePlanning:)` filtra por categoria antes de agrupar.

### Multi-tenancy

**Atual (pós-3B):** `agencyId = AgencyContext.activeAgencyId` em `clients` e `projects`. Branding em `agencies/{activeAgencyId}` (3C).

Papéis Fase 1: `owner`, `admin`, `member` — sem `partner`.

Ver módulo `lib/core/agency/` e seção **Multi-agência** em [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md).

### SettingsService ⚠ Legado

`lib/core/settings/settings_service.dart` — **sem uso na UI após 3C**. Lido apenas no bootstrap legado via `AgencyService.loadLegacySettings(uid)` para popular `agencies/{uid}` na primeira migração.

### Branding (Subetapa 3C ✅)

| Componente | Função |
|------------|--------|
| `agencies/{activeAgencyId}` | Fonte de verdade: `name`, `primaryColor` |
| `AgencyContext` | `activeAgencyName`, `activePrimaryColor`, `updateActiveAgencyBranding()` |
| `AgencyBrandingSync` | Listener → `ThemeProvider.applyAgencyBranding()` |
| `ThemeProvider` | UI: sidebar, AppBar, login panel, `MaterialApp` themes |
| `ProfilePage` | Edição owner/admin → `updateActiveAgencyBranding` (Firestore `agencies/`) |

Membro (`member`): `canManageSettings == false` → botão Configurações oculto na Dashboard.

Logout: `AgencyContext.reset()` + `ThemeProvider.resetToDefaults()`.

### AgencyContext (Fase 1 — Etapa 1)

`lib/core/agency/agency_context.dart` — estado global:

| Propriedade | Descrição |
|-------------|-----------|
| `activeAgencyId` | Agência em uso |
| `activeAgency` | Branding carregado |
| `activeMembership` | Role do usuário |
| `memberships` | Agências do usuário |
| `needsOnboarding` | Wizard necessário (usuário novo) |
| `needsAgencySelection` | Seletor necessário (2+ agências) |
| `canManageSettings` | owner ou admin |
| `hasMultipleAgencies` | 2+ memberships (sem fallback legado) |
| `selectAgency(id)` | Persiste `activeAgencyId` + recarrega branding |
| `createFirstAgency` | Wizard — UUID + membership owner |

Serviços: `UserService`, `AgencyService`, `MembershipService`, `AgencyBootstrapService`.

### AgencyGate (Subetapas 3A–3D ✅)

`lib/presentation/agency/agency_gate.dart` — após login:

1. `AgencyContext.initialize(user)` → bootstrap + migração legada
2. `needsOnboarding` → `AgencyOnboardingPage` (wizard)
3. `needsAgencySelection` → `AgencySelectionPage`
4. `hasActiveAgency` → `AgencyBrandingSync` + services + `MainShell` (+ `AgencySwitcher` na sidebar se 2+ agências)

`ProjectService` / `ClientService` recebem `agencyId: activeAgencyId` (3B). Rotas empurradas usam `AgencyServiceScope.wrapRoute` (3B).

Logout em `AuthGate` chama `AgencyContext.reset()` + `ThemeProvider.resetToDefaults()`.

---

| Breakpoint | Constante | Uso |
|------------|-----------|-----|
| 768px | `DashboardLayoutBreakpoints.mobileCarousel` | Carrossel vs colunas fixas |
| 720px | `compactHeader` | Header do dashboard |
| 900px | `MainShell` | Sidebar vs drawer |
| 800px | Login | Painel branding |

### Layout responsivo manual

## Arquitetura

```
main.dart
  → Firebase.initializeApp
  → MultiProvider(ThemeProvider, AgencyContext)
  → MaterialApp(home: AuthGate)
       ├─ LoginPage
       └─ AgencyGate (3A–3D)
            ├─ AgencyOnboardingPage / AgencySelectionPage
            └─ AgencyBrandingSync + MainShell (+ AgencySwitcher)
                 ├─ DashboardPage → Kanban + NewProjectDialog + ProjectDetailPage
                 ├─ ClientsPage → ClientFormPage
                 ├─ SidebarDeliveryCalendar (na sidebar)
                 └─ TeamPlaceholder
```

### Camadas

| Camada | Status |
|--------|--------|
| `core/` | Tema, settings, utils — **ativo** |
| `presentation/` | UI + services — **ativo** |
| `domain/entities/` | **não integrado** |
| Repository / data | **inexistente** |

### Injeção de dependências

`ProjectService` e `ClientService` injetados via `MultiProvider` no `AgencyGate` (3B), com `agencyId: activeAgencyId`.

Rotas/dialogs empurrados recebem instâncias via `AgencyServiceScope.wrapRoute`.

---

## Gerenciamento de estado

### Global — `ThemeProvider`

| Propriedade | Descrição |
|-------------|-----------|
| `primaryColor` | Cor da marca |
| `agencyName` | Nome exibido (default "Pequi") |
| `themeMode` | `light` / `dark` (só em memória) |

| Método | Efeito |
|--------|--------|
| `applyAgencyBranding({name, color})` | Sincroniza com `agencies/{activeAgencyId}` (3C) |
| `resetToDefaults()` | Pequi / `#FFD700` — chamado no logout |
| `toggleTheme()` | Alterna claro/escuro |

### Local — telas

| Tela | Mecanismo |
|------|-----------|
| `DashboardPage` | `setState` + `StreamBuilder` + filtros `_showJobs` / `_showPlanning` |
| `ProjectDetailPage` | `setState` + `StreamBuilder` documento |
| `ClientsPage` | `StreamBuilder` clientes |
| `ClientFormPage` | `setState` + controllers |
| `MainShell` | `setState` índice aba |

### Reativo — Firestore

Padrão: `StreamBuilder<QuerySnapshot>` ou `StreamBuilder<DocumentSnapshot>`.

---

## Firebase

**Project ID:** `dofluxo-organizer`

### Arquivos de infra

| Arquivo | Função |
|---------|--------|
| `firestore.rules` | Isolamento por `agencyId` / `uid` |
| `firestore.indexes.json` | `agencyId ASC` + `createdAt DESC` |
| `.firebaserc` | Projeto default |
| `firebase.json` | Rules + indexes + FlutterFire |
| `lib/firebase_options.dart` | Web + Android |

Deploy:

```bash
firebase deploy --only firestore
```

### Coleções multi-agência (Fase 1)

| Coleção | Doc ID | Função |
|---------|--------|--------|
| `users/{uid}` | uid | Perfil + `activeAgencyId` |
| `agencies/{agencyId}` | UUID ou uid (legado) | Branding + metadados |
| `memberships/{agencyId}_{userId}` | composto | Permissões (owner/admin/member) |

Bootstrap legado (`AgencyBootstrapService`):

1. Se `settings/{uid}` ou docs com `agencyId=uid` existem → cria `agencies/{uid}` + membership owner.
2. Se nada existe → `needsOnboarding` (wizard na Etapa 4).
3. 1 membership → auto-seleciona; 2+ → seletor.

**Rules e índices memberships:** ✅ Etapa 2 concluída. Rules transitórias com `isLegacyOwner` + membership. Backup: `docs/firestore-backup-pre-fase2.md`.

### AuthService

```dart
Stream<User?> get authStateChanges
Future<User?> signInWithGoogle()  // Web only
Future<void> signOut()
```

### ProjectService

| Método | Firestore |
|--------|-----------|
| `addProject` | `projects.add` — injeta `agencyId` (= `activeAgencyId`), `category`, `status`, `createdAt`, `progress` |
| `updateProjectStatus` | `projects.doc.update({status, updatedAt})` — legado; preferir `updateProject` |
| `updateProject` | update parcial + `updatedAt` |
| `getProjectsStream` | query `where agencyId == activeAgencyId` + `orderBy createdAt desc` |
| `getProjectStream` | `doc.snapshots()` |

### ClientService

| Método | Firestore |
|--------|-----------|
| `addClient` | `clients.add` |
| `updateClient` | `clients.doc.update` |
| `getClientsStream` | query com índice composto |
| `deleteClient` | `clients.doc.delete` |

### Regras (Fase 2 — transitórias)

Funções centrais (`firestore.rules`):

| Função | Descrição |
|--------|-----------|
| `isLegacyOwner(agencyId)` | `auth.uid == agencyId` — **fallback MVP** |
| `isActiveMember(agencyId)` | membership `{agencyId}_{uid}` com `status == active` |
| `canAccessAgency(agencyId)` | legado **OU** membro ativo |
| `isAgencyAdmin(agencyId)` | role `owner` ou `admin` |
| `isAgencyOwner(agencyId)` | role `owner` |

| Coleção | Acesso |
|---------|--------|
| `users/{uid}` | próprio usuário |
| `agencies/{id}` | membro ativo; create se `ownerId == uid`; update admin ou legado |
| `memberships/{id}` | própria ou admin; create bootstrap owner ou admin |
| `settings/{uid}` | **inalterado** — `auth.uid == userId` |
| `clients`, `projects` | `canAccessAgency(agencyId)`; `agencyId` imutável no update |

**TODO:** remover `isLegacyOwner` quando migração 100% + Etapa 3 estável (comentário no arquivo rules).

Validação local: `node test/firestore_rules_test.mjs` (requer Node.js). Ver `docs/firestore-rules-validation-fase2.md`.

### Índices compostos

Arquivo: `firestore.indexes.json`. Deploy: `firebase deploy --only firestore:indexes` (ou `firebase deploy --only firestore`).

| collectionGroup | Campos | Query / uso |
|-----------------|--------|-------------|
| `projects` | `agencyId ASC`, `createdAt DESC` | `ProjectService.getProjectsStream` |
| `clients` | `agencyId ASC`, `createdAt DESC` | `ClientService.getClientsStream` |
| `memberships` | `userId ASC`, `status ASC` | `MembershipService.listActiveForUser` |
| `memberships` | `userId ASC`, `status ASC`, `joinedAt DESC` | reserva / ordenação futura |
| `memberships` | `agencyId ASC`, `status ASC` | reserva (equipe usa `activeMemberIds`) |
| `agency_invite_codes` | `agencyId ASC`, `status ASC` | `InviteCodeService.watchActiveForAgency` |

**Índice de campo único (não versionado):** `users.email` — query `where('email', isEqualTo: …)` em `UserService.findByEmail`. O Firestore indexa automaticamente; **não** declarar em `firestore.indexes.json` (deploy rejeita com *"this index is not necessary, configure using single field index controls"*).

---

## Modelos de dados

### `ProjectBoardItem` (UI)

Mapeado de Firestore em `project_board_item.dart`.

Campos comuns: `id`, `title`, `clientName`, `description`, `expectedDeliveryDate`, `statusLabel`, `progress`, `isCompleted`.

Campos planejamento: `isPlanejamento`, `format`, `planningStatusLabel`, `accentColor` (cor do status).

`progress` prioriza cálculo a partir de `productionTasks`; fallback para campo `progress` numérico.

### `ProjectCategory`

```dart
enum ProjectCategory { job, planejamento }
```

Firestore: `category: 'job' | 'planejamento'`. Default/legado: `job`.

Helper: `isPlanejamentoProject(data)`, `projectCategoryFromFirestore(value)`.

### `PlanningStatus` + `PlanningFormat`

Status de posts (`planning_status.dart`):

| ID Firestore | Label | Cor (UI) |
|--------------|-------|----------|
| `pendente` | Pendente | Cinza |
| `emProducao` | Em produção | Laranja |
| `pronto` | Pronto | Azul |
| `agendado` | Agendado | Roxo |
| `publicado` | Publicado | Verde |

Formatos: Feed, Reels, Stories, Carrossel, Vídeo, Outro.

Sincronização ao mover no Kanban: `DashboardBoardMapper.planningStatusForStage(stage)`.

### `ProjectProductionTask`

```dart
{ label: string, completed: bool }
```

Helpers em `project_production_task.dart`:
- `progressFromTasks` → `double?` 0.0–1.0
- `serializeList` / `listFromFirestore`

### `ClientSocialLink` + `SocialPlatform`

Detecção automática de plataforma a partir de URL, @handle ou telefone. Persistido em `socialLinks[]`.

`ThemeUtils.brandColor()` ajusta ícones pretos (TikTok, X) no tema escuro.

### `DateFormatUtils` (`core/utils/date_format_utils.dart`)

| Função | Uso |
|--------|-----|
| `dateOnly` | Normaliza para meia-noite local |
| `isSameDay` / `isSameMonth` | Comparação de calendário |
| `fromFirestore` | Lê `Timestamp`, `DateTime` ou string `dd/MM/yyyy` |
| `toFirestoreTimestamp` | Grava `Timestamp` ou `FieldValue.delete()` |
| `formatMonthYear`, `formatDayMonth` | Labels PT-BR na UI |

Usado em: cards do Kanban, `ExpectedDeliveryDateField`, calendário lateral, `ProjectDetailPage`.

### `CalendarDeliveryEntry`

```dart
{ projectId, title, deliveryDate, clientName?, statusLabel? }
```

`displayTitle` → `"Cliente - Título"` quando há cliente.

### Entidades domain (não usadas)

`UserEntity`, `ClientEntity`, `ProjectEntity` — código morto em `lib/domain/entities/`.

---

## Kanban e projetos

### Colunas (`DashboardStage.workflow`)

| `DashboardStageId` | Título UI | `status` Firestore |
|--------------------|-----------|-------------------|
| `incendios` | 🔥 Incêndios | `Incêndios` |
| `planejamento` | 📋 Planejamento | `Planejamento` |
| `producao` | 🏃 Produção | `Produção` |
| `aprovacao` | 💬 Aprovação | `Aprovação` |
| `concluido` | ✅ Concluído | `Concluído` |

Mapeamento bidirecional: `DashboardBoardMapper.stageIdForStatus` / `firestoreStatusForStage`.

**Legado:** `Postagens`→Planejamento; `Criação`/`Captação`/`Edição`→Produção; etc. (ver `PROJECT_CONTEXT.md`).

### Fluxo de dados

```
getProjectsStream()
  → DashboardBoardMapper.groupSnapshot(includeJobs, includePlanning)
  → Map<stageKey, List<ProjectBoardItem>>
  → DashboardBoardLayout
       → WorkflowColumn × 5 (desktop) ou PageView (mobile)
```

### Criar projeto — `NewProjectDialog`

**SegmentedButton** escolhe categoria.

**Job** → Firestore: `category: job`, `title`, `description`, `clientId`, `clientName`, `productionTasks[]`, `progress`, `expectedDeliveryDate`, `status: Planejamento`.

**Planejamento digital** → `category: planejamento`, `format`, `reference`, `planningStatus`, `scheduledDate` (+ espelho `expectedDeliveryDate`), `description`, `title` opcional.

### Detalhe — `ProjectDetailPage`

- Stream do documento `projects/{docId}`
- UI bifurcada por `_isPlanejamento`
- **Job:** radios das 5 etapas Kanban + atividades de produção
- **Planejamento:** chips de `PlanningStatus` + campos data/formato/referência
- Salvar → `updateProject`

### Drag-and-drop

```dart
// dashboard_page.dart
_moveProject(projectId, targetStage)
  → DashboardBoardMapper.firestoreStatusForStage(targetStage)
  → DashboardBoardMapper.planningStatusForStage(targetStage)  // opcional sync
  → ProjectService.updateProject({ status, planningStatus? })
```

`DashboardBoardLayout` desabilita scroll do `PageView` durante drag (`_isDragging`).

### Data de entrega

- Job: `expectedDeliveryDate` via `ExpectedDeliveryDateField`
- Planejamento: `scheduledDate` (gravado também em `expectedDeliveryDate` para calendário)
- Card Kanban: linha `DATA: dd/MM/yyyy` quando definida

### Mobile

5 páginas no carrossel (uma por coluna). Navegação por:
- `IconButton` chevron
- `ChoiceChip` horizontal
- Bolinhas clicáveis
- Swipe `PageView` (quando não está arrastando card)

---

## Clientes

### `ClientsPage`

Lista com `StreamBuilder`, ações editar/excluir, ícones de redes (`ClientSocialIconsRow`).

### `ClientFormPage`

Formulário completo + `ClientSocialLinksField` (detecção de plataforma em tempo real).

### Campos Firestore `clients`

`name`, `email`, `phone`, `sector`, `responsible`, `address`, `socialLinks`, `agencyId`, `createdAt`.

---

## Tema e acessibilidade visual

### `AppTheme.build(primaryColor, brightness)`

Define `ColorScheme` com tokens explícitos para light/dark:
- `onSurface`, `onSurfaceVariant`, `surfaceContainer*`
- `inputDecorationTheme`, `cardTheme`, `listTileTheme`
- `chipTheme`, `dialogTheme`, `snackBarTheme`
- `checkboxTheme`, `radioTheme`, botões

### `ThemeUtils`

| Função | Uso |
|--------|-----|
| `getContrastColor` | Texto sobre cor primária |
| `brandColor` | Ícones de redes no dark mode |
| `sectionTitle` | Títulos de seção |
| `bodyMuted` | Texto secundário |
| `successColor` | Barras de progresso verdes |

### Cards do Kanban

`ProjectBoardCard`:
- Cores por estágio em `dashboard_stages.dart`
- **Job:** badge check + progresso no card
- **Planejamento:** borda/barra lateral na cor do `planningStatus`; label "PLANEJAMENTO"; exibe formato

Colunas no dark mode usam `surfaceContainerHigh`; coluna Incêndios com borda/sombra vermelha.

### Toggle de tema

`ThemeToggleButton` em login, sidebar, AppBar mobile, perfil. **Não persiste** entre sessões.

---

## Calendário de entregas

### Componentes

| Arquivo | Responsabilidade |
|---------|------------------|
| `sidebar_delivery_calendar.dart` | UI: grade mensal, painel do dia, navegação |
| `delivery_calendar_mapper.dart` | Agrupa `QuerySnapshot` por `expectedDeliveryDate` |
| `calendar_delivery_entry.dart` | Modelo de item no calendário |

### Fluxo

```
MainShell._buildSidebar()
  → SidebarDeliveryCalendar
       → StreamBuilder(getProjectsStream)
       → DeliveryCalendarMapper.fromSnapshot()
       → grade com bolinhas nos dias com entregas
       → tap no dia → lista entregas
       → tap na entrega → onProjectTap(projectId)
            → MainShell._openProjectFromCalendar()
            → ProjectDetailPage
```

### Regras de inclusão

- Projeto entra no calendário só se tem `title` não vazio **e** `expectedDeliveryDate` parseável.
- `statusLabel` derivado de `DashboardBoardMapper` (mesma lógica dos cards).
- Ordenação por título dentro de cada dia.

### UX

- Cores e textos usam `onPrimary` da sidebar (fundo `primaryColor`).
- Mobile: fecha drawer antes de abrir detalhe do projeto.

---

## Rotas e navegação

Navegação imperativa (`Navigator.push`), sem `go_router`.

| Origem | Destino | Método |
|--------|---------|--------|
| `AuthGate` | `MainShell` / `LoginPage` | automático |
| `MainShell` sidebar | `ProfilePage` | `push` |
| `DashboardPage` | `ProfilePage`, `ProjectDetailPage` | `push` |
| `ClientsPage` | `ClientFormPage` | `push` |
| Calendário sidebar | `ProjectDetailPage` | `push` via `onProjectTap` |

`ProfilePage` não está no índice do `MainShell`.

---

## Tratamento de erros

| Operação | Sucesso | Erro |
|----------|---------|------|
| Login | AuthGate navega | SnackBar vermelho |
| Criar projeto | SnackBar | SnackBar |
| Mover projeto | sync stream | SnackBar |
| Salvar perfil/projeto | SnackBar verde | SnackBar |
| Listar clientes/projetos | UI inline | Texto com `colorScheme.error` |
| Excluir cliente | silencioso | SnackBar |

Services: `try/catch` + `debugPrint` ou retorno antecipado se `user == null`.

---

## Testes

| Arquivo | Cobertura |
|---------|-----------|
| `dashboard_board_mapper_test.dart` | Mapeamento status (incl. legado), snapshot, filtros categoria, planejamento |
| `delivery_calendar_mapper_test.dart` | Agrupamento por data de entrega |
| `client_social_link_test.dart` | Detecção de plataformas |
| `dashboard_page_test.dart` | Smoke layout Kanban 5 colunas + filtros Exibir |
| `agency_models_test.dart` | Serialização Agency/Membership, papéis Fase 1 |
| `firestore_rules_test.mjs` | Rules Fase 2 — legado, membership, settings (requer Node.js) |
| `theme_toggle_test.dart` | Toggle ThemeProvider |
| `widget_test.dart` | Smoke login |

Testes widget **não** inicializam Firebase — `AuthGate` pode exigir mock em testes de integração futuros.

---

## Guia rápido: onde alterar o quê

| Necessidade | Arquivo(s) |
|-------------|------------|
| Tema global / contraste | `app_theme.dart`, `theme_utils.dart`, `theme_provider.dart` |
| Auth / logout / agency gate | `auth_service.dart`, `main.dart` (`AuthGate`), `agency_gate.dart` |
| Kanban UI | `dashboard_workflow_board.dart`, `dashboard_board_layout.dart` |
| Filtros dashboard | `dashboard_display_filter.dart`, `dashboard_page.dart` |
| Mapeamento colunas | `dashboard_board_mapper.dart`, `dashboard_stages.dart` |
| Categorias / planejamento | `project_category.dart`, `planning_status.dart`, `planning_status_chip.dart` |
| CRUD projetos | `project_service.dart`, `project_detail_page.dart`, `new_project_dialog.dart` |
| CRUD clientes | `client_service.dart`, `client_form_page.dart` |
| Settings agência | `agency_context.dart`, `agency_service.dart`, `profile_page.dart`; legado bootstrap: `settings_service.dart` |
| Branding sync | `agency_branding_sync.dart`, `theme_provider.dart`, `agency_gate.dart` |
| Onboarding / seletor / switcher | `agency_onboarding_page.dart`, `agency_selection_page.dart`, `agency_switcher.dart` |
| Multi-agência / permissões | `lib/core/agency/` |
| Bootstrap / migração legada | `agency_bootstrap_service.dart` |
| Calendário entregas | `sidebar_delivery_calendar.dart`, `delivery_calendar_mapper.dart` |
| Datas | `date_format_utils.dart`, `expected_delivery_date_field.dart` |
| Firestore rules/indexes | `firestore.rules`, `firestore.indexes.json`, `docs/firestore-backup-pre-fase2.md` |
| Shell / menu | `main_shell.dart` |
| Roadmap | `NEXT_STEPS.md` |

---

## Histórico de mudanças relevantes (jun/2026)

- Substituição do board `appflowy_board` por implementação custom
- Sync completo projetos ↔ Firestore
- **Redesign Kanban:** 5 colunas unificadas (Incêndios → Concluído); Job + Planejamento no mesmo board
- **Categorias de projeto:** `job` e `planejamento` com formulários condicionais
- **Filtros Exibir:** Job / Planejamento digital na Dashboard (sem abas separadas)
- Remoção do painel "Status do Projeto" e colunas legadas (Postagens, Criação, Captação, Edição separadas)
- Coluna Incêndios com destaque visual de prioridade
- `ProjectDetailPage` com UI bifurcada por categoria
- `planningStatus`, `format`, `reference`, `scheduledDate` em `projects`
- Mapeamento de status legados em `DashboardBoardMapper`
- `AppTheme` expandido para legibilidade dark/light
- Carrossel mobile com 5 colunas
- Calendário lateral de entregas previstas na sidebar
- `DateFormatUtils` unificado para Firestore e UI

---

*Revisar este documento ao alterar Kanban, auth, schema Firestore ou sistema de temas.*
