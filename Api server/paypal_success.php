<?php
// paypal_success.php - Gestisce il completamento di un pagamento PayPal

// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Includi le configurazioni e le funzioni necessarie
include 'config.php';
include 'paypal_config.php';
require_once 'auth_functions.php';
require_once 'subscription_limits.php';

// Funzione per il logging di debug
function debugLog($message, $data = null) {
    $log_file = __DIR__ . '/paypal_success_debug.log';
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

// Funzione per gestire gli errori e reindirizzare alla pagina di errore
function handleError($message, $errorCode = 500) {
    //debugLog("ERRORE: {$message}");
    header("Location: " . FRONTEND_URL . "/api/payment-error.php?message=" . urlencode($message));
    exit;
}

// Funzione per catturare il pagamento PayPal
function capturePayPalOrder($accessToken, $paypalOrderId) {
    // Log per debug
    /*debugLog("Tentativo di cattura pagamento", [
        'paypalOrderId' => $paypalOrderId
    ]);*/
    
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
    
    /*debugLog("Risposta cattura pagamento", [
        'httpCode' => $httpCode,
        'result' => $result
    ]);*/
    
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

// Funzione per ottenere un token di accesso OAuth 2.0
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

try {
    // Log dei parametri ricevuti
    /*debugLog("Inizio elaborazione pagamento completato", [
        'GET' => $_GET,
        'POST' => $_POST
    ]);*/
    
    // Ottieni l'ID ordine dall'URL
    $orderId = isset($_GET['order_id']) ? $_GET['order_id'] : null;
    
    if (!$orderId) {
        //debugLog("Nessun ID ordine trovato nell'URL");
        handleError('Nessun ordine in sospeso trovato');
    }
    
    // Recupera i dati dell'ordine dal database
    $stmt = $conn->prepare("SELECT * FROM paypal_orders WHERE order_id = ? AND status = 'pending'");
    $stmt->bind_param('s', $orderId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        //debugLog("Nessun ordine trovato con ID: {$orderId}");
        handleError('Ordine non trovato o già elaborato');
    }
    
    $order = $result->fetch_assoc();
    $stmt->close();
    
    //debugLog("Ordine trovato", $order);
    
    // Ottieni il token di accesso
    $accessToken = getPayPalAccessToken();
    
    // Cattura il pagamento
    $captureResponse = capturePayPalOrder($accessToken, $order['paypal_order_id']);
    
    // Verifica il risultato
    if (!isset($captureResponse['status']) || $captureResponse['status'] !== 'COMPLETED') {
        //debugLog("Il pagamento non è stato completato con successo", $captureResponse);
        handleError('Il pagamento non è stato completato con successo');
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
            
            // Crea il nuovo abbonamento
            // Verifica che il campo plan_id sia un intero valido e non nullo
            if (empty($order['plan_id']) || !is_numeric($order['plan_id'])) {
                //debugLog("ERRORE: plan_id non valido", $order['plan_id']);
                // Usa un valore di default o gestisci l'errore
                $plan_id = 3; // Assumi che sia il piano Premium (ID 3)
            } else {
                $plan_id = intval($order['plan_id']);
            }

            // Assicurati di usare $plan_id invece di $order['plan_id'] in tutte le query successive
$insertStmt = $conn->prepare("
    INSERT INTO user_subscriptions 
    (user_id, plan_id, status, start_date, end_date, payment_reference, payment_provider, auto_renew) 
    VALUES (?, ?, 'active', NOW(), CONCAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ' 23:59:59'), ?, 'paypal', 1)
");
            $insertStmt->bind_param('iis', $order['user_id'], $plan_id, $transactionId);
            $insertStmt->execute();
            $insertStmt->close();
            
            // Aggiorna il piano corrente nell'utente
            $updateUserStmt = $conn->prepare("
                UPDATE users SET current_plan_id = ? WHERE id = ?
            ");
            $updateUserStmt->bind_param('ii', $order['plan_id'], $order['user_id']);
            $updateUserStmt->execute();
            $updateUserStmt->close();
            
            $conn->commit();
            
            // Reindirizza alla pagina di successo
            /*debugLog("Aggiornamento piano completato con successo", [
                'userId' => $order['user_id'],
                'planId' => $order['plan_id']
            ]);*/
            
            header("Location: " . FRONTEND_URL . "/standalone/subscription?success=true");
        } catch (Exception $e) {
            $conn->rollback();
            /*debugLog("Errore nell'aggiornamento dell'abbonamento", [
                'error' => $e->getMessage()
            ]);*/
            handleError('Errore durante l\'aggiornamento dell\'abbonamento: ' . $e->getMessage());
        }
    } else if ($order['type'] === 'donation') {
        // Registra la donazione
        try {
            $stmt = $conn->prepare("
                INSERT INTO donations 
                (user_id, amount, message, display_name, payment_provider, payment_reference)
                VALUES (?, ?, ?, ?, 'paypal', ?)
            ");
            
            $stmt->bind_param('idsss', 
                $order['user_id'], 
                $order['amount'], 
                $order['message'], 
                $order['display_name'], 
                $transactionId
            );
            
            if ($stmt->execute()) {
                /*debugLog("Donazione registrata con successo", [
                    'userId' => $order['user_id'],
                    'amount' => $order['amount']
                ]);*/
                
                // Reindirizza alla pagina di successo
                header("Location: " . FRONTEND_URL);
            } else {
                throw new Exception($stmt->error);
            }
            
            $stmt->close();
        } catch (Exception $e) {
            /*debugLog("Errore nella registrazione della donazione", [
                'error' => $e->getMessage()
            ]);*/
            handleError('Errore nella registrazione della donazione: ' . $e->getMessage());
        }
    } else {
        /*debugLog("Tipo di pagamento non valido", [
            'type' => $order['type']
        ]);*/
        handleError('Tipo di pagamento non valido');
    }
} catch (Exception $e) {
    /*debugLog("Eccezione generale", [
        'error' => $e->getMessage()
    ]);*/
    handleError('Errore: ' . $e->getMessage());
}