<?php
include 'config.php';
require_once 'auth_functions.php';
require_once 'stripe_auth_bridge.php';

// ============================================================================
// STRIPE CONFIGURATION
// ============================================================================

// 💳 STRIPE API KEYS - Sostituisci con le tue chiavi reali
define('STRIPE_SECRET_KEY', 'sk_test_51RW3uvHHtQGHyul9p5RR6cxcgdZsXYtUr2DE7v7ue2FRUZAl1LKaDhFlWKTBIpmHz56y9Uhgq58Ztqq8i8lcEXTj00xoAbsxmw');  // ⚠️ DA CONFIGURARE
define('STRIPE_PUBLISHABLE_KEY', 'pk_test_51RW3uvHHtQGHyul9D48kPP1cBny9yxD75X4hrA1DWsudV37kNGVvPJNzZyCMjIFzuEHlPkRHT4W9R8vCASNpX1xL00qADtuDiY');
define('STRIPE_WEBHOOK_SECRET', 'whsec_9QC6yRw5u8zwKuzvgsBQeIqVxzjRqowq');  // ✅ Configurato per test

// Test mode
define('STRIPE_TEST_MODE', true);

// Currency e country
define('STRIPE_CURRENCY', 'eur');
define('STRIPE_COUNTRY', 'IT');

// ============================================================================
// STRIPE PRICE IDS - Configurare in Stripe Dashboard
// ============================================================================

define('STRIPE_PREMIUM_MONTHLY_PRICE_ID', 'price_1RXVOfHHtQGHyul9qMGFmpmO');
define('STRIPE_PREMIUM_YEARLY_PRICE_ID', 'price_1RbmRkHHtQGHyul92oUMSkUY');

// ============================================================================
// STRIPE PHP SDK - Download da https://github.com/stripe/stripe-php
// ============================================================================

// Assicurati di scaricare e includere la Stripe PHP library
// composer require stripe/stripe-php
// require_once 'vendor/autoload.php';

// Caricamento automatico della libreria Stripe
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
} else {
    // ⚠️ FALLBACK: se non hai composer, usa la versione semplificata
    error_log("⚠️ STRIPE: SDK non trovato. Usando fallback semplificato");
    if (file_exists(__DIR__ . '/vendor/stripe/stripe-php/lib/Stripe/init.php')) {
        require_once __DIR__ . '/vendor/stripe/stripe-php/lib/Stripe/init.php';
    } else {
        error_log("❌ STRIPE: Nessun SDK disponibile. Esegui install_stripe_sdk.php");
    }
}

// Inizializza Stripe
if (class_exists('\Stripe\Stripe')) {
    \Stripe\Stripe::setApiKey(STRIPE_SECRET_KEY);
    \Stripe\Stripe::setApiVersion('2023-10-16');  // Versione API stabile
} else {
    error_log("❌ STRIPE: Impossibile inizializzare Stripe SDK");
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Verifica se Stripe è configurato correttamente
 */
function stripe_is_configured() {
    return class_exists('\Stripe\Stripe') && 
           !empty(STRIPE_SECRET_KEY) && 
           strpos(STRIPE_SECRET_KEY, 'sk_') === 0;
}

/**
 * Log errori Stripe in modo sicuro
 */
function stripe_log_error($message, $context = []) {
    $log_message = "[STRIPE ERROR] " . $message;
    if (!empty($context)) {
        $log_message .= " | Context: " . json_encode($context);
    }
    error_log($log_message);
}

/**
 * Log info Stripe
 */
function stripe_log_info($message) {
    error_log("[STRIPE INFO] " . $message);
}

/**
 * Converte centesimi in euro
 */
function stripe_cents_to_euros($cents) {
    return $cents / 100.0;
}

/**
 * Converte euro in centesimi
 */
function stripe_euros_to_cents($euros) {
    return intval($euros * 100);
}

/**
 * Restituisce response JSON standard
 */
function stripe_json_response($success, $data = null, $message = '') {
    header('Content-Type: application/json');
    
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

/**
 * Gestisce errori Stripe e restituisce response appropriata
 */
function handle_stripe_error($e) {
    if ($e instanceof \Stripe\Exception\CardException) {
        // Errore della carta
        stripe_json_response(false, null, 'Errore carta: ' . $e->getMessage());
    } elseif ($e instanceof \Stripe\Exception\RateLimitException) {
        // Rate limit
        stripe_json_response(false, null, 'Troppe richieste. Riprova tra poco.');
    } elseif ($e instanceof \Stripe\Exception\InvalidRequestException) {
        // Richiesta non valida
        stripe_log_error('Invalid request', ['error' => $e->getMessage()]);
        stripe_json_response(false, null, 'Richiesta non valida.');
    } elseif ($e instanceof \Stripe\Exception\AuthenticationException) {
        // Autenticazione fallita
        stripe_log_error('Authentication failed', ['error' => $e->getMessage()]);
        stripe_json_response(false, null, 'Errore di autenticazione.');
    } elseif ($e instanceof \Stripe\Exception\ApiConnectionException) {
        // Connessione API fallita
        stripe_log_error('API connection failed', ['error' => $e->getMessage()]);
        stripe_json_response(false, null, 'Errore di connessione. Riprova più tardi.');
    } elseif ($e instanceof \Stripe\Exception\ApiErrorException) {
        // Errore generico API
        stripe_log_error('API error', ['error' => $e->getMessage()]);
        stripe_json_response(false, null, 'Errore del servizio. Riprova più tardi.');
    } else {
        // Errore generico
        stripe_log_error('Generic error', ['error' => $e->getMessage()]);
        stripe_json_response(false, null, 'Errore sconosciuto.');
    }
}

/**
 * Verifica webhook signature
 */
function verify_stripe_webhook($payload, $sig_header) {
    try {
        $event = \Stripe\Webhook::constructEvent($payload, $sig_header, STRIPE_WEBHOOK_SECRET);
        return $event;
    } catch (\UnexpectedValueException $e) {
        stripe_log_error('Invalid payload in webhook', ['error' => $e->getMessage()]);
        return false;
    } catch (\Stripe\Exception\SignatureVerificationException $e) {
        stripe_log_error('Invalid signature in webhook', ['error' => $e->getMessage()]);
        return false;
    }
}

// ============================================================================
// DATABASE SCHEMA CHECK
// ============================================================================

/**
 * Crea tabelle per Stripe se non esistono
 */
function create_stripe_tables_if_needed($pdo) {
    try {
        // Tabella per clienti Stripe
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

        // Tabella per subscription Stripe
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

        // Tabella per payment intent
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

        stripe_log_info('Stripe database tables verified/created successfully');
        return true;

    } catch (PDOException $e) {
        stripe_log_error('Failed to create Stripe tables', ['error' => $e->getMessage()]);
        return false;
    }
}

// Crea le tabelle automaticamente
if (!empty($pdo)) {
    create_stripe_tables_if_needed($pdo);
}

// ============================================================================
// CONFIGURAZIONE CHECK
// ============================================================================

if (!stripe_is_configured()) {
    stripe_log_error('Stripe not properly configured. Please set STRIPE_SECRET_KEY.');
}

stripe_log_info('Stripe configuration loaded. Test mode: ' . (STRIPE_TEST_MODE ? 'ON' : 'OFF'));
?>
