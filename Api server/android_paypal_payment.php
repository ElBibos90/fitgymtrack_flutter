<?php
// android_paypal_payment.php - API per inizializzare i pagamenti PayPal per l'app Android

// Impostazione esplicita degli header CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
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

// Funzione per generare un identificatore unico
function generateOrderId() {
    return uniqid('ORD_', true);
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

// Funzione per creare un ordine PayPal
function createPayPalOrder($amount, $description, $orderId) {
    $tokenResult = getPayPalAccessToken();
    
    if (!$tokenResult['success']) {
        return $tokenResult;
    }
    
    $accessToken = $tokenResult['access_token'];
    
    // Crea un array della richiesta per l'ordine PayPal
    $orderRequest = [
        'intent' => 'CAPTURE',
        'purchase_units' => [
            [
                'reference_id' => $orderId,
                'description' => $description,
                'amount' => [
                    'currency_code' => 'EUR',
                    'value' => number_format($amount, 2, '.', '')
                ]
            ]
        ],
        'application_context' => [
            'brand_name' => 'FitGymTrack',
            'landing_page' => 'NO_PREFERENCE',
            'user_action' => 'PAY_NOW',
            'return_url' => 'fitgymtrack://payment/success',
            'cancel_url' => 'fitgymtrack://payment/cancel'
        ]
    ];
    
    $curl = curl_init();
    
    curl_setopt_array($curl, [
        CURLOPT_URL => PAYPAL_API_URL . "/v2/checkout/orders",
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => "POST",
        CURLOPT_POSTFIELDS => json_encode($orderRequest),
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
    
    // Decodifica la risposta
    $result = json_decode($response, true);
    
    // Verifica il codice di risposta HTTP
    if ($httpCode >= 400) {
        return [
            'success' => false,
            'message' => "Errore nella creazione dell'ordine PayPal: " . $httpCode,
            'details' => $result
        ];
    }
    
    // Verifica che l'ordine sia stato creato
    if (!isset($result['id'])) {
        return [
            'success' => false,
            'message' => "ID ordine PayPal mancante nella risposta",
            'response' => $result
        ];
    }
    
    // Estrai l'URL di approvazione
    $approvalUrl = null;
    if (isset($result['links'])) {
        foreach ($result['links'] as $link) {
            if ($link['rel'] === 'approve') {
                $approvalUrl = $link['href'];
                break;
            }
        }
    }
    
    if (!$approvalUrl) {
        return [
            'success' => false,
            'message' => "URL di approvazione mancante nella risposta",
            'response' => $result
        ];
    }
    
    return [
        'success' => true,
        'order_id' => $orderId,
        'paypal_order_id' => $result['id'],
        'approval_url' => $approvalUrl
    ];
}

// Funzione per salvare l'ordine nel database
function saveOrder($userId, $amount, $type, $planId, $message, $displayName, $orderId, $paypalOrderId) {
    global $conn;
    
    $stmt = $conn->prepare("
        INSERT INTO paypal_orders 
        (order_id, paypal_order_id, user_id, amount, type, plan_id, message, display_name, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ");
    
    $stmt->bind_param('ssidssis', $orderId, $paypalOrderId, $userId, $amount, $type, $planId, $message, $displayName);
    
    if ($stmt->execute()) {
        return true;
    } else {
        return false;
    }
}

// Verifica che la richiesta sia POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    handleError('Metodo non supportato. Utilizza POST.', 405);
}

// Verifica l'autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);
$user = validateAuthToken($conn, $token);

if (!$user) {
    handleError('Utente non autenticato', 401);
}

// Leggi i dati inviati
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

// Verifica la validità dell'input
if ($input === null) {
    handleError('Dati JSON non validi', 400);
}

// Verifica i campi obbligatori
if (!isset($input['amount']) || !is_numeric($input['amount']) || $input['amount'] <= 0) {
    handleError('Importo non valido o mancante', 400);
}

// Imposta valori predefiniti per i campi opzionali
$type = isset($input['type']) ? $input['type'] : 'subscription';
$planId = isset($input['plan_id']) ? intval($input['plan_id']) : null;
$message = isset($input['message']) ? $input['message'] : '';
$displayName = isset($input['display_name']) ? (bool)$input['display_name'] : true;

// Genera un ID ordine interno
$orderId = generateOrderId();

// Prepara la descrizione del pagamento
$description = "FitGymTrack - ";
if ($type === 'subscription') {
    $description .= "Abbonamento Premium";
} elseif ($type === 'donation') {
    $description .= "Donazione";
} else {
    $description .= "Pagamento";
}

// Crea l'ordine PayPal
$paypalResult = createPayPalOrder($input['amount'], $description, $orderId);

if (!$paypalResult['success']) {
    handleError('Errore durante la creazione dell\'ordine PayPal: ' . $paypalResult['message'], 500);
}

// Salva l'ordine nel database
$saveResult = saveOrder(
    $user['user_id'],
    $input['amount'],
    $type,
    $planId,
    $message,
    $displayName ? 1 : 0,
    $orderId,
    $paypalResult['paypal_order_id']
);

if (!$saveResult) {
    handleError('Errore durante il salvataggio dell\'ordine nel database', 500);
}

// Prepara la risposta
$response = [
    'order_id' => $orderId,
    'paypal_order_id' => $paypalResult['paypal_order_id'],
    'approval_url' => $paypalResult['approval_url']
];

// Invia la risposta
handleResponse($response, 'Ordine PayPal creato con successo');
?>
