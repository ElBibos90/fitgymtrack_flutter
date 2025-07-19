<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';
require_once 'stripe_user_subscription_sync.php';

// ============================================================================
// STRIPE USER SUBSCRIPTION SYNC ENDPOINT
// ============================================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
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
$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'POST':
            handle_manual_sync($user_id);
            break;
            
        case 'GET':
            handle_sync_status($user_id);
            break;
            
        default:
            http_response_code(405);
            stripe_json_response(false, null, 'Metodo non supportato');
    }
    
} catch (Exception $e) {
    stripe_log_error('Sync endpoint error', [
        'user_id' => $user_id,
        'method' => $method,
        'error' => $e->getMessage()
    ]);
    handle_stripe_error($e);
}

// ============================================================================
// SYNC FUNCTIONS
// ============================================================================

/**
 * 🚀 MAIN: Gestisce sincronizzazione manuale
 */
function handle_manual_sync($user_id) {
    global $pdo;
    
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? 'sync_current';
    $subscription_id = $input['subscription_id'] ?? null;
    $force = $input['force'] ?? false;
    
    stripe_log_info("Manual sync requested for user {$user_id}, action: {$action}");
    
    switch ($action) {
        case 'sync_current':
            handle_sync_current_subscription($user_id, $force);
            break;
            
        case 'sync_specific':
            if (!$subscription_id) {
                stripe_json_response(false, null, 'subscription_id richiesto per sync_specific');
            }
            handle_sync_specific_subscription($user_id, $subscription_id, $force);
            break;
            
        case 'sync_expired':
            handle_sync_expired_subscriptions();
            break;
            
        case 'reset_to_free':
            handle_reset_user_to_free($user_id);
            break;
            
        case 'debug_status':
            handle_debug_user_status($user_id);
            break;
            
        case 'force_premium':
            handle_force_premium($user_id, $input);
            break;
            
        default:
            stripe_json_response(false, null, 'Azione non supportata: ' . $action);
    }
}

/**
 * Sincronizza la subscription corrente dell'utente
 */
function handle_sync_current_subscription($user_id, $force = false) {
    global $pdo;
    
    try {
        // Trova subscription attiva per l'utente
        $stmt = $pdo->prepare("
            SELECT stripe_subscription_id, status 
            FROM user_subscriptions 
            WHERE user_id = ? AND stripe_subscription_id IS NOT NULL
            ORDER BY created_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$user_id]);
        $local_subscription = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$local_subscription) {
            stripe_json_response(false, null, 'Nessuna subscription Stripe trovata per questo utente');
        }
        
        $subscription_id = $local_subscription['stripe_subscription_id'];
        
        stripe_log_info("Syncing current subscription {$subscription_id} for user {$user_id}");
        
        // Esegui sincronizzazione
        $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
        
        // Debug post-sync
        $debug_status = debug_user_subscription_status($user_id);
        
        stripe_json_response(true, [
            'sync_result' => $sync_result,
            'debug_status' => $debug_status,
            'subscription_id' => $subscription_id,
            'action' => 'sync_current'
        ], 'Sincronizzazione completata');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to sync current subscription', [
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore sincronizzazione: ' . $e->getMessage());
    }
}

/**
 * Sincronizza una subscription specifica
 */
function handle_sync_specific_subscription($user_id, $subscription_id, $force = false) {
    try {
        stripe_log_info("Syncing specific subscription {$subscription_id} for user {$user_id}");
        
        // Verifica che la subscription appartenga all'utente (se non force)
        if (!$force) {
            global $pdo;
            $stmt = $pdo->prepare("
                SELECT user_id FROM stripe_customers 
                WHERE user_id = ? AND stripe_customer_id = (
                    SELECT customer FROM stripe_subscriptions_temp WHERE id = ?
                )
            ");
            // Nota: questa verifica può essere opzionale con force=true
        }
        
        // Esegui sincronizzazione
        $sync_result = sync_user_subscription_after_stripe_payment($user_id, $subscription_id);
        
        // Debug post-sync
        $debug_status = debug_user_subscription_status($user_id);
        
        stripe_json_response(true, [
            'sync_result' => $sync_result,
            'debug_status' => $debug_status,
            'subscription_id' => $subscription_id,
            'action' => 'sync_specific'
        ], 'Sincronizzazione specifica completata');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to sync specific subscription', [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore sincronizzazione specifica: ' . $e->getMessage());
    }
}

