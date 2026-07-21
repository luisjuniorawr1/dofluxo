# PROJECT_CONTEXT — DOFLUXO

Documento de referência do projeto **DOFLUXO** (marca interna: **Pequi Agência**).  
Última atualização: **junho/2026** — alinhado ao código em `lib/`, Firebase e dependências do `pubspec.yaml`.

---

## Objetivo do sistema

O **DOFLUXO** é um organizador de fluxo de trabalho para **agências criativas**. O sistema permite que uma agência:

- Faça login com conta Google (Web)
- Personalize identidade visual (nome + cor primária)
- Gerencie **projetos** em um **Kanban unificado** de 5 colunas (Job + Planejamento digital)
- Cadastre projetos em duas **categorias**: Job (produção) ou Planejamento digital (posts)
- Filtre na Dashboard o que exibir: Job, Planejamento digital, ou ambos
- Cadastre e edite **clientes** com redes sociais
- Acompanhe **atividades de produção** por projeto (% de conclusão)
- Visualize **entregas previstas** em calendário compacto na sidebar
- Alterne entre **tema claro e escuro** com textos legíveis em todas as telas

O produto está em estágio **MVP avançado**: fluxo principal Web + Firebase funcional; mobile auth, publicação e tela Equipe ainda pendentes.

---

## Tecnologias utilizadas

| Camada | Tecnologia |
|--------|------------|
| Framework | Flutter 3.x (SDK Dart ^3.10.0) |
| Linguagem | Dart |
| UI | Material Design 3 |
| Estado global | `provider` (`ChangeNotifier`) |
| Backend / Auth | Firebase (Auth, Firestore) |
| Kanban | Implementação **custom** (`dashboard_workflow_board.dart`) — **não** usa `appflowy_board` no código |
| Identificadores | `uuid` |
| Color picker | `flutter_colorpicker` |
| Plataformas configuradas | **Web** e **Android** (FlutterFire) |
| Testes | `flutter_test` |

**Firebase Project ID:** `dofluxo-organizer`

**Infra versionada no repo:** `firestore.rules`, `firestore.indexes.json`, `.firebaserc`, `firebase.json`, `docs/firestore-backup-pre-fase2.md`

---

## Estrutura de pastas

```
dofluxo/
├── lib/
│   ├── main.dart                          # Firebase, ThemeProvider, AuthGate
│   ├── firebase_options.dart
│   │
│   ├── core/
│   │   ├── agency/                        # Fase 1 multi-agência (Etapa 1 ✅)
│   │   │   ├── agency_context.dart        # activeAgencyId, memberships, bootstrap
│   │   │   ├── agency_branding_sync.dart  # 3C — ThemeProvider ← agencies/
│   │   │   ├── models/                    # Agency, Membership, UserProfile, AgencyRole
│   │   │   └── services/                  # User, Agency, Membership, Bootstrap
│   │   ├── settings/settings_service.dart # ⚠ Legado — só bootstrap lê settings/{uid}
│   │   ├── theme/
│   │   │   ├── app_theme.dart             # ThemeData completo light/dark
│   │   │   ├── theme_provider.dart        # Cor, agencyName, ThemeMode
│   │   │   ├── agency_theme.dart          # ⚠ Legado — não usado
│   │   │   └── app_colors.dart            # ⚠ Legado — não usado
│   │   └── utils/
│   │       ├── theme_utils.dart           # Contraste, brandColor, estilos
│   │       └── date_format_utils.dart
│   │
│   ├── domain/entities/                   # ⚠ Definidas, não integradas
│   │
│   └── presentation/
│       ├── auth/manager/auth_service.dart
│       ├── clients/
│       │   ├── manager/client_service.dart
│       │   ├── models/client_social_link.dart
│       │   ├── pages/clients_page.dart, client_form_page.dart
│       │   └── widgets/client_social_links_field.dart
│       ├── dashboard/
│       │   ├── config/dashboard_stages.dart, dashboard_layout_breakpoints.dart
│       │   ├── models/project_board_item.dart
│       │   ├── pages/dashboard_page.dart, login_page.dart
│       │   ├── utils/dashboard_board_mapper.dart
│       │   └── widgets/                   # Kanban, layout, filtros Exibir
│       ├── profile/pages/profile_page.dart
│       ├── projects/
│       │   ├── manager/project_service.dart
│       │   ├── models/project_production_task.dart, project_category.dart, planning_status.dart
│       │   ├── pages/project_detail_page.dart
│       │   └── widgets/new_project_dialog.dart, expected_delivery_date_field.dart, planning_status_chip.dart
│       ├── agency/                        # 3A–3D ✅
│       │   ├── agency_gate.dart
│       │   ├── agency_service_scope.dart
│       │   ├── pages/agency_onboarding_page.dart
│       │   ├── pages/agency_selection_page.dart
│       │   └── widgets/agency_switcher.dart
│       └── shared/
│           ├── main_shell.dart            # Sidebar, drawer, calendário, logout
│           ├── theme_toggle_button.dart
│           ├── models/calendar_delivery_entry.dart
│           ├── utils/delivery_calendar_mapper.dart
│           └── widgets/sidebar_delivery_calendar.dart
│
├── test/                                  # mapper, calendário, social links, widget smoke
├── firestore.rules
├── firestore.indexes.json
├── .firebaserc
├── firebase.json
└── pubspec.yaml
```

