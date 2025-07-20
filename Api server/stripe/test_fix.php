<?php
/**
 * Test per verificare la correzione del problema con current_period_start
 * 
 * Questo script testa che i timestamp Unix vengano inseriti correttamente
 * nella tabella stripe_subscriptions senza errori di troncamento
 */

require_once '../config.php';

echo "🧪 TESTING STRIPE SUBSCRIPTION SYNC FIX\n";
echo "========================================\n\n";

echo "🔧 CORREZIONI APPLICATE:\n";
echo "  - ✅ Timestamp Unix invece di datetime in stripe_subscriptions\n";
echo "  - ✅ Rimosso updated_at da users table\n";
echo "  - ✅ Rimosso updated_at da user_subscriptions table\n";
echo "  - ✅ Rimosso updated_at da stripe_payment_intents table\n\n";

try {
    // Test con timestamp Unix realistici
    $test_timestamp_start = 1753031209; // 20-Jul-2025 17:07:06 UTC
    $test_timestamp_end = 1755709609;   // 20-Jul-2025 17:07:06 UTC + 30 giorni
    
    echo "📅 Test timestamps:\n";
    echo "  - Start: " . $test_timestamp_start . " (" . date('Y-m-d H:i:s', $test_timestamp_start) . ")\n";
    echo "  - End: " . $test_timestamp_end . " (" . date('Y-m-d H:i:s', $test_timestamp_end) . ")\n\n";
    
    // Test inserimento in stripe_subscriptions
    echo "🗄️  Testing stripe_subscriptions insert...\n";
    
    $stmt = $pdo->prepare("
        INSERT INTO stripe_subscriptions (
            user_id, stripe_subscription_id, stripe_customer_id, status,
            current_period_start, current_period_end, cancel_at_period_end,
            created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
        status = VALUES(status),
        current_period_start = VALUES(current_period_start),
        current_period_end = VALUES(current_period_end),
        cancel_at_period_end = VALUES(cancel_at_period_end),
        updated_at = NOW()
    ");
    
    $test_subscription_id = 'sub_test_' . time();
    $test_customer_id = 'cus_test_' . time();
    
    $result = $stmt->execute([
        17, // test user_id (esiste nel database)
        $test_subscription_id,
        $test_customer_id,
        'active',
        $test_timestamp_start, // ✅ TIMESTAMP UNIX (INT)
        $test_timestamp_end,   // ✅ TIMESTAMP UNIX (INT)
        0 // cancel_at_period_end
    ]);
    
    if ($result) {
        echo "✅ SUCCESS: stripe_subscriptions insert completed without errors\n";
        
        // Verifica che i dati siano stati inseriti correttamente
        $stmt = $pdo->prepare("
            SELECT current_period_start, current_period_end 
            FROM stripe_subscriptions 
            WHERE stripe_subscription_id = ?
        ");
        $stmt->execute([$test_subscription_id]);
        $inserted = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($inserted) {
            echo "📊 Verification:\n";
            echo "  - Inserted start: " . $inserted['current_period_start'] . "\n";
            echo "  - Inserted end: " . $inserted['current_period_end'] . "\n";
            echo "  - Expected start: " . $test_timestamp_start . "\n";
            echo "  - Expected end: " . $test_timestamp_end . "\n";
            
            if ($inserted['current_period_start'] == $test_timestamp_start && 
                $inserted['current_period_end'] == $test_timestamp_end) {
                echo "✅ DATA INTEGRITY: Timestamps match exactly\n";
            } else {
                echo "❌ DATA INTEGRITY: Timestamps don't match\n";
            }
        }
        
        // Cleanup
        $stmt = $pdo->prepare("DELETE FROM stripe_subscriptions WHERE stripe_subscription_id = ?");
        $stmt->execute([$test_subscription_id]);
        echo "🧹 Cleanup completed\n";
        
    } else {
        echo "❌ FAILED: stripe_subscriptions insert failed\n";
        print_r($stmt->errorInfo());
    }
    
} catch (Exception $e) {
    echo "❌ ERROR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}

echo "\n🎯 TEST COMPLETED\n";
?> 