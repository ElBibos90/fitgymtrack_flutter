<?php
/**
 * get-publishable-key.php
 * Endpoint per fornire la chiave pubblica Stripe all'app Android
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

// Verifica che la chiave pubblica sia definita
if (!defined('STRIPE_PUBLISHABLE_KEY') || empty(STRIPE_PUBLISHABLE_KEY)) {
    sendError('Chiave pubblica Stripe non configurata', 500);
}

// Verifica che la chiave abbia il formato corretto
if (strpos(STRIPE_PUBLISHABLE_KEY, 'pk_') !== 0) {
    sendError('Formato chiave pubblica Stripe non valido', 500);
}

// Restituisci la chiave pubblica
$response_data = [
    'publishable_key' => STRIPE_PUBLISHABLE_KEY,
    'test_mode' => STRIPE_TEST_MODE,
    'currency' => STRIPE_CURRENCY,
    'country' => STRIPE_COUNTRY,
    'available_prices' => [
        'monthly_premium' => STRIPE_PREMIUM_MONTHLY_PRICE_ID,
        'yearly_premium' => STRIPE_PREMIUM_YEARLY_PRICE_ID
    ]
];

sendSuccess($response_data);
?> 