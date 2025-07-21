<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';
// require_once __DIR__ . '/stripe_utils.php'; // ❌ FILE NON ESISTENTE - RIMOSSO

// 🆕 DEBUG: Log per verificare se il file viene chiamato (TEMPORANEO - per debug)
$log_file = __DIR__ . '/debug_subscription.log';
$timestamp = date('Y-m-d H:i:s');
$log_entry = "[{$timestamp}] [STRIPE_DEBUG] create-donation-payment-intent.php START - Method: {$_SERVER['REQUEST_METHOD']}\n";
file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);

// ============================================================================
// DONATION PAYMENT INTENT - UPDATED WITH COMPATIBILITY FIX
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
    $log_entry = "[{$timestamp}] [STRIPE_DEBUG] ERROR: Stripe not configured properly\n";
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    stripe_json_response(false, null, 'Stripe non configurato correttamente');
}

$log_entry = "[{$timestamp}] [STRIPE_DEBUG] Stripe configuration check passed\n";
file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);

// Get user from token
$user = get_user_from_token();
if (!$user) {
    http_response_code(401);
    stripe_json_response(false, null, 'Token non valido');
}

$user_id = $user['id'];

try {
    handle_create_donation_payment_intent($user_id);
} catch (Exception $e) {
    stripe_log_error('Donation payment intent error', [
        'user_id' => $user_id,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
    handle_stripe_error($e);
}

// ============================================================================
// DONATION PAYMENT INTENT FUNCTION
// ============================================================================

/**
 * Crea un Payment Intent per donazione
 */
function handle_create_donation_payment_intent($user_id) {
    global $pdo;
    
    // Parse request data
    $input = json_decode(file_get_contents('php://input'), true);
    $amount = $input['amount'] ?? 0; // in centesimi
    $currency = $input['currency'] ?? STRIPE_CURRENCY;
    $metadata = $input['metadata'] ?? [];
    
    // 🆕 DEBUG: Log input data
    $log_file = __DIR__ . '/debug_subscription.log';
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Donation input data: " . json_encode($input) . "\n";
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    
    // Validazione
    if ($amount < 50) { // Minimo €0.50
        stripe_json_response(false, null, 'Importo minimo per donazione: €0.50');
    }
    
    if ($amount > 50000) { // Massimo €500
        stripe_json_response(false, null, 'Importo massimo per donazione: €500.00');
    }
    
    try {
        // 🆕 DEBUG: Log before customer creation
        $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Starting donation payment intent creation\n";
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
        // Ottieni o crea Stripe customer
        $stripe_customer_id = get_or_create_stripe_customer($user_id);
        
        $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Customer ID: {$stripe_customer_id}\n";
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
        // 🆕 DEBUG: Log payment intent parameters
        $payment_intent_params = [
            'amount' => $amount,
            'currency' => $currency,
            'customer' => $stripe_customer_id,
            'automatic_payment_methods' => [
                'enabled' => true
            ],
            'metadata' => array_merge($metadata, [
                'user_id' => $user_id,
                'payment_type' => 'donation',
                'platform' => 'fitgymtrack_flutter'
            ])
        ];
        
        $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Payment intent params: " . json_encode($payment_intent_params) . "\n";
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
        $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Creating Stripe Payment Intent...\n";
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
        // 🆕 DEBUG: Check if Stripe class exists
        if (!class_exists('\Stripe\PaymentIntent')) {
            $log_entry = "[{$timestamp}] [STRIPE_DEBUG] ERROR: Stripe\PaymentIntent class not found\n";
            file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
            throw new Exception('Stripe SDK not loaded properly');
        }
        
        $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Stripe\PaymentIntent class found, proceeding...\n";
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
        // Crea Payment Intent con try-catch specifico
        try {
            $payment_intent = \Stripe\PaymentIntent::create($payment_intent_params);
            $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Payment Intent created successfully: {$payment_intent->id}\n";
            file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        } catch (\Stripe\Exception\InvalidRequestException $e) {
            $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Stripe InvalidRequestException: " . $e->getMessage() . "\n";
            file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
            throw $e;
        } catch (\Stripe\Exception\AuthenticationException $e) {
            $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Stripe AuthenticationException: " . $e->getMessage() . "\n";
            file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
            throw $e;
        } catch (\Exception $e) {
            $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Generic Exception: " . $e->getMessage() . "\n";
            file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
            throw $e;
        }
        
        // Salva nel database
        save_payment_intent_to_db($user_id, $payment_intent, 'donation', 'one_time', null);
        
        stripe_log_info("Donation payment intent created: {$payment_intent->id} for user {$user_id}, amount: €" . stripe_cents_to_euros($amount));
        
        stripe_json_response(true, [
            'payment_intent' => [
                'client_secret' => $payment_intent->client_secret,
                'payment_intent_id' => $payment_intent->id,
                'status' => $payment_intent->status,
                'amount' => $payment_intent->amount,
                'currency' => $payment_intent->currency,
                'customer_id' => $payment_intent->customer
            ]
        ], 'Payment Intent per donazione creato');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to create donation payment intent', [
            'user_id' => $user_id,
            'amount' => $amount,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Ottiene o crea un Stripe customer per l'utente
 */
function get_or_create_stripe_customer($user_id) {
    global $pdo;
    
    // Cerca customer esistente
    $stmt = $pdo->prepare("SELECT stripe_customer_id FROM stripe_customers WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $customer = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($customer) {
        // Verifica che esista ancora su Stripe
        try {
            \Stripe\Customer::retrieve($customer['stripe_customer_id']);
            return $customer['stripe_customer_id'];
        } catch (\Stripe\Exception\InvalidRequestException $e) {
            // Customer non esiste più, ricrea
        }
    }
    
    // Crea nuovo customer
    $user_data = get_user_data($user_id);
    
    $stripe_customer = \Stripe\Customer::create([
        'email' => $user_data['email'] ?? '',
        'name' => $user_data['username'] ?? '',
        'metadata' => [
            'user_id' => $user_id,
            'platform' => 'fitgymtrack_flutter'
        ]
    ]);
    
    // Salva nel database
    $stmt = $pdo->prepare("
        INSERT INTO stripe_customers (user_id, stripe_customer_id, email, name)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        stripe_customer_id = VALUES(stripe_customer_id)
    ");
    $stmt->execute([
        $user_id,
        $stripe_customer->id,
        $user_data['email'] ?? '',
        $user_data['username'] ?? ''
    ]);
    
    stripe_log_info("Created new Stripe customer for donation: {$stripe_customer->id}");
    
    return $stripe_customer->id;
}

/**
 * Ottiene dati utente
 */
function get_user_data($user_id) {
    global $pdo;
    
    $stmt = $pdo->prepare("SELECT email, username FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
}

/**
 * 🆕 UPDATED: Salva Payment Intent nel database con payment_type e stripe_subscription_id
 */
function save_payment_intent_to_db($user_id, $payment_intent, $payment_type, $subscription_payment_type = 'recurring', $stripe_subscription_id = null) {
    global $pdo;
    
    // 🆕 DEBUG: Log per verificare se il file viene chiamato (COMMENTATO - non serve al momento)
    // $log_file = __DIR__ . '/debug_subscription.log';
    // $timestamp = date('Y-m-d H:i:s');
    // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] === SAVE PAYMENT INTENT TO DB START ===\n";
    // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    
    if (!$pdo) {
        // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] WARNING: PDO not available, skipping payment intent save\n";
        // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        return;
    }
    
    // 🆕 NUOVO: Include payment_type e stripe_subscription_id nei metadata
    $metadata = $payment_intent->metadata->toArray();
    $metadata['subscription_payment_type'] = $subscription_payment_type;
    
    // 🆕 CRITICO: Aggiungi stripe_subscription_id ai metadata
    if ($stripe_subscription_id) {
        $metadata['stripe_subscription_id'] = $stripe_subscription_id;
        // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Added stripe_subscription_id to metadata: {$stripe_subscription_id}\n";
        // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    }
    
    $save_data = [
        'payment_intent_id' => $payment_intent->id,
        'user_id' => $user_id,
        'amount' => $payment_intent->amount,
        'currency' => $payment_intent->currency,
        'status' => $payment_intent->status,
        'payment_type' => $payment_type,
        'subscription_payment_type' => $subscription_payment_type,
        'stripe_subscription_id' => $stripe_subscription_id,
        'metadata' => $metadata
    ];
    
    // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Payment intent save data: " . json_encode($save_data) . "\n";
    // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO stripe_payment_intents (
                user_id, stripe_payment_intent_id, amount, currency, status, payment_type, metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            status = VALUES(status),
            metadata = VALUES(metadata)
        ");
        
        $execute_params = [
            $user_id,
            $payment_intent->id,
            $payment_intent->amount,
            $payment_intent->currency,
            $payment_intent->status,
            $payment_type, // 'subscription'
            json_encode($metadata)
        ];
        
        // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Payment intent execute params: " . json_encode($execute_params) . "\n";
        // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
        $result = $stmt->execute($execute_params);
        
        if ($result) {
            // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Payment intent saved successfully, affected rows: " . $stmt->rowCount() . "\n";
            // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        } else {
            // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Failed to save payment intent to database\n";
            // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        }
        
        // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] Payment intent saved with subscription metadata\n";
        // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        
    } catch (Exception $e) {
        // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] ERROR saving payment intent to database: " . $e->getMessage() . "\n";
        // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
        throw $e;
    }
    
    // $log_entry = "[{$timestamp}] [STRIPE_DEBUG] === SAVE PAYMENT INTENT TO DB END ===\n";
    // file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
}
?>