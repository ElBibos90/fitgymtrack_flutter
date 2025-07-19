<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';
require_once 'stripe_user_subscription_sync.php';

// ============================================================================
// STRIPE PAYMENT CONFIRMATION - UPDATED WITH RECURRING/ONETIME SUPPORT
// ============================================================================

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
    
    stripe_log_info("Confirming payment: {$payment_intent_id} for user {$user_id}, type: {$subscription_type}");
    
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
        
        stripe_log_info("Payment confirmation details", [
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
            SET status = ?, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND stripe_payment_intent_id = ?
        ");
        $stmt->execute(['succeeded', $user_id, $payment_intent_id]);
        
        // 🆕 UPDATED: Gestisci completamento in base al tipo con logica recurring/onetime
        if ($subscription_type === 'subscription') {
            $sync_result = handle_subscription_payment_success_with_type($user_id, $payment_intent, $subscription_payment_type);
            
            stripe_log_info("Payment confirmed successfully: {$payment_intent_id} for user {$user_id}, type: {$subscription_type}, payment_type: {$subscription_payment_type}");
            
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

// ============================================================================
// UPDATED PAYMENT SUCCESS HANDLERS
// ============================================================================

/**
 * 🆕 NEW: Gestisce il successo di un pagamento subscription con supporto recurring/onetime
 */
function handle_subscription_payment_success_with_type($user_id, $payment_intent, $payment_type) {
    global $pdo;
    
    stripe_log_info("Handling subscription payment success", [
        'user_id' => $user_id,
        'payment_intent_id' => $payment_intent->id,
        'payment_type' => $payment_type
    ]);
    
    try {
        // Trova la subscription associata tramite invoice
        $target_subscription_id = find_subscription_for_payment_intent($payment_intent);
        
        if (!$target_subscription_id) {
            throw new Exception("No subscription found for payment intent {$payment_intent->id}");
        }
        
        // 🆕 NUOVO: Gestisci diversamente in base al payment_type
        if ($payment_type === 'onetime') {
            $sync_result = handle_onetime_subscription_success($user_id, $target_subscription_id, $payment_intent);
        } else {
            $sync_result = handle_recurring_subscription_success($user_id, $target_subscription_id, $payment_intent);
        }
        
        stripe_log_info("Subscription sync completed for user {$user_id}: " . json_encode($sync_result));
        
        // Debug status post-sync
        debug_user_subscription_status($user_id);
        
        return $sync_result;
        
    } catch (Exception $e) {
        stripe_log_error('Failed to handle subscription payment success', [
            'user_id' => $user_id,
            'payment_intent_id' => $payment_intent->id,
            'payment_type' => $payment_type,
            'error' => $e->getMessage()
        ]);
        
        // Fallback
        try {
            stripe_log_info("Attempting fallback subscription handling for user {$user_id}");
            handle_subscription_payment_success_fallback($user_id, $payment_intent);
            
            return [
                'success' => true,
                'fallback_mode' => true,
                'user_id' => $user_id,
                'payment_type' => $payment_type,
                'message' => 'Subscription activated with basic sync'
            ];
        } catch (Exception $fallback_error) {
            stripe_log_error('Even fallback subscription handling failed', [
                'user_id' => $user_id,
                'error' => $fallback_error->getMessage()
            ]);
            throw $e;
        }
    }
}

/**
 * 🆕 NEW: Gestisce subscription ricorrente (comportamento normale)
 */
function handle_recurring_subscription_success($user_id, $subscription_id, $payment_intent) {
    stripe_log_info("Handling RECURRING subscription success for user {$user_id}");
    
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
    
    stripe_log_info("Handling ONETIME subscription success for user {$user_id}");
    
    try {
        // 1. Sincronizzazione normale prima
        $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
        
        // 2. 🆕 NUOVO: Assicurati che la subscription sia impostata per cancellarsi
        $stripe_subscription = \Stripe\Subscription::retrieve($subscription_id);
        
        if (!$stripe_subscription->cancel_at_period_end) {
            stripe_log_info("Setting cancel_at_period_end for onetime subscription: {$subscription_id}");
            
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
        
        stripe_log_info("Onetime subscription configured successfully: will cancel at period end");
        
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
 * Trova subscription associata al payment intent
 */
function find_subscription_for_payment_intent($payment_intent) {
    stripe_log_info("Finding subscription for payment intent: {$payment_intent->id}");
    
    try {
        // Cerca invoice associata
        $invoices = \Stripe\Invoice::all([
            'customer' => $payment_intent->customer,
            'status' => 'paid',
            'limit' => 10
        ]);
        
        foreach ($invoices->data as $invoice) {
            if ($invoice->payment_intent === $payment_intent->id && $invoice->subscription) {
                stripe_log_info("Found subscription {$invoice->subscription} for payment {$payment_intent->id}");
                return $invoice->subscription;
            }
        }
        
        // Fallback: cerca l'ultima subscription attiva per questo customer
        $subscriptions = \Stripe\Subscription::all([
            'customer' => $payment_intent->customer,
            'status' => 'active',
            'limit' => 1
        ]);
        
        if (!empty($subscriptions->data)) {
            $target_subscription_id = $subscriptions->data[0]->id;
            stripe_log_info("Found subscription via fallback method: {$target_subscription_id}");
            return $target_subscription_id;
        }
        
        return null;
        
    } catch (Exception $e) {
        stripe_log_error('Error finding subscription for payment intent', [
            'payment_intent_id' => $payment_intent->id,
            'error' => $e->getMessage()
        ]);
        return null;
    }
}

/**
 * Fallback per gestione base subscription (unchanged)
 */
function handle_subscription_payment_success_fallback($user_id, $payment_intent) {
    global $pdo;
    
    stripe_log_info("Using fallback subscription handling for user {$user_id}");
    
    // Almeno aggiorna l'utente al piano Premium base (2 = Monthly)
    $stmt = $pdo->prepare("
        UPDATE users 
        SET current_plan_id = 2
        WHERE id = ?
    ");
    $stmt->execute([$user_id]);
    
    stripe_log_info("User {$user_id} updated to plan_id 2 via fallback");
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
        
        stripe_log_info("Donation recorded: {$payment_intent->id} for user {$user_id}, amount: €" . stripe_cents_to_euros($payment_intent->amount));
        
    } catch (Exception $e) {
        stripe_log_error('Failed to handle donation payment success', [
            'user_id' => $user_id,
            'payment_intent_id' => $payment_intent->id,
            'error' => $e->getMessage()
        ]);
    }
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
?>