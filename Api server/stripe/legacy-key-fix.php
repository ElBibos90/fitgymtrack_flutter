<?php
/**
 * legacy-key-fix.php
 * Endpoint temporaneo per risolvere il problema della chiave hardcoded nell'app Android
 * Questo endpoint restituisce sempre la chiave pubblica corretta
 */

// Impostazione header CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
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

try {
    // Verifica che la chiave pubblica sia definita
    if (!defined('STRIPE_PUBLISHABLE_KEY') || empty(STRIPE_PUBLISHABLE_KEY)) {
        sendError('Chiave pubblica Stripe non configurata', 500);
    }
    
    // Restituisci la chiave pubblica corretta
    $response_data = [
        'publishable_key' => STRIPE_PUBLISHABLE_KEY,
        'test_mode' => STRIPE_TEST_MODE,
        'currency' => STRIPE_CURRENCY,
        'country' => STRIPE_COUNTRY,
        'message' => 'Chiave pubblica Stripe corretta'
    ];
    
    sendSuccess($response_data);
    
} catch (Exception $e) {
    sendError('Errore interno: ' . $e->getMessage(), 500);
}
?> 