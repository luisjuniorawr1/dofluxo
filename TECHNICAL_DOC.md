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
- `DragTarget` por coluna
- Web: `Draggable` no ícone ⋮⋮
- Mobile: `LongPressDraggable` no card inteiro
- Tap no card → `ProjectDetailPage`

Pacote `appflowy_board` no `pubspec.yaml` é **dependência morta**.

### Multi-tenancy

`agencyId = FirebaseAuth.currentUser.uid` em `clients` e `projects`. Settings em `settings/{uid}`.

### Layout responsivo manual

| Breakpoint | Constante | Uso |
|------------|-----------|-----|
| 768px | `DashboardLayoutBreakpoints.mobileCarousel` | Carrossel vs colunas fixas |
| 720px | `compactHeader` | Header do dashboard |
| 900px | `MainShell` | Sidebar vs drawer |
| 800px | Login | Painel branding |

### SettingsService

`lib/core/settings/settings_service.dart` centraliza leitura/escrita de `settings/{uid}` (`agencyName`, `primaryColor`).

---

## Arquitetura

```
main.dart
  → Firebase.initializeApp
  → ThemeProvider (+ SettingsService no boot)
  → MaterialApp(home: AuthGate)
       ├─ LoginPage
       └─ MainShell
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

Nenhum DI container. Services instanciados inline:

```dart
final ProjectService _projectService = ProjectService();
```

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
| `applySettings({primaryColor, agencyName})` | Atualiza branding |
| `toggleTheme()` | Alterna claro/escuro |

### Local — telas

| Tela | Mecanismo |
|------|-----------|
| `DashboardPage` | `setState` + `StreamBuilder` projetos |
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

### AuthService

```dart
Stream<User?> get authStateChanges
Future<User?> signInWithGoogle()  // Web only
Future<void> signOut()
```

### ProjectService

| Método | Firestore |
|--------|-----------|
| `addProject` | `projects.add` — injeta `agencyId`, `status`, `createdAt`, `progress` |
| `updateProjectStatus` | `projects.doc.update({status, updatedAt})` |
| `updateProject` | update parcial + `updatedAt` |
| `getProjectsStream` | query `agencyId` + `orderBy createdAt desc` |
| `getProjectStream` | `doc.snapshots()` |

### ClientService

| Método | Firestore |
|--------|-----------|
| `addClient` | `clients.add` |
| `updateClient` | `clients.doc.update` |
| `getClientsStream` | query com índice composto |
| `deleteClient` | `clients.doc.delete` |

### Regras (resumo)

- `settings/{userId}`: read/write se `auth.uid == userId`
- `clients`, `projects`: read/write/delete se `resource.data.agencyId == auth.uid`

---

## Modelos de dados

### `ProjectBoardItem` (UI)

Mapeado de Firestore em `project_board_item.dart`. Campos: `id`, `title`, `clientName`, `description`, `progress`, `statusLabel`, `date`, etc.

`progress` prioriza cálculo a partir de `productionTasks`; fallback para campo `progress` numérico.

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
| `postagensDoDia` | Postagens do dia | `Postagens` |
| `criacao` | Criação | `Criação` |
| `incendios` | INCÊNDIOS | `Incêndios` |
| `captacao` | Captação | `Captação` |
| `edicao` | Edição | `Edição` |
| `aprovacao` | Aprovação | `Aprovação` |

Mapeamento bidirecional: `DashboardBoardMapper.stageIdForStatus` / `firestoreStatusForStage`.

### Fluxo de dados

```
getProjectsStream()
  → DashboardBoardMapper.groupSnapshot()
  → Map<stageKey, List<ProjectBoardItem>>
  → DashboardBoardLayout
       → WorkflowColumn (desktop) ou PageView (mobile)
       → ProjectStatusPanel (progresso %)