### Observação arquitetural

Esboço de Clean Architecture (`domain/`, `presentation/`, `core/`), mas na prática a `presentation` acessa Firebase via **services**, sem repositórios. Entidades e states BLoC existem como código morto.

**Fase 1 multi-agência (em andamento):** Etapas 1, 2 e **3 (3A–3D)** concluídas.

---

## Multi-agência — Fase 1 (jun/2026)

### Status de implementação

| Etapa | Escopo | Status |
|-------|--------|--------|
| **1** | Models, services, `AgencyContext`, bootstrap | ✅ Concluída |
| **2** | Firestore rules + índices memberships | ✅ Concluída |
| **3A** | `AgencyGate` + bootstrap + `AgencyContext` no app | ✅ Concluída |
| **3B** | Services → `activeAgencyId` | ✅ Concluída |
| **3C** | Branding da agência ativa | ✅ Concluída |
| **3D** | Wizard + seletor + switcher | ✅ Concluída |
| **4** | *(absorvida em 3D)* | — |

### Papéis (Fase 1)

| Role | Permissões |
|------|------------|
| `owner` | Controle total; único que pode excluir agência |
| `admin` | Settings + CRUD dados; gerencia equipe (futuro) |
| `member` | CRUD clientes/projetos; **sem** acesso a configurações |

Sem `partner` nesta fase.

### Fluxo pós-login (3A ✅)

```
Login → AuthGate
     → AgencyGate.initialize(user)
           → Bootstrap legado? agencies/{uid} + memberships/{uid}_{uid}
           → needsOnboarding → AgencyOnboardingPage (wizard 3D)
           → needsAgencySelection → AgencySelectionPage (3D)
           → hasActiveAgency → MainShell (+ AgencySwitcher se 2+ agências)
```

Logout → `AgencyContext.reset()` + `ThemeProvider.resetToDefaults()`.

### Subetapa 3B ✅ — arquivos alterados

```
lib/presentation/agency/agency_service_scope.dart          (criado)
lib/presentation/agency/agency_gate.dart
lib/presentation/clients/manager/client_service.dart
lib/presentation/clients/pages/client_form_page.dart
lib/presentation/clients/pages/clients_page.dart
lib/presentation/dashboard/pages/dashboard_page.dart
lib/presentation/projects/manager/project_service.dart
lib/presentation/projects/pages/project_detail_page.dart
lib/presentation/projects/widgets/new_project_dialog.dart
lib/presentation/shared/main_shell.dart
test/dashboard_page_test.dart
```

### Subetapa 3C ✅ — arquivos alterados

```
lib/core/agency/agency_branding_sync.dart                  (criado)
lib/core/theme/theme_provider.dart
lib/core/settings/settings_service.dart                    (comentário legado)
lib/main.dart
lib/presentation/agency/agency_gate.dart
lib/presentation/dashboard/pages/dashboard_page.dart
lib/presentation/dashboard/pages/login_page.dart
lib/presentation/profile/pages/profile_page.dart
test/dashboard_page_test.dart
```

### Subetapa 3D ✅ — arquivos alterados

```
lib/presentation/agency/pages/agency_onboarding_page.dart   (criado)
lib/presentation/agency/pages/agency_selection_page.dart    (criado)
lib/presentation/agency/widgets/agency_switcher.dart        (criado)
lib/presentation/agency/pages/agency_pending_page.dart    (removido)
lib/core/agency/agency_context.dart
lib/presentation/agency/agency_gate.dart
lib/presentation/shared/main_shell.dart
test/widget_test.dart
test/agency_selection_page_test.dart                        (criado)
```

