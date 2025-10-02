<?php
// cron_renewal_check.php
// CRON JOB PER RINNOVI AUTOMATICI STRIPE

$baseDir = '/var/www/html/api';
$logDir = '/var/www/html/api/stripe/logs';

// Crea directory log se non esiste
if (!is_dir($logDir)) {
    mkdir($logDir, 0755, true);
}

// Include database
require_once $baseDir . '/config.php';

// Configurazione Stripe API Key
$STRIPE_SECRET_KEY = 'sk_test_51RW3uvHHtQGHyul9p5RR6cxcgdZsXYtUr2DE7v7ue2FRUZAl1LKaDhFlWKTBIpmHz56y9Uhgq58Ztqq8i8lcEXTj00xoAbsxmw';

// Logging
$logFile = $logDir . '/renewal_cron_' . date('Y-m') . '.log';

function renewalLog($message, $level = 'INFO') {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] [$level] $message" . PHP_EOL;
    file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
    echo $logEntry;
}

function renewalErrorLog($message, $error = null) {
    $fullMessage = $message;
    if ($error) {
        $fullMessage .= " - Error: $error";
    }
    renewalLog($fullMessage, 'ERROR');
}

// Recupera dati subscription da Stripe
function getStripeSubscriptionData($stripeSubscriptionId) {
    global $STRIPE_SECRET_KEY;
    
    if (empty($STRIPE_SECRET_KEY)) {
        renewalErrorLog("Stripe secret key non configurata");
        return null;
    }
    
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
        renewalLog("Subscription $stripeSubscriptionId non trovata su Stripe", 'WARN');
        return ['status' => 'not_found'];
    }
    
    if ($httpCode !== 200) {
        renewalErrorLog("Errore API Stripe per subscription $stripeSubscriptionId - HTTP $httpCode");
        return null;
    }
    
    $data = json_decode($response, true);
    if (!$data) {
        renewalErrorLog("Risposta JSON invalida da Stripe per subscription $stripeSubscriptionId");
        return null;
    }
    
    return [
        'id' => $data['id'],
        'status' => $data['status'],
        'current_period_start' => $data['current_period_start'] ?? null,
        'current_period_end' => $data['current_period_end'] ?? null,
        'cancel_at_period_end' => $data['cancel_at_period_end'] ?? false,
        'customer' => $data['customer'] ?? null
    ];
}

