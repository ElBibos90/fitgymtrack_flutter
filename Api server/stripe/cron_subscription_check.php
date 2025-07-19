<?php
/**
 * cron_subscription_check.php
 * CRON JOB SEMPLIFICATO - Solo Stripe Status Check
 * 
 * Location: /var/www/html/api/stripe/cron_subscription_check.php
 * Schedule: 0 6 * * * (ogni giorno alle 6:00 AM)
 * 
 * LOGICA GENIUS (idea dell'utente):
 * 1. Trova TUTTE le subscription con status = 'active' (ignora date)
 * 2. Per ognuna, verifica stato REALE su Stripe
 * 3. Se Stripe = cancelled → Downgrade a Free
 * 4. Se Stripe = active → Lascia stare
 * 
 * VANTAGGI:
 * - Zero problemi date/timezone
 * - Sempre sincronizzato con Stripe
 * - Molto più semplice e affidabile
 * - Zero edge cases
 */

// =============================================================================
// CONFIGURAZIONE E INCLUDE
// =============================================================================

$baseDir = '/var/www/html/api';
$logDir = '/var/www/html/api/stripe/logs';

// Crea directory log se non esiste
if (!is_dir($logDir)) {
    mkdir($logDir, 0755, true);
}

// Include database
require_once $baseDir . '/config.php';

// Configurazione Stripe API Key (inserisci la tua)
// TODO: Sostituisci con la tua secret key di test
$STRIPE_SECRET_KEY = 'sk_test_51RW3uvHHtQGHyul9p5RR6cxcgdZsXYtUr2DE7v7ue2FRUZAl1LKaDhFlWKTBIpmHz56y9Uhgq58Ztqq8i8lcEXTj00xoAbsxmw';

// =============================================================================
// LOGGING
// =============================================================================

$logFile = $logDir . '/subscription_cron_' . date('Y-m') . '.log';

function cronLog($message, $level = 'INFO') {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] [$level] $message" . PHP_EOL;
    file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
    echo $logEntry;
}

function cronErrorLog($message, $error = null) {
    $fullMessage = $message;
    if ($error) {
        $fullMessage .= " - Error: $error";
    }
    cronLog($fullMessage, 'ERROR');
}

// =============================================================================
// STRIPE API FUNCTIONS
// =============================================================================

/**
 * Verifica stato subscription su Stripe (versione semplificata)
 */
function getStripeSubscriptionStatus($stripeSubscriptionId) {
    global $STRIPE_SECRET_KEY;
    
    if (empty($STRIPE_SECRET_KEY) || $STRIPE_SECRET_KEY === 'sk_test_YOUR_SECRET_KEY_HERE') {
        cronErrorLog("Stripe secret key non configurata");
        return null;
    }
    
    // Usa cURL per chiamare Stripe API
    $url = "https://api.stripe.com/v1/subscriptions/" . $stripeSubscriptionId;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $STRIPE_SECRET_KEY,
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 404) {
        cronLog("⚠️  Subscription {$stripeSubscriptionId} non trovata su Stripe (già cancellata)", 'WARN');
        return ['status' => 'not_found'];
    }
    
    if ($httpCode !== 200) {
        cronErrorLog("Errore API Stripe per subscription {$stripeSubscriptionId} - HTTP $httpCode");
        return null;
    }
    
    $data = json_decode($response, true);
    if (!$data) {
        cronErrorLog("Risposta JSON invalida da Stripe per subscription {$stripeSubscriptionId}");
        return null;
    }
    
    return [
        'id' => $data['id'],
        'status' => $data['status'],
        'cancel_at_period_end' => $data['cancel_at_period_end'] ?? false,
    ];
}

// =============================================================================
// FUNZIONE PRINCIPALE - LOGICA SEMPLIFICATA
// =============================================================================

/**
 * Controlla TUTTE le subscription attive e sincronizza con Stripe
 */