### Migração legada

Usuários existentes: `agencies/{uid}` usa o **próprio uid** como ID. `clients` e `projects` com `agencyId=uid` permanecem inalterados.

Usuários novos: wizard cria agência com UUID; **não** cria agência automaticamente.

### Security Rules (Etapa 2 ✅)

Rules transitórias em `firestore.rules`:

- **`canAccessAgency`** = `isLegacyOwner` (fallback) **OU** membership ativa
- **`settings/{uid}`** mantido integralmente
- Novas coleções: `users`, `agencies`, `memberships`
- **`clients` / `projects`** permanecem na raiz; acesso via `canAccessAgency(agencyId)`

**TODO:** remover `isLegacyOwner` após migração 100% + Etapa 3 estável (ver comentário em `firestore.rules`).

Backup pré-deploy: `docs/firestore-backup-pre-fase2.md`  
Validação: `docs/firestore-rules-validation-fase2.md`, `test/firestore_rules_test.mjs`

Deploy: `firebase deploy --only firestore`

---

### Branding (3C ✅)

- **Fonte exclusiva na UI:** `agencies/{activeAgencyId}` via `AgencyContext` → `AgencyBrandingSync` → `ThemeProvider`
- **`ProfilePage`:** salva em `agencies/{activeAgencyId}` (`AgencyContext.updateActiveAgencyBranding`); **não** grava em `settings/{uid}`
- **`settings/{uid}`:** mantido nas rules; lido **apenas** no bootstrap legado (`AgencyService.loadLegacySettings`) para criar `agencies/{uid}` na primeira migração
- **Membro (`member`):** botão Configurações oculto na Dashboard (`canManageSettings == false`)
- **Logout:** reseta tema para defaults (Pequi / `#FFD700`)

### Onboarding e multi-agência (3D ✅)

- **Wizard:** `AgencyOnboardingPage` — nome + cor → `createFirstAgency` (UUID)
- **Seletor:** `AgencySelectionPage` — lista memberships quando 2+ agências e `activeAgencyId` inválido/ausente
- **Switcher:** `AgencySwitcher` na sidebar — visível se `hasMultipleAgencies`; troca via `selectAgency`
- **Troca de agência:** recria `ProjectService`/`ClientService` no `AgencyGate` + atualiza branding

---

## Funcionalidades implementadas

### Autenticação
- Login Google via `signInWithPopup` (**Web**)
- **Auth guard** (`AuthGate` em `main.dart`) — `authStateChanges` → `MainShell` ou `LoginPage`
- Sessão persistente no browser (Firebase Auth)
- **Logout** com confirmação na sidebar
- Loading e SnackBar de erro no login
- Carregamento de branding após login via `AgencyGate` (não mais `settings/{uid}` na UI)

### Tema e personalização
- Cor primária padrão: `#FFD700` (Pequi)
- **Tema claro/escuro** global (`ThemeToggleButton`)
- **`AppTheme`** com tokens M3: inputs, cards, chips, dialogs, snackbars, botões
- **`ThemeUtils`**: contraste `onPrimary`, `brandColor` (ícones escuros no dark mode), `sectionTitle`, `bodyMuted`
- **`agencyName`** aplicado na sidebar, AppBar mobile e painel de login (via `ThemeProvider`, sincronizado com `agencies/`)
- `ProfilePage`: nome + cor → `agencies/{activeAgencyId}` (owner/admin); oculto para `member`

### Dashboard (Kanban unificado)

- **Uma única tela** — sem abas Job/Planejamento; tudo no mesmo fluxo Kanban
- **5 colunas fixas** (esquerda → direita):
  1. **Incêndios** — prioridade máxima (borda/sombra vermelha)
  2. **Planejamento** — novos itens ou sem data definida
  3. **Produção** — criação, captação ou edição
  4. **Aprovação** — aguardando feedback do cliente
  5. **Concluído** — itens finalizados
- **Job e Planejamento digital** compartilham o mesmo board; cards diferenciados visualmente
- **Filtros no header** (`DashboardDisplayFilter`): checkboxes **Job** e **Planejamento digital** (padrão: ambos marcados)
- **Leitura em tempo real** do Firestore (`getProjectsStream`)
- **Criar projeto** (`NewProjectDialog`): escolha de categoria + campos condicionais
- **Clicar no card** → `ProjectDetailPage`
- **Arrastar card** entre colunas → `updateProject` com novo `status` (+ `planningStatus` em posts de planejamento)
  - Web/desktop: drag no card inteiro
  - Mobile: long press no card