// Controlla rinnovi automatici
function cronCheckRenewals() {
    global $conn;
    
    renewalLog("INIZIO controllo rinnovi automatici");
    
    try {
        $stmt = $conn->prepare("
            SELECT us.id, us.user_id, us.plan_id, us.stripe_subscription_id, 
                   us.payment_type, us.start_date, us.end_date, us.auto_renew,
                   us.status, sp.name as plan_name, u.email as user_email
            FROM user_subscriptions us
            JOIN subscription_plans sp ON us.plan_id = sp.id
            JOIN users u ON us.user_id = u.id
            WHERE us.auto_renew = 1
            AND us.stripe_subscription_id IS NOT NULL
            AND (us.status = 'active' OR us.status = 'expired')
            ORDER BY us.user_id
        ");
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $totalChecked = 0;
        $renewalsFound = 0;
        $noChanges = 0;
        $errors = 0;
        $processedUsers = [];
        
        while ($row = $result->fetch_assoc()) {
            $totalChecked++;
            
            renewalLog("CHECK RINNOVO: User={$row['user_id']}, Email={$row['user_email']}, Piano={$row['plan_name']}, Status={$row['status']}, StripeID={$row['stripe_subscription_id']}");
            
            $stripeData = getStripeSubscriptionData($row['stripe_subscription_id']);
            
            if ($stripeData === null) {
                renewalErrorLog("Errore recupero dati Stripe per {$row['stripe_subscription_id']}");
                $errors++;
                continue;
            }
            
            if ($stripeData['status'] === 'not_found') {
                renewalLog("Subscription non trovata su Stripe - salto");
                continue;
            }
            
            // Verifica se Stripe ha un abbonamento attivo
            $stripeStatus = $stripeData['status'];
            renewalLog("STRIPE STATUS: $stripeStatus");
            
            // Se Stripe è attivo e il DB è expired, riattiva
            if ($stripeStatus === 'active' && $row['status'] === 'expired') {
                renewalLog("RINNOVO RILEVATO! Aggiorno database");
                
                try {
                    // Se Stripe ha le date, usale. Altrimenti calcola date future
                    if ($stripeData['current_period_start'] && $stripeData['current_period_end']) {
                        $newStartDate = date('Y-m-d H:i:s', $stripeData['current_period_start']);
                        $newEndDate = date('Y-m-d H:i:s', $stripeData['current_period_end']);
                        renewalLog("Usando date da Stripe: $newStartDate -> $newEndDate");
                    } else {
                        // Calcola nuove date: inizio ora, fine tra 1 mese
                        $newStartDate = date('Y-m-d H:i:s');
                        $newEndDate = date('Y-m-d H:i:s', strtotime('+1 month'));
                        renewalLog("Stripe non ha date, calcolo nuove: $newStartDate -> $newEndDate");
                    }
                    
                    $updateStmt = $conn->prepare("
                        UPDATE user_subscriptions 
                        SET 
                            start_date = ?,
                            end_date = ?,
                            status = 'active',
                            last_payment_date = NOW(),
                            updated_at = NOW()
                        WHERE id = ?
                    ");
                    $updateStmt->bind_param('ssi', $newStartDate, $newEndDate, $row['id']);
                    $updateStmt->execute();
                    
                    // Aggiorna anche current_plan_id dell'utente
                    $updateUserStmt = $conn->prepare("
                        UPDATE users 
                        SET current_plan_id = ?
                        WHERE id = ?
                    ");
                    $updateUserStmt->bind_param('ii', $row['plan_id'], $row['user_id']);
                    $updateUserStmt->execute();
                    
                    // Aggiorna stripe_subscriptions solo se abbiamo i dati
                    if ($stripeData['current_period_start'] && $stripeData['current_period_end']) {
                        $updateStripeStmt = $conn->prepare("
                            UPDATE stripe_subscriptions 
                            SET 
                                current_period_start = ?,
                                current_period_end = ?,
                                status = 'active',
                                updated_at = NOW()
                            WHERE stripe_subscription_id = ?
                        ");
                        $updateStripeStmt->bind_param('iis', 
                            $stripeData['current_period_start'], 
                            $stripeData['current_period_end'], 
                            $row['stripe_subscription_id']
                        );
                        $updateStripeStmt->execute();
                    }
                    
                    renewalLog("RINNOVO PROCESSATO per utente {$row['user_id']} ({$row['user_email']})");
                    renewalLog("Status aggiornato da '{$row['status']}' a 'active'");
                    renewalLog("current_plan_id aggiornato a {$row['plan_id']}");
                    renewalLog("Date aggiornate da: {$row['start_date']} -> {$row['end_date']}");
                    renewalLog("Date aggiornate a: $newStartDate -> $newEndDate");
                    
                    $processedUsers[] = [
                        'user_id' => $row['user_id'],
                        'email' => $row['user_email'],
                        'plan' => $row['plan_name'],
                        'type' => $row['payment_type'],
                        'old_end_date' => $row['end_date'],
                        'new_end_date' => $newEndDate,
                        'stripe_status' => $stripeData['status']
                    ];
                    
                    $renewalsFound++;
                    
                } catch (Exception $e) {
                    renewalErrorLog("Errore aggiornamento rinnovo per subscription {$row['id']}", $e->getMessage());
                    $errors++;
                }
                
            } else {
                // Nessun rinnovo rilevato
                if ($stripeStatus === 'active' && $row['status'] === 'active') {
                    renewalLog("Abbonamento già attivo - nessuna azione");
                } else {
                    renewalLog("Stripe status: $stripeStatus, DB status: {$row['status']} - nessuna azione");
                }
                $noChanges++;
            }
        }
        
        renewalLog("RISULTATO FINALE:");
        renewalLog("Totali controllate: $totalChecked");
        renewalLog("Rinnovi rilevati: $renewalsFound");
        renewalLog("Nessun cambiamento: $noChanges");
        renewalLog("Errori: $errors");
        
        if ($renewalsFound > 0) {
            renewalLog("RINNOVI PROCESSATI:");
            foreach ($processedUsers as $user) {
                renewalLog("{$user['email']} - {$user['plan']} ({$user['type']})");
                renewalLog("Da: {$user['old_end_date']} -> A: {$user['new_end_date']}");
            }
        }
        
        return [
            'success' => true,
            'total_checked' => $totalChecked,
            'renewals_found' => $renewalsFound,
            'no_changes' => $noChanges,
            'errors' => $errors,
            'processed_users' => $processedUsers
        ];
        
    } catch (Exception $e) {
        renewalErrorLog("ERRORE FATALE", $e->getMessage());
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

// Controllo accesso
if (php_sapi_name() !== 'cli' && !isset($_GET['manual_run'])) {
    renewalErrorLog("ACCESSO NEGATO: Solo da CLI o con manual_run");
    http_response_code(403);
    echo json_encode(['error' => 'Access denied']);
    exit;
}

renewalLog("CRON JOB RINNOVI AUTOMATICI AVVIATO");
renewalLog("Data/Ora: " . date('Y-m-d H:i:s T'));

// Controllo database
if (!$conn) {
    renewalErrorLog("ERRORE: Connessione database fallita");
    exit(1);
}

renewalLog("Connessione database OK");

// Esecuzione
$startTime = microtime(true);
$result = cronCheckRenewals();
$endTime = microtime(true);
$executionTime = round(($endTime - $startTime) * 1000, 2);

renewalLog("Tempo esecuzione: {$executionTime}ms");

if ($result['success']) {
    renewalLog("CRON JOB RINNOVI COMPLETATO CON SUCCESSO");
    renewalLog("SUMMARY: {$result['renewals_found']} rinnovi, {$result['no_changes']} invariati");
    
    echo "SUCCESS: {$result['renewals_found']} renewals, {$result['no_changes']} unchanged";
    exit(0);
} else {
    renewalErrorLog("CRON JOB RINNOVI FALLITO", $result['error'] ?? 'Unknown error');
    echo "ERROR: " . ($result['error'] ?? 'Unknown error');
    exit(1);
}

$conn->close();
renewalLog("FINE CRON JOB RINNOVI");
renewalLog("=====================================");

?>