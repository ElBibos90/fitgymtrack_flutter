<?php
// paypal_payment.php - Gestisce l'inizializzazione di un pagamento PayPal

// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Includi le configurazioni e le funzioni necessarie
include 'config.php';
include 'paypal_config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

// Funzione per il logging di debug
function debugLog($message, $data = null) {
    $log_file = __DIR__ . '/paypal_debug.log';
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

// Funzione per gestire gli errori e restituire JSON appropriato
function handleError($message, $errorCode = 500) {
    //debugLog("ERRORE: {$message}");
    header('Content-Type: application/json');
    http_response_code($errorCode);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
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

// Funzione per creare un ordine PayPal
function createPayPalOrder($accessToken, $amount, $currency, $description, $returnUrl, $cancelUrl) {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, PAYPAL_API_URL . '/v2/checkout/orders');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POST, 1);
    
    $payload = json_encode([
        'intent' => 'CAPTURE',
        'purchase_units' => [
            [
                'amount' => [
                    'currency_code' => $currency,
                    'value' => number_format($amount, 2, '.', '')
                ],
                'description' => $description
            ]
        ],
        'application_context' => [
            'return_url' => $returnUrl,
            'cancel_url' => $cancelUrl,
            'brand_name' => 'FitGymTrack',
            'locale' => 'it-IT',
            'user_action' => 'PAY_NOW',
            'payment_method' => [
                'payee_preferred' => 'IMMEDIATE_PAYMENT_REQUIRED'
            ]
        ]
    ]);
    
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    
    $headers = array();
    $headers[] = 'Content-Type: application/json';
    $headers[] = 'Authorization: Bearer ' . $accessToken;
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $result = curl_exec($ch);
    
    if (curl_errno($ch)) {
        throw new Exception('Errore Curl: ' . curl_error($ch));
    }
    
    curl_close($ch);
    return json_decode($result, true);
}

// Gestisci la richiesta
try {
    // Verifica che la richiesta sia POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        handleError('Metodo non consentito', 405);
    }
    
    // Leggi l'input JSON
    $inputJson = file_get_contents('php://input');
    if (!$inputJson) {
        handleError('Nessun dato ricevuto', 400);
    }
    
    $input = json_decode($inputJson, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        handleError('JSON non valido: ' . json_last_error_msg(), 400);
    }
    
    if (!isset($input['amount'], $input['type'])) {
        handleError('Dati mancanti o non validi', 400);
    }
    
    $amount = floatval($input['amount']);
    $type = $input['type']; // 'subscription' o 'donation'
    
    // Verifica che l'importo sia valido
    if ($amount <= 0) {
        handleError('Importo non valido', 400);
    }
    
    // Verifica l'autenticazione dell'utente
    $authHeader = getAuthorizationHeader();
    $token = str_replace('Bearer ', '', $authHeader);
    $user = validateAuthToken($conn, $token);
    
    if (!$user) {
        handleError('Utente non autenticato', 401);
    }
    
    $userId = $user['user_id'];
    
    // Crea una tabella per tracciare gli ordini se non esiste
    $createTableSql = "
        CREATE TABLE IF NOT EXISTS paypal_orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_id VARCHAR(255) NOT NULL,
            paypal_order_id VARCHAR(255) NULL,
            user_id INT NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            type VARCHAR(50) NOT NULL,
            plan_id INT NULL,
            message TEXT NULL,
            display_name TINYINT(1) DEFAULT 1,
            status VARCHAR(50) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ";
    
    $conn->query($createTableSql);
    
    // Genera un ID ordine univoco
    $orderId = uniqid('order_');
    
    // Prepara i dati aggiuntivi in base al tipo di pagamento
    $planId = null;
    $message = null;
    $displayName = 1;
    $description = '';
    
    if ($type === 'subscription') {
        // Gestione abbonamento
        if (!isset($input['plan_id'])) {
            handleError('ID piano mancante', 400);
        }
        
        $planId = intval($input['plan_id']);
        $description = 'Abbonamento FitGymTrack - Piano Base';
    } else if ($type === 'donation') {
        // Gestione donazione
        $message = isset($input['message']) ? $input['message'] : null;
        $displayName = isset($input['display_name']) ? ($input['display_name'] ? 1 : 0) : 1;
        $description = 'Donazione a FitGymTrack';
    } else {
        handleError('Tipo di pagamento non valido', 400);
    }
    
    /*debugLog("Creazione ordine", [
        'orderId' => $orderId,
        'userId' => $userId,
        'amount' => $amount,
        'type' => $type,
        'planId' => $planId,
        'message' => $message,
        'displayName' => $displayName
    ]);*/
    
    // Salva i dati dell'ordine nel database
    $stmt = $conn->prepare("
        INSERT INTO paypal_orders 
        (order_id, user_id, amount, type, plan_id, message, display_name) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->bind_param(
        'sidssis', 
        $orderId, 
        $userId, 
        $amount, 
        $type, 
        $planId, 
        $message, 
        $displayName
    );
    
    if (!$stmt->execute()) {
        //debugLog("Errore inserimento ordine: " . $stmt->error);
        handleError('Errore nel salvataggio dell\'ordine: ' . $stmt->error);
    }
    
    $stmt->close();
    
    // Prepara gli URL di ritorno con l'ID ordine
    $returnUrl = PAYPAL_RETURN_URL . $orderId;
    $cancelUrl = PAYPAL_CANCEL_URL . $orderId;
    
    /*debugLog("URL di ritorno", [
        'returnUrl' => $returnUrl,
        'cancelUrl' => $cancelUrl
    ]);*/
    
    // Ottieni il token di accesso
    $accessToken = getPayPalAccessToken();
    
    // Crea l'ordine PayPal
    $orderResponse = createPayPalOrder($accessToken, $amount, 'EUR', $description, $returnUrl, $cancelUrl);
    
    //debugLog("Risposta PayPal", $orderResponse);
    
    // Verifica il risultato
    if (!isset($orderResponse['id'], $orderResponse['links'])) {
        handleError('Errore nella creazione dell\'ordine PayPal');
    }
    
    // Aggiorna l'ID ordine PayPal nel database
    $updateStmt = $conn->prepare("UPDATE paypal_orders SET paypal_order_id = ? WHERE order_id = ?");
    $updateStmt->bind_param('ss', $orderResponse['id'], $orderId);
    $updateStmt->execute();
    $updateStmt->close();
    
    // Trova il link di approvazione
    $approvalUrl = null;
    foreach ($orderResponse['links'] as $link) {
        if ($link['rel'] === 'approve') {
            $approvalUrl = $link['href'];
            break;
        }
    }
    
    if (!$approvalUrl) {
        handleError('Link di approvazione PayPal non trovato');
    }
    
    // Restituisci l'URL di approvazione e l'ID dell'ordine
    echo json_encode([
        'success' => true,
        'approval_url' => $approvalUrl,
        'order_id' => $orderId,
        'paypal_order_id' => $orderResponse['id']
    ]);
} catch (Exception $e) {
    //debugLog("Eccezione: " . $e->getMessage());
    handleError('Errore: ' . $e->getMessage());
}