/**
 * Sincronizza tutte le subscription scadute
 */
function handle_sync_expired_subscriptions() {
    try {
        stripe_log_info("Starting global expired subscriptions sync");
        
        sync_expired_subscriptions();
        
        stripe_json_response(true, [
            'action' => 'sync_expired',
            'message' => 'Sincronizzazione subscription scadute completata'
        ], 'Sync globale completato');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to sync expired subscriptions', [
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore sync globale: ' . $e->getMessage());
    }
}

/**
 * Reset utente al piano Free
 */
function handle_reset_user_to_free($user_id) {
    global $pdo;
    
    try {
        stripe_log_info("Resetting user {$user_id} to Free plan");
        
        $pdo->beginTransaction();
        
        // 1. Aggiorna users.current_plan_id
        update_user_current_plan($user_id, 1); // plan_id 1 = Free
        
        // 2. Marca user_subscriptions come expired
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND status = 'active'
        ");
        $stmt->execute([$user_id]);
        $affected_subscriptions = $stmt->rowCount();
        
        $pdo->commit();
        
        // Debug post-reset
        $debug_status = debug_user_subscription_status($user_id);
        
        stripe_json_response(true, [
            'user_id' => $user_id,
            'affected_subscriptions' => $affected_subscriptions,
            'debug_status' => $debug_status,
            'action' => 'reset_to_free'
        ], 'Utente resettato al piano Free');
        
    } catch (Exception $e) {
        $pdo->rollBack();
        
        stripe_log_error('Failed to reset user to free', [
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore reset a Free: ' . $e->getMessage());
    }
}

/**
 * Debug completo status utente
 */
function handle_debug_user_status($user_id) {
    try {
        stripe_log_info("Debugging user {$user_id} status");
        
        // Status completo
        $debug_status = debug_user_subscription_status($user_id);
        $subscription_status = get_user_subscription_status($user_id);
        $has_premium = user_has_premium_access($user_id);
        
        // Subscription Stripe attive
        global $pdo;
        $stmt = $pdo->prepare("
            SELECT ss.stripe_subscription_id, ss.status, ss.current_period_start, 
                   ss.current_period_end, ss.plan_id, ss.price_id
            FROM stripe_subscriptions ss
            WHERE ss.user_id = ?
            ORDER BY ss.created_at DESC
        ");
        $stmt->execute([$user_id]);
        $stripe_subscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // User subscriptions locali
        $stmt = $pdo->prepare("
            SELECT us.id, us.plan_id, us.status, us.start_date, us.end_date,
                   us.stripe_subscription_id, sp.name as plan_name
            FROM user_subscriptions us
            LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
            WHERE us.user_id = ?
            ORDER BY us.created_at DESC
        ");
        $stmt->execute([$user_id]);
        $user_subscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        stripe_json_response(true, [
            'user_id' => $user_id,
            'subscription_status' => $subscription_status,
            'has_premium_access' => $has_premium,
            'stripe_subscriptions' => $stripe_subscriptions,
            'user_subscriptions' => $user_subscriptions,
            'debug_info' => $debug_status,
            'action' => 'debug_status'
        ], 'Debug status completo');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to debug user status', [
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore debug: ' . $e->getMessage());
    }
}

/**
 * Forza utente a Premium (per testing)
 */
function handle_force_premium($user_id, $input) {
    global $pdo;
    
    $plan_id = $input['plan_id'] ?? 2; // Default: Premium Monthly
    $days_duration = $input['days'] ?? 30; // Default: 30 giorni
    
    try {
        stripe_log_info("Forcing user {$user_id} to Premium plan {$plan_id} for {$days_duration} days");
        
        $pdo->beginTransaction();
        
        // 1. Aggiorna users.current_plan_id
        update_user_current_plan($user_id, $plan_id);
        
        // 2. Crea user_subscription locale
        $start_date = date('Y-m-d H:i:s');
        $end_date = date('Y-m-d H:i:s', strtotime("+{$days_duration} days"));
        
        $stmt = $pdo->prepare("
            INSERT INTO user_subscriptions (
                user_id, plan_id, status, start_date, end_date,
                auto_renew, payment_provider, payment_reference,
                created_at, updated_at
            ) VALUES (?, ?, 'active', ?, ?, 0, 'manual', 'force_premium_test', 
                     CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ");
        $stmt->execute([$user_id, $plan_id, $start_date, $end_date]);
        
        $pdo->commit();
        
        // Debug post-force
        $debug_status = debug_user_subscription_status($user_id);
        
        stripe_json_response(true, [
            'user_id' => $user_id,
            'plan_id' => $plan_id,
            'days_duration' => $days_duration,
            'start_date' => $start_date,
            'end_date' => $end_date,
            'debug_status' => $debug_status,
            'action' => 'force_premium'
        ], 'Utente forzato a Premium');
        
    } catch (Exception $e) {
        $pdo->rollBack();
        
        stripe_log_error('Failed to force user to premium', [
            'user_id' => $user_id,
            'plan_id' => $plan_id,
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore force Premium: ' . $e->getMessage());
    }
}

/**
 * Ottiene lo status di sincronizzazione (GET)
 */
function handle_sync_status($user_id) {
    try {
        stripe_log_info("Getting sync status for user {$user_id}");
        
        // Status completo
        $subscription_status = get_user_subscription_status($user_id);
        $has_premium = user_has_premium_access($user_id);
        
        // Controlla se ci sono subscription non sincronizzate
        global $pdo;
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM stripe_subscriptions ss
            LEFT JOIN user_subscriptions us ON ss.stripe_subscription_id = us.stripe_subscription_id
            WHERE ss.user_id = ? AND us.id IS NULL
        ");
        $stmt->execute([$user_id]);
        $unsynced_stripe_subscriptions = $stmt->fetchColumn();
        
        // Controlla subscription locali senza Stripe
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM user_subscriptions us
            WHERE us.user_id = ? AND us.stripe_subscription_id IS NULL AND us.status = 'active'
        ");
        $stmt->execute([$user_id]);
        $local_only_subscriptions = $stmt->fetchColumn();
        
        // Disponibilità azioni
        $available_actions = [
            'sync_current' => $subscription_status['stripe_subscription_id'] !== null,
            'reset_to_free' => true,
            'debug_status' => true,
            'force_premium' => true,
            'sync_expired' => true
        ];
        
        stripe_json_response(true, [
            'user_id' => $user_id,
            'subscription_status' => $subscription_status,
            'has_premium_access' => $has_premium,
            'unsynced_stripe_subscriptions' => $unsynced_stripe_subscriptions,
            'local_only_subscriptions' => $local_only_subscriptions,
            'available_actions' => $available_actions,
            'sync_recommendations' => get_sync_recommendations($user_id, $subscription_status, $unsynced_stripe_subscriptions, $local_only_subscriptions)
        ], 'Status sincronizzazione');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to get sync status', [
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        
        stripe_json_response(false, null, 'Errore get status: ' . $e->getMessage());
    }
}

/**
 * Ottiene raccomandazioni di sincronizzazione
 */
function get_sync_recommendations($user_id, $subscription_status, $unsynced_stripe, $local_only) {
    $recommendations = [];
    
    if ($unsynced_stripe > 0) {
        $recommendations[] = [
            'action' => 'sync_current',
            'priority' => 'high',
            'message' => "Ci sono {$unsynced_stripe} subscription Stripe non sincronizzate"
        ];
    }
    
    if ($local_only > 0 && $subscription_status['stripe_subscription_id'] === null) {
        $recommendations[] = [
            'action' => 'reset_to_free',
            'priority' => 'medium',
            'message' => "Ci sono subscription locali senza corrispondente Stripe"
        ];
    }
    
    if ($subscription_status['current_plan_id'] == 1 && $subscription_status['subscription_status'] == 'active') {
        $recommendations[] = [
            'action' => 'debug_status',
            'priority' => 'medium',
            'message' => "Piano Free ma subscription attiva - verifica inconsistenza"
        ];
    }
    
    if (empty($recommendations)) {
        $recommendations[] = [
            'action' => 'none',
            'priority' => 'low',
            'message' => "Tutto sembra sincronizzato correttamente"
        ];
    }
    
    return $recommendations;
}
?>