- **Layout responsivo** (`DashboardBoardLayout`):
  - Desktop (≥768px): 5 colunas lado a lado
  - Mobile: carrossel com setas, chips clicáveis e bolinhas (5 páginas)
- Sem dados mock — colunas vazias quando não há projetos

### Categorias de projeto

| Categoria | Uso | Campos principais (criar/editar) |
|-----------|-----|----------------------------------|
| **Job** (`category: job`) | Fluxo de produção da agência | Nome, descrição, cliente, data entrega, até 5 atividades de produção |
| **Planejamento digital** (`category: planejamento`) | Posts dos clientes | Data, formato, descrição, referência, status colorido (`planningStatus`) |

Campos extras de planejamento **não** têm tela separada — só em `NewProjectDialog` e `ProjectDetailPage`.

### Detalhes do projeto (`ProjectDetailPage`)

- Formulário **condicional** conforme `category` (Job vs Planejamento digital)
- **Job:** nome, descrição, cliente (read-only), data entrega, etapa no Kanban (5 radios), atividades de produção, info adicional
- **Planejamento digital:** data, formato, descrição, referência, título interno, status via chips coloridos
- Etapa/status → `updateProject` com `status` (+ `planningStatus` se planejamento)
- Até **5 atividades de produção** (Job) com checkbox → calcula `progress` (0–1)
- Progresso exibido no **card do Kanban** (Job)
- Data exibida no card e no calendário lateral quando definida
- Persistência via `ProjectService.updateProject` e stream do documento

### Clientes
- Listagem em tempo real com loading/erro
- **Criar/editar** via `ClientFormPage` (nome, e-mail, telefone, ramo, responsável, endereço)
- **Redes sociais** com detecção automática de plataforma (`ClientSocialLink`)
- Exclusão com **confirmação**
- Ícones de redes visíveis em tema claro e escuro

### Calendário de entregas (sidebar)
- **`SidebarDeliveryCalendar`** na sidebar (desktop e drawer mobile)
- Lê `expectedDeliveryDate` dos projetos via `getProjectsStream()`
- Grade mensal com indicadores nos dias com entregas
- Painel do dia selecionado: título, cliente, status da fase
- Navegação mês anterior/próximo e botão **Hoje**
- Toque em entrega → abre `ProjectDetailPage` do projeto
- Mapeamento: `DeliveryCalendarMapper` + `CalendarDeliveryEntry`
- Datas: `DateFormatUtils` (Timestamp, `DateTime` ou string `dd/MM/yyyy`)

### Navegação (`MainShell`)
- Sidebar desktop (>900px) / Drawer + AppBar mobile
- Abas: Dashboard, Clientes, Equipe (placeholder)
- Calendário de entregas abaixo do menu (scrollável)
- Link **Configurações** na sidebar
- Botão **Sair**

### Firebase (produção local)
- Regras de segurança por `agencyId` / `uid`
- Índices compostos versionados: `projects`, `clients`, `memberships` (×3), `agency_invite_codes` — ver `TECHNICAL_DOC.md` § Índices compostos
- `users.email`: índice automático de campo único (não entra em `firestore.indexes.json`)
- Deploy via `firebase deploy --only firestore` ou `--only firestore:indexes`
- **Hosting Web (comando único):** `powershell -ExecutionPolicy Bypass -File .\deploy.ps1` — pull + bump + build + hosting + push da versão → `https://dofluxo-organizer.web.app`
- Build web: `--pwa-strategy=none --no-web-resources-cdn --dart-define=APP_VERSION=x.y.z+N` (sem service worker; CanvasKit local)
- **Atualização obrigatória (web):** notificação canto inferior direito (`AppUpdateGate`) — compara sessão vs `/version.json` a cada ~2,5 min e ao focar a aba; contador de 5 min até auto-reload; botão "Atualizar agora". Ver `TECHNICAL_DOC.md` § Atualização obrigatória.

---

## Funcionalidades pendentes

