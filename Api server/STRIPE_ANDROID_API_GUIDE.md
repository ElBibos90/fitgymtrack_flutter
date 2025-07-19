# 🚀 Guida API Stripe per App Android

## 📋 Panoramica

L'app Android deve utilizzare le API Stripe nella cartella `api/stripe/` per i pagamenti. Le API nella cartella principale `api/` sono vecchie e utilizzano PayPal.

## 🔗 Endpoint API Stripe Corretti

### 0. **Ottenere Chiave Pubblica (NUOVO)**
```
GET /api/stripe/get-publishable-key.php
```

**Response di successo:**
```json
{
  "success": true,
  "data": {
    "publishable_key": "pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY",
    "test_mode": true,
    "currency": "eur",
    "country": "IT",
    "available_prices": {
      "monthly_premium": "price_1RXVOfHHtQGHyul9qMGFmpmO",
      "yearly_premium": "price_1RbmRkHHtQGHyul92oUMSkUY"
    }
  }
}
```

### 1. **Test Connessione (NUOVO)**
```
GET /api/stripe/test-connection.php
```

**Response di successo:**
```json
{
  "success": true,
  "data": {
    "stripe_configured": true,
    "api_connection": "success",
    "publishable_key": {
      "value": "pk_test_51RW3uvHHtQG...",
      "format": "pk_test_...",
      "length": 108
    },
    "test_mode": true
  }
}
```

### 2. **Creazione Payment Intent per Subscription**
```
POST /api/stripe/create-subscription-payment-intent.php
```

**Headers richiesti:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Body:**
```json
{
  "price_id": "price_1RXVOfHHtQGHyul9qMGFmpmO",
  "metadata": {
    "payment_type": "recurring",
    "platform": "android"
  }
}
```

**Response di successo:**
```json
{
  "success": true,
  "data": {
    "client_secret": "pi_xxx_secret_xxx",
    "payment_intent_id": "pi_xxx",
    "subscription_id": "sub_xxx"
  }
}
```

### 2. **Conferma Pagamento**
```
POST /api/stripe/confirm-payment.php
```

**Headers richiesti:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Body:**
```json
{
  "payment_intent_id": "pi_xxx",
  "subscription_type": "subscription"
}
```

### 3. **Gestione Subscription**
```
GET /api/stripe/subscription.php
```

**Headers richiesti:**
```
Authorization: Bearer {token}
```

**Query parameters opzionali:**
- `include_incomplete=true` - Include subscription incomplete
- `include_recent=true` - Include subscription recenti

### 4. **Gestione Cliente**
```
GET /api/stripe/customer.php
POST /api/stripe/customer.php
```

## 🔧 Configurazione Stripe

### Chiavi Configurate
- **Secret Key**: `sk_test_51RW3uvHHtQGHyul9p5RR6cxcgdZsXYtUr2DE7v7ue2FRUZAl1LKaDhFlWKTBIpmHz56y9Uhgq58Ztqq8i8lcEXTj00xoAbsxmw`
- **Publishable Key**: `pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY`
- **Webhook Secret**: `whsec_9QC6yRw5u8zwKuzvgsBQeIqVxzjRqowq`

### Price ID Disponibili
- **Monthly Premium**: `price_1RXVOfHHtQGHyul9qMGFmpmO`
- **Yearly Premium**: `price_1RbmRkHHtQGHyul92oUMSkUY`

## 🚨 API da NON Utilizzare

❌ **Non utilizzare queste API (sono vecchie):**
- `api/android_paypal_payment.php`
- `api/android_subscription_api.php`
- `api/android_update_plan_api.php`
- `api/paypal_*.php`

## 🔍 Test Configurazione

Per testare se Stripe è configurato correttamente:
```
GET /api/stripe_test_config.php
```

## 📱 Flusso Pagamento Android

1. **Ottieni chiave pubblica** → `get-publishable-key.php` (NUOVO)
2. **Testa connessione** → `test-connection.php` (NUOVO)
3. **Inizializza pagamento** → `create-subscription-payment-intent.php`
4. **Mostra form pagamento** → Usa `client_secret` con Stripe SDK
5. **Conferma pagamento** → `confirm-payment.php`
6. **Verifica subscription** → `subscription.php`

## 🛠️ Troubleshooting

### Errore "Invalid API Key provided"
- **NUOVO**: Usa `get-publishable-key.php` per ottenere la chiave corretta
- Verifica che l'app non abbia una versione cache della chiave vecchia
- Controlla che la chiave non sia troncata nell'app
- Testa la connessione con `test-connection.php`

### Errore "Stripe non configurato correttamente"
- Verifica che le chiavi siano corrette
- Controlla che il file `stripe_config.php` sia caricato
- Verifica che la funzione `stripe_is_configured()` restituisca `true`

### Errore "Price ID non valido"
- Usa solo i Price ID configurati sopra
- Verifica che il Price ID sia attivo su Stripe Dashboard

### Errore di autenticazione
- Verifica che il token Bearer sia valido
- Controlla che l'utente sia autenticato

## 📞 Supporto

Se hai problemi, controlla:
1. I log in `api/stripe/logs/`
2. Il file di test `api/stripe_test_config.php`
3. La configurazione in `api/stripe_config.php` 