<?php
// 🆕 CRITICO: Abilita logging errori PHP (COMMENTATO - non serve al momento)
// error_reporting(E_ALL);
// ini_set('display_errors', 0);
// ini_set('log_errors', 1);
// ini_set('error_log', __DIR__ . '/php_errors.log');

// 🆕 DEBUG: Log per verificare se il file viene chiamato (COMMENTATO - non serve al momento)
// $log_file = __DIR__ . '/debug_subscription.log';
// $timestamp = date('Y-m-d H:i:s');
// $log_entry = "[{$timestamp}] [STRIPE_DEBUG] confirm-payment.php START - Method: {$_SERVER['REQUEST_METHOD']}\n";
// file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);

// 🆕 CRITICO: Try-catch globale per catturare errori fatali
try {
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';
    // require_once 'stripe_user_subscription_sync.php'; // TEMPORANEO: Rimosso per debug

// ============================================================================
// STRIPE PAYMENT CONFIRMATION - UPDATED WITH RECURRING/ONETIME SUPPORT
// ============================================================================

    // 🆕 NUOVO: Funzione per log dedicato (RIMOSSA - già dichiarata in stripe_auth_bridge.php)
    // function stripe_debug_log($message, $data = null) {
    //     $log_file = __DIR__ . '/debug_subscription.log';
    //     $timestamp = date('Y-m-d H:i:s');
    //     
    //     $log_entry = "[{$timestamp}] [STRIPE_DEBUG] {$message}";
    //     if ($data) {
    //         $log_entry .= " - " . json_encode($data, JSON_UNESCAPED_UNICODE);
    //     }
    //     $log_entry .= "\n";
    //     
    //     file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    // }

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Solo POST supportato
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    stripe_json_response(false, null, 'Solo POST supportato');
}

// Verifica che Stripe sia configurato
if (!stripe_is_configured()) {
    stripe_json_response(false, null, 'Stripe non configurato correttamente');
}

// Get user from token
$user = get_user_from_token();
if (!$user) {
    http_response_code(401);
    stripe_json_response(false, null, 'Token non valido');
}

