# 🚀 FitGymTrack: Recurring vs OneTime Subscriptions - Complete Implementation

## 📋 **Project Overview**
Implementato sistema di abbonamenti che permette all'utente di scegliere tra:
- **🔄 Ricorrente**: €4.99/mese con rinnovo automatico 
- **💸 Una Tantum**: €4.99 per 30 giorni senza rinnovo automatico

---

## ✅ **Completed Steps**

### **STEP 1: Database Migration ✅**
```sql
-- Campo aggiunto alla tabella user_subscriptions
ALTER TABLE user_subscriptions 
ADD COLUMN payment_type ENUM('recurring', 'onetime') DEFAULT 'recurring';

-- Aggiornamento dati esistenti
UPDATE user_subscriptions 
SET payment_type = CASE 
    WHEN auto_renew = 1 THEN 'recurring'
    WHEN auto_renew = 0 THEN 'onetime'
    ELSE 'recurring'
END;
```

### **STEP 2: Flutter StripeConfig Update ✅**
**File**: `lib/core/config/stripe_config.dart`

**Novità aggiunte:**
- Due piani distinti: `premium_monthly_recurring` e `premium_monthly_onetime`
- Campo `isRecurring` per distinguere i tipi
- Helper methods: `getPlanByPaymentType()`, `recurringPlan`, `onetimePlan`
- Price IDs:
  - Recurring: `price_1RXVOfHHtQGHyul9qMGFmpmO`
  - OneTime: `price_1RbmRkHHtQGHyul92oUMSkUY`
- Metodi di validazione: `isValidKey()`, `isTestMode`, `isDemoMode`

### **STEP 3: Flutter UI Implementation ✅**
**File**: `lib/features/subscription/presentation/screens/subscription_screen.dart`

**Nuove funzionalità:**
- Sezione selezione tipo pagamento con radio buttons
- Card animate per recurring vs onetime
- Badge distintivi ("RINNOVO AUTOMATICO" vs "NESSUN RINNOVO")
- Info piano selezionato con prezzo dinamico
- Note legali che cambiano in base al tipo selezionato
- Gestione stato `_selectedPaymentType`
- Passa `payment_type` nei metadata a StripeBloc

### **STEP 4: Backend PHP Updates ✅**

#### **File 1: `create-subscription-payment-intent.php`**
**Modifiche:**
- Riceve `payment_type` dai metadata
- Valida payment_type ('recurring'/'onetime')
- Se onetime: imposta `cancel_at_period_end = true`
- Salva payment_type nei metadata del payment intent

#### **File 2: `confirm-payment.php`** 
**Modifiche:**
- Estrae `subscription_payment_type` dai metadata
- Gestione separata per recurring vs onetime
- `handle_onetime_subscription_success()`: forza `cancel_at_period_end`
- `handle_recurring_subscription_success()`: comportamento normale
- Aggiorna `user_subscriptions` con `payment_type = 'onetime'` e `auto_renew = 0`

#### **File 3: `stripe_user_subscription_sync.php`**
**Modifiche:**
- `determine_payment_type_from_stripe_data()`: auto-detect tipo
- `update_or_create_user_subscription_with_type()`: salva payment_type
- `sync_expired_subscriptions()`: logica separata per onetime
- Auto-renew impostato in base a payment_type
- Debug con informazioni payment_type

---

## 🎯 **System Logic**

### **Recurring Subscription Flow:**
1. User seleziona "Ricorrente" 
2. Crea Stripe subscription normale
3. Si rinnova automaticamente ogni mese
4. User può cancellare quando vuole

### **OneTime Subscription Flow:**
1. User seleziona "Una Tantum"
2. Crea Stripe subscription con `cancel_at_period_end = true`
3. Accesso Premium per 30 giorni
4. Automatic downgrade a Free dopo scadenza
5. NO rinnovo automatico

---

## 🧪 **Testing with Postman - Next Steps**

### **API Endpoints to Test:**

