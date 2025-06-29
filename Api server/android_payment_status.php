<?php
// android_payment_status.php - API per verificare lo stato dei pagamenti PayPal per l'app Android

// Impostazione esplicita degli header CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Max-Age: 3600");

// Gestione richieste OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit; // Termina qui per le richieste OPTIONS
}

// Includi configurazione e funzioni di autenticazione
include 'config.php';
require_once 'auth_functions.php';
require_once 'paypal_config.php';

// Impostazione dell'output come JSON
header('Content-Type: application/json');

// Funzione per gestire errori e restituire JSON
function handleError($message, $errorCode = 500) {
    http_response_code($errorCode);
    echo json_encode([
        'success' => false, 
        'message' => $message
    ]);
    exit;
}

// Funzione per generare una risposta JSON di successo
function handleResponse($data, $message = 'Success') {
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

// Funzione per ottenere un token di accesso PayPal
function getPayPalAccessToken() {
    $curl = curl_init();
    
    curl_setopt_array($curl, [
        CURLOPT_URL => PAYPAL_API_URL . "/v1/oauth2/token",
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_USERPWD => PAYPAL_CLIENT_ID . ":" . PAYPAL_SECRET,
        CURLOPT_POSTFIELDS => "grant_type=client_credentials",
        CURLOPT_HTTPHEADER => [
            "Content-Type: application/x-www-form-urlencoded"
        ]
    ]);
    
    $response = curl_exec($curl);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
        return [
            'success' => false,
            'message' => "cURL Error #:" . $err
        ];
    }
    
    $result = json_decode($response, true);
    
    if (!isset($result['access_token'])) {
        return [
            'success' => false,
            'message' => "Impossibile ottenere il token di accesso PayPal",
            'response' => $result
        ];
    }
    
    return [
        'success' => true,
        'access_token' => $result['access_token']
    ];
}

// Funzione per verificare lo stato di un ordine PayPal
function checkPayPalOrderStatus($paypalOrderId) {
    $tokenResult = getPayPalAccessToken();
    
    if (!$tokenResult['success']) {
        return $tokenResult;
    }
    
    $accessToken = $tokenResult['access_token'];
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
        CURLOPT_URL => PAYPAL_API_URL . "/v2/checkout/orders/" . $paypalOrderId,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            "Content-Type: application/json",
            "Authorization: Bearer " . $accessToken
        ]
    ]);
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
        return [
            'success' => false,
            'message' => "cURL Error #:" . $err
        ];
    }
    
    // Verifica il codice di risposta HTTP
    if ($httpCode >= 400) {
        return [
            'success' => false,
            'message' => "Errore nella verifica dell'ordine PayPal: " . $httpCode,
            'response' => json_decode($response, true)
        ];
    }
    
    $result = json_decode($response, true);
    
    return [
        'success' => true,
        'paypal_order_id' => $paypalOrderId,
        'status' => $result['status'],
        'details' => $result
    ];
}

function capturePayPalOrder($paypalOrderId) {
    $tokenResult = getPayPalAccessToken();
    
    if (!$tokenResult['success']) {
        return $tokenResult;
    }
    
    $accessToken = $tokenResult['access_token'];
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
        CURLOPT_URL => PAYPAL_API_URL . "/v2/checkout/orders/" . $paypalOrderId . "/capture",
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => "POST",
        CURLOPT_HTTPHEADER => [
            "Content-Type: application/json",
            "Authorization: Bearer " . $accessToken
        ]
    ]);
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $err = curl_error($curl);
    
    curl_close($curl);
    
    if ($err) {
        return [
            'success' => false,
            'message' => "cURL Error #:" . $err
        ];
    }
    
    // Verifica il codice di risposta HTTP
    if ($httpCode >= 400) {
        return [
            'success' => false,
            'message' => "Errore nella capture dell'ordine PayPal: " . $httpCode,
            'response' => json_decode($response, true)
        ];
    }
    
    $result = json_decode($response, true);
    
    return [
        'success' => true,
        'paypal_order_id' => $paypalOrderId,
        'status' => $result['status'],
        'details' => $result
    ];
}

