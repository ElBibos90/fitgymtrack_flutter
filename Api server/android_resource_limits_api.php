<?php
// android_resource_limits_api.php - API per verificare i limiti delle risorse per l'app Android

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

// Ottieni l'abbonamento attuale dell'utente 
function getCurrentSubscription($userId) {
    global $conn;
    
    // Ottieni l'abbonamento attivo dell'utente
    $stmt = $conn->prepare("
        SELECT us.*, sp.name as plan_name, sp.price, sp.max_workouts, 
               sp.max_custom_exercises, sp.advanced_stats, 
               sp.cloud_backup, sp.no_ads
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ? AND us.status = 'active' 
        ORDER BY us.end_date DESC 
        LIMIT 1
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    // Se non c'è un abbonamento attivo, restituisci il piano Free
    $freePlanStmt = $conn->prepare("
        SELECT * FROM subscription_plans WHERE name = 'Free' LIMIT 1
    ");
    
    $freePlanStmt->execute();
    $freePlanResult = $freePlanStmt->get_result();
    
    if ($freePlanResult->num_rows > 0) {
        $freePlan = $freePlanResult->fetch_assoc();
        
        return [
            'user_id' => $userId,
            'plan_id' => $freePlan['id'],
            'plan_name' => $freePlan['name'],
            'status' => 'active',
            'price' => $freePlan['price'],
            'max_workouts' => $freePlan['max_workouts'],
            'max_custom_exercises' => $freePlan['max_custom_exercises'],
            'advanced_stats' => $freePlan['advanced_stats'],
            'cloud_backup' => $freePlan['cloud_backup'],
            'no_ads' => $freePlan['no_ads']
        ];
    }
    
    return null;
}

// Verifica i limiti per una risorsa specifica
function checkResourceLimits($userId, $resourceType) {
    global $conn;
    
    // Ottieni l'abbonamento dell'utente
    $subscription = getCurrentSubscription($userId);
    
    if (!$subscription) {
        return [
            'success' => false,
            'message' => 'Nessun abbonamento trovato',
            'limit_reached' => true
        ];
    }
    
    // Se l'utente ha un piano a pagamento e il limite è NULL (illimitato)
    if ($subscription['price'] > 0 && $subscription[$resourceType] === null) {
        return [
            'success' => true,
            'message' => 'Nessun limite per questo piano',
            'limit_reached' => false,
            'current_count' => 0,
            'max_allowed' => null,
            'remaining' => null
        ];
    }
    
    // Controllo specifico per tipo di risorsa
    switch ($resourceType) {
        case 'max_workouts':
            // Conta le schede attive dell'utente
            $stmt = $conn->prepare("
                SELECT COUNT(*) as count 
                FROM schede s
                INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
                WHERE uwa.user_id = ? AND uwa.active = 1
            ");
            break;
            
        case 'max_custom_exercises':
            // Conta gli esercizi creati dall'utente
            $stmt = $conn->prepare("
                SELECT COUNT(*) as count 
                FROM esercizi 
                WHERE created_by_user_id = ?
            ");
            break;
            
        default:
            return [
                'success' => false,
                'message' => 'Tipo di risorsa non valido',
                'limit_reached' => true
            ];
    }
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $count = $result->fetch_assoc()['count'];
    
    $limit = $subscription[$resourceType];
    
    // Converti il limite a intero se è stringa (per evitare problemi di confronto)
    if (is_string($limit)) {
        $limit = intval($limit);
    }
    
    return [
        'success' => true,
        'current_count' => $count,
        'max_allowed' => $limit,
        'limit_reached' => $count >= $limit,
        'remaining' => max(0, $limit - $count)
    ];
}

// Verifica l'autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);
$user = validateAuthToken($conn, $token);

if (!$user) {
    handleError('Utente non autenticato', 401);
}

// Gestione delle richieste in base al metodo e ai parametri
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (!isset($_GET['resource_type'])) {
        handleError('Tipo di risorsa non specificato', 400);
    }
    
    $resourceType = $_GET['resource_type'];
    
    // Verifica se il tipo di risorsa è valido
    if ($resourceType !== 'max_workouts' && $resourceType !== 'max_custom_exercises') {
        handleError('Tipo di risorsa non valido. Valori consentiti: max_workouts, max_custom_exercises', 400);
    }
    
    $result = checkResourceLimits($user['user_id'], $resourceType);
    
    if ($result['success']) {
        handleResponse($result);
    } else {
        handleError($result['message'], 400);
    }
} else {
    handleError('Metodo non supportato', 405);
}

$conn->close();
?>
