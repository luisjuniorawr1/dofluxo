# Validação Firestore Rules — Fase 2

## Execução automatizada

Requer Node.js 18+:

```bash
cd dofluxo
npm install --no-save @firebase/rules-unit-testing firebase
node test/firestore_rules_test.mjs
```

## Cenários cobertos

| # | Cenário | Resultado esperado |
|---|---------|-------------------|
| 1 | Legado lê `clients`/`projects` com `agencyId=uid` **sem** doc membership | ✅ allow |
| 2 | Legado CRUD `clients` com `agencyId=uid` | ✅ allow |
| 3 | Legado read/write `settings/{uid}` | ✅ allow |
| 4 | Legado lê client de outra agência | ❌ deny |
| 5 | Member com membership ativa lê client da agência | ✅ allow |
| 6 | Usuário sem membership lê agência alheia | ❌ deny |
| 7 | Bootstrap: create `agencies` + `memberships` owner | ✅ allow |
| 8 | `users/{uid}` read/write próprio | ✅ allow |

## Confirmação lógica — legado sem membership

Regra `canAccessAgency(agencyId)`:

```
isLegacyOwner(agencyId)  →  auth.uid == agencyId
|| isActiveMember(agencyId)
```

Para usuário legado com `clients.agencyId == auth.uid`:

- `membership(agencyId).exists` → **false** (doc não existe)
- `isLegacyOwner(agencyId)` → **true**
- **Resultado: allow** em read/create/update/delete de clients e projects

O app MVP atual (`agencyId = user.uid`) continua funcionando **antes** do bootstrap e **sem** deploy da Etapa 3.

## Deploy

```bash
firebase deploy --only firestore
```

Backup pré-Fase 2: [`firestore-backup-pre-fase2.md`](firestore-backup-pre-fase2.md)
