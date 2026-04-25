# PedalTrack API — Postman Reference

Base URL: `http://localhost:5000/api`

> Todos os endpoints marcados com 🔒 exigem o header:
> `Authorization: Bearer {accessToken}`

---

## Variável de ambiente (recomendado)

Configure no Postman Environment:

| Variável | Valor inicial |
|----------|---------------|
| `base_url` | `http://localhost:5000/api` |
| `token` | _(preenchido automaticamente pelo script do login)_ |

Script de teste no endpoint de login (aba **Tests**):
```javascript
pm.environment.set("token", pm.response.json().accessToken);
```

---

## 🔑 Auth (público)

### Registrar usuário

```
POST {{base_url}}/auth/register
Content-Type: application/json
```

```json
{
  "name": "William Franco",
  "email": "william@pedaltrack.com",
  "password": "Senha@123"
}
```

Resposta `201`:
```json
{
  "id": 1,
  "name": "William Franco",
  "email": "william@pedaltrack.com",
  "createdAt": "2026-04-25T12:00:00Z"
}
```

---

### Login

```
POST {{base_url}}/auth/login
Content-Type: application/json
```

```json
{
  "email": "william@pedaltrack.com",
  "password": "Senha@123"
}
```

Resposta `200`:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6..."
}
```

> ⚠️ Refresh token foi removido do projeto. O token JWT tem validade de 8 horas — basta fazer login novamente quando expirar.

---

## 🚲 Bikes 🔒

### Criar bicicleta

```
POST {{base_url}}/bikes
Authorization: Bearer {{token}}
Content-Type: application/json
```

```json
{
  "nickname": "Minha MTB",
  "brand": "Trek",
  "model": "Marlin 7"
}
```

Resposta `201`:
```json
{
  "id": 1,
  "userId": 1,
  "nickname": "Minha MTB",
  "brand": "Trek",
  "model": "Marlin 7",
  "createdAt": "2026-04-25T12:00:00Z",
  "updatedAt": "2026-04-25T12:00:00Z",
  "parts": []
}
```

---

### Listar bicicletas

```
GET {{base_url}}/bikes
Authorization: Bearer {{token}}
```

Resposta `200`:
```json
[
  {
    "id": 1,
    "nickname": "Minha MTB",
    "brand": "Trek",
    "model": "Marlin 7",
    "parts": []
  }
]
```

---

### Buscar bicicleta por ID

```
GET {{base_url}}/bikes/1
Authorization: Bearer {{token}}
```

---

### Atualizar bicicleta

```
PUT {{base_url}}/bikes/1
Authorization: Bearer {{token}}
Content-Type: application/json
```

```json
{
  "nickname": "Trek da Trilha",
  "brand": null,
  "model": null
}
```

> Todos os campos são opcionais. Envie `null` para manter o valor atual.

---

### Deletar bicicleta

```
DELETE {{base_url}}/bikes/1
Authorization: Bearer {{token}}
```

Resposta `204` (sem body).

---

## ⚙️ Peças 🔒

### Instalar peça

```
POST {{base_url}}/bikes/1/parts
Authorization: Bearer {{token}}
Content-Type: application/json
```

```json
{
  "name": "Pneu Traseiro",
  "expectedDurationKm": 2000,
  "pricePaid": 150.00,
  "installedAt": "2026-04-25T10:00:00Z"
}
```

> `installedAt` é opcional — usa a data/hora atual se omitido.

Resposta `201`:
```json
{
  "id": 1,
  "bikeId": 1,
  "name": "Pneu Traseiro",
  "expectedDurationKm": 2000,
  "kmRidden": 0,
  "progressPercent": 0.0,
  "isOverLimit": false,
  "pricePaid": 150.00,
  "installedAt": "2026-04-25T10:00:00Z",
  "status": "Active",
  "alertSent": false,
  "createdAt": "2026-04-25T12:00:00Z"
}
```

---

### Listar peças da bicicleta

```
GET {{base_url}}/bikes/1/parts
Authorization: Bearer {{token}}
```

Resposta `200` (exemplo após passeios):
```json
[
  {
    "id": 1,
    "name": "Pneu Traseiro",
    "expectedDurationKm": 2000,
    "kmRidden": 1800,
    "progressPercent": 90.0,
    "isOverLimit": false,
    "status": "Active",
    "alertSent": true
  },
  {
    "id": 2,
    "name": "Corrente",
    "expectedDurationKm": 1500,
    "kmRidden": 1600,
    "progressPercent": 106.7,
    "isOverLimit": true,
    "status": "Active",
    "alertSent": true
  }
]
```

---

### Buscar peça por ID

```
GET {{base_url}}/bikes/1/parts/1
Authorization: Bearer {{token}}
```

---

### Trocar peça

```
POST {{base_url}}/bikes/1/parts/1/exchange
Authorization: Bearer {{token}}
Content-Type: application/json
```

```json
{
  "notes": "Rasgou em uma pedra na trilha"
}
```

> `notes` é opcional (RN05). Envie `{}` ou `{ "notes": null }` para registrar a troca sem observação.

Resposta `201` (registro imutável — não pode ser editado ou deletado):
```json
{
  "id": 1,
  "partId": 1,
  "bikeId": 1,
  "partName": "Pneu Traseiro",
  "expectedDurationKm": 2000,
  "actualKmReached": 800,
  "pricePaidAtTime": 150.00,
  "notes": "Rasgou em uma pedra na trilha",
  "exchangedAt": "2026-04-25T15:00:00Z",
  "createdAt": "2026-04-25T15:00:00Z"
}
```

> Após a troca, a peça fica com `status: "Replaced"`. Cadastre a nova peça com `POST /bikes/1/parts` — o contador de km começa do zero, sem herdar dados da peça anterior.

---

### Histórico de trocas de uma peça

```
GET {{base_url}}/bikes/1/parts/1/exchanges
Authorization: Bearer {{token}}
```

---

## 🚴 Passeios 🔒

> Ao registrar um passeio, o sistema distribui automaticamente os km para todas as peças ativas da bicicleta. Se alguma peça atingir 90% da vida útil, um alerta é gerado automaticamente.

### Registrar passeio

```
POST {{base_url}}/bikes/1/rides
Authorization: Bearer {{token}}
Content-Type: application/json
```

```json
{
  "distanceKm": 45.5,
  "terrain": "trilha",
  "riddenAt": "2026-04-25T08:30:00Z"
}
```

> `riddenAt` é opcional — usa a data/hora atual se omitido.
> Valores sugeridos para `terrain`: `"seco"`, `"chuva"`, `"lama"`, `"trilha"`, `"asfalto"`.

Resposta `201`:
```json
{
  "id": 1,
  "bikeId": 1,
  "distanceKm": 45.5,
  "terrain": "trilha",
  "riddenAt": "2026-04-25T08:30:00Z",
  "createdAt": "2026-04-25T12:00:00Z"
}
```

---

### Histórico de passeios

```
GET {{base_url}}/bikes/1/rides
Authorization: Bearer {{token}}
```

---

## ✅ Checklist de Manutenção 🔒

### Registrar execução de checklist

```
POST {{base_url}}/bikes/1/checklists
Authorization: Bearer {{token}}
Content-Type: application/json
```

```json
{
  "executedAt": "2026-04-25T09:00:00Z",
  "itemsChecked": "corrente,pneus,freios,câmbio,iluminação",
  "notes": "Revisão pós-trilha. Corrente com desgaste moderado."
}
```

> `executedAt` e `notes` são opcionais.
> Itens disponíveis: `corrente`, `pneus`, `freios`, `câmbio`, `iluminação`, `pedal`, `banco`, `chassi`, `cubo/aro`, `cabos`.

Resposta `201`:
```json
{
  "id": 1,
  "bikeId": 1,
  "executedAt": "2026-04-25T09:00:00Z",
  "itemsChecked": "corrente,pneus,freios,câmbio,iluminação",
  "notes": "Revisão pós-trilha. Corrente com desgaste moderado.",
  "createdAt": "2026-04-25T12:00:00Z"
}
```

---

### Histórico de checklists

```
GET {{base_url}}/bikes/1/checklists
Authorization: Bearer {{token}}
```

---

## 🔔 Alertas 🔒

> Alertas são gerados automaticamente pelo sistema ao registrar passeios — não é possível criá-los manualmente.

### Listar alertas da bicicleta

```
GET {{base_url}}/bikes/1/alerts
Authorization: Bearer {{token}}
```

Resposta `200`:
```json
[
  {
    "id": 1,
    "bikeId": 1,
    "partId": 1,
    "message": "Peça 'Pneu Traseiro' atingiu 90% da vida útil esperada.",
    "triggeredAt": "2026-04-25T14:00:00Z",
    "createdAt": "2026-04-25T14:00:00Z"
  }
]
```

---

## 📋 Histórico Consolidado 🔒

### Buscar histórico completo da bicicleta

```
GET {{base_url}}/bikes/1/history
Authorization: Bearer {{token}}
```

Resposta `200`:
```json
{
  "rides": [
    {
      "id": 1,
      "distanceKm": 45.5,
      "terrain": "trilha",
      "riddenAt": "2026-04-25T08:30:00Z"
    }
  ],
  "partExchanges": [
    {
      "id": 1,
      "partName": "Pneu Traseiro",
      "actualKmReached": 800,
      "expectedDurationKm": 2000,
      "notes": "Rasgou em uma pedra na trilha",
      "exchangedAt": "2026-04-25T15:00:00Z"
    }
  ],
  "checklists": [
    {
      "id": 1,
      "executedAt": "2026-04-25T09:00:00Z",
      "itemsChecked": "corrente,pneus,freios,câmbio,iluminação"
    }
  ]
}
```

---

## Fluxo de teste recomendado

```
1. POST /auth/register         → cria o usuário
2. POST /auth/login            → salva o token no environment
3. POST /bikes                 → cria a bicicleta (anote o id)
4. POST /bikes/1/parts         → instala peças (pneu, corrente, etc.)
5. POST /bikes/1/rides         → registra passeios acumulando km
6. GET  /bikes/1/parts         → observa progressPercent e isOverLimit
7. GET  /bikes/1/alerts        → verifica alertas gerados automaticamente
8. POST /bikes/1/parts/1/exchange → troca a peça
9. POST /bikes/1/parts         → instala peça nova (km zera)
10. GET /bikes/1/history       → histórico consolidado
```

---

## Endpoints removidos em relação ao projeto anterior

| Endpoint antigo | Motivo da remoção |
|-----------------|-------------------|
| `POST /auth/refresh` | Refresh token não implementado no novo projeto |
| `POST /api/usage-records` | Substituído por `POST /bikes/{id}/rides` com lógica de distribuição de km |
| `POST /api/rides` | Rota reestruturada para `POST /bikes/{id}/rides` |
| `POST /api/maintenance-alerts` | Alertas agora são gerados automaticamente pelo sistema |
| `POST /api/maintenance-checklist` | Rota reestruturada para `POST /bikes/{id}/checklists` |
