<?php
include 'config.php';
require_once 'auth_functions.php';
require_once 'stripe_config.php';

// ============================================================================
// STRIPE SYSTEM SETUP AND VERIFICATION
// ============================================================================

header('Content-Type: application/json');

// Permettiamo l'accesso solo in sviluppo o con autenticazione admin
$is_dev = STRIPE_TEST_MODE;
$user = get_user_from_token();
$is_admin = $user && isset($user['role_id']) && $user['role_id'] == 3; // Admin role

if (!$is_dev && !$is_admin) {
    http_response_code(403);
    echo json_encode(['error' => 'Accesso negato']);
    exit;
}

try {
    $setup_result = run_stripe_setup();
    echo json_encode($setup_result);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

// ============================================================================
// SETUP FUNCTIONS
// ============================================================================

/**
 * Esegue il setup completo del sistema Stripe
 */
function run_stripe_setup() {
    global $pdo;
    
    $results = [
        'success' => true,
        'timestamp' => date('Y-m-d H:i:s'),
        'checks' => [],
        'actions_taken' => [],
        'warnings' => [],
        'errors' => []
    ];
    
    // 1. Verifica configurazione Stripe
    $config_check = check_stripe_configuration();
    $results['checks']['stripe_config'] = $config_check;
    
    if (!$config_check['success']) {
        $results['success'] = false;
        $results['errors'][] = 'Configurazione Stripe non valida';
    }
    
    // 2. Verifica SDK Stripe
    $sdk_check = check_stripe_sdk();
    $results['checks']['stripe_sdk'] = $sdk_check;
    
    if (!$sdk_check['success']) {
        $results['success'] = false;
        $results['errors'][] = 'Stripe SDK non disponibile';
    }
    
    // 3. Verifica/Crea tabelle database
    if ($results['success']) {
        $db_setup = setup_stripe_database($pdo);
        $results['checks']['database'] = $db_setup;
        $results['actions_taken'] = array_merge($results['actions_taken'], $db_setup['actions']);
        
        if (!$db_setup['success']) {
            $results['warnings'][] = 'Alcuni problemi con il database';
        }
    }
    
    // 4. Test connessione Stripe API
    if ($results['success'] && $config_check['success']) {
        $api_test = test_stripe_api_connection();
        $results['checks']['stripe_api'] = $api_test;
        
        if (!$api_test['success']) {
            $results['warnings'][] = 'Connessione API Stripe non riuscita';
        }
    }
    
    // 5. Verifica webhook endpoint
    $webhook_check = check_webhook_endpoint();
    $results['checks']['webhook'] = $webhook_check;
    
    // 6. Verifica file system
    $files_check = check_stripe_files();
    $results['checks']['files'] = $files_check;
    
    // 7. Crea dati di test se richiesto
    if (isset($_GET['create_test_data']) && STRIPE_TEST_MODE) {
        $test_data = create_test_data($pdo);
        $results['checks']['test_data'] = $test_data;
        $results['actions_taken'] = array_merge($results['actions_taken'], $test_data['actions']);
    }
    
    return $results;
}

/**
 * Verifica configurazione Stripe
 */
function check_stripe_configuration() {
    $checks = [
        'secret_key_set' => !empty(STRIPE_SECRET_KEY) && STRIPE_SECRET_KEY !== 'sk_test_...',
        'secret_key_format' => strpos(STRIPE_SECRET_KEY, 'sk_') === 0,
        'publishable_key_set' => !empty(STRIPE_PUBLISHABLE_KEY),
        'publishable_key_format' => strpos(STRIPE_PUBLISHABLE_KEY, 'pk_') === 0,
        'webhook_secret_set' => !empty(STRIPE_WEBHOOK_SECRET) && STRIPE_WEBHOOK_SECRET !== 'whsec_...',
        'price_ids_set' => !empty(STRIPE_PREMIUM_MONTHLY_PRICE_ID),
        'test_mode' => STRIPE_TEST_MODE
    ];
    
    $success = $checks['secret_key_set'] && $checks['secret_key_format'] && 
               $checks['publishable_key_set'] && $checks['publishable_key_format'];
    
    return [
        'success' => $success,
        'details' => $checks,
        'message' => $success ? 'Configurazione Stripe OK' : 'Configurazione Stripe incompleta'
    ];
}

/**
 * Verifica disponibilità Stripe SDK
 */
function check_stripe_sdk() {
    $sdk_available = class_exists('\Stripe\Stripe');
    $version = null;
    
    if ($sdk_available) {
        try {
            $version = \Stripe\Stripe::VERSION;
        } catch (Exception $e) {
            $version = 'Unknown';
        }
    }
    
    return [
        'success' => $sdk_available,
        'version' => $version,
        'message' => $sdk_available ? "Stripe SDK v{$version} disponibile" : 'Stripe SDK non trovato'
    ];
}

/**
 * Setup database per Stripe
 */
function setup_stripe_database($pdo) {
    $actions = [];
    $success = true;
    
    try {
        // Tabella stripe_customers
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS stripe_customers (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                stripe_customer_id VARCHAR(255) NOT NULL UNIQUE,
                email VARCHAR(255),
                name VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_id (user_id),
                INDEX idx_stripe_customer_id (stripe_customer_id)
            )
        ");
        $actions[] = 'Tabella stripe_customers verificata/creata';
        
        // Tabella stripe_subscriptions
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS stripe_subscriptions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                stripe_subscription_id VARCHAR(255) NOT NULL UNIQUE,
                stripe_customer_id VARCHAR(255) NOT NULL,
                status VARCHAR(50) NOT NULL,
                current_period_start INT NOT NULL,
                current_period_end INT NOT NULL,
                cancel_at_period_end BOOLEAN DEFAULT FALSE,
                plan_id INT,
                price_id VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_id (user_id),
                INDEX idx_stripe_subscription_id (stripe_subscription_id),
                INDEX idx_status (status)
            )
        ");
        $actions[] = 'Tabella stripe_subscriptions verificata/creata';
        
        // Tabella stripe_payment_intents
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS stripe_payment_intents (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                stripe_payment_intent_id VARCHAR(255) NOT NULL UNIQUE,
                amount INT NOT NULL,
                currency VARCHAR(3) NOT NULL DEFAULT 'eur',
                status VARCHAR(50) NOT NULL,
                payment_type ENUM('subscription', 'donation') NOT NULL,
                metadata JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_id (user_id),
                INDEX idx_stripe_payment_intent_id (stripe_payment_intent_id),
                INDEX idx_status (status),
                INDEX idx_payment_type (payment_type)
            )
        ");
        $actions[] = 'Tabella stripe_payment_intents verificata/creata';
        
        // Tabella donations
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
        $actions[] = 'Tabella donations verificata/creata';
        
        // Tabella stripe_webhook_events
        $pdo->exec("
            CREATE TABLE IF NOT EXISTS stripe_webhook_events (
                id INT AUTO_INCREMENT PRIMARY KEY,
                stripe_event_id VARCHAR(255) NOT NULL UNIQUE,
                event_type VARCHAR(100) NOT NULL,
                processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                data JSON,
                INDEX idx_event_type (event_type),
                INDEX idx_processed_at (processed_at)
            )
        ");
        $actions[] = 'Tabella stripe_webhook_events verificata/creata';
        
    } catch (PDOException $e) {
        $success = false;
        $actions[] = 'ERRORE: ' . $e->getMessage();
    }
    
    return [
        'success' => $success,
        'actions' => $actions,
        'message' => $success ? 'Database setup completato' : 'Errori nel database setup'
    ];
}

/**
 * Test connessione API Stripe
 */
function test_stripe_api_connection() {
    if (!stripe_is_configured()) {
        return [
            'success' => false,
            'message' => 'Stripe non configurato'
        ];
    }
    
    try {
        // Test semplice: lista primi 3 customers
        $customers = \Stripe\Customer::all(['limit' => 3]);
        
        return [
            'success' => true,
            'customers_count' => count($customers->data),
            'message' => 'Connessione API Stripe OK'
        ];
        
    } catch (Exception $e) {
        return [
            'success' => false,
            'error' => $e->getMessage(),
            'message' => 'Test API Stripe fallito'
        ];
    }
}

/**
 * Verifica endpoint webhook
 */
function check_webhook_endpoint() {
    $webhook_url = 'https://' . $_SERVER['HTTP_HOST'] . '/api/stripe/webhook';
    
    // Test base: verifica se il file esiste
    $webhook_file_exists = file_exists(__DIR__ . '/stripe/webhook.php');
    
    return [
        'success' => $webhook_file_exists,
        'webhook_url' => $webhook_url,
        'file_exists' => $webhook_file_exists,
        'message' => $webhook_file_exists ? 'Webhook endpoint disponibile' : 'Webhook file mancante'
    ];
}

/**
 * Verifica file system Stripe
 */
function check_stripe_files() {
    $required_files = [
        'stripe_config.php',
        'stripe/customer.php',
        'stripe/subscription.php',
        'stripe/create-donation-payment-intent.php',
        'stripe/create-subscription-payment-intent.php',
        'stripe/confirm-payment.php',
        'stripe/webhook.php'
    ];
    
    $existing_files = [];
    $missing_files = [];
    
    foreach ($required_files as $file) {
        if (file_exists(__DIR__ . '/' . $file)) {
            $existing_files[] = $file;
        } else {
            $missing_files[] = $file;
        }
    }
    
    $success = empty($missing_files);
    
    return [
        'success' => $success,
        'existing_files' => $existing_files,
        'missing_files' => $missing_files,
        'message' => $success ? 'Tutti i file Stripe presenti' : count($missing_files) . ' file mancanti'
    ];
}

/**
 * Crea dati di test
 */
function create_test_data($pdo) {
    $actions = [];
    
    if (!STRIPE_TEST_MODE) {
        return [
            'success' => false,
            'actions' => [],
            'message' => 'Dati test disponibili solo in modalità test'
        ];
    }
    
    try {
        // Trova un utente test o ne crea uno
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
        $stmt->execute(['test@stripe.local']);
        $test_user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$test_user) {
            // Crea utente test
            $stmt = $pdo->prepare("
                INSERT INTO users (username, email, password_hash, role_id, created_at)
                VALUES (?, ?, ?, 1, NOW())
            ");
            $stmt->execute(['stripe_test', 'test@stripe.local', password_hash('test123', PASSWORD_DEFAULT)]);
            $test_user_id = $pdo->lastInsertId();
            $actions[] = "Utente test creato (ID: {$test_user_id})";
        } else {
            $test_user_id = $test_user['id'];
            $actions[] = "Utente test esistente trovato (ID: {$test_user_id})";
        }
        
        // Crea customer test se non esiste
        $stmt = $pdo->prepare("SELECT id FROM stripe_customers WHERE user_id = ?");
        $stmt->execute([$test_user_id]);
        if (!$stmt->fetch()) {
            $stmt = $pdo->prepare("
                INSERT INTO stripe_customers (user_id, stripe_customer_id, email, name)
                VALUES (?, ?, ?, ?)
            ");
            $stmt->execute([$test_user_id, 'cus_test_' . uniqid(), 'test@stripe.local', 'Test User']);
            $actions[] = 'Customer test creato';
        }
        
        return [
            'success' => true,
            'actions' => $actions,
            'test_user_id' => $test_user_id,
            'message' => 'Dati test creati'
        ];
        
    } catch (Exception $e) {
        return [
            'success' => false,
            'actions' => $actions,
            'error' => $e->getMessage(),
            'message' => 'Errore creazione dati test'
        ];
    }
}

// ============================================================================
// UTILITY ENDPOINT
// ============================================================================

// Se chiamato con ?info=1, mostra solo informazioni
if (isset($_GET['info'])) {
    $info = [
        'stripe_configured' => stripe_is_configured(),
        'stripe_test_mode' => STRIPE_TEST_MODE,
        'stripe_sdk_available' => class_exists('\Stripe\Stripe'),
        'stripe_version' => class_exists('\Stripe\Stripe') ? \Stripe\Stripe::VERSION : null,
        'required_files' => [
            'stripe_config.php' => file_exists(__DIR__ . '/stripe_config.php'),
            'customer.php' => file_exists(__DIR__ . '/stripe/customer.php'),
            'subscription.php' => file_exists(__DIR__ . '/stripe/subscription.php'),
            'webhook.php' => file_exists(__DIR__ . '/stripe/webhook.php')
        ],
        'webhook_url' => 'https://' . $_SERVER['HTTP_HOST'] . '/api/stripe/webhook'
    ];
    
    echo json_encode($info, JSON_PRETTY_PRINT);
    exit;
}
?>
