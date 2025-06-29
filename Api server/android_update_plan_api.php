<?php
// android_update_plan_api.php - API per aggiornare l'abbonamento dell'utente nell'app Android

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

// Gestione della risposta API
function handleResponse($data, $message = 'Success') {
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

// Funzione per aggiornare il piano dell'utente
function updateUserPlan($userId, $planId) {
    global $conn;
    
    // Verifica se il piano esiste
    $planStmt = $conn->prepare("SELECT * FROM subscription_plans WHERE id = ?");
    $planStmt->bind_param('i', $planId);
    $planStmt->execute();
    $planResult = $planStmt->get_result();
    
    if ($planResult->num_rows === 0) {
        return [
            'success' => false,
            'message' => 'Il piano richiesto non esiste'
        ];
    }
    
    $plan = $planResult->fetch_assoc();
    
    // Inizia la transazione
    $conn->begin_transaction();
    
    try {
        // Annulla abbonamenti attivi esistenti
        $cancelStmt = $conn->prepare("
            UPDATE user_subscriptions 
            SET status = 'cancelled', end_date = NOW(), updated_at = NOW()
            WHERE user_id = ? AND status = 'active'
        ");
        
        $cancelStmt->bind_param('i', $userId);
        $cancelStmt->execute();
        
        // Per il piano gratuito, non serve un riferimento di pagamento
        $paymentProvider = null;
        $paymentReference = null;
        
        // Crea il nuovo abbonamento
        $insertStmt = $conn->prepare("
            INSERT INTO user_subscriptions 
            (user_id, plan_id, status, start_date, end_date, auto_renew, payment_provider, payment_reference)
            VALUES (?, ?, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 1 MONTH), 1, ?, ?)
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
        
        // Conferma le modifiche
        $conn->commit();
        
        return [
            'success' => true,
            'message' => 'Piano aggiornato con successo',
            'plan_name' => $plan['name']
        ];
    } catch (Exception $e) {
        // Annulla le modifiche in caso di errore
        $conn->rollback();
        
        return [
            'success' => false,
            'message' => 'Errore durante l\'aggiornamento del piano: ' . $e->getMessage()
        ];
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

// Verifica che l'input sia valido
if ($input === null) {
    handleError('Dati JSON non validi', 400);
}

// Verifica che il plan_id sia stato fornito
if (!isset($input['plan_id'])) {
    handleError('ID piano non specificato', 400);
}

$planId = intval($input['plan_id']);

// Aggiorna il piano dell'utente
$result = updateUserPlan($user['user_id'], $planId);

if ($result['success']) {
    handleResponse($result, $result['message']);
} else {
    handleError($result['message'], 400);
}

$conn->close();
?>