```

### Criar projeto — `NewProjectDialog`

Campos enviados ao Firestore:
- `title`, `description`, `clientId`, `clientName`
- `productionTasks[]`, `progress`
- `expectedDeliveryDate` (via `ExpectedDeliveryDateField`)

### Detalhe — `ProjectDetailPage`

- Stream do documento `projects/{docId}`
- Radio de fase → `updateProject` com novo `status`
- Checkbox atividades → atualiza `productionTasks` + `progress`
- Campos texto → salvar via botão Salvar

### Drag-and-drop

```dart
// dashboard_page.dart
_moveProject(projectId, targetStage)
  → DashboardBoardMapper.firestoreStatusForStage(targetStage)
  → ProjectService.updateProjectStatus()
```

`DashboardBoardLayout` desabilita scroll do `PageView` durante drag (`_isDragging`).

### Data de entrega

- Criação: `NewProjectDialog` + `ExpectedDeliveryDateField` (opcional)
- Edição: `ProjectDetailPage` — mesmo widget
- Persistência: `expectedDeliveryDate` como `Timestamp` no Firestore
- Card Kanban: linha `ENTREGA PREVISTA: dd/MM/yyyy` quando definida

### Mobile

7 páginas no carrossel: 6 colunas + painel Status. Navegação por:
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

`ProjectBoardCard` calcula cor de texto pela luminância do fundo do card (cores saturadas por estágio em `dashboard_stages.dart`). Colunas no dark mode usam `surfaceContainerHigh`; títulos usam `onSurface`.

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
| `dashboard_board_mapper_test.dart` | Mapeamento status, snapshot, progresso |
| `delivery_calendar_mapper_test.dart` | Agrupamento por data de entrega |
| `client_social_link_test.dart` | Detecção de plataformas |
| `dashboard_page_test.dart` | Smoke layout (viewport amplo) |
| `theme_toggle_test.dart` | Toggle ThemeProvider |
| `widget_test.dart` | Smoke login |

Testes widget **não** inicializam Firebase — `AuthGate` pode exigir mock em testes de integração futuros.

---

## Guia rápido: onde alterar o quê

| Necessidade | Arquivo(s) |
|-------------|------------|
| Tema global / contraste | `app_theme.dart`, `theme_utils.dart`, `theme_provider.dart` |
| Auth / logout | `auth_service.dart`, `main.dart` (`AuthGate`) |
| Kanban UI | `dashboard_workflow_board.dart`, `dashboard_board_layout.dart` |
| Mapeamento colunas | `dashboard_board_mapper.dart`, `dashboard_stages.dart` |
| CRUD projetos | `project_service.dart`, `project_detail_page.dart`, `new_project_dialog.dart` |
| CRUD clientes | `client_service.dart`, `client_form_page.dart` |
| Settings agência | `settings_service.dart`, `profile_page.dart` |
| Calendário entregas | `sidebar_delivery_calendar.dart`, `delivery_calendar_mapper.dart` |
| Datas | `date_format_utils.dart`, `expected_delivery_date_field.dart` |
| Firestore rules/indexes | `firestore.rules`, `firestore.indexes.json` |
| Shell / menu | `main_shell.dart` |
| Roadmap | `NEXT_STEPS.md` |

---

## Histórico de mudanças relevantes (jun/2026)

- Substituição do board `appflowy_board` por implementação custom
- Sync completo projetos ↔ Firestore
- `ProjectDetailPage` com atividades de produção
- CRUD clientes + redes sociais
- `AuthGate`, logout, `firestore.rules`, índices
- `AppTheme` expandido para legibilidade dark/light
- Carrossel mobile com navegação explícita
- Correção imports `project_board_item.dart` (build Web)
- Calendário lateral de entregas previstas na sidebar
- `DateFormatUtils` unificado para Firestore e UI
- Teste `delivery_calendar_mapper_test.dart`

---

*Revisar este documento ao alterar Kanban, auth, schema Firestore ou sistema de temas.*