#### **1. Create Customer** 
```http
POST /stripe/customer.php
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": "test@example.com",
  "name": "Test User"
}
```

#### **2. Create Recurring Subscription**
```http
POST /stripe/create-subscription-payment-intent.php
Authorization: Bearer {token}
Content-Type: application/json

{
  "price_id": "price_1RXVOfHHtQGHyul9qMGFmpmO",
  "metadata": {
    "payment_type": "recurring",
    "plan_id": "premium_monthly_recurring",
    "user_platform": "flutter"
  }
}
```

#### **3. Create OneTime Subscription**
```http
POST /stripe/create-subscription-payment-intent.php
Authorization: Bearer {token}
Content-Type: application/json

{
  "price_id": "price_1RbmRkHHtQGHyul92oUMSkUY",
  "metadata": {
    "payment_type": "onetime", 
    "plan_id": "premium_monthly_onetime",
    "user_platform": "flutter"
  }
}
```

#### **4. Confirm Payment**
```http
POST /stripe/confirm-payment.php
Authorization: Bearer {token}
Content-Type: application/json

{
  "payment_intent_id": "pi_xxx...",
  "subscription_type": "subscription"
}
```

#### **5. Get Subscription Status**
```http
GET /stripe/subscription.php
Authorization: Bearer {token}
```

#### **6. Test Expiry (OneTime)**
```http
POST /android_subscription_api.php?action=check_expired
Authorization: Bearer {token}
```

---

## 🔧 **Environment Setup**

### **Stripe Configuration:**
- Test keys: Already configured
- Price IDs: Both recurring and onetime configured
- Webhook: Ready for both types

### **Database:**
- ✅ `payment_type` field added to `user_subscriptions`
- ✅ All existing tables compatible

### **Flutter App:**
- ✅ UI ready for user selection
- ✅ StripeBloc passes payment_type to backend
- ✅ Error handling and success flows

---

## 🐛 **Known Issues to Test**

1. **Webhook handling**: Verify onetime subscriptions process correctly
2. **Expiry logic**: Test that onetime actually downgrades to Free
3. **UI state**: Confirm selected payment type persists through flow  
4. **Edge cases**: What happens if user changes mind mid-payment?
5. **Database consistency**: Verify all fields sync correctly

---

## 📱 **Testing Scenarios**

### **Happy Path - Recurring:**
1. User selects recurring → Payment succeeds → Gets Premium → Renews next month

### **Happy Path - OneTime:**  
1. User selects onetime → Payment succeeds → Gets Premium → Downgrades after 30 days

### **Edge Cases:**
1. Payment fails halfway through
2. User switches payment type during process
3. Network issues during sync
4. Stripe webhook delays

---

## 🎯 **Success Criteria**

- [ ] User can clearly choose between recurring/onetime
- [ ] Recurring subscriptions renew automatically  
- [ ] OneTime subscriptions downgrade to Free after 30 days
- [ ] Database correctly tracks payment_type
- [ ] UI shows correct information for each type
- [ ] Webhooks handle both types correctly
- [ ] No duplicate subscriptions created
- [ ] Error handling works for both flows

---

## 🔄 **Next Steps for Testing Chat**

1. **Postman Collection**: Create comprehensive test collection
2. **Test Users**: Create test users for both subscription types  
3. **Webhook Testing**: Use Stripe CLI for webhook simulation
4. **Database Verification**: Check data consistency after each test
5. **Error Scenarios**: Test payment failures, network issues
6. **Expiry Simulation**: Test what happens at subscription end

---

## 📞 **Ready for Production Checklist**

- [ ] All Postman tests pass
- [ ] Webhook handling verified
- [ ] Database migration applied to production
- [ ] Flutter app tested on real devices
- [ ] OneTime expiry cron job scheduled
- [ ] Monitoring and logging in place
- [ ] User documentation updated
- [ ] Support team trained on new flow

---

*This implementation provides users with clear choice and transparent pricing while maintaining all existing functionality.*