function cronCheckAllActiveSubscriptions() {
    global $conn;
    
    cronLog("🚀 INIZIO controllo TUTTE le subscription attive - SYNC CON STRIPE");
    
    try {
        // Query SEMPLIFICATA: tutte le subscription attive (ignora date!)
        $stmt = $conn->prepare("
            SELECT us.id, us.user_id, us.plan_id, us.stripe_subscription_id, us.payment_type,
                   sp.name as plan_name, u.email as user_email
            FROM user_subscriptions us
            JOIN subscription_plans sp ON us.plan_id = sp.id
            JOIN users u ON us.user_id = u.id
            WHERE us.status = 'active'
            ORDER BY us.user_id
        ");
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $totalChecked = 0;
        $expiredCount = 0;
        $activeCount = 0;
        $processedUsers = [];
        
        while ($row = $result->fetch_assoc()) {
            $totalChecked++;
            
            cronLog("🔍 CHECK SUBSCRIPTION: User={$row['user_id']}, Email={$row['user_email']}, Piano={$row['plan_name']}, StripeID={$row['stripe_subscription_id']}, Tipo={$row['payment_type']}");
            
            // Se non ha stripe_subscription_id, salta
            if (empty($row['stripe_subscription_id'])) {
                cronLog("⏭️  Saltata - nessun StripeID (probabilmente creata manualmente)");
                continue;
            }
            
            // Verifica stato su Stripe
            $stripeData = getStripeSubscriptionStatus($row['stripe_subscription_id']);
            
            if ($stripeData === null) {
                cronErrorLog("Errore verifica Stripe per {$row['stripe_subscription_id']} - salto");
                continue;
            }
            
            $stripeStatus = $stripeData['status'];
            cronLog("📊 STRIPE STATUS: {$stripeStatus}");
            
            // LOGICA SEMPLICE: Se Stripe dice cancelled/not_found → Free
            if (in_array($stripeStatus, ['canceled', 'cancelled', 'not_found'])) {
                cronLog("🚨 SUBSCRIPTION SCADUTA SU STRIPE - procedo con downgrade");
                
                try {
                    // 1. Aggiorna subscription a expired
                    $updateStmt = $conn->prepare("
                        UPDATE user_subscriptions 
                        SET status = 'expired', updated_at = NOW() 
                        WHERE id = ?
                    ");
                    $updateStmt->bind_param('i', $row['id']);
                    $updateStmt->execute();
                    
                    // 2. Trova piano Free
                    $freePlanStmt = $conn->prepare("
                        SELECT id FROM subscription_plans WHERE name = 'Free' LIMIT 1
                    ");
                    $freePlanStmt->execute();
                    $freePlanResult = $freePlanStmt->get_result();
                    
                    if ($freePlanResult->num_rows > 0) {
                        $freePlan = $freePlanResult->fetch_assoc();
                        
                        // 3. Aggiorna utente a Free
                        $updateUserStmt = $conn->prepare("
                            UPDATE users SET current_plan_id = ? WHERE id = ?
                        ");
                        $updateUserStmt->bind_param('ii', $freePlan['id'], $row['user_id']);
                        $updateUserStmt->execute();
                        
                        cronLog("✅ Utente {$row['user_id']} ({$row['user_email']}) downgrade a Free completato");
                        
                        $processedUsers[] = [
                            'user_id' => $row['user_id'],
                            'email' => $row['user_email'],
                            'plan' => $row['plan_name'],
                            'type' => $row['payment_type'],
                            'stripe_status' => $stripeStatus
                        ];
                        
                        $expiredCount++;
                    } else {
                        cronErrorLog("Piano Free non trovato!");
                    }
                    
                } catch (Exception $e) {
                    cronErrorLog("Errore processamento subscription {$row['id']}", $e->getMessage());
                }
                
            } else {
                // Subscription ancora attiva su Stripe
                cronLog("✅ Subscription attiva su Stripe - nessuna azione");
                $activeCount++;
            }
        }
        
        // Summary finale
        cronLog("📊 RISULTATO FINALE:");
        cronLog("   - Totali controllate: $totalChecked");
        cronLog("   - Scadute/processate: $expiredCount");
        cronLog("   - Ancora attive: $activeCount");
        
        if ($expiredCount > 0) {
            cronLog("📋 UTENTI DOWNGRADE A FREE:");
            foreach ($processedUsers as $user) {
                cronLog("   ✅ {$user['email']} - {$user['plan']} ({$user['type']}) - Stripe: {$user['stripe_status']}");
            }
        }
        
        return [
            'success' => true,
            'total_checked' => $totalChecked,
            'expired_count' => $expiredCount,
            'active_count' => $activeCount,
            'processed_users' => $processedUsers
        ];
        
    } catch (Exception $e) {
        cronErrorLog("ERRORE FATALE", $e->getMessage());
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

// =============================================================================
// ESECUZIONE PRINCIPALE
// =============================================================================

// Controllo accesso
if (php_sapi_name() !== 'cli' && !isset($_GET['manual_run'])) {
    cronErrorLog("ACCESSO NEGATO: Solo da CLI o con manual_run");
    http_response_code(403);
    echo json_encode(['error' => 'Access denied']);
    exit;
}

cronLog("🕕 CRON JOB SUBSCRIPTION SEMPLIFICATO AVVIATO");
cronLog("📅 Data/Ora: " . date('Y-m-d H:i:s T'));

// Controllo database
if (!$conn) {
    cronErrorLog("ERRORE: Connessione database fallita");
    exit(1);
}

cronLog("✅ Connessione database OK");

// Esecuzione
$startTime = microtime(true);
$result = cronCheckAllActiveSubscriptions();
$endTime = microtime(true);
$executionTime = round(($endTime - $startTime) * 1000, 2);

cronLog("⏱️  Tempo esecuzione: {$executionTime}ms");

if ($result['success']) {
    cronLog("🎉 CRON JOB COMPLETATO CON SUCCESSO");
    cronLog("📊 SUMMARY: {$result['expired_count']} downgrade, {$result['active_count']} attive");
    
    echo "SUCCESS: {$result['expired_count']} expired, {$result['active_count']} active";
    exit(0);
} else {
    cronErrorLog("💥 CRON JOB FALLITO", $result['error'] ?? 'Unknown error');
    echo "ERROR: " . ($result['error'] ?? 'Unknown error');
    exit(1);
}

$conn->close();
cronLog("🔚 FINE CRON JOB");
cronLog("=====================================");

?>