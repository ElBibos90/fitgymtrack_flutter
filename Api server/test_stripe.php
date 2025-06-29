<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>🔧 Test Stripe Setup Completo</h2>";

// Test 1: Caricamento file
echo "<h3>1. Test caricamento file base...</h3>";
$files_to_check = [
    'config.php',
    'auth_functions.php', 
    'stripe_auth_bridge.php',
    'stripe_config.php'
];

foreach($files_to_check as $file) {
    if (file_exists($file)) {
        echo "✅ $file trovato<br>";
        try {
            include_once $file;
        } catch (Exception $e) {
            echo "❌ Errore caricando $file: " . $e->getMessage() . "<br>";
        }
    } else {
        echo "❌ $file NON trovato<br>";
    }
}

// Test 2: Database connections
echo "<h3>2. Test connessioni database...</h3>";
if (isset($conn)) {
    if ($conn->connect_error) {
        echo "❌ MySQLi connection failed: " . $conn->connect_error . "<br>";
    } else {
        echo "✅ MySQLi connection OK<br>";
    }
} else {
    echo "❌ MySQLi connection variable not found<br>";
}

if (isset($pdo)) {
    if ($pdo === null) {
        echo "❌ PDO connection failed (check logs)<br>";
    } else {
        try {
            $pdo->query('SELECT 1');
            echo "✅ PDO connection OK<br>";
        } catch (Exception $e) {
            echo "❌ PDO connection error: " . $e->getMessage() . "<br>";
        }
    }
} else {
    echo "❌ PDO connection variable not found<br>";
}

// Test 3: Auth Functions
echo "<h3>3. Test auth functions...</h3>";
if (function_exists('validateAuthToken')) {
    echo "✅ validateAuthToken() disponibile<br>";
} else {
    echo "❌ validateAuthToken() NON trovata<br>";
}

if (function_exists('getAuthorizationHeader')) {
    echo "✅ getAuthorizationHeader() disponibile<br>";
} else {
    echo "❌ getAuthorizationHeader() NON trovata<br>";
}

// Test 4: Bridge Functions  
echo "<h3>4. Test bridge functions...</h3>";
if (function_exists('get_user_from_token')) {
    echo "✅ get_user_from_token() disponibile<br>";
} else {
    echo "❌ get_user_from_token() NON trovata<br>";
}

if (function_exists('user_has_role')) {
    echo "✅ user_has_role() disponibile<br>";
} else {
    echo "❌ user_has_role() NON trovata<br>";
}

// Test 5: Stripe SDK
echo "<h3>5. Test Stripe SDK...</h3>";
if (class_exists('\Stripe\Stripe')) {
    echo "✅ Stripe SDK caricato<br>";
    echo "Versione: " . \Stripe\Stripe::VERSION . "<br>";
} else {
    echo "❌ Stripe SDK NON trovato<br>";
    echo "Esegui: composer require stripe/stripe-php<br>";
}

// Test 6: Stripe Configuration
echo "<h3>6. Test configurazione Stripe...</h3>";
$config_checks = [
    'STRIPE_SECRET_KEY' => defined('STRIPE_SECRET_KEY') && STRIPE_SECRET_KEY !== 'sk_test_...',
    'STRIPE_PUBLISHABLE_KEY' => defined('STRIPE_PUBLISHABLE_KEY') && STRIPE_PUBLISHABLE_KEY !== 'pk_test_...',
    'STRIPE_WEBHOOK_SECRET' => defined('STRIPE_WEBHOOK_SECRET') && STRIPE_WEBHOOK_SECRET !== 'whsec_...',
    'STRIPE_TEST_MODE' => defined('STRIPE_TEST_MODE')
];

foreach($config_checks as $config => $is_set) {
    if ($is_set) {
        echo "✅ $config configurato<br>";
    } else {
        echo "❌ $config NON configurato<br>";
    }
}

// Test 7: Test auth senza token (dovrebbe fallire gracefully)
echo "<h3>7. Test auth (senza token)...</h3>";
try {
    $user = get_user_from_token();
    if ($user === false) {
        echo "✅ get_user_from_token() ritorna false correttamente (nessun token)<br>";
    } else {
        echo "⚠️ get_user_from_token() ritorna dati senza token: " . json_encode($user) . "<br>";
    }
} catch (Exception $e) {
    echo "❌ Errore in get_user_from_token(): " . $e->getMessage() . "<br>";
}

// Test 8: Stripe API Connection (se configurato)
if (class_exists('\Stripe\Stripe') && defined('STRIPE_SECRET_KEY') && STRIPE_SECRET_KEY !== 'sk_test_...') {
    echo "<h3>8. Test Stripe API...</h3>";
    try {
        \Stripe\Stripe::setApiKey(STRIPE_SECRET_KEY);
        $customers = \Stripe\Customer::all(['limit' => 1]);
        echo "✅ Stripe API connection OK<br>";
        echo "Test customers fetched: " . count($customers->data) . "<br>";
    } catch (Exception $e) {
        echo "❌ Stripe API error: " . $e->getMessage() . "<br>";
    }
}

// Test 9: File structure
echo "<h3>9. Test struttura file Stripe...</h3>";
$stripe_files = [
    'stripe/customer.php',
    'stripe/subscription.php', 
    'stripe/create-donation-payment-intent.php',
    'stripe/create-subscription-payment-intent.php',
    'stripe/confirm-payment.php',
    'stripe/webhook.php',
    'stripe/.htaccess'
];

foreach($stripe_files as $file) {
    if (file_exists($file)) {
        echo "✅ $file presente<br>";
    } else {
        echo "❌ $file mancante<br>";
    }
}

echo "<h3>✅ Test completato!</h3>";

// Summary
$total_issues = 0;
echo "<h3>📋 Riassunto:</h3>";
echo "Se tutti i test mostrano ✅, il sistema è pronto per Stripe!<br>";
echo "Se ci sono ❌, risolvi prima i problemi evidenziati.<br>";
echo "<br><strong>Prossimo step:</strong> Testa stripe_setup.php<br>";
?>