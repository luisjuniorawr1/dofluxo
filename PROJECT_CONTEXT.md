# PROJECT_CONTEXT — DOFLUXO

Documento de referência do projeto **DOFLUXO** (marca interna: **Pequi Agência**).  
Última atualização: **junho/2026** — alinhado ao código em `lib/`, Firebase e dependências do `pubspec.yaml`.

---

## Objetivo do sistema

O **DOFLUXO** é um organizador de fluxo de trabalho para **agências criativas**. O sistema permite que uma agência:

- Faça login com conta Google (Web)
- Personalize identidade visual (nome + cor primária)
- Gerencie **projetos** em quadro Kanban de 6 colunas + painel de status
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

**Infra versionada no repo:** `firestore.rules`, `firestore.indexes.json`, `.firebaserc`, `firebase.json`

---

## Estrutura de pastas

```
dofluxo/
├── lib/
│   ├── main.dart                          # Firebase, ThemeProvider, AuthGate
│   ├── firebase_options.dart
│   │
│   ├── core/
│   │   ├── settings/settings_service.dart # Leitura/escrita settings/{uid}
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
│       │   └── widgets/                   # Kanban, layout responsivo, status panel
│       ├── profile/pages/profile_page.dart
│       ├── projects/
│       │   ├── manager/project_service.dart
│       │   ├── models/project_production_task.dart
│       │   ├── pages/project_detail_page.dart
│       │   └── widgets/new_project_dialog.dart, expected_delivery_date_field.dart
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

---

## Funcionalidades implementadas

### Autenticação
- Login Google via `signInWithPopup` (**Web**)
- **Auth guard** (`AuthGate` em `main.dart`) — `authStateChanges` → `MainShell` ou `LoginPage`
- Sessão persistente no browser (Firebase Auth)
- **Logout** com confirmação na sidebar
- Loading e SnackBar de erro no login
- Carregamento de settings após login

### Tema e personalização
- Cor primária padrão: `#FFD700` (Pequi)
- **Tema claro/escuro** global (`ThemeToggleButton`)
- **`AppTheme`** com tokens M3: inputs, cards, chips, dialogs, snackbars, botões
- **`ThemeUtils`**: contraste `onPrimary`, `brandColor` (ícones escuros no dark mode), `sectionTitle`, `bodyMuted`
- **`agencyName`** aplicado na sidebar, AppBar mobile e painel de login
- `ProfilePage`: nome + cor → Firestore `settings/{uid}` via `SettingsService`

### Dashboard (Kanban)
- **6 colunas de workflow** + painel **Status do Projeto**:
  - Postagens do dia, Criação, Incêndios, Captação, Edição, Aprovação
- **Leitura em tempo real** do Firestore (`getProjectsStream`)
- **Criar projeto** (`NewProjectDialog`): cliente obrigatório, até 5 atividades de produção, data de entrega prevista
- **Clicar no card** → `ProjectDetailPage`
- **Arrastar projeto** entre colunas → `updateProjectStatus` no Firestore
  - Web/desktop: ícone ⋮⋮ (drag handle)
  - Mobile: long press no card
- **Layout responsivo** (`DashboardBoardLayout`):
  - Desktop (≥768px): colunas lado a lado + painel status
  - Mobile: carrossel com setas, chips clicáveis e bolinhas de navegação
- Sem dados mock — board vazio quando não há projetos

### Detalhes do projeto (`ProjectDetailPage`)
- Editar nome, descrição, informações adicionais (links Drive etc.)
- Cliente somente leitura (definido na criação)
- **Fase atual** via radio → atualiza `status` e coluna no Kanban
- Até **5 atividades de produção** com checkbox → calcula `progress` (0–1)
- **Data de entrega prevista** editável (`ExpectedDeliveryDateField`)
- Progresso exibido no painel **Status do Projeto**
- Data de entrega exibida no card do Kanban quando definida
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
- Índices compostos `agencyId + createdAt` (projects, clients)
- Deploy via `firebase deploy --only firestore`

