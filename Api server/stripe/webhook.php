<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';
require_once 'stripe_user_subscription_sync.php'; // 🚀 NUOVO: Include sync functions

// ============================================================================
// STRIPE WEBHOOK HANDLER - ENHANCED WITH USER SYNC
// ============================================================================

header('Content-Type: application/json');

// Verifica che Stripe sia configurato
if (!stripe_is_configured()) {
    http_response_code(500);
    echo json_encode(['error' => 'Stripe non configurato']);
    exit;
}

// Solo POST supportato
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Solo POST supportato']);
    exit;
}

try {
    handle_stripe_webhook();
} catch (Exception $e) {
    stripe_log_error('Webhook error', ['error' => $e->getMessage()]);
    http_response_code(500);
    echo json_encode(['error' => 'Errore interno']);
    exit;
}

// ============================================================================
// ENHANCED WEBHOOK HANDLER FUNCTION
// ============================================================================

/**
 * 🚀 ENHANCED: Gestisce i webhook Stripe con sincronizzazione utente completa
 */
function handle_stripe_webhook() {
    global $pdo;
    
    // Ottieni payload e signature
    $payload = file_get_contents('php://input');
    $sig_header = $_SERVER['HTTP_STRIPE_SIGNATURE'] ?? '';
    
    if (empty($sig_header)) {
        stripe_log_error('Missing Stripe signature header');
        http_response_code(400);
        echo json_encode(['error' => 'Missing signature']);
        exit;
    }
    
    // Verifica webhook signature
    $event = verify_stripe_webhook($payload, $sig_header);
    
    if (!$event) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid signature']);
        exit;
    }
    
    stripe_log_info("Webhook received: {$event->type} - {$event->id}");
    
    // 🚀 NUOVO: Gestisci eventi in base al tipo con sincronizzazione enhanced
    switch ($event->type) {
        case 'payment_intent.succeeded':
            handle_payment_intent_succeeded_enhanced($event->data->object);
            break;
            
        case 'payment_intent.payment_failed':
            handle_payment_intent_failed($event->data->object);
            break;
            
        case 'invoice.payment_succeeded':
            handle_invoice_payment_succeeded_enhanced($event->data->object);
            break;
            
        case 'invoice.payment_failed':
            handle_invoice_payment_failed_enhanced($event->data->object);
            break;
            
        case 'customer.subscription.created':
            handle_subscription_created_enhanced($event->data->object);
            break;
            
        case 'customer.subscription.updated':
            handle_subscription_updated_enhanced($event->data->object);
            break;
            
        case 'customer.subscription.deleted':
            handle_subscription_deleted_enhanced($event->data->object);
            break;
            
        case 'customer.subscription.trial_will_end':
            handle_subscription_trial_will_end($event->data->object);
            break;
            
        // 🚀 NUOVO: Altri eventi utili
        case 'invoice.payment_action_required':
            handle_invoice_payment_action_required($event->data->object);
            break;
            
        case 'customer.subscription.paused':
            handle_subscription_paused($event->data->object);
            break;
            
        case 'customer.subscription.resumed':
            handle_subscription_resumed($event->data->object);
            break;
            
        default:
            stripe_log_info("Unhandled webhook event type: {$event->type}");
    }
    
    // Registra evento nel database
    log_webhook_event($event);
    
    // Risposta di successo
    http_response_code(200);
    echo json_encode(['status' => 'success']);
}

// ============================================================================
// ENHANCED PAYMENT INTENT HANDLERS
// ============================================================================

/**
 * 🚀 ENHANCED: Gestisce payment intent completato con successo
 */
