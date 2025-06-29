<?php
/**
 * android_paypal_callback.php
 * API per gestire i callback di PayPal dopo pagamento da app Android
 */

// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Includi le configurazioni e le funzioni necessarie
require_once 'config.php';
require_once 'paypal_config.php';
require_once 'auth_functions.php';

file_put_contents('/var/www/html/paypal_debug.log', 
    "=== PAYPAL CALLBACK CHIAMATO ===\n" .
    "Timestamp: " . date('Y-m-d H:i:s') . "\n" .
    "File: " . __FILE__ . "\n" .
    "Action: " . ($_GET['action'] ?? 'none') . "\n" .
    "Order ID: " . ($_GET['order_id'] ?? 'none') . "\n\n", 
    FILE_APPEND
);

// Funzione per il logging di debug
function debugLog($message, $data = null) {
    $log_file = __DIR__ . '/android_paypal_callback_debug.log';
    $timestamp = date('Y-m-d H:i:s');
    $log_message = "[{$timestamp}] {$message}";
    
    if ($data !== null) {
        if (is_array($data) || is_object($data)) {
            $log_message .= " - Data: " . print_r($data, true);
        } else {
            $log_message .= " - Data: {$data}";
        }
    }
    
    file_put_contents($log_file, $log_message . PHP_EOL, FILE_APPEND);
}

// Funzione per gestire errori e restituire JSON
function sendResponse($success, $data = null, $message = null, $code = 200) {
    http_response_code($code);
    
    $response = [
        'success' => $success
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    if ($message !== null) {
        $response['message'] = $message;
    }
    
    echo json_encode($response);
    exit;
}

// Funzione per ottenere un token di accesso OAuth 2.0 da PayPal
function getPayPalAccessToken() {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, PAYPAL_API_URL . '/v1/oauth2/token');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, 'grant_type=client_credentials');
    curl_setopt($ch, CURLOPT_USERPWD, PAYPAL_CLIENT_ID . ':' . PAYPAL_SECRET);
    
    $headers = array();
    $headers[] = 'Accept: application/json';
    $headers[] = 'Accept-Language: en_US';
    $headers[] = 'Content-Type: application/x-www-form-urlencoded';
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $result = curl_exec($ch);
    
    if (curl_errno($ch)) {
        throw new Exception('Errore Curl: ' . curl_error($ch));
    }
    
    curl_close($ch);
    $response = json_decode($result, true);
    
    if (!isset($response['access_token'])) {
        throw new Exception('Impossibile ottenere token di accesso PayPal');
    }
    
    return $response['access_token'];
}

// Funzione per catturare il pagamento PayPal
function capturePayPalOrder($accessToken, $paypalOrderId) {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, PAYPAL_API_URL . '/v2/checkout/orders/' . $paypalOrderId . '/capture');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, '{}');
    
    $headers = array();
    $headers[] = 'Content-Type: application/json';
    $headers[] = 'Authorization: Bearer ' . $accessToken;
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if (curl_errno($ch)) {
        throw new Exception('Errore Curl: ' . curl_error($ch));
    }
    
    curl_close($ch);
    
    // Verifica il codice di stato HTTP
    if ($httpCode < 200 || $httpCode >= 300) {
        throw new Exception('Errore nella cattura del pagamento. Codice: ' . $httpCode);
    }
    
    return json_decode($result, true);
}

// Determina l'azione (success o cancel)
$action = isset($_GET['action']) ? $_GET['action'] : null;

if (!in_array($action, ['success', 'cancel'])) {
    sendResponse(false, null, 'Azione non valida', 400);
}

// Ottieni l'ID ordine dall'URL
$orderId = isset($_GET['order_id']) ? $_GET['order_id'] : null;

if (!$orderId) {
    sendResponse(false, null, 'Ordine non specificato', 400);
}

// Recupera i dati dell'ordine dal database
$stmt = $conn->prepare("SELECT * FROM paypal_orders WHERE order_id = ? AND platform = 'android'");
$stmt->bind_param('s', $orderId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    sendResponse(false, null, 'Ordine non trovato', 404);
}

$order = $result->fetch_assoc();
$stmt->close();

// Gestisci l'annullamento del pagamento
if ($action === 'cancel') {
    // Aggiorna lo stato dell'ordine a "cancelled"
    $updateStmt = $conn->prepare("UPDATE paypal_orders SET status = 'cancelled' WHERE order_id = ? AND status = 'pending'");
    $updateStmt->bind_param('s', $orderId);
    $updateStmt->execute();
    $updateStmt->close();
    
    sendResponse(true, null, 'Pagamento annullato');
}

