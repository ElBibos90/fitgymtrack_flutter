<?php
/**
 * test-connection.php
 * Endpoint per testare la connessione Stripe e verificare le chiavi
 */

// Impostazione header CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json; charset=UTF-8');

// Gestione richieste OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

// Include configurazione
include '../config.php';
require_once '../stripe_config.php';

// Funzione per gestire errori
function sendError($message, $code = 400) {
    http_response_code($code);
    echo json_encode([
        'success' => false,
        'error' => $message,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    exit;
}

// Funzione per inviare risposta di successo
function sendSuccess($data) {
    echo json_encode([
        'success' => true,
        'data' => $data,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    exit;
}

// Verifica che Stripe sia configurato
if (!stripe_is_configured()) {
    sendError('Stripe non configurato correttamente', 500);
}

// Verifica che la classe Stripe esista
if (!class_exists('\Stripe\Stripe')) {
    sendError('Libreria Stripe non caricata', 500);
}

try {
    // Test connessione API Stripe
    $customers = \Stripe\Customer::all(['limit' => 1]);
    
    $test_results = [
        'stripe_configured' => true,
        'api_connection' => 'success',
        'publishable_key' => [
            'value' => substr(STRIPE_PUBLISHABLE_KEY, 0, 20) . '...',
            'format' => 'pk_test_...',
            'length' => strlen(STRIPE_PUBLISHABLE_KEY)
        ],
        'secret_key' => [
            'value' => substr(STRIPE_SECRET_KEY, 0, 20) . '...',
            'format' => 'sk_test_...',
            'length' => strlen(STRIPE_SECRET_KEY)
        ],
        'test_mode' => STRIPE_TEST_MODE,
        'api_version' => \Stripe\Stripe::getApiVersion(),
        'customers_count' => count($customers->data)
    ];
    
    sendSuccess($test_results);
    
} catch (\Stripe\Exception\AuthenticationException $e) {
    sendError('Errore di autenticazione Stripe: ' . $e->getMessage(), 401);
} catch (\Stripe\Exception\ApiConnectionException $e) {
    sendError('Errore di connessione API Stripe: ' . $e->getMessage(), 503);
} catch (\Stripe\Exception\ApiErrorException $e) {
    sendError('Errore API Stripe: ' . $e->getMessage(), 500);
} catch (Exception $e) {
    sendError('Errore generico: ' . $e->getMessage(), 500);
}
?> 