function handle_payment_intent_succeeded_enhanced($payment_intent) {
    global $pdo;
    
    $payment_intent_id = $payment_intent->id;
    $customer_id = $payment_intent->customer;
    $amount = $payment_intent->amount;
    
    stripe_log_info("Payment succeeded webhook: {$payment_intent_id}, amount: €" . stripe_cents_to_euros($amount));
    
    // Aggiorna status nel database
    $stmt = $pdo->prepare("
        UPDATE stripe_payment_intents 
        SET status = 'succeeded', updated_at = CURRENT_TIMESTAMP
        WHERE stripe_payment_intent_id = ?
    ");
    $stmt->execute([$payment_intent_id]);
    
    // Ottieni user_id dal customer
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if (!$user_id) {
        stripe_log_error("Could not find user for customer: {$customer_id}");
        return;
    }
    
    // 🚀 NUOVO: Gestisci in base al tipo di pagamento con sync completo
    $payment_type = $payment_intent->metadata->payment_type ?? 'unknown';
    
    if ($payment_type === 'subscription') {
        stripe_log_info("Processing subscription payment success via webhook for user {$user_id}");
        
        try {
            // Usa l'hook di sincronizzazione per subscription
            stripe_payment_success_hook($user_id, $payment_intent_id, 'subscription');
            
        } catch (Exception $e) {
            stripe_log_error("Subscription webhook processing failed", [
                'user_id' => $user_id,
                'payment_intent_id' => $payment_intent_id,
                'error' => $e->getMessage()
            ]);
        }
        
    } elseif ($payment_type === 'donation') {
        handle_donation_payment_success_webhook($user_id, $payment_intent);
    }
}

/**
 * Gestisce payment intent fallito (unchanged but enhanced logging)
 */
function handle_payment_intent_failed($payment_intent) {
    global $pdo;
    
    $payment_intent_id = $payment_intent->id;
    $customer_id = $payment_intent->customer;
    
    stripe_log_info("Payment failed webhook: {$payment_intent_id}");
    
    // Aggiorna status nel database
    $stmt = $pdo->prepare("
        UPDATE stripe_payment_intents 
        SET status = 'payment_failed', updated_at = CURRENT_TIMESTAMP
        WHERE stripe_payment_intent_id = ?
    ");
    $stmt->execute([$payment_intent_id]);
    
    // 🚀 NUOVO: Log dettagliato dell'errore
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if ($user_id) {
        stripe_log_error("Payment failed for user {$user_id}", [
            'payment_intent_id' => $payment_intent_id,
            'amount' => $payment_intent->amount,
            'currency' => $payment_intent->currency,
            'last_payment_error' => $payment_intent->last_payment_error->message ?? 'Unknown error'
        ]);
    }
}

// ============================================================================
// ENHANCED INVOICE HANDLERS
// ============================================================================

/**
 * 🚀 ENHANCED: Gestisce pagamento invoice riuscito con sync completo
 */
function handle_invoice_payment_succeeded_enhanced($invoice) {
    global $pdo;
    
    $subscription_id = $invoice->subscription;
    $customer_id = $invoice->customer;
    
    if (!$subscription_id) {
        stripe_log_info("Invoice payment succeeded but no subscription (one-time payment): {$invoice->id}");
        return; // Non è una subscription invoice
    }
    
    stripe_log_info("Invoice payment succeeded webhook for subscription: {$subscription_id}");
    
    // Ottieni user_id
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if (!$user_id) {
        stripe_log_error("Could not find user for customer: {$customer_id}");
        return;
    }
    
    try {
        // 🚀 SINCRONIZZAZIONE COMPLETA: Usa le nuove funzioni
        $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
        
        stripe_log_info("Invoice payment webhook sync completed for user {$user_id}: " . json_encode($sync_result));
        
    } catch (Exception $e) {
        stripe_log_error("Invoice payment webhook sync failed", [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'invoice_id' => $invoice->id,
            'error' => $e->getMessage()
        ]);
        
        // 🔧 FALLBACK: Aggiornamento base
        try {
            $stmt = $pdo->prepare("
                UPDATE stripe_subscriptions 
                SET status = 'active', updated_at = CURRENT_TIMESTAMP
                WHERE stripe_subscription_id = ? AND user_id = ?
            ");
            $stmt->execute([$subscription_id, $user_id]);
            
            stripe_log_info("Applied fallback update for subscription {$subscription_id}");
        } catch (Exception $fallback_error) {
            stripe_log_error("Even fallback update failed", [
                'error' => $fallback_error->getMessage()
            ]);
        }
    }
}

/**
 * 🚀 ENHANCED: Gestisce pagamento invoice fallito
 */
function handle_invoice_payment_failed_enhanced($invoice) {
    global $pdo;
    
    $subscription_id = $invoice->subscription;
    $customer_id = $invoice->customer;
    
    if (!$subscription_id) {
        return;
    }
    
    stripe_log_info("Invoice payment failed webhook for subscription: {$subscription_id}");
    
    // Ottieni user_id
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if (!$user_id) {
        return;
    }
    
    try {
        // Aggiorna subscription status
        $stmt = $pdo->prepare("
            UPDATE stripe_subscriptions 
            SET status = 'past_due', updated_at = CURRENT_TIMESTAMP
            WHERE stripe_subscription_id = ? AND user_id = ?
        ");
        $stmt->execute([$subscription_id, $user_id]);
        
        // 🚀 NUOVO: Aggiorna anche user_subscriptions
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'active', updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND stripe_subscription_id = ?
        ");
        $stmt->execute([$user_id, $subscription_id]);
        
        stripe_log_info("Marked subscription {$subscription_id} as past_due for user {$user_id}");
        
        // 🚀 NUOVO: Log dettagliato per monitoraggio
        stripe_log_error("Subscription payment failed - monitoring required", [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'invoice_id' => $invoice->id,
            'amount_due' => $invoice->amount_due,
            'attempt_count' => $invoice->attempt_count,
            'next_payment_attempt' => $invoice->next_payment_attempt
        ]);
        
    } catch (Exception $e) {
        stripe_log_error("Failed to handle invoice payment failure", [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'error' => $e->getMessage()
        ]);
    }
}

// ============================================================================
// ENHANCED SUBSCRIPTION HANDLERS
// ============================================================================

/**
 * 🚀 ENHANCED: Gestisce subscription creata
 */
function handle_subscription_created_enhanced($subscription) {
    global $pdo;
    
    $subscription_id = $subscription->id;
    $customer_id = $subscription->customer;
    
    stripe_log_info("Subscription created webhook: {$subscription_id}, status: {$subscription->status}");
    
    // Ottieni user_id
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if (!$user_id) {
        stripe_log_error("Could not find user for customer: {$customer_id}");
        return;
    }
    
    try {
        // 🚀 SINCRONIZZAZIONE COMPLETA: Solo se subscription è attiva o incomplete
        if (in_array($subscription->status, ['active', 'trialing', 'incomplete'])) {
            $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
            stripe_log_info("Subscription created webhook sync completed: " . json_encode($sync_result));
        } else {
            stripe_log_info("Subscription created but status {$subscription->status} - skipping full sync");
        }
        
    } catch (Exception $e) {
        stripe_log_error("Subscription created webhook sync failed", [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * 🚀 ENHANCED: Gestisce subscription aggiornata
 */
function handle_subscription_updated_enhanced($subscription) {
    global $pdo;
    
    $subscription_id = $subscription->id;
    $customer_id = $subscription->customer;
    
    stripe_log_info("Subscription updated webhook: {$subscription_id}, status: {$subscription->status}");
    
    // Ottieni user_id
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if (!$user_id) {
        return;
    }
    
    try {
        // 🚀 SINCRONIZZAZIONE COMPLETA: Sempre, per gestire cambi di stato
        $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
        stripe_log_info("Subscription updated webhook sync completed: " . json_encode($sync_result));
        
    } catch (Exception $e) {
        stripe_log_error("Subscription updated webhook sync failed", [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'status' => $subscription->status,
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * 🚀 ENHANCED: Gestisce subscription cancellata
 */
function handle_subscription_deleted_enhanced($subscription) {
    global $pdo;
    
    $subscription_id = $subscription->id;
    $customer_id = $subscription->customer;
    
    stripe_log_info("Subscription deleted webhook: {$subscription_id}");
    
    // Ottieni user_id
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if (!$user_id) {
        return;
    }
    
    try {
        // 🚀 NUOVO: Gestione completa cancellazione
        
        // 1. Aggiorna stripe_subscriptions
        $stmt = $pdo->prepare("
            UPDATE stripe_subscriptions 
            SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
            WHERE stripe_subscription_id = ? AND user_id = ?
        ");
        $stmt->execute([$subscription_id, $user_id]);
        
        // 2. Aggiorna user_subscriptions
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND stripe_subscription_id = ?
        ");
        $stmt->execute([$user_id, $subscription_id]);
        
        // 3. Riporta utente al piano Free
        update_user_current_plan($user_id, 1); // plan_id 1 = Free
        
        stripe_log_info("Subscription deleted: user {$user_id} returned to Free plan");
        
        // 🚀 NUOVO: Debug post-cancellazione
        debug_user_subscription_status($user_id);
        
    } catch (Exception $e) {
        stripe_log_error("Failed to handle subscription deletion", [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'error' => $e->getMessage()
        ]);
    }
}

// ============================================================================
// NUOVI GESTORI EVENTI AVANZATI
// ============================================================================

/**
 * 🚀 NUOVO: Gestisce avviso fine trial
 */
function handle_subscription_trial_will_end($subscription) {
    $subscription_id = $subscription->id;
    $customer_id = $subscription->customer;
    
    stripe_log_info("Subscription trial ending soon webhook: {$subscription_id}");
    
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if ($user_id) {
        stripe_log_info("Trial ending for user {$user_id} - consider sending notification");
        // Qui potresti inviare email di notifica all'utente
        // send_trial_ending_email($user_id, $subscription);
    }
}

/**
 * 🚀 NUOVO: Gestisce richiesta azione pagamento
 */
function handle_invoice_payment_action_required($invoice) {
    $subscription_id = $invoice->subscription;
    $customer_id = $invoice->customer;
    
    if (!$subscription_id) return;
    
    stripe_log_info("Payment action required webhook for subscription: {$subscription_id}");
    
    $user_id = get_user_id_from_stripe_customer($customer_id);
    if ($user_id) {
        stripe_log_info("Payment action required for user {$user_id} - consider sending notification");
        // Qui potresti inviare notifica all'utente per completare il pagamento
    }
}

/**
 * 🚀 NUOVO: Gestisce subscription in pausa
 */
function handle_subscription_paused($subscription) {
    $user_id = get_user_id_from_stripe_customer($subscription->customer);
    if ($user_id) {
        stripe_log_info("Subscription paused for user {$user_id}");
        // Mantieni accesso ma loggalo
    }
}

/**
 * 🚀 NUOVO: Gestisce subscription ripresa
 */
function handle_subscription_resumed($subscription) {
    $user_id = get_user_id_from_stripe_customer($subscription->customer);
    if ($user_id) {
        stripe_log_info("Subscription resumed for user {$user_id}");
        // Sincronizza per assicurarsi che tutto sia aggiornato
        try {
            sync_user_subscription_after_stripe_payment($user_id, $subscription->id);
        } catch (Exception $e) {
            stripe_log_error("Failed to sync resumed subscription", ['error' => $e->getMessage()]);
        }
    }
}

// ============================================================================
// ENHANCED HELPER FUNCTIONS
// ============================================================================

/**
 * Gestisce successo pagamento donazione da webhook (unchanged)
 */
function handle_donation_payment_success_webhook($user_id, $payment_intent) {
    global $pdo;
    
    stripe_log_info("Donation payment success webhook for user {$user_id}");
    
    // Registra donazione se non esiste già
    $stmt = $pdo->prepare("
        INSERT IGNORE INTO donations (
            user_id, stripe_payment_intent_id, amount, currency, 
            payment_date, status, metadata
        ) VALUES (?, ?, ?, ?, NOW(), 'completed', ?)
    ");
    
    $metadata = json_encode([
        'stripe_customer_id' => $payment_intent->customer,
        'source' => 'webhook'
    ]);
    
    $stmt->execute([
        $user_id,
        $payment_intent->id,
        $payment_intent->amount,
        $payment_intent->currency,
        $metadata
    ]);
}

/**
 * 🚀 ENHANCED: Registra evento webhook nel database con metadata completi
 */
function log_webhook_event($event) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO stripe_webhook_events (
                stripe_event_id, event_type, processed_at, data, livemode, api_version
            ) VALUES (?, ?, NOW(), ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
            processed_at = NOW(),
            data = VALUES(data)
        ");
        
        $stmt->execute([
            $event->id,
            $event->type,
            json_encode($event->data),
            $event->livemode ? 1 : 0,
            $event->api_version
        ]);
        
    } catch (Exception $e) {
        stripe_log_error('Failed to log webhook event', ['error' => $e->getMessage()]);
    }
}

/**
 * 🚀 ENHANCED: Crea tabella webhook events con campi aggiuntivi
 */
function create_webhook_events_table_if_needed($pdo) {
    try {
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS stripe_webhook_events (
                id INT AUTO_INCREMENT PRIMARY KEY,
                stripe_event_id VARCHAR(255) NOT NULL UNIQUE,
                event_type VARCHAR(100) NOT NULL,
                processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                data JSON,
                livemode TINYINT(1) DEFAULT 0,
                api_version VARCHAR(20),
                INDEX idx_event_type (event_type),
                INDEX idx_processed_at (processed_at),
                INDEX idx_livemode (livemode)
            )
        ");
        return true;
    } catch (PDOException $e) {
        stripe_log_error('Failed to create webhook events table', ['error' => $e->getMessage()]);
        return false;
    }
}

// Crea tabella webhook events se necessario
if (!empty($pdo)) {
    create_webhook_events_table_if_needed($pdo);
}
?>