| Área | Pendência |
|------|-----------|
| **Auth** | Login Google Android/iOS (`google_sign_in` não implementado) |
| **Publicação** | Firebase Hosting / deploy do app (não necessário para dev local) |
| **Equipe** | Tela placeholder sem dados |
| **Tema** | Persistir preferência claro/escuro entre sessões |
| **Projetos** | Editar/excluir projeto pela UI; migrar status legados; projetos antigos sem `clientId` |
| **Kanban** | Regra automática Incêndios (itens atrasados do dia anterior); remover `project_status_panel.dart` (código morto) |
| **Dashboard** | Persistir filtros Job/Planejamento entre sessões |
| **Arquitetura** | Repositórios, entidades integradas ou remoção de código morto |
| **Dependências** | Remover `appflowy_board`, `flutter_bloc`, etc. do `pubspec.yaml` |
| **Plataformas** | iOS, Windows, macOS, Linux sem `firebase_options` |
| **Testes** | Integração Firebase mockada; fluxos E2E |
| **Analyzer** | Warnings: `RadioListTile` deprecated, `DropdownButtonFormField.value` deprecated |

---

## Fluxos principais

### 1. Inicialização

```
main()
  → Firebase.initializeApp()
  → ThemeProvider (defaults) + AgencyContext
  → runApp → MaterialApp(home: AuthGate)
```

### 2. Auth guard

```
AuthGate → authStateChanges
  → waiting: loading
  → user != null: AgencyGate → MainShell
  → user == null: LoginPage (+ reset AgencyContext + ThemeProvider)
```

### 3. Criar projeto

```
Dashboard → Novo Projeto → NewProjectDialog
  → escolher categoria (Job | Planejamento digital)
  → campos condicionais + cliente obrigatório
  → ProjectService.addProject() → Firestore
  → Stream atualiza Kanban
```

### 4. Mover / editar projeto

```
Arrastar card → updateProject({ status, planningStatus? })
OU
Clicar card → ProjectDetailPage
  → editar campos / etapa Kanban / atividades → updateProject()
```

### 5. Clientes

```
Clientes → Novo/Editar → ClientFormPage → addClient / updateClient
Listagem → StreamBuilder → delete com confirmação
```

---

## Banco de dados (Firestore)

### Coleções multi-agência (Fase 1 — novas)

#### `users/{userId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `displayName` | string | Nome do usuário |
| `email` | string | E-mail |
| `photoUrl` | string? | Avatar |
| `activeAgencyId` | string? | Agência em uso |
| `createdAt`, `updatedAt` | timestamp | |

#### `agencies/{agencyId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `name` | string | Nome da agência |
| `ownerId` | string | uid do dono |
| `primaryColor` | string | ARGB decimal |
| `logoUrl` | string? | Logo (futuro) |
| `createdBy` | string | |
| `createdAt`, `updatedAt` | timestamp | |

**Legado:** primeira agência migrada usa `agencyId = uid`.

#### `memberships/{agencyId}_{userId}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `agencyId` | string | |
| `userId` | string | |
| `role` | string | `owner` \| `admin` \| `member` |
| `status` | string | `active` (Fase 1) |
| `agencyName` | string | Denorm — seletor |
| `userEmail` | string | Denorm |
| `joinedAt`, `createdAt`, `updatedAt` | timestamp | |

**Query:** `where userId == uid AND status == active orderBy joinedAt desc`.

### Coleções operacionais (inalteradas na Fase 1)

#### `settings/{uid}` ⚠ Legado

Migrado para `agencies/{uid}` no bootstrap. **Sem writes pela UI** após 3C; leitura só na migração inicial.

#### `clients/{autoId}`

| Campo | Tipo |
|-------|------|
| `agencyId` | string |
| `name`, `email`, `phone`, `sector`, `responsible`, `address` | string |
| `socialLinks` | array `[{platform, value, handle?}]` |
| `createdAt` | timestamp |

**Query:** `where('agencyId').orderBy('createdAt', desc)` — índice composto necessário.

### `projects/{autoId}`

| Campo | Tipo |
|-------|------|
| `agencyId` | string |
| `id` | string (UUID client) |
| `category` | string — `job` (default) ou `planejamento` |
| `title`, `description` | string |
| `clientId`, `clientName` | string |
| `status` | string — etapa do Kanban (ver mapeamento abaixo) |
| `productionTasks` | array `[{label, completed}]` — Job |
| `progress` | number 0.0–1.0 |
| `additionalInfo` | string — Job |
| `format` | string — Planejamento (Feed, Reels, etc.) |
| `reference` | string — Planejamento (link/inspiração) |
| `planningStatus` | string — `pendente`, `emProducao`, `pronto`, `agendado`, `publicado` |
| `scheduledDate` | `Timestamp` — Planejamento (também espelhado em `expectedDeliveryDate`) |
| `expectedDeliveryDate` | `Timestamp` (preferido), `DateTime` ou string `dd/MM/yyyy` |
| `createdAt`, `updatedAt` | timestamp |