// Gestisci il successo del pagamento
if ($action === 'success') {
    try {
        // Verifica che l'ordine sia ancora in stato "pending"
        if ($order['status'] !== 'pending') {
            sendResponse(false, null, 'Ordine già elaborato', 400);
        }
        
        // Ottieni il token di accesso
        $accessToken = getPayPalAccessToken();
        
        // Cattura il pagamento
        $captureResponse = capturePayPalOrder($accessToken, $order['paypal_order_id']);
        
        // Verifica il risultato
        if (!isset($captureResponse['status']) || $captureResponse['status'] !== 'COMPLETED') {
            sendResponse(false, null, 'Il pagamento non è stato completato con successo', 400);
        }
        
        // Ottieni i dettagli della transazione
        $transactionId = $captureResponse['purchase_units'][0]['payments']['captures'][0]['id'];
        $paymentStatus = $captureResponse['status'];
        
        // Aggiorna lo stato dell'ordine
        $updateStmt = $conn->prepare("UPDATE paypal_orders SET status = 'completed' WHERE order_id = ?");
        $updateStmt->bind_param('s', $orderId);
        $updateStmt->execute();
        $updateStmt->close();
        
        // Gestisci il pagamento in base al tipo
        if ($order['type'] === 'subscription') {
            // Aggiorna l'abbonamento dell'utente
            $conn->begin_transaction();
            
            try {
                // Recupera il piano 
                $planQuery = $conn->prepare("SELECT * FROM subscription_plans WHERE id = ?");
                $planQuery->bind_param('i', $order['plan_id']);
                $planQuery->execute();
                $planResult = $planQuery->get_result();
                
                if ($planResult->num_rows === 0) {
                    throw new Exception('Piano non trovato');
                }
                
                $plan = $planResult->fetch_assoc();
                $planQuery->close();
                
                // Annulla gli abbonamenti precedenti
                $cancelStmt = $conn->prepare("
                    UPDATE user_subscriptions 
                    SET status = 'cancelled', end_date = NOW() 
                    WHERE user_id = ? AND status = 'active'
                ");
                $cancelStmt->bind_param('i', $order['user_id']);
                $cancelStmt->execute();
                $cancelStmt->close();
                
                // Verifica che il campo plan_id sia un intero valido e non nullo
                if (empty($order['plan_id']) || !is_numeric($order['plan_id'])) {
                    throw new Exception('ID piano non valido');
                }
                
                $plan_id = intval($order['plan_id']);
if ($order['type'] === 'subscription') {
    file_put_contents('/var/www/html/paypal_debug.log', 
        "=== CREAZIONE SUBSCRIPTION ===\n" .
        "User ID: " . $order['user_id'] . "\n" .
        "Plan ID: " . $plan_id . "\n" .
        "Transaction ID: " . $transactionId . "\n" .
        "QUERY: INSERT con CONCAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ' 23:59:59')\n\n", 
        FILE_APPEND
    );

				// Crea il nuovo abbonamento
				$insertStmt = $conn->prepare("
					INSERT INTO user_subscriptions 
					(user_id, plan_id, status, start_date, end_date, payment_reference, payment_provider, auto_renew) 
					VALUES (?, ?, 'active', NOW(), CONCAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ' 23:59:59'), ?, 'paypall', 1)
				");

    $newRecordId = $conn->insert_id;
    file_put_contents('/var/www/html/paypal_debug.log', 
        "Record inserito con ID: " . $newRecordId . "\n" .
        "=== FINE CREAZIONE SUBSCRIPTION ===\n\n", 
        FILE_APPEND
    );
                $insertStmt->bind_param('iis', $order['user_id'], $plan_id, $transactionId);
                $insertStmt->execute();
                $insertStmt->close();
                
                // Aggiorna il piano corrente nell'utente
                $updateUserStmt = $conn->prepare("
                    UPDATE users SET current_plan_id = ? WHERE id = ?
                ");
                $updateUserStmt->bind_param('ii', $plan_id, $order['user_id']);
                $updateUserStmt->execute();
                $updateUserStmt->close();
                
                $conn->commit();
                
                // Ottieni l'abbonamento aggiornato
                require_once 'subscription_limits.php';
                $updatedSubscription = getUserSubscription($order['user_id']);
                
                sendResponse(true, ['subscription' => $updatedSubscription], 'Abbonamento aggiornato con successo');
                
            } catch (Exception $e) {
                $conn->rollback();
                sendResponse(false, null, 'Errore durante l\'aggiornamento dell\'abbonamento: ' . $e->getMessage(), 500);
            }
        } else if ($order['type'] === 'donation') {
            // Registra la donazione
            try {
                $stmt = $conn->prepare("
                    INSERT INTO donations 
                    (user_id, amount, message, display_name, payment_provider, payment_reference, platform)
                    VALUES (?, ?, ?, ?, 'paypal', ?, 'android')
                ");
                
                $stmt->bind_param('idsss', 
                    $order['user_id'], 
                    $order['amount'], 
                    $order['message'], 
                    $order['display_name'], 
                    $transactionId
                );
                
                if ($stmt->execute()) {
                    sendResponse(true, null, 'Donazione registrata con successo');
                } else {
                    throw new Exception($stmt->error);
                }
                
                $stmt->close();
            } catch (Exception $e) {
                sendResponse(false, null, 'Errore nella registrazione della donazione: ' . $e->getMessage(), 500);
            }
        } else {
            sendResponse(false, null, 'Tipo di pagamento non valido', 400);
        }
    } catch (Exception $e) {
        sendResponse(false, null, 'Errore: ' . $e->getMessage(), 500);
    }
}
?>