<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Include files necessari
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';

// ============================================================================
// STRIPE TEST PAYMENT SIMULATOR - Solo per testing!
// ============================================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Solo POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Solo POST supportato']);
    exit;
}

// 🔧 FIXED: Log personalizzato in /api/stripe directory
function test_payment_log($message, $data = null) {
    $log_file = __DIR__ . '/test_payment_debug.log';
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[{$timestamp}] {$message}";
    if ($data) {
        $log_entry .= " | Data: " . json_encode($data);
    }
    $log_entry .= PHP_EOL;
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
}

// 🔧 FIXED: Response helper sicura
function safe_json_response($success, $data = null, $message = '') {
    $response = [
        'success' => $success,
        'message' => $message
    ];
    if ($data !== null) {
        $response['data'] = $data;
    }
    echo json_encode($response);
    exit;
}

test_payment_log("TEST PAYMENT: Starting request", [
    'method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'unknown'
]);

try {
    // Verifica configurazione Stripe
    if (!function_exists('stripe_is_configured')) {
        test_payment_log("ERROR: stripe_is_configured function not found");
        safe_json_response(false, null, 'Funzioni Stripe non disponibili');
    }
    
    if (!stripe_is_configured()) {
        test_payment_log("ERROR: Stripe not configured");
        safe_json_response(false, null, 'Stripe non configurato correttamente');
    }

    // Get user (opzionale per test)
    $user = null;
    if (function_exists('get_user_from_token')) {
        $user = get_user_from_token();
        test_payment_log("User auth result", ['user_found' => $user ? true : false]);
    }

    // Parse input
    $input_raw = file_get_contents('php://input');
    test_payment_log("Raw input received", ['input' => $input_raw]);
    
    $input = json_decode($input_raw, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        test_payment_log("JSON parse error", ['error' => json_last_error_msg()]);
        safe_json_response(false, null, 'JSON non valido');
    }
    
    $payment_intent_id = $input['payment_intent_id'] ?? '';
    
    if (empty($payment_intent_id)) {
        test_payment_log("Missing payment_intent_id");
        safe_json_response(false, null, 'payment_intent_id è obbligatorio');
    }
    
    test_payment_log("Processing payment intent", ['payment_intent_id' => $payment_intent_id]);
    
    // Simula pagamento
    simulate_payment($payment_intent_id);
    
} catch (Exception $e) {
    test_payment_log("Fatal error in main", [
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
        'trace' => $e->getTraceAsString()
    ]);
    
    safe_json_response(false, null, 'Errore interno: ' . $e->getMessage());
}

/**
 * 🧪 Simula il completamento di un pagamento per testing
 */
function simulate_payment($payment_intent_id) {
    test_payment_log("Starting payment simulation", ['payment_intent_id' => $payment_intent_id]);
    
    try {
        // Verifica che Stripe SDK sia disponibile
        if (!class_exists('\Stripe\PaymentIntent')) {
            test_payment_log("ERROR: Stripe PHP SDK not loaded");
            safe_json_response(false, null, 'Stripe SDK non disponibile');
        }
        
        // Recupera il payment intent
        test_payment_log("Retrieving payment intent from Stripe");
        $payment_intent = \Stripe\PaymentIntent::retrieve($payment_intent_id);
        
        test_payment_log("Payment intent retrieved", [
            'id' => $payment_intent->id,
            'status' => $payment_intent->status,
            'amount' => $payment_intent->amount,
            'currency' => $payment_intent->currency
        ]);
        
        // Verifica stato
        if ($payment_intent->status === 'succeeded') {
            test_payment_log("Payment already succeeded");
            safe_json_response(true, [
                'payment_intent_id' => $payment_intent->id,
                'status' => $payment_intent->status,
                'amount' => $payment_intent->amount,
                'currency' => $payment_intent->currency,
                'already_completed' => true
            ], 'Payment Intent già completato');
        }
        
        if (!in_array($payment_intent->status, ['requires_payment_method', 'requires_confirmation', 'requires_action'])) {
            test_payment_log("Payment in unexpected status", ['status' => $payment_intent->status]);
            safe_json_response(false, null, 'Payment Intent in stato non gestibile: ' . $payment_intent->status);
        }
        
        // 🎯 FIXED: Usa il metodo corretto per confermare il payment intent
        test_payment_log("Attempting to confirm payment intent");
        
        try {
            // Strategia 1: Conferma direttamente sull'istanza esistente
            $confirmed = $payment_intent->confirm([
                'payment_method' => 'pm_card_visa'
            ]);
            
            test_payment_log("Payment confirmed successfully", [
                'final_status' => $confirmed->status,
                'amount' => $confirmed->amount
            ]);
            
        } catch (\Stripe\Exception\InvalidRequestException $e) {
            test_payment_log("Confirm failed, trying alternative method", ['error' => $e->getMessage()]);
            
            // Strategia 2: Crea payment method e poi conferma
            try {
                $payment_method = \Stripe\PaymentMethod::create([
                    'type' => 'card',
                    'card' => [
                        'number' => '4242424242424242',
                        'exp_month' => 12,
                        'exp_year' => 2025,
                        'cvc' => '123',
                    ],
                ]);
                
                test_payment_log("Created payment method", ['pm_id' => $payment_method->id]);
                
                // FIXED: Usa l'istanza, non il metodo statico
                $confirmed = $payment_intent->confirm([
                    'payment_method' => $payment_method->id
                ]);
                
                test_payment_log("Payment confirmed with new payment method", [
                    'payment_method_id' => $payment_method->id,
                    'final_status' => $confirmed->status
                ]);
                
            } catch (Exception $e2) {
                test_payment_log("Both confirmation methods failed", [
                    'error1' => $e->getMessage(),
                    'error2' => $e2->getMessage()
                ]);
                throw $e2;
            }
        }
        
        safe_json_response(true, [
            'payment_intent_id' => $confirmed->id,
            'status' => $confirmed->status,
            'amount' => $confirmed->amount,
            'currency' => $confirmed->currency,
            'simulated' => true,
            'timestamp' => time()
        ], 'Pagamento simulato con successo');
        
    } catch (\Stripe\Exception\ApiErrorException $e) {
        test_payment_log("Stripe API error", [
            'error' => $e->getMessage(),
            'type' => get_class($e),
            'code' => $e->getStripeCode()
        ]);
        safe_json_response(false, null, 'Errore Stripe: ' . $e->getMessage());
        
    } catch (Exception $e) {
        test_payment_log("General error in simulate_payment", [
            'error' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
        safe_json_response(false, null, 'Errore simulazione: ' . $e->getMessage());
    }
}
?>