# Backup lógico Firestore — pré Fase 2 (multi-agência)

**Data:** junho/2026  
**Motivo:** Etapa 2 — rules transitórias com fallback legado  
**Projeto Firebase:** `dofluxo-organizer`

---

## Coleções em uso (MVP + Etapa 1 código)

| Coleção | Doc ID | Escopo | Escrita atual (app) |
|---------|--------|--------|---------------------|
| `settings/{uid}` | uid do Auth | Branding legado por usuário | `SettingsService`, `ProfilePage` |
| `clients/{autoId}` | auto | Clientes da agência | `ClientService` |
| `projects/{autoId}` | auto | Projetos Kanban | `ProjectService` |
| `users/{uid}` | uid | Perfil + activeAgencyId | `UserService` (Etapa 1, não integrado) |
| `agencies/{agencyId}` | UUID ou uid legado | Branding organizacional | `AgencyService` (Etapa 1, não integrado) |
| `memberships/{agencyId}_{userId}` | composto | Permissões | `MembershipService` (Etapa 1, não integrado) |

---

## Schema operacional (inalterado na Fase 1)

### `settings/{uid}`

| Campo | Tipo |
|-------|------|
| `agencyName` | string |
| `primaryColor` | string (ARGB decimal) |

### `clients/{clientId}`

| Campo | Tipo |
|-------|------|
| `agencyId` | string (= uid no MVP legado) |
| `name`, `email`, `phone`, `sector`, `responsible`, `address` | string |
| `socialLinks` | array |
| `createdAt` | timestamp |

### `projects/{projectId}`

| Campo | Tipo |
|-------|------|
| `agencyId` | string (= uid no MVP legado) |
| `id`, `title`, `description`, `clientId`, `clientName`, `status`, `category` | diversos |
| `productionTasks`, `progress`, `planningStatus`, `format`, etc. | diversos |
| `createdAt`, `updatedAt` | timestamp |

---

## Security Rules — snapshot pré Fase 2

Arquivo: `firestore.rules` (31 linhas)

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(agencyId) {
      return isSignedIn() && request.auth.uid == agencyId;
    }

    match /settings/{userId} {
      allow read, write: if isSignedIn() && request.auth.uid == userId;
    }

    match /clients/{clientId} {
      allow read, delete: if isOwner(resource.data.agencyId);
      allow create: if isOwner(request.resource.data.agencyId);
      allow update: if isOwner(resource.data.agencyId)
        && request.resource.data.agencyId == resource.data.agencyId;
    }

    match /projects/{projectId} {
      allow read, delete: if isOwner(resource.data.agencyId);
      allow create: if isOwner(request.resource.data.agencyId);
      allow update: if isOwner(resource.data.agencyId)
        && request.resource.data.agencyId == resource.data.agencyId;
    }
  }
}
```

**Modelo de acesso:** `agencyId == auth.uid` (1 usuário = 1 agência implícita).

**Coleções sem rules:** `users`, `agencies`, `memberships` (deny implícito).

---

## Índices compostos — snapshot pré Fase 2

Arquivo: `firestore.indexes.json`

| collectionGroup | Campos |
|-----------------|--------|
| `projects` | `agencyId ASC`, `createdAt DESC` |
| `clients` | `agencyId ASC`, `createdAt DESC` |

---

## Queries dependentes de índice

| Service | Query |
|---------|-------|
| `ProjectService.getProjectsStream` | `projects where agencyId == X orderBy createdAt desc` |
| `ClientService.getClientsStream` | `clients where agencyId == X orderBy createdAt desc` |
| `MembershipService.listActiveForUser` | `memberships where userId == X AND status == active orderBy joinedAt desc` *(novo — Etapa 2)* |

---

## Restauração

Para reverter rules ao MVP:

1. Copiar bloco "Security Rules — snapshot pré Fase 2" para `firestore.rules`
2. Remover índices `memberships` de `firestore.indexes.json` (manter projects/clients)
3. `firebase deploy --only firestore`