**Query:** `where('agencyId').orderBy('createdAt', desc)` — índice composto necessário.

### Mapeamento status ↔ colunas Kanban

| Status Firestore (atual) | Coluna UI |
|--------------------------|-----------|
| `Incêndios` | Incêndios |
| `Planejamento` | Planejamento |
| `Produção` | Produção |
| `Aprovação` | Aprovação |
| `Concluído` | Concluído |

**Status legados** (projetos antigos) — mapeados em `DashboardBoardMapper.stageIdForStatus`:

| Legado | Coluna atual |
|--------|--------------|
| `Postagens` | Planejamento |
| `Criação`, `Captação`, `Edição` | Produção |
| `Incêndios` | Incêndios |
| `Aprovação` | Aprovação |
| `Publicado`, `Aprovado`, etc. | Concluído |

**Default** ao criar projeto: `status: Planejamento`.

---

## Bugs corrigidos (sessão recente)

| Bug | Correção |
|-----|----------|
| Erro `failed-precondition` (índice Firestore) | `firestore.indexes.json` + deploy |
| Kanban sem leitura do Firestore | `StreamBuilder` + `getProjectsStream` |
| Drag sem persistir | `updateProjectStatus` nos callbacks |
| Sem auth guard / logout | `AuthGate` + `signOut` na sidebar |
| Clientes sem CRUD UI | `ClientFormPage` + confirmação delete |
| `agencyName` hardcoded | `ThemeProvider.agencyName` na UI |
| Compiler crash Web (imports) | Restaurados imports em `project_board_item.dart` |
| Mobile: não navega entre colunas | Chips, setas e bolinhas no carrossel |
| Mobile: tap/drag nos cards | Long press drag + `GestureDetector` tap |
| Textos ilegíveis no dark mode | `AppTheme` + `ThemeUtils` em todas as telas |
| Sem `firestore.rules` no repo | Arquivo versionado e deployado |
| Projetos sem data no calendário | Campo `expectedDeliveryDate` + `DateFormatUtils.fromFirestore` |
| Kanban 6 colunas + painel status | Redesign: 5 colunas unificadas; Job + Planejamento no mesmo board |
| Tentativa de abas Job/Planejamento | Revertido — uma Dashboard; categorias só em criar/editar |
| Cards soltos acima do Kanban | Removidos; tudo dentro das colunas |
| Coleção `planning_posts` (experimental) | Removida; planejamento usa `projects` com `category: planejamento` |

---

## Handoff para outro agente

1. Leia nesta ordem: **`PROJECT_CONTEXT.md`** → **`TECHNICAL_DOC.md`** → **`NEXT_STEPS.md`**.
2. Valide o ambiente: `flutter pub get`, `flutter analyze`, `flutter test`.
3. **Não reintroduza `appflowy_board`** — Kanban custom em `dashboard_workflow_board.dart`.
4. **Não crie abas ou telas separadas** para Job vs Planejamento — uma Dashboard com filtros `Exibir:`.
5. **Categorias de projeto** vivem em `projects` (`category`, `planningStatus`, `format`, etc.) — não usar coleção separada.
6. Queries `where('agencyId').orderBy('createdAt')` exigem índice em `firestore.indexes.json`.
7. Cliente é **obrigatório** na criação de projeto; docs antigos podem não ter `clientName`.
8. Auth mobile retorna `null` — próximo passo P1 é `google_sign_in` em `AuthService`.
9. Usuário **não quer publicar ainda** — dev local (`flutter run -d chrome`) é suficiente.
10. Alterou rules/indexes? Rode `firebase deploy --only firestore`.

---

## Comandos úteis

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter run -d android
firebase deploy --only firestore   # rules + indexes
```

---

## Referências internas

- Entrada: `lib/main.dart`
- Kanban: `dashboard_workflow_board.dart`, `dashboard_board_layout.dart`, `dashboard_board_mapper.dart`
- Filtros dashboard: `dashboard_display_filter.dart`
- Categorias/status planejamento: `project_category.dart`, `planning_status.dart`
- Projetos: `lib/presentation/projects/`
- Clientes: `lib/presentation/clients/`
- Tema: `lib/core/theme/app_theme.dart`
- Calendário: `lib/presentation/shared/widgets/sidebar_delivery_calendar.dart`
- Docs: `TECHNICAL_DOC.md`, `NEXT_STEPS.md`