// Funzione per verificare lo stato di un ordine interno tramite PayPal
function checkOrderStatus($orderId) {
    global $conn;
    
    // Recupera l'ordine dal database
    $stmt = $conn->prepare("
        SELECT * FROM paypal_orders
        WHERE order_id = ? OR paypal_order_id = ?
    ");
    
    $stmt->bind_param('ss', $orderId, $orderId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        return [
            'success' => false,
            'message' => "Ordine non trovato"
        ];
    }
    
    $order = $result->fetch_assoc();
    
    // Se l'ordine è già completato o annullato, restituisci lo stato dal database
    if ($order['status'] === 'completed' || $order['status'] === 'cancelled') {
        return [
            'success' => true,
            'order_id' => $order['order_id'],
            'paypal_order_id' => $order['paypal_order_id'],
            'status' => $order['status'],
            'amount' => $order['amount'],
            'type' => $order['type'],
            'plan_id' => $order['plan_id']
        ];
    }
    
    // Verifica lo stato attuale con PayPal
    $paypalResult = checkPayPalOrderStatus($order['paypal_order_id']);
    
    if (!$paypalResult['success']) {
        return $paypalResult;
    }
    
    $paypalStatus = $paypalResult['status'];
    $dbStatus = 'pending';
    
    // Mappa lo stato PayPal allo stato del database
if ($paypalStatus === 'COMPLETED') {
    $dbStatus = 'completed';
    
    // Se l'ordine è completato ed è un abbonamento, aggiorna l'abbonamento dell'utente
    if ($order['type'] === 'subscription' && $order['plan_id'] !== null) {
        updateUserSubscription($order['user_id'], $order['plan_id'], $order['paypal_order_id']);
    }
} elseif ($paypalStatus === 'APPROVED') {
    // Esegui la capture se lo stato è APPROVED
    $captureResult = capturePayPalOrder($order['paypal_order_id']);
    
    if ($captureResult['success'] && $captureResult['status'] === 'COMPLETED') {
        $dbStatus = 'completed';
        
        // Aggiorna l'abbonamento solo dopo una capture riuscita
        if ($order['type'] === 'subscription' && $order['plan_id'] !== null) {
            updateUserSubscription($order['user_id'], $order['plan_id'], $order['paypal_order_id']);
        }
    }
}
    
    // Aggiorna lo stato nel database se è cambiato
    if ($dbStatus !== $order['status']) {
        $updateStmt = $conn->prepare("
            UPDATE paypal_orders
            SET status = ?
            WHERE id = ?
        ");
        
        $updateStmt->bind_param('si', $dbStatus, $order['id']);
        $updateStmt->execute();
    }
    
    return [
        'success' => true,
        'order_id' => $order['order_id'],
        'paypal_order_id' => $order['paypal_order_id'],
        'status' => $dbStatus,
        'amount' => $order['amount'],
        'type' => $order['type'],
        'plan_id' => $order['plan_id'],
        'paypal_status' => $paypalStatus
    ];
}

// Funzione per aggiornare l'abbonamento dell'utente
function updateUserSubscription($userId, $planId, $paymentReference) {
    global $conn;
    
    // Annulla abbonamenti attivi esistenti
    $cancelStmt = $conn->prepare("
        UPDATE user_subscriptions 
        SET status = 'cancelled', end_date = NOW(), updated_at = NOW()
        WHERE user_id = ? AND status = 'active'
    ");
    
    $cancelStmt->bind_param('i', $userId);
    $cancelStmt->execute();
    
    // Crea il nuovo abbonamento
    $paymentProvider = 'paypal';
    
    $insertStmt = $conn->prepare("
        INSERT INTO user_subscriptions 
        (user_id, plan_id, status, start_date, end_date, auto_renew, payment_provider, payment_reference, last_payment_date)
        VALUES (?, ?, 'active', NOW(), CONCAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ' 23:59:59'), 1, ?, ?, NOW())
    ");
    
    $insertStmt->bind_param('iiss', $userId, $planId, $paymentProvider, $paymentReference);
    $insertStmt->execute();
    
    // Aggiorna il piano attuale nell'utente
    $updateUserStmt = $conn->prepare("
        UPDATE users SET current_plan_id = ?, active = 1
        WHERE id = ?
    ");
    
    $updateUserStmt->bind_param('ii', $planId, $userId);
    $updateUserStmt->execute();
    
    return true;
}

// Verifica il metodo della richiesta
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    handleError('Metodo non supportato. Utilizza GET.', 405);
}

// Verifica l'autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);
$user = validateAuthToken($conn, $token);

if (!$user) {
    handleError('Utente non autenticato', 401);
}

// Verifica che l'order_id sia fornito
if (!isset($_GET['order_id'])) {
    handleError('ID ordine non specificato', 400);
}

$orderId = $_GET['order_id'];

// Verifica lo stato dell'ordine
$result = checkOrderStatus($orderId);

if ($result['success']) {
    handleResponse($result, 'Stato ordine recuperato con successo');
} else {
    handleError($result['message'], 400);
}

$conn->close();
?>
