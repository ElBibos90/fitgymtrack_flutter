<?php
// stripe_user_subscription_sync.php - UPDATED WITH PAYMENT_TYPE SUPPORT
// ============================================================================
// STRIPE USER SUBSCRIPTION SYNC - INTEGRAZIONE COMPLETA CON RECURRING/ONETIME
// ============================================================================

// 🆕 NUOVO: Funzione per log dedicato
function stripe_debug_log($message, $data = null) {
    $log_file = __DIR__ . '/debug_subscription.log';
    $timestamp = date('Y-m-d H:i:s');
    
    $log_entry = "[{$timestamp}] [STRIPE_DEBUG] {$message}";
    if ($data) {
        $log_entry .= " - " . json_encode($data, JSON_UNESCAPED_UNICODE);
    }
    $log_entry .= "\n";
    
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
}

/**
 * Funzioni per sincronizzare automaticamente le subscription Stripe
 * con il database locale (users, user_subscriptions, subscription_plans)
 * 🆕 AGGIORNATO: Supporto per payment_type (recurring/onetime)
 */

// ============================================================================
// MAPPATURA STRIPE PRICE_ID → LOCAL PLAN_ID (Updated)
// ============================================================================

/**
 * 🆕 UPDATED: Mappa Stripe price_id al plan_id locale con supporto onetime
 */
function get_local_plan_id_from_stripe_price($stripe_price_id) {
    // Mappatura basata sui price_id definiti in stripe_config.php
    $price_to_plan_map = [
        STRIPE_PREMIUM_MONTHLY_PRICE_ID => 2,           // Premium Monthly Recurring
        STRIPE_PREMIUM_YEARLY_PRICE_ID => 3,            // Premium Yearly Recurring  
        'price_1RbmRkHHtQGHyul92oUMSkUY' => 2,          // Premium Monthly Onetime (stesso piano)
    ];
    
    return $price_to_plan_map[$stripe_price_id] ?? 1; // Default: Free (plan_id = 1)
}

/**
 * 🆕 NEW: Determina il payment_type in base al price_id o subscription
 */
function determine_payment_type_from_stripe_data($stripe_subscription) {
    // Controlla nei metadata prima
    if (isset($stripe_subscription->metadata['payment_type'])) {
        return $stripe_subscription->metadata['payment_type'];
    }
    
    // Controlla se è impostato per cancellarsi
    if ($stripe_subscription->cancel_at_period_end) {
        return 'onetime';
    }
    
    // Controlla price_id specifici
    $price_id = $stripe_subscription->items->data[0]->price->id;
    if ($price_id === 'price_1RbmRkHHtQGHyul92oUMSkUY') {
        return 'onetime';
    }
    
    return 'recurring'; // Default
}

/**
 * Ottiene informazioni del piano locale (unchanged)
 */
function get_subscription_plan_info($plan_id) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        SELECT id, name, price, billing_cycle, max_workouts, max_custom_exercises,
               advanced_stats, cloud_backup, no_ads
        FROM subscription_plans 
        WHERE id = ?
    ");
    $stmt->execute([$plan_id]);
    
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

// ============================================================================
// SINCRONIZZAZIONE UTENTE E SUBSCRIPTION POST-PAGAMENTO (Updated)
// ============================================================================

/**
 * 🆕 UPDATED: Sincronizza tutto dopo pagamento Stripe con supporto payment_type
 */
