<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';

// ============================================================================
// STRIPE DONATION PAYMENT INTENT
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
    handle_create_donation_payment_intent($user_id);
} catch (Exception $e) {
    stripe_log_error('Donation payment intent error', [
        'user_id' => $user_id,
        'error' => $e->getMessage()
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
    
    // Validazione
    if ($amount < 50) { // Minimo €0.50
        stripe_json_response(false, null, 'Importo minimo per donazione: €0.50');
    }
    
    if ($amount > 50000) { // Massimo €500
        stripe_json_response(false, null, 'Importo massimo per donazione: €500.00');
    }
    
    try {
        // Ottieni o crea Stripe customer
        $stripe_customer_id = get_or_create_stripe_customer($user_id);
        
        // Crea Payment Intent
        $payment_intent = \Stripe\PaymentIntent::create([
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
        ]);
        
        // Salva nel database
        save_payment_intent_to_db($user_id, $payment_intent, 'donation');
        
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
        stripe_customer_id = VALUES(stripe_customer_id),
        updated_at = CURRENT_TIMESTAMP
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
 * Salva Payment Intent nel database
 */
function save_payment_intent_to_db($user_id, $payment_intent, $payment_type) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        INSERT INTO stripe_payment_intents (
            user_id, stripe_payment_intent_id, amount, currency, status, payment_type, metadata
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        status = VALUES(status),
        updated_at = CURRENT_TIMESTAMP
    ");
    
    $stmt->execute([
        $user_id,
        $payment_intent->id,
        $payment_intent->amount,
        $payment_intent->currency,
        $payment_intent->status,
        $payment_type,
        json_encode($payment_intent->metadata->toArray())
    ]);
}
?>