<?php
/**
 * Test configurazione Stripe per Android
 * Questo file verifica se Stripe è configurato correttamente
 */

// Impostazione header per output JSON
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione richieste OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

// Include configurazione
include 'config.php';
require_once 'stripe_config.php';

// Funzione per testare la configurazione
function test_stripe_configuration() {
    $results = [
        'timestamp' => date('Y-m-d H:i:s'),
        'tests' => [],
        'success' => true,
        'errors' => []
    ];
    
    // Test 1: Verifica file di configurazione
    $results['tests']['config_files'] = [
        'config.php' => file_exists('config.php'),
        'stripe_config.php' => file_exists('stripe_config.php'),
        'auth_functions.php' => file_exists('auth_functions.php'),
        'stripe_auth_bridge.php' => file_exists('stripe_auth_bridge.php')
    ];
    
    // Test 2: Verifica costanti Stripe
    $results['tests']['stripe_constants'] = [
        'STRIPE_SECRET_KEY' => [
            'defined' => defined('STRIPE_SECRET_KEY'),
            'not_empty' => !empty(STRIPE_SECRET_KEY),
            'format' => strpos(STRIPE_SECRET_KEY, 'sk_') === 0,
            'value' => substr(STRIPE_SECRET_KEY, 0, 20) . '...'
        ],
        'STRIPE_PUBLISHABLE_KEY' => [
            'defined' => defined('STRIPE_PUBLISHABLE_KEY'),
            'not_empty' => !empty(STRIPE_PUBLISHABLE_KEY),
            'format' => strpos(STRIPE_PUBLISHABLE_KEY, 'pk_') === 0,
            'value' => substr(STRIPE_PUBLISHABLE_KEY, 0, 20) . '...'
        ],
        'STRIPE_WEBHOOK_SECRET' => [
            'defined' => defined('STRIPE_WEBHOOK_SECRET'),
            'not_empty' => !empty(STRIPE_WEBHOOK_SECRET),
            'format' => strpos(STRIPE_WEBHOOK_SECRET, 'whsec_') === 0,
            'value' => substr(STRIPE_WEBHOOK_SECRET, 0, 20) . '...'
        ],
        'STRIPE_TEST_MODE' => [
            'defined' => defined('STRIPE_TEST_MODE'),
            'value' => STRIPE_TEST_MODE
        ]
    ];
    
    // Test 3: Verifica Price ID
    $results['tests']['price_ids'] = [
        'STRIPE_PREMIUM_MONTHLY_PRICE_ID' => [
            'defined' => defined('STRIPE_PREMIUM_MONTHLY_PRICE_ID'),
            'value' => STRIPE_PREMIUM_MONTHLY_PRICE_ID,
            'format' => strpos(STRIPE_PREMIUM_MONTHLY_PRICE_ID, 'price_') === 0
        ],
        'STRIPE_PREMIUM_YEARLY_PRICE_ID' => [
            'defined' => defined('STRIPE_PREMIUM_YEARLY_PRICE_ID'),
            'value' => STRIPE_PREMIUM_YEARLY_PRICE_ID,
            'format' => strpos(STRIPE_PREMIUM_YEARLY_PRICE_ID, 'price_') === 0
        ]
    ];
    
    // Test 4: Verifica funzione stripe_is_configured
    $results['tests']['stripe_is_configured'] = [
        'function_exists' => function_exists('stripe_is_configured'),
        'result' => stripe_is_configured()
    ];
    
    // Test 5: Verifica database connection
    global $pdo;
    $results['tests']['database'] = [
        'pdo_exists' => isset($pdo),
        'connection_test' => false
    ];
    
    if (isset($pdo)) {
        try {
            $pdo->query('SELECT 1');
            $results['tests']['database']['connection_test'] = true;
        } catch (Exception $e) {
            $results['tests']['database']['error'] = $e->getMessage();
        }
    }
    
    // Test 6: Verifica tabelle Stripe
    if (isset($pdo) && $results['tests']['database']['connection_test']) {
        $stripe_tables = [
            'stripe_customers',
            'stripe_subscriptions', 
            'stripe_payment_intents'
        ];
        
        $results['tests']['stripe_tables'] = [];
        foreach ($stripe_tables as $table) {
            try {
                $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
                $results['tests']['stripe_tables'][$table] = $stmt->rowCount() > 0;
            } catch (Exception $e) {
                $results['tests']['stripe_tables'][$table] = false;
                $results['tests']['stripe_tables'][$table . '_error'] = $e->getMessage();
            }
        }
    }
    
    // Test 7: Verifica API endpoints
    $api_endpoints = [
        'stripe/create-subscription-payment-intent.php',
        'stripe/confirm-payment.php',
        'stripe/subscription.php',
        'stripe/customer.php'
    ];
    
    $results['tests']['api_endpoints'] = [];
    foreach ($api_endpoints as $endpoint) {
        $results['tests']['api_endpoints'][$endpoint] = file_exists($endpoint);
    }
    
    // Calcola successo generale
    foreach ($results['tests'] as $test_category => $tests) {
        if (is_array($tests)) {
            foreach ($tests as $test_name => $test_result) {
                if (is_array($test_result) && isset($test_result['result']) && !$test_result['result']) {
                    $results['success'] = false;
                    $results['errors'][] = "$test_category.$test_name failed";
                }
            }
        }
    }
    
    return $results;
}

// Esegui test
$test_results = test_stripe_configuration();

// Output risultati
echo json_encode($test_results, JSON_PRETTY_PRINT);
?> 