---

## Funcionalidades pendentes

| Área | Pendência |
|------|-----------|
| **Auth** | Login Google Android/iOS (`google_sign_in` não implementado) |
| **Publicação** | Firebase Hosting / deploy do app (não necessário para dev local) |
| **Equipe** | Tela placeholder sem dados |
| **Tema** | Persistir preferência claro/escuro entre sessões |
| **Projetos** | Editar/excluir projeto pela UI; projetos antigos sem `clientId` |
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
  → ThemeProvider + SettingsService.load (se logado)
  → runApp → MaterialApp(home: AuthGate)
```

### 2. Auth guard

```
AuthGate → authStateChanges
  → waiting: loading
  → user != null: MainShell
  → user == null: LoginPage
```

### 3. Criar projeto

```
Dashboard → Novo Projeto → NewProjectDialog
  → cliente + título + atividades + data entrega
  → ProjectService.addProject() → Firestore
  → Stream atualiza Kanban
```

### 4. Mover / editar projeto

```
Arrastar card → updateProjectStatus(status)
OU
Clicar card → ProjectDetailPage
  → editar campos / fase / atividades → updateProject()
```

### 5. Clientes

```
Clientes → Novo/Editar → ClientFormPage → addClient / updateClient
Listagem → StreamBuilder → delete com confirmação
```

---

## Banco de dados (Firestore)

### `settings/{uid}`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `agencyName` | string | Nome da agência |
| `primaryColor` | string | ARGB decimal (`Color.toARGB32().toString()`) |

### `clients/{autoId}`

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
| `title`, `description` | string |
| `clientId`, `clientName` | string |
| `status` | string (ver mapeamento abaixo) |
| `productionTasks` | array `[{label, completed}]` |
| `progress` | number 0.0–1.0 |
| `additionalInfo` | string |
| `expectedDeliveryDate` | `Timestamp` (preferido), `DateTime` ou string `dd/MM/yyyy` |
| `createdAt`, `updatedAt` | timestamp |

**Query:** `where('agencyId').orderBy('createdAt', desc)` — índice composto necessário.

### Mapeamento status ↔ colunas

| Status Firestore | Coluna UI |
|------------------|-----------|
| `Postagens` | Postagens do dia |
| `Criação` | Criação |
| `Incêndios` | INCÊNDIOS |
| `Captação` | Captação |
| `Edição` | Edição |
| `Aprovação` | Aprovação |

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

---

## Handoff para outro agente

1. Leia nesta ordem: **`PROJECT_CONTEXT.md`** → **`TECHNICAL_DOC.md`** → **`NEXT_STEPS.md`**.
2. Valide o ambiente: `flutter pub get`, `flutter analyze`, `flutter test`.
3. **Não reintroduza `appflowy_board`** — o Kanban é custom em `dashboard_workflow_board.dart`.
4. Queries `where('agencyId').orderBy('createdAt')` exigem índice em `firestore.indexes.json`.
5. Cliente é **obrigatório** na criação de projeto; docs antigos podem não ter `clientName`.
6. Auth mobile retorna `null` — próximo passo P1 é `google_sign_in` em `AuthService`.
7. Usuário **não quer publicar ainda** — dev local (`flutter run -d chrome`) é suficiente.
8. Alterou rules/indexes? Rode `firebase deploy --only firestore`.

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
- Kanban: `lib/presentation/dashboard/widgets/dashboard_workflow_board.dart`
- Mapper: `lib/presentation/dashboard/utils/dashboard_board_mapper.dart`
- Projetos: `lib/presentation/projects/`
- Clientes: `lib/presentation/clients/`
- Tema: `lib/core/theme/app_theme.dart`
- Calendário: `lib/presentation/shared/widgets/sidebar_delivery_calendar.dart`
- Docs: `TECHNICAL_DOC.md`, `NEXT_STEPS.md`