function sync_user_subscription_after_stripe_payment($user_id, $stripe_subscription_id) {
    global $pdo;
    
    stripe_debug_log("🚀 STARTING FULL SYNC", [
        'user_id' => $user_id,
        'stripe_subscription_id' => $stripe_subscription_id
    ]);
    
    // Inizia transazione
    $pdo->beginTransaction();
    
    try {
        // 1. Recupera subscription da Stripe
        stripe_debug_log("📡 Retrieving subscription from Stripe: {$stripe_subscription_id}");
        $stripe_subscription = \Stripe\Subscription::retrieve($stripe_subscription_id);
        stripe_debug_log("✅ Stripe subscription retrieved successfully", [
            'subscription_id' => $stripe_subscription->id,
            'status' => $stripe_subscription->status,
            'customer_id' => $stripe_subscription->customer,
            'current_period_start' => $stripe_subscription->current_period_start,
            'current_period_end' => $stripe_subscription->current_period_end
        ]);
        
        // 2. Ottieni price_id e mappa al plan_id locale
        $stripe_price_id = $stripe_subscription->items->data[0]->price->id;
        $local_plan_id = get_local_plan_id_from_stripe_price($stripe_price_id);
        
        // 🆕 NUOVO: Determina payment_type
        $payment_type = determine_payment_type_from_stripe_data($stripe_subscription);
        
        stripe_debug_log("🗺️ Mapping Stripe data", [
            'price_id' => $stripe_price_id,
            'local_plan_id' => $local_plan_id,
            'payment_type' => $payment_type,
            'cancel_at_period_end' => $stripe_subscription->cancel_at_period_end
        ]);
        
        // 3. Aggiorna users.current_plan_id
        stripe_debug_log("👤 Updating user current plan to {$local_plan_id}");
        update_user_current_plan($user_id, $local_plan_id);
        
        // 4. 🆕 UPDATED: Aggiorna/Crea user_subscriptions con payment_type
        stripe_debug_log("📝 Updating user_subscriptions table with stripe_subscription_id: {$stripe_subscription_id}");
        update_or_create_user_subscription_with_type($user_id, $stripe_subscription, $local_plan_id, $payment_type);
        
        // 5. Aggiorna stripe_subscriptions (se non già fatto)
        stripe_debug_log("💳 Updating stripe_subscriptions table");
        update_stripe_subscriptions_table($user_id, $stripe_subscription, $local_plan_id, $stripe_price_id);
        
        // 6. Pulisci subscription precedenti
        stripe_debug_log("🧹 Cleaning up old subscriptions");
        cleanup_old_user_subscriptions($user_id, $stripe_subscription_id);
        
        $pdo->commit();
        
        stripe_debug_log("🎉 FULL SYNC COMPLETED SUCCESSFULLY", [
            'user_id' => $user_id,
            'stripe_subscription_id' => $stripe_subscription_id,
            'local_plan_id' => $local_plan_id,
            'payment_type' => $payment_type
        ]);
        
        return [
            'success' => true,
            'user_id' => $user_id,
            'local_plan_id' => $local_plan_id,
            'payment_type' => $payment_type, // 🆕 NUOVO
            'stripe_subscription_id' => $stripe_subscription_id,
            'cancel_at_period_end' => $stripe_subscription->cancel_at_period_end,
            'plan_info' => get_subscription_plan_info($local_plan_id)
        ];
        
    } catch (Exception $e) {
        $pdo->rollBack();
        
        stripe_debug_log("❌ SYNC FAILED", [
            'user_id' => $user_id,
            'stripe_subscription_id' => $stripe_subscription_id,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        
        throw $e;
    }
}

// ============================================================================
// AGGIORNAMENTO TABELLA USERS (unchanged)
// ============================================================================

/**
 * Aggiorna users.current_plan_id (unchanged)
 */
function update_user_current_plan($user_id, $plan_id) {
    global $pdo;
    
    stripe_debug_log("Updating user {$user_id} current_plan_id to {$plan_id}");
    
    $stmt = $pdo->prepare("
        UPDATE users 
        SET current_plan_id = ?, last_login = CURRENT_TIMESTAMP
        WHERE id = ?
    ");
    
    $result = $stmt->execute([$plan_id, $user_id]);
    
    if ($result && $stmt->rowCount() > 0) {
        stripe_debug_log("User {$user_id} current_plan_id updated successfully");
    } else {
        stripe_debug_log("Failed to update user {$user_id} current_plan_id");
        throw new Exception("Failed to update user current plan");
    }
    
    return $result;
}

// ============================================================================
// GESTIONE USER_SUBSCRIPTIONS (Updated)
// ============================================================================

/**
 * 🆕 UPDATED: Aggiorna o crea record in user_subscriptions con payment_type
 */
function update_or_create_user_subscription_with_type($user_id, $stripe_subscription, $local_plan_id, $payment_type) {
    global $pdo;
    
    $subscription_id = $stripe_subscription->id;
    $customer_id = $stripe_subscription->customer;
    $start_date = date('Y-m-d H:i:s', $stripe_subscription->current_period_start);
    $end_date = date('Y-m-d H:i:s', $stripe_subscription->current_period_end);
    $status = map_stripe_status_to_local($stripe_subscription->status);
    
    // 🆕 NUOVO: auto_renew dipende da payment_type
    $auto_renew = ($payment_type === 'recurring') ? 1 : 0;
    
    stripe_debug_log("📝 UPDATING USER_SUBSCRIPTIONS", [
        'user_id' => $user_id,
        'stripe_subscription_id' => $subscription_id,
        'payment_type' => $payment_type,
        'auto_renew' => $auto_renew,
        'cancel_at_period_end' => $stripe_subscription->cancel_at_period_end,
        'start_date' => $start_date,
        'end_date' => $end_date,
        'status' => $status
    ]);
    
    // Controlla se esiste già una subscription per questo utente
    $stmt = $pdo->prepare("
        SELECT id, status 
        FROM user_subscriptions 
        WHERE user_id = ? AND stripe_subscription_id = ?
    ");
    $stmt->execute([$user_id, $subscription_id]);
    $existing_subscription = $stmt->fetch(PDO::FETCH_ASSOC);
    
    stripe_debug_log("🔍 CHECKING EXISTING SUBSCRIPTION", [
        'user_id' => $user_id,
        'subscription_id' => $subscription_id,
        'existing_found' => $existing_subscription ? 'YES' : 'NO',
        'existing_id' => $existing_subscription ? $existing_subscription['id'] : null,
        'existing_status' => $existing_subscription ? $existing_subscription['status'] : null
    ]);
    
    if ($existing_subscription) {
        // 🆕 UPDATED: Aggiorna subscription esistente con payment_type
        stripe_debug_log("🔄 UPDATING EXISTING USER_SUBSCRIPTION", [
            'existing_id' => $existing_subscription['id'],
            'stripe_subscription_id' => $subscription_id
        ]);
        
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET 
                plan_id = ?,
                status = ?,
                start_date = ?,
                end_date = ?,
                auto_renew = ?,
                payment_type = ?,
                payment_provider = 'stripe',
                payment_reference = ?,
                last_payment_date = CURRENT_TIMESTAMP,
                stripe_customer_id = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ");
        
        $result = $stmt->execute([
            $local_plan_id,
            $status,
            $start_date,
            $end_date,
            $auto_renew,           // 🆕 NUOVO
            $payment_type,         // 🆕 NUOVO
            $subscription_id,
            $customer_id,
            $existing_subscription['id']
        ]);
        
        stripe_debug_log("✅ UPDATE RESULT", [
            'success' => $result,
            'rows_affected' => $stmt->rowCount(),
            'stripe_subscription_id' => $subscription_id
        ]);
        
    } else {
        // 🆕 UPDATED: Crea nuova subscription con payment_type
        stripe_debug_log("🆕 CREATING NEW USER_SUBSCRIPTION", [
            'user_id' => $user_id,
            'stripe_subscription_id' => $subscription_id,
            'payment_type' => $payment_type
        ]);
        
        // Prima, marca come expired le subscription attive precedenti
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND status = 'active' AND stripe_subscription_id IS NULL
        ");
        $stmt->execute([$user_id]);
        stripe_debug_log("🧹 EXPIRED OLD SUBSCRIPTIONS", [
            'rows_affected' => $stmt->rowCount()
        ]);
        
        // Crea nuova subscription con campi aggiornati
        $stmt = $pdo->prepare("
            INSERT INTO user_subscriptions (
                user_id, plan_id, status, start_date, end_date,
                auto_renew, payment_type, payment_provider, payment_reference,
                last_payment_date, stripe_subscription_id, stripe_customer_id,
                created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'stripe', ?, CURRENT_TIMESTAMP, ?, ?, 
                     CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ");
        
        stripe_debug_log("📝 EXECUTING INSERT WITH VALUES", [
            'user_id' => $user_id,
            'plan_id' => $local_plan_id,
            'status' => $status,
            'start_date' => $start_date,
            'end_date' => $end_date,
            'auto_renew' => $auto_renew,
            'payment_type' => $payment_type,
            'payment_reference' => $subscription_id,
            'stripe_subscription_id' => $subscription_id,
            'stripe_customer_id' => $customer_id
        ]);
        
        $result = $stmt->execute([
            $user_id,
            $local_plan_id,
            $status,
            $start_date,
            $end_date,
            $auto_renew,           // 🆕 NUOVO
            $payment_type,         // 🆕 NUOVO
            $subscription_id,
            $subscription_id,
            $customer_id
        ]);
        
        stripe_debug_log("✅ INSERT RESULT", [
            'success' => $result,
            'insert_id' => $pdo->lastInsertId(),
            'stripe_subscription_id' => $subscription_id
        ]);
    }
    
    if (!$result) {
        stripe_debug_log("❌ FAILED TO UPDATE USER_SUBSCRIPTIONS", [
            'user_id' => $user_id,
            'stripe_subscription_id' => $subscription_id,
            'error_info' => $pdo->errorInfo()
        ]);
        throw new Exception("Failed to update user_subscriptions table");
    }
    
    stripe_debug_log("🎉 USER_SUBSCRIPTIONS UPDATED SUCCESSFULLY", [
        'user_id' => $user_id,
        'stripe_subscription_id' => $subscription_id,
        'payment_type' => $payment_type,
        'method' => $existing_subscription ? 'UPDATE' : 'INSERT'
    ]);
    
    return $result;
}

/**
 * 🆕 UPDATED: Mappa status Stripe a status locale con logica onetime
 */
function map_stripe_status_to_local($stripe_status) {
    $status_map = [
        'active' => 'active',
        'past_due' => 'active',          // Mantieni attivo durante grace period
        'unpaid' => 'active',            // Mantieni attivo durante grace period
        'cancelled' => 'cancelled',
        'incomplete' => 'active',        // Se pagamento riesce, è attivo
        'incomplete_expired' => 'expired',
        'trialing' => 'active',
        'paused' => 'active'
    ];
    
    return $status_map[$stripe_status] ?? 'expired';
}

// ============================================================================
// GESTIONE STRIPE_SUBSCRIPTIONS (unchanged)
// ============================================================================

/**
 * Aggiorna stripe_subscriptions table (unchanged)
 */
function update_stripe_subscriptions_table($user_id, $stripe_subscription, $local_plan_id, $stripe_price_id) {
    global $pdo;
    
    stripe_debug_log("Updating stripe_subscriptions table for user {$user_id}");
    
    $stmt = $pdo->prepare("
        INSERT INTO stripe_subscriptions (
            user_id, stripe_subscription_id, stripe_customer_id, status,
            current_period_start, current_period_end, cancel_at_period_end,
            plan_id, price_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE
        status = VALUES(status),
        current_period_start = VALUES(current_period_start),
        current_period_end = VALUES(current_period_end),
        cancel_at_period_end = VALUES(cancel_at_period_end),
        plan_id = VALUES(plan_id),
        price_id = VALUES(price_id),
        updated_at = CURRENT_TIMESTAMP
    ");
    
    $result = $stmt->execute([
        $user_id,
        $stripe_subscription->id,
        $stripe_subscription->customer,
        $stripe_subscription->status,
        $stripe_subscription->current_period_start,
        $stripe_subscription->current_period_end,
        $stripe_subscription->cancel_at_period_end ? 1 : 0,
        $local_plan_id,
        $stripe_price_id
    ]);
    
    if (!$result) {
        throw new Exception("Failed to update stripe_subscriptions table");
    }
    
    stripe_debug_log("stripe_subscriptions updated successfully");
    return $result;
}

// ============================================================================
// CLEANUP E MAINTENANCE (Updated)
// ============================================================================

/**
 * Pulisce subscription precedenti non-Stripe quando ne viene attivata una Stripe (unchanged)
 */
function cleanup_old_user_subscriptions($user_id, $current_stripe_subscription_id) {
    global $pdo;
    
    stripe_debug_log("Cleaning up old subscriptions for user {$user_id}");
    
    // Marca come expired le subscription non-Stripe attive
    $stmt = $pdo->prepare("
        UPDATE user_subscriptions 
        SET status = 'expired', updated_at = CURRENT_TIMESTAMP
        WHERE user_id = ? 
        AND status = 'active' 
        AND (stripe_subscription_id IS NULL OR stripe_subscription_id != ?)
    ");
    
    $result = $stmt->execute([$user_id, $current_stripe_subscription_id]);
    
    if ($stmt->rowCount() > 0) {
        stripe_debug_log("Cleaned up {$stmt->rowCount()} old subscriptions for user {$user_id}");
    }
    
    return $result;
}

/**
 * 🆕 UPDATED: Sincronizza subscription scadute con logica onetime
 */
function sync_expired_subscriptions() {
    global $pdo;
    
    stripe_debug_log("Starting expired subscriptions sync with onetime logic");
    
    try {
        // 1. Trova subscription onetime scadute che devono essere downgrade a Free
        $stmt = $pdo->prepare("
            SELECT DISTINCT us.user_id, us.stripe_subscription_id, us.payment_type
            FROM user_subscriptions us
            WHERE us.status = 'active'
            AND us.payment_type = 'onetime'
            AND us.end_date <= CURRENT_TIMESTAMP
        ");
        $stmt->execute();
        $expired_onetime = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($expired_onetime as $sub) {
            stripe_debug_log("Processing expired ONETIME subscription for user {$sub['user_id']}");
            
            // Aggiorna a piano Free
            update_user_current_plan($sub['user_id'], 1); // plan_id 1 = Free
            
            // Marca subscription come expired
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET status = 'expired', updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ? AND stripe_subscription_id = ?
            ");
            $stmt->execute([$sub['user_id'], $sub['stripe_subscription_id']]);
        }
        
        // 2. Trova subscription Stripe cancellate ma ancora attive localmente
        $stmt = $pdo->prepare("
            SELECT DISTINCT us.user_id, us.stripe_subscription_id, us.payment_type
            FROM user_subscriptions us
            JOIN stripe_subscriptions ss ON us.stripe_subscription_id = ss.stripe_subscription_id
            WHERE us.status = 'active'
            AND ss.status IN ('cancelled', 'incomplete_expired')
            AND (us.end_date < CURRENT_TIMESTAMP OR us.payment_type = 'onetime')
        ");
        $stmt->execute();
        $expired_stripe = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($expired_stripe as $sub) {
            stripe_debug_log("Processing expired STRIPE subscription for user {$sub['user_id']} (type: {$sub['payment_type']})");
            
            // Aggiorna a piano Free
            update_user_current_plan($sub['user_id'], 1); // plan_id 1 = Free
            
            // Marca subscription come expired
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET status = 'expired', updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ? AND stripe_subscription_id = ?
            ");
            $stmt->execute([$sub['user_id'], $sub['stripe_subscription_id']]);
        }
        
        $total_processed = count($expired_onetime) + count($expired_stripe);
        stripe_debug_log("Expired subscriptions sync completed: {$total_processed} processed (onetime: " . count($expired_onetime) . ", stripe: " . count($expired_stripe) . ")");
        
    } catch (Exception $e) {
        stripe_debug_log("Failed to sync expired subscriptions", ['error' => $e->getMessage()]);
    }
}

// ============================================================================
// FUNZIONI DI UTILITÀ (Updated)
// ============================================================================

/**
 * 🆕 UPDATED: Ottiene lo stato completo della subscription di un utente con payment_type
 */
function get_user_subscription_status($user_id) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        SELECT 
            u.id as user_id,
            u.username,
            u.current_plan_id,
            sp.name as current_plan_name,
            sp.billing_cycle,
            us.status as subscription_status,
            us.start_date,
            us.end_date,
            us.stripe_subscription_id,
            us.payment_provider,
            us.payment_type,
            us.auto_renew,
            ss.status as stripe_status,
            ss.cancel_at_period_end
        FROM users u
        LEFT JOIN subscription_plans sp ON u.current_plan_id = sp.id
        LEFT JOIN user_subscriptions us ON u.id = us.user_id AND us.status = 'active'
        LEFT JOIN stripe_subscriptions ss ON us.stripe_subscription_id = ss.stripe_subscription_id
        WHERE u.id = ?
    ");
    $stmt->execute([$user_id]);
    
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Verifica se un utente ha accesso Premium (unchanged)
 */
function user_has_premium_access($user_id) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        SELECT COUNT(*) 
        FROM users u
        JOIN user_subscriptions us ON u.id = us.user_id
        WHERE u.id = ? 
        AND us.status = 'active'
        AND us.end_date > CURRENT_TIMESTAMP
        AND u.current_plan_id > 1
    ");
    $stmt->execute([$user_id]);
    
    return $stmt->fetchColumn() > 0;
}

/**
 * 🆕 ENHANCED: Debug dello stato subscription dell'utente con focus su stripe_subscription_id
 */
function debug_user_subscription_status($user_id) {
    global $pdo;
    
    stripe_debug_log("[STRIPE_DEBUG] DEBUGGING USER SUBSCRIPTION STATUS", [
        'user_id' => $user_id
    ]);
    
    try {
        // 1. Stato utente
        $stmt = $pdo->prepare("
            SELECT id, username, email, current_plan_id, created_at, last_login
            FROM users 
            WHERE id = ?
        ");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        stripe_debug_log("[STRIPE_DEBUG] USER STATUS", [
            'user_id' => $user['id'],
            'username' => $user['username'],
            'current_plan_id' => $user['current_plan_id'],
            'last_login' => $user['last_login']
        ]);
        
        // 2. User subscriptions
        $stmt = $pdo->prepare("
            SELECT id, plan_id, status, start_date, end_date, auto_renew, 
                   payment_type, payment_provider, payment_reference,
                   stripe_subscription_id, stripe_customer_id, created_at, updated_at
            FROM user_subscriptions 
            WHERE user_id = ?
            ORDER BY created_at DESC
        ");
        $stmt->execute([$user_id]);
        $user_subs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        stripe_debug_log("[STRIPE_DEBUG] USER_SUBSCRIPTIONS COUNT", [
            'total_records' => count($user_subs)
        ]);
        
        foreach ($user_subs as $index => $sub) {
            stripe_debug_log("[STRIPE_DEBUG] USER_SUBSCRIPTION #{$index}", [
                'id' => $sub['id'],
                'plan_id' => $sub['plan_id'],
                'status' => $sub['status'],
                'payment_type' => $sub['payment_type'],
                'auto_renew' => $sub['auto_renew'],
                'stripe_subscription_id' => $sub['stripe_subscription_id'] ?? 'NULL',
                'stripe_customer_id' => $sub['stripe_customer_id'] ?? 'NULL',
                'payment_reference' => $sub['payment_reference'] ?? 'NULL',
                'start_date' => $sub['start_date'],
                'end_date' => $sub['end_date'],
                'created_at' => $sub['created_at']
            ]);
        }
        
        // 3. Stripe subscriptions
        $stmt = $pdo->prepare("
            SELECT id, stripe_subscription_id, stripe_customer_id, status,
                   current_period_start, current_period_end, cancel_at_period_end,
                   plan_id, price_id, created_at, updated_at
            FROM stripe_subscriptions 
            WHERE user_id = ?
            ORDER BY created_at DESC
        ");
        $stmt->execute([$user_id]);
        $stripe_subs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        stripe_debug_log("[STRIPE_DEBUG] STRIPE_SUBSCRIPTIONS COUNT", [
            'total_records' => count($stripe_subs)
        ]);
        
        foreach ($stripe_subs as $index => $sub) {
            stripe_debug_log("[STRIPE_DEBUG] STRIPE_SUBSCRIPTION #{$index}", [
                'id' => $sub['id'],
                'stripe_subscription_id' => $sub['stripe_subscription_id'],
                'stripe_customer_id' => $sub['stripe_customer_id'],
                'status' => $sub['status'],
                'plan_id' => $sub['plan_id'],
                'price_id' => $sub['price_id'],
                'cancel_at_period_end' => $sub['cancel_at_period_end'],
                'current_period_start' => $sub['current_period_start'],
                'current_period_end' => $sub['current_period_end'],
                'created_at' => $sub['created_at']
            ]);
        }
        
        // 4. Payment intents
        $stmt = $pdo->prepare("
            SELECT id, stripe_payment_intent_id, user_id, payment_type, amount, 
                   currency, status, metadata, created_at, updated_at
            FROM stripe_payment_intents 
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT 5
        ");
        $stmt->execute([$user_id]);
        $payment_intents = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        stripe_debug_log("[STRIPE_DEBUG] PAYMENT_INTENTS COUNT", [
            'total_records' => count($payment_intents)
        ]);
        
        foreach ($payment_intents as $index => $pi) {
            stripe_debug_log("[STRIPE_DEBUG] PAYMENT_INTENT #{$index}", [
                'id' => $pi['id'],
                'stripe_payment_intent_id' => $pi['stripe_payment_intent_id'],
                'payment_type' => $pi['payment_type'],
                'amount' => $pi['amount'],
                'status' => $pi['status'],
                'metadata' => $pi['metadata'],
                'created_at' => $pi['created_at']
            ]);
        }
        
        // 5. 🔍 ANALISI CRITICA: Verifica coerenza stripe_subscription_id
        $active_user_subs = array_filter($user_subs, function($sub) {
            return $sub['status'] === 'active';
        });
        
        $active_stripe_subs = array_filter($stripe_subs, function($sub) {
            return $sub['status'] === 'active';
        });
        
        stripe_debug_log("[STRIPE_DEBUG] CRITICAL ANALYSIS", [
            'active_user_subscriptions' => count($active_user_subs),
            'active_stripe_subscriptions' => count($active_stripe_subs),
            'user_subs_with_stripe_id' => count(array_filter($user_subs, function($sub) {
                return !empty($sub['stripe_subscription_id']);
            })),
            'user_subs_without_stripe_id' => count(array_filter($user_subs, function($sub) {
                return empty($sub['stripe_subscription_id']);
            }))
        ]);
        
        // 6. ⚠️ PROBLEMI IDENTIFICATI
        $problems = [];
        
        if (count($active_user_subs) === 0) {
            $problems[] = "No active user_subscriptions found";
        }
        
        if (count($active_user_subs) > 1) {
            $problems[] = "Multiple active user_subscriptions found";
        }
        
        foreach ($active_user_subs as $sub) {
            if (empty($sub['stripe_subscription_id'])) {
                $problems[] = "Active user_subscription missing stripe_subscription_id (ID: {$sub['id']})";
            }
        }
        
        if (!empty($problems)) {
            stripe_debug_log("[STRIPE_DEBUG] PROBLEMS IDENTIFIED", [
                'user_id' => $user_id,
                'problems' => $problems
            ]);
        } else {
            stripe_debug_log("[STRIPE_DEBUG] NO PROBLEMS IDENTIFIED", [
                'user_id' => $user_id
            ]);
        }
        
    } catch (Exception $e) {
        stripe_debug_log("[STRIPE_DEBUG] DEBUG FAILED", [
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
    }
}

// ============================================================================
// INTEGRATION HOOKS - UPDATED
// ============================================================================

/**
 * Hook da chiamare quando un pagamento Stripe viene confermato (unchanged)
 */
function stripe_payment_success_hook($user_id, $payment_intent_id, $subscription_type) {
    if ($subscription_type !== 'subscription') {
        return; // Solo per subscription
    }
    
    try {
        // Trova subscription associata al payment intent
        $payment_intent = \Stripe\PaymentIntent::retrieve($payment_intent_id);
        
        // Cerca invoice associata
        $invoices = \Stripe\Invoice::all([
            'customer' => $payment_intent->customer,
            'status' => 'paid',
            'limit' => 10
        ]);
        
        foreach ($invoices->data as $invoice) {
            if ($invoice->payment_intent === $payment_intent_id && $invoice->subscription) {
                stripe_debug_log("Found subscription {$invoice->subscription} for payment {$payment_intent_id}");
                
                // Sincronizza tutto
                sync_user_subscription_after_stripe_payment($user_id, $invoice->subscription);
                
                break;
            }
        }
        
    } catch (Exception $e) {
        stripe_debug_log("Payment success hook failed", [
            'user_id' => $user_id,
            'payment_intent_id' => $payment_intent_id,
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * Hook da chiamare quando una subscription viene aggiornata via webhook (unchanged)
 */
function stripe_subscription_webhook_hook($stripe_subscription) {
    try {
        // Trova user_id dal customer
        $customer_id = $stripe_subscription->customer;
        $user_id = get_user_id_from_stripe_customer($customer_id);
        
        if ($user_id) {
            stripe_debug_log("Webhook: syncing subscription {$stripe_subscription->id} for user {$user_id}");
            sync_user_subscription_after_stripe_payment($user_id, $stripe_subscription->id);
        }
        
    } catch (Exception $e) {
        stripe_debug_log("Subscription webhook hook failed", [
            'subscription_id' => $stripe_subscription->id,
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * Ottiene user_id da stripe customer_id (unchanged)
 */
function get_user_id_from_stripe_customer($stripe_customer_id) {
    global $pdo;
    
    $stmt = $pdo->prepare("SELECT user_id FROM stripe_customers WHERE stripe_customer_id = ?");
    $stmt->execute([$stripe_customer_id]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    return $result ? $result['user_id'] : null;
}

// ============================================================================
// 🆕 NUOVE FUNZIONI PER ONETIME MANAGEMENT
// ============================================================================

/**
 * 🆕 NEW: Cron job per gestire scadenze subscription onetime
 * Da chiamare giornalmente via cron
 */
function process_onetime_subscription_expiry() {
    stripe_debug_log("Starting daily onetime subscription expiry check");
    
    sync_expired_subscriptions();
    
    stripe_debug_log("Daily onetime subscription expiry check completed");
}

/**
 * 🆕 NEW: Controlla se una subscription è configurata correttamente per onetime
 */
function validate_onetime_subscription_setup($user_id, $stripe_subscription_id) {
    global $pdo;
    
    try {
        // Controlla setup locale
        $stmt = $pdo->prepare("
            SELECT payment_type, auto_renew 
            FROM user_subscriptions 
            WHERE user_id = ? AND stripe_subscription_id = ?
        ");
        $stmt->execute([$user_id, $stripe_subscription_id]);
        $local_sub = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Controlla setup Stripe
        $stripe_subscription = \Stripe\Subscription::retrieve($stripe_subscription_id);
        
        $validation = [
            'local_payment_type_correct' => $local_sub['payment_type'] === 'onetime',
            'local_auto_renew_disabled' => $local_sub['auto_renew'] == 0,
            'stripe_cancel_at_period_end' => $stripe_subscription->cancel_at_period_end,
            'overall_valid' => false
        ];
        
        $validation['overall_valid'] = $validation['local_payment_type_correct'] && 
                                     $validation['local_auto_renew_disabled'] && 
                                     $validation['stripe_cancel_at_period_end'];
        
        stripe_debug_log("Onetime subscription validation for user {$user_id}: " . json_encode($validation));
        
        return $validation;
        
    } catch (Exception $e) {
        stripe_debug_log("Failed to validate onetime subscription setup", [
            'user_id' => $user_id,
            'subscription_id' => $stripe_subscription_id,
            'error' => $e->getMessage()
        ]);
        return ['overall_valid' => false, 'error' => $e->getMessage()];
    }
}
?>