$user_id = $user['id'];

    // ============================================================================
    // HELPER FUNCTIONS (DEFINITE PRIMA DELLA FUNZIONE PRINCIPALE)
    // ============================================================================

    /**
     * 🆕 NEW: Gestisce il successo di un pagamento subscription con supporto recurring/onetime
     */
    function handle_subscription_payment_success_with_type($user_id, $payment_intent, $payment_type) {
        global $pdo;
        
        stripe_debug_log("Handling subscription payment success", [
            'user_id' => $user_id,
            'payment_intent_id' => $payment_intent->id,
            'payment_type' => $payment_type
        ]);
        
        try {
            // Trova la subscription associata tramite invoice
            $target_subscription_id = find_subscription_for_payment_intent($payment_intent);
            
            stripe_debug_log("SUBSCRIPTION SEARCH RESULT", [
                'payment_intent_id' => $payment_intent->id,
                'target_subscription_id' => $target_subscription_id,
                'found' => $target_subscription_id ? 'YES' : 'NO'
            ]);
            
            if (!$target_subscription_id) {
                stripe_debug_log("NO SUBSCRIPTION FOUND - USING FALLBACK", [
                    'payment_intent_id' => $payment_intent->id,
                    'customer_id' => $payment_intent->customer
                ]);
                
                // Usa fallback
                handle_subscription_payment_success_fallback($user_id, $payment_intent);
                return [
                    'success' => true,
                    'method' => 'fallback',
                    'payment_type' => $payment_type,
                    'stripe_subscription_id' => null
                ];
            }
            
            stripe_debug_log("SUBSCRIPTION FOUND - PROCEEDING WITH SYNC", [
                'subscription_id' => $target_subscription_id,
                'payment_type' => $payment_type
            ]);
            
            // 🆕 NUOVO: Gestisci diversamente in base al payment_type
            if ($payment_type === 'onetime') {
                $sync_result = handle_onetime_subscription_success($user_id, $target_subscription_id, $payment_intent);
            } else {
                $sync_result = handle_recurring_subscription_success($user_id, $target_subscription_id, $payment_intent);
            }
            
            stripe_debug_log("SYNC COMPLETED SUCCESSFULLY", [
                'user_id' => $user_id,
                'subscription_id' => $target_subscription_id,
                'sync_result' => $sync_result
            ]);
            
            // Debug status post-sync
            debug_user_subscription_status($user_id);
            
            return $sync_result;
            
        } catch (Exception $e) {
            stripe_debug_log("FAILED TO HANDLE SUBSCRIPTION PAYMENT SUCCESS", [
                'user_id' => $user_id,
                'payment_intent_id' => $payment_intent->id,
                'payment_type' => $payment_type,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * 🆕 NEW: Gestisce subscription ricorrente (comportamento normale)
     */
    function handle_recurring_subscription_success($user_id, $subscription_id, $payment_intent) {
        stripe_debug_log("Handling RECURRING subscription success for user {$user_id}");
        
        // Sincronizzazione normale - subscription si rinnoverà automaticamente
        $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
        $sync_result['payment_type'] = 'recurring';
        $sync_result['will_auto_renew'] = true;
        
        return $sync_result;
    }

    /**
     * 🆕 NEW: Gestisce subscription una tantum
     */
    function handle_onetime_subscription_success($user_id, $subscription_id, $payment_intent) {
        global $pdo;
        
        stripe_debug_log("Handling ONETIME subscription success for user {$user_id}");
        
        try {
            // 1. Sincronizzazione normale prima
            $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
            
            // 2. 🆕 NUOVO: Assicurati che la subscription sia impostata per cancellarsi
            $stripe_subscription = \Stripe\Subscription::retrieve($subscription_id);
            
            if (!$stripe_subscription->cancel_at_period_end) {
                stripe_debug_log("Setting cancel_at_period_end for onetime subscription: {$subscription_id}");
                
                \Stripe\Subscription::update($subscription_id, [
                    'cancel_at_period_end' => true
                ]);
            }
            
            // 3. Aggiorna database locale
            $stmt = $pdo->prepare("
                UPDATE stripe_subscriptions 
                SET cancel_at_period_end = 1, updated_at = CURRENT_TIMESTAMP
                WHERE stripe_subscription_id = ? AND user_id = ?
            ");
            $stmt->execute([$subscription_id, $user_id]);
            
            // 4. 🆕 NUOVO: Aggiorna user_subscriptions con payment_type = 'onetime'
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET payment_type = 'onetime', auto_renew = 0, updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ? AND stripe_subscription_id = ?
            ");
            $stmt->execute([$user_id, $subscription_id]);
            
            stripe_debug_log("Onetime subscription configured successfully: will cancel at period end");
            
            $sync_result['payment_type'] = 'onetime';
            $sync_result['will_auto_renew'] = false;
            $sync_result['cancel_at_period_end'] = true;
            
            return $sync_result;
            
        } catch (Exception $e) {
            stripe_log_error('Failed to handle onetime subscription', [
                'user_id' => $user_id,
                'subscription_id' => $subscription_id,
                'error' => $e->getMessage()
            ]);
            throw $e;
        }
    }

    /**
     * Gestisce il successo di un pagamento per donazione (unchanged)
     */
    function handle_donation_payment_success($user_id, $payment_intent) {
        global $pdo;
        
        try {
            // Registra la donazione
            $stmt = $pdo->prepare("
                INSERT INTO donations (
                    user_id, stripe_payment_intent_id, amount, currency, 
                    payment_date, status, metadata
                ) VALUES (?, ?, ?, ?, NOW(), 'completed', ?)
                ON DUPLICATE KEY UPDATE
                status = 'completed',
                payment_date = NOW()
            ");
            
            $metadata = json_encode([
                'stripe_customer_id' => $payment_intent->customer,
                'platform' => 'fitgymtrack_flutter'
            ]);
            
            $stmt->execute([
                $user_id,
                $payment_intent->id,
                $payment_intent->amount,
                $payment_intent->currency,
                $metadata
            ]);
            
            stripe_debug_log("Donation recorded: {$payment_intent->id} for user {$user_id}, amount: €" . stripe_cents_to_euros($payment_intent->amount));
            
        } catch (Exception $e) {
            stripe_log_error('Failed to handle donation payment success', [
                'user_id' => $user_id,
                'payment_intent_id' => $payment_intent->id,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * 🆕 ENHANCED: Trova subscription associata al payment intent con ricerca più robusta
     */
    function find_subscription_for_payment_intent($payment_intent) {
        stripe_debug_log("ENHANCED: Finding subscription for payment intent: {$payment_intent->id}");
        
        try {
            $customer_id = $payment_intent->customer;
            $payment_intent_id = $payment_intent->id;
            
            stripe_debug_log("SEARCH PARAMETERS", [
                'payment_intent_id' => $payment_intent_id,
                'customer_id' => $customer_id
            ]);
            
            // 🆕 METODO 0: Cerca nei metadata del payment intent locale
            stripe_debug_log("METHOD 0: Searching via local payment intent metadata");
            global $pdo;
            
            $stmt = $pdo->prepare("
                SELECT metadata 
                FROM stripe_payment_intents 
                WHERE stripe_payment_intent_id = ?
            ");
            $stmt->execute([$payment_intent_id]);
            $local_payment = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($local_payment && $local_payment['metadata']) {
                $metadata = json_decode($local_payment['metadata'], true);
                if (isset($metadata['stripe_subscription_id'])) {
                    $subscription_id = $metadata['stripe_subscription_id'];
                    stripe_debug_log("Found subscription in local payment intent metadata: {$subscription_id}");
                    return $subscription_id;
                }
            }
            
            // 🆕 METODO 1: Cerca subscription tramite metadata del payment intent Stripe
            stripe_debug_log("METHOD 1: Searching via Stripe payment intent metadata");
            if (isset($payment_intent->metadata) && isset($payment_intent->metadata['subscription_id'])) {
                $subscription_id = $payment_intent->metadata['subscription_id'];
                stripe_debug_log("Found subscription in Stripe payment intent metadata: {$subscription_id}");
                return $subscription_id;
            }
            
            // 🆕 METODO 2: Cerca subscription tramite invoice più recente
            stripe_debug_log("METHOD 2: Searching via recent invoices");
            $invoices = \Stripe\Invoice::all([
                'customer' => $customer_id,
                'status' => ['paid', 'open'],
                'limit' => 5
            ]);
            
            stripe_debug_log("Found " . count($invoices->data) . " invoices for customer");
            
            foreach ($invoices->data as $invoice) {
                stripe_debug_log("Checking invoice: {$invoice->id}", [
                    'payment_intent' => $invoice->payment_intent,
                    'subscription' => $invoice->subscription,
                    'status' => $invoice->status,
                    'created' => $invoice->created
                ]);
                
                if ($invoice->payment_intent === $payment_intent_id && $invoice->subscription) {
                    stripe_debug_log("Found subscription via invoice: {$invoice->subscription}");
                    return $invoice->subscription;
                }
            }
            
            // 🆕 METODO 3: Cerca subscription attive/incomplete per questo customer
            stripe_debug_log("METHOD 3: Searching active/incomplete subscriptions");
            $subscriptions = \Stripe\Subscription::all([
                'customer' => $customer_id,
                'status' => ['active', 'incomplete', 'past_due'],
                'limit' => 10
            ]);
            
            stripe_debug_log("Found " . count($subscriptions->data) . " subscriptions for customer");
            
            // Log tutte le subscription trovate
            foreach ($subscriptions->data as $subscription) {
                stripe_debug_log("Subscription: {$subscription->id}", [
                    'status' => $subscription->status,
                    'created' => $subscription->created,
                    'current_period_start' => $subscription->current_period_start,
                    'latest_invoice' => $subscription->latest_invoice
                ]);
            }
            
            // Cerca la subscription più recente
            $latest_subscription = null;
            foreach ($subscriptions->data as $subscription) {
                if (!$latest_subscription || $subscription->created > $latest_subscription->created) {
                    $latest_subscription = $subscription;
                }
            }
            
            if ($latest_subscription) {
                stripe_debug_log("Found latest subscription: {$latest_subscription->id} (created: {$latest_subscription->created})");
                
                // 🆕 VERIFICA: Controlla se questa subscription ha un invoice che corrisponde al payment intent
                if ($latest_subscription->latest_invoice) {
                    try {
                        $latest_invoice = \Stripe\Invoice::retrieve($latest_subscription->latest_invoice);
                        stripe_debug_log("Latest invoice for subscription", [
                            'invoice_id' => $latest_invoice->id,
                            'payment_intent' => $latest_invoice->payment_intent,
                            'target_payment_intent' => $payment_intent_id,
                            'match' => ($latest_invoice->payment_intent === $payment_intent_id)
                        ]);
                        
                        if ($latest_invoice->payment_intent === $payment_intent_id) {
                            stripe_debug_log("CONFIRMED: Subscription {$latest_subscription->id} matches payment intent {$payment_intent_id}");
                            return $latest_subscription->id;
                        }
                    } catch (Exception $e) {
                        stripe_log_error("Error retrieving latest invoice", [
                            'subscription_id' => $latest_subscription->id,
                            'invoice_id' => $latest_subscription->latest_invoice,
                            'error' => $e->getMessage()
                        ]);
                    }
                }
                
                // Se non abbiamo conferma ma è la subscription più recente, la usiamo comunque
                stripe_debug_log("Using latest subscription without invoice confirmation: {$latest_subscription->id}");
                return $latest_subscription->id;
            }
            
            // 🆕 METODO 4: Cerca subscription tramite database locale
            stripe_debug_log("METHOD 4: Searching via local database");
            
            $stmt = $pdo->prepare("
                SELECT stripe_subscription_id 
                FROM stripe_subscriptions 
                WHERE user_id = (SELECT user_id FROM stripe_payment_intents WHERE stripe_payment_intent_id = ?)
                AND status IN ('active', 'incomplete')
                ORDER BY created_at DESC 
                LIMIT 1
            ");
            $stmt->execute([$payment_intent_id]);
            $local_sub = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($local_sub && $local_sub['stripe_subscription_id']) {
                stripe_debug_log("Found subscription via local database: {$local_sub['stripe_subscription_id']}");
                return $local_sub['stripe_subscription_id'];
            }
            
            stripe_debug_log("NO SUBSCRIPTION FOUND", [
                'payment_intent_id' => $payment_intent_id,
                'customer_id' => $customer_id,
                'methods_tried' => ['local_metadata', 'stripe_metadata', 'invoices', 'subscriptions', 'local_db']
            ]);
            
            return null;
            
        } catch (Exception $e) {
            stripe_log_error('ERROR FINDING SUBSCRIPTION', [
                'payment_intent_id' => $payment_intent->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }

    /**
     * 🆕 ENHANCED: Fallback per gestione base subscription con ricerca stripe_subscription_id
     */
    function handle_subscription_payment_success_fallback($user_id, $payment_intent) {
        global $pdo;
        
        stripe_debug_log("ENHANCED FALLBACK: Using fallback subscription handling for user {$user_id}");
        
        try {
            // 1. Aggiorna l'utente al piano Premium base (2 = Monthly)
            $stmt = $pdo->prepare("
                UPDATE users 
                SET current_plan_id = 2
                WHERE id = ?
            ");
            $stmt->execute([$user_id]);
            stripe_debug_log("Updated user {$user_id} current_plan_id to 2");
            
            // 2. Marca come expired le subscription precedenti
            stripe_debug_log("BEFORE UPDATE: Checking active subscriptions for user {$user_id}");
            $checkStmt = $pdo->prepare("SELECT id, plan_id, status FROM user_subscriptions WHERE user_id = ? AND status = 'active'");
            $checkStmt->execute([$user_id]);
            $activeSubscriptions = $checkStmt->fetchAll();
            stripe_debug_log("Active subscriptions before update: " . json_encode($activeSubscriptions));
            
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET status = 'expired', updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ? AND status = 'active'
            ");
            $stmt->execute([$user_id]);
            $rowsAffected = $stmt->rowCount();
            stripe_debug_log("Expired old subscriptions, rows affected: {$rowsAffected}");
            
            // Verifica dopo l'update
            $checkAfterStmt = $pdo->prepare("SELECT id, plan_id, status FROM user_subscriptions WHERE user_id = ?");
            $checkAfterStmt->execute([$user_id]);
            $allSubscriptionsAfter = $checkAfterStmt->fetchAll();
            stripe_debug_log("All subscriptions after update: " . json_encode($allSubscriptionsAfter));
            
            // 🆕 ENHANCED: Cerca stripe_subscription_id con metodi multipli
            $stripe_subscription_id = null;
            $stripe_customer_id = $payment_intent->customer;
            
            // Metodo 1: Cerca dalla tabella stripe_subscriptions
            $stmt = $pdo->prepare("
                SELECT stripe_subscription_id 
                FROM stripe_subscriptions 
                WHERE user_id = ? AND status = 'active' 
                ORDER BY created_at DESC 
                LIMIT 1
            ");
            $stmt->execute([$user_id]);
            $stripe_sub = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($stripe_sub && $stripe_sub['stripe_subscription_id']) {
                $stripe_subscription_id = $stripe_sub['stripe_subscription_id'];
                stripe_debug_log("Found stripe_subscription_id from stripe_subscriptions: {$stripe_subscription_id}");
            } else {
                // Metodo 2: Cerca subscription recenti per questo customer
                stripe_debug_log("Searching Stripe for recent subscriptions for customer: {$stripe_customer_id}");
                try {
                    $subscriptions = \Stripe\Subscription::all([
                        'customer' => $stripe_customer_id,
                        'status' => ['active', 'incomplete'],
                        'limit' => 5
                    ]);
                    
                    if (count($subscriptions->data) > 0) {
                        $latest_subscription = $subscriptions->data[0];
                        foreach ($subscriptions->data as $sub) {
                            if ($sub->created > $latest_subscription->created) {
                                $latest_subscription = $sub;
                            }
                        }
                        $stripe_subscription_id = $latest_subscription->id;
                        stripe_debug_log("Found stripe_subscription_id from Stripe API: {$stripe_subscription_id}");
                    }
                } catch (Exception $e) {
                    stripe_log_error("Error searching Stripe subscriptions", [
                        'customer_id' => $stripe_customer_id,
                        'error' => $e->getMessage()
                    ]);
                }
            }
            
            if (!$stripe_subscription_id) {
                stripe_debug_log("No stripe_subscription_id found, creating record without it");
            }
            
            // 4. Crea nuova subscription in user_subscriptions
            $start_date = date('Y-m-d H:i:s');
            $end_date = date('Y-m-d H:i:s', strtotime('+1 month'));
            
            $stmt = $pdo->prepare("
                INSERT INTO user_subscriptions (
                    user_id, plan_id, status, start_date, end_date,
                    auto_renew, payment_type, payment_provider, payment_reference,
                    last_payment_date, created_at, updated_at, stripe_subscription_id, stripe_customer_id
                ) VALUES (?, 2, 'active', ?, ?, 1, 'recurring', 'stripe', ?, ?, NOW(), NOW(), ?, ?)
            ");
            $stmt->execute([
                $user_id,
                $start_date,
                $end_date,
                $payment_intent->id,
                date('Y-m-d H:i:s'),
                $stripe_subscription_id, // Può essere null
                $stripe_customer_id
            ]);
            
            $insert_id = $pdo->lastInsertId();
            
            stripe_debug_log("ENHANCED FALLBACK COMPLETED", [
                'user_id' => $user_id,
                'insert_id' => $insert_id,
                'stripe_subscription_id' => $stripe_subscription_id,
                'stripe_customer_id' => $stripe_customer_id,
                'payment_intent_id' => $payment_intent->id
            ]);
            
        } catch (Exception $e) {
            stripe_log_error('ENHANCED FALLBACK FAILED', [
                'user_id' => $user_id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * 🆕 ENHANCED: Sincronizza subscription utente dopo pagamento Stripe
     */
    function sync_user_subscription_after_stripe_payment($user_id, $stripe_subscription_id) {
        global $pdo;
        
        stripe_debug_log("SYNC: Starting subscription sync for user {$user_id}, subscription {$stripe_subscription_id}");
        
        try {
            // 1. Recupera subscription da Stripe
            $stripe_subscription = \Stripe\Subscription::retrieve($stripe_subscription_id);
            $stripe_customer_id = $stripe_subscription->customer;
            
            stripe_debug_log("SYNC: Retrieved subscription from Stripe", [
                'subscription_id' => $stripe_subscription_id,
                'status' => $stripe_subscription->status,
                'customer_id' => $stripe_customer_id,
                'current_period_start' => $stripe_subscription->current_period_start,
                'current_period_end' => $stripe_subscription->current_period_end
            ]);
            
            // 2. Aggiorna o inserisci in stripe_subscriptions
            $stmt = $pdo->prepare("
                INSERT INTO stripe_subscriptions (
                    user_id, stripe_subscription_id, stripe_customer_id, status,
                    current_period_start, current_period_end, cancel_at_period_end,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
                ON DUPLICATE KEY UPDATE
                status = VALUES(status),
                current_period_start = VALUES(current_period_start),
                current_period_end = VALUES(current_period_end),
                cancel_at_period_end = VALUES(cancel_at_period_end),
                updated_at = NOW()
            ");
            
            $stmt->execute([
                $user_id,
                $stripe_subscription_id,
                $stripe_customer_id,
                $stripe_subscription->status,
                $stripe_subscription->current_period_start,
                $stripe_subscription->current_period_end,
                $stripe_subscription->cancel_at_period_end ? 1 : 0
            ]);
            
            stripe_debug_log("SYNC: Updated stripe_subscriptions table");
            
            // 3. Aggiorna l'utente al piano Premium (2 = Monthly)
            $stmt = $pdo->prepare("
                UPDATE users 
                SET current_plan_id = 2
                WHERE id = ?
            ");
            $stmt->execute([$user_id]);
            stripe_debug_log("SYNC: Updated user current_plan_id to 2");
            
            // 4. Marca come expired le subscription precedenti
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET status = 'expired'
                WHERE user_id = ? AND status = 'active' 
                AND (stripe_subscription_id != ? OR stripe_subscription_id IS NULL)
            ");
            $stmt->execute([$user_id, $stripe_subscription_id]);
            stripe_debug_log("SYNC: Expired old subscriptions, rows affected: " . $stmt->rowCount());
            
            // 5. Crea o aggiorna subscription in user_subscriptions
            $start_date = date('Y-m-d H:i:s', $stripe_subscription->current_period_start);
            $end_date = date('Y-m-d H:i:s', $stripe_subscription->current_period_end);
            
            $stmt = $pdo->prepare("
                INSERT INTO user_subscriptions (
                    user_id, plan_id, status, start_date, end_date,
                    auto_renew, payment_type, payment_provider, payment_reference,
                    last_payment_date, created_at, stripe_subscription_id, stripe_customer_id
                ) VALUES (?, 2, 'active', ?, ?, ?, 'recurring', 'stripe', ?, ?, NOW(), ?, ?)
                ON DUPLICATE KEY UPDATE
                status = 'active',
                start_date = VALUES(start_date),
                end_date = VALUES(end_date),
                auto_renew = VALUES(auto_renew),
                last_payment_date = VALUES(last_payment_date)
            ");
            
            $auto_renew = $stripe_subscription->cancel_at_period_end ? 0 : 1;
            
            $stmt->execute([
                $user_id,
                $start_date,
                $end_date,
                $auto_renew,
                $stripe_subscription_id,
                date('Y-m-d H:i:s'),
                $stripe_subscription_id,
                $stripe_customer_id
            ]);
            
            $insert_id = $pdo->lastInsertId();
            
            stripe_debug_log("SYNC: Updated user_subscriptions table", [
                'insert_id' => $insert_id,
                'auto_renew' => $auto_renew,
                'start_date' => $start_date,
                'end_date' => $end_date
            ]);
            
            return [
                'success' => true,
                'method' => 'sync',
                'stripe_subscription_id' => $stripe_subscription_id,
                'stripe_customer_id' => $stripe_customer_id,
                'subscription_status' => $stripe_subscription->status,
                'auto_renew' => $auto_renew
            ];
            
        } catch (Exception $e) {
            stripe_log_error('SYNC FAILED', [
                'user_id' => $user_id,
                'stripe_subscription_id' => $stripe_subscription_id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * 🆕 DEBUG: Mostra status subscription utente per debug
     */
    function debug_user_subscription_status($user_id) {
        global $pdo;
        
        try {
            // Status utente
            $stmt = $pdo->prepare("SELECT current_plan_id FROM users WHERE id = ?");
            $stmt->execute([$user_id]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Subscription attive
            $stmt = $pdo->prepare("
                SELECT * FROM user_subscriptions 
                WHERE user_id = ? AND status = 'active'
                ORDER BY created_at DESC
            ");
            $stmt->execute([$user_id]);
            $active_subs = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Stripe subscriptions
            $stmt = $pdo->prepare("
                SELECT * FROM stripe_subscriptions 
                WHERE user_id = ?
                ORDER BY created_at DESC
            ");
            $stmt->execute([$user_id]);
            $stripe_subs = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            stripe_debug_log("DEBUG USER SUBSCRIPTION STATUS", [
                'user_id' => $user_id,
                'current_plan_id' => $user['current_plan_id'] ?? 'null',
                'active_subscriptions_count' => count($active_subs),
                'stripe_subscriptions_count' => count($stripe_subs),
                'active_subscriptions' => $active_subs,
                'stripe_subscriptions' => $stripe_subs
            ]);
            
} catch (Exception $e) {
            stripe_log_error('DEBUG USER STATUS FAILED', [
        'user_id' => $user_id,
        'error' => $e->getMessage()
    ]);
        }
}

// ============================================================================
// UPDATED PAYMENT CONFIRMATION FUNCTION
// ============================================================================

/**
 * 🆕 UPDATED: Conferma il completamento di un pagamento con supporto recurring/onetime
 */
function handle_confirm_payment($user_id) {
    global $pdo;
    
    // Parse request data
    $input = json_decode(file_get_contents('php://input'), true);
    $payment_intent_id = $input['payment_intent_id'] ?? '';
    $subscription_type = $input['subscription_type'] ?? ''; // 'subscription' o 'donation'
    
    // Validazione
    if (empty($payment_intent_id)) {
        stripe_json_response(false, null, 'payment_intent_id è obbligatorio');
    }
    
    if (!in_array($subscription_type, ['subscription', 'donation'])) {
        stripe_json_response(false, null, 'subscription_type deve essere "subscription" o "donation"');
    }
    
        stripe_debug_log("Confirming payment: {$payment_intent_id} for user {$user_id}, type: {$subscription_type}");
    
    try {
        // Verifica che il payment intent appartenga all'utente
        $stmt = $pdo->prepare("
            SELECT id, payment_type, amount, currency, status, metadata 
            FROM stripe_payment_intents 
            WHERE user_id = ? AND stripe_payment_intent_id = ?
        ");
        $stmt->execute([$user_id, $payment_intent_id]);
        $local_payment = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$local_payment) {
            stripe_json_response(false, null, 'Payment Intent non trovato');
        }
        
        // 🆕 NUOVO: Estrai payment_type dai metadata se disponibile
        $metadata = json_decode($local_payment['metadata'] ?? '{}', true);
        $subscription_payment_type = $metadata['subscription_payment_type'] ?? 'recurring';
        
            stripe_debug_log("Payment confirmation details", [
            'payment_intent_id' => $payment_intent_id,
            'user_id' => $user_id,
            'subscription_type' => $subscription_type,
            'subscription_payment_type' => $subscription_payment_type
        ]);
        
        // Recupera payment intent da Stripe
        $payment_intent = \Stripe\PaymentIntent::retrieve($payment_intent_id);
        
        // Verifica che il pagamento sia completato
        if ($payment_intent->status !== 'succeeded') {
            stripe_json_response(false, null, 'Pagamento non completato su Stripe (status: ' . $payment_intent->status . ')');
        }
        
        // Aggiorna status nel database
        $stmt = $pdo->prepare("
            UPDATE stripe_payment_intents 
            SET status = ?
            WHERE user_id = ? AND stripe_payment_intent_id = ?
        ");
        $stmt->execute(['succeeded', $user_id, $payment_intent_id]);
        
        // 🆕 UPDATED: Gestisci completamento in base al tipo con logica recurring/onetime
        if ($subscription_type === 'subscription') {
            $sync_result = handle_subscription_payment_success_with_type($user_id, $payment_intent, $subscription_payment_type);
            
                stripe_debug_log("Payment confirmed successfully: {$payment_intent_id} for user {$user_id}, type: {$subscription_type}, payment_type: {$subscription_payment_type}");
            
            $success_message = $subscription_payment_type === 'recurring' 
                ? 'Pagamento confermato e abbonamento ricorrente attivato'
                : 'Pagamento confermato e abbonamento una tantum attivato';
            
            stripe_json_response(true, [
                'payment_intent_id' => $payment_intent->id,
                'status' => $payment_intent->status,
                'amount' => $payment_intent->amount,
                'currency' => $payment_intent->currency,
                'payment_type' => $subscription_payment_type, // 🆕 NUOVO
                'sync_result' => $sync_result
            ], $success_message);
            
        } else {
            handle_donation_payment_success($user_id, $payment_intent);
            
            stripe_json_response(true, [
                'payment_intent_id' => $payment_intent->id,
                'status' => $payment_intent->status,
                'amount' => $payment_intent->amount,
                'currency' => $payment_intent->currency
            ], 'Donazione confermata con successo');
        }
        
    } catch (Exception $e) {
        stripe_log_error('Failed to confirm payment', [
            'user_id' => $user_id,
            'payment_intent_id' => $payment_intent_id,
            'subscription_type' => $subscription_type,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

    try {
        handle_confirm_payment($user_id);
    } catch (Exception $e) {
        stripe_log_error('Payment confirmation error', [
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        handle_stripe_error($e);
}

// ============================================================================
// CREA TABELLA DONATIONS SE NON ESISTE (unchanged)
// ============================================================================

/**
 * Crea tabella donations se non esiste
 */
function create_donations_table_if_needed($pdo) {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS donations (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                stripe_payment_intent_id VARCHAR(255) NOT NULL UNIQUE,
                amount INT NOT NULL,
                currency VARCHAR(3) NOT NULL DEFAULT 'eur',
                payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
                metadata JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_id (user_id),
                INDEX idx_payment_date (payment_date),
                INDEX idx_status (status)
            )
        ");
        return true;
    } catch (PDOException $e) {
        stripe_log_error('Failed to create donations table', ['error' => $e->getMessage()]);
        return false;
    }
}

// Crea tabella donations se necessario
if (!empty($pdo)) {
    create_donations_table_if_needed($pdo);
    }
} catch (Exception $e) {
    // 🆕 CRITICO: Log errori PHP globali
    error_log("Unhandled Exception: " . $e->getMessage() . "\n" . $e->getTraceAsString());
    http_response_code(500);
    stripe_json_response(false, null, 'Errore interno del server: ' . $e->getMessage());
}
?>