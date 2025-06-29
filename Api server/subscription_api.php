<?php
// subscription_api.php - API per la gestione degli abbonamenti (MODIFICATA per controllo scadenza)

// Impostazione esplicita degli header CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Max-Age: 3600");

// Gestione richieste OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit; // Termina qui per le richieste OPTIONS
}

ini_set('display_errors', 0);
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

// Funzione per gestire errori e restituire JSON
function handleError($message, $errorCode = 500) {
    header('Content-Type: application/json');
    http_response_code($errorCode);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

// NUOVA FUNZIONE: Controlla e aggiorna le subscription scadute
function checkAndUpdateExpiredSubscriptions($userId) {
    global $conn;
    
    // Trova tutte le subscription attive ma scadute per questo utente
    $stmt = $conn->prepare("
        SELECT id, plan_id, end_date 
        FROM user_subscriptions 
        WHERE user_id = ? AND status = 'active' AND end_date <= NOW()
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $expiredCount = 0;
    while ($row = $result->fetch_assoc()) {
        // Aggiorna lo status a 'expired'
        $updateStmt = $conn->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = NOW() 
            WHERE id = ?
        ");
        $updateStmt->bind_param('i', $row['id']);
        $updateStmt->execute();
        $expiredCount++;
    }
    
    if ($expiredCount > 0) {
        // Se ci sono subscription scadute, aggiorna l'utente al piano Free
        $freePlanStmt = $conn->prepare("
            SELECT id FROM subscription_plans WHERE name = 'Free' LIMIT 1
        ");
        $freePlanStmt->execute();
        $freePlanResult = $freePlanStmt->get_result();
        
        if ($freePlanResult->num_rows > 0) {
            $freePlan = $freePlanResult->fetch_assoc();
            
            // Aggiorna il piano corrente dell'utente
            $updateUserStmt = $conn->prepare("
                UPDATE users SET current_plan_id = ? WHERE id = ?
            ");
            $updateUserStmt->bind_param('ii', $freePlan['id'], $userId);
            $updateUserStmt->execute();
        }
    }
    
    return $expiredCount;
}

// Ottieni gli abbonamenti disponibili
function getAvailablePlans() {
    global $conn;
    
    $stmt = $conn->prepare("SELECT * FROM subscription_plans ORDER BY price ASC");
    $stmt->execute();
    $result = $stmt->get_result();
    
    $plans = [];
    while ($row = $result->fetch_assoc()) {
        $plans[] = $row;
    }
    
    return $plans;
}

// MODIFICATA: Ottieni l'abbonamento attuale dell'utente con controllo scadenza
function getUserSubscription($userId) {
    global $conn;
    
    // PRIMA: Controlla e aggiorna eventuali subscription scadute
    $expiredCount = checkAndUpdateExpiredSubscriptions($userId);
    
    // MODIFICATA: Query che controlla sia status = 'active' CHE end_date > NOW()
    $stmt = $conn->prepare("
        SELECT us.*, sp.name as plan_name, sp.max_workouts, sp.max_custom_exercises, 
               sp.advanced_stats, sp.cloud_backup, sp.no_ads, sp.price,
               CASE 
                   WHEN us.end_date <= NOW() THEN 'expired'
                   ELSE us.status 
               END as computed_status,
               DATEDIFF(us.end_date, NOW()) as days_remaining
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ? AND us.status = 'active' AND us.end_date > NOW()
        ORDER BY us.end_date DESC 
        LIMIT 1
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $subscription = $result->fetch_assoc();
        
        // Aggiungiamo i conteggi attuali
        // Conteggio schede
        $workoutStmt = $conn->prepare("
            SELECT COUNT(*) as count 
            FROM schede s
            INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
            WHERE uwa.user_id = ? AND uwa.active = 1
        ");
        $workoutStmt->bind_param('i', $userId);
        $workoutStmt->execute();
        $workoutResult = $workoutStmt->get_result();
        $subscription['current_count'] = $workoutResult->fetch_assoc()['count'];
        
        // Conteggio esercizi personalizzati
        $exerciseStmt = $conn->prepare("
            SELECT COUNT(*) as count FROM esercizi 
            WHERE created_by_user_id = ?
        ");
        $exerciseStmt->bind_param('i', $userId);
        $exerciseStmt->execute();
        $exerciseResult = $exerciseStmt->get_result();
        $subscription['current_custom_exercises'] = $exerciseResult->fetch_assoc()['count'];
        
        return $subscription;
    }
    
    // Se non c'è un abbonamento attivo e valido, restituisci il piano Free
    $freePlanStmt = $conn->prepare("
        SELECT * FROM subscription_plans WHERE name = 'Free' LIMIT 1
    ");
    $freePlanStmt->execute();
    $freePlanResult = $freePlanStmt->get_result();
    
    if ($freePlanResult->num_rows > 0) {
        $freePlan = $freePlanResult->fetch_assoc();
        
        // Aggiungiamo i conteggi anche per il piano free
        // Conteggio schede
        $workoutStmt = $conn->prepare("
            SELECT COUNT(*) as count 
            FROM schede s
            INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
            WHERE uwa.user_id = ? AND uwa.active = 1
        ");
        $workoutStmt->bind_param('i', $userId);
        $workoutStmt->execute();
        $workoutResult = $workoutStmt->get_result();
        $currentCount = $workoutResult->fetch_assoc()['count'];
        
        // Conteggio esercizi personalizzati
        $exerciseStmt = $conn->prepare("
            SELECT COUNT(*) as count FROM esercizi 
            WHERE created_by_user_id = ?
        ");
        $exerciseStmt->bind_param('i', $userId);
        $exerciseStmt->execute();
        $exerciseResult = $exerciseStmt->get_result();
        $currentCustomExercises = $exerciseResult->fetch_assoc()['count'];
        
        return [
            'user_id' => $userId,
            'plan_id' => $freePlan['id'],
            'plan_name' => $freePlan['name'],
            'status' => 'active',
            'max_workouts' => $freePlan['max_workouts'],
            'max_custom_exercises' => $freePlan['max_custom_exercises'],
            'advanced_stats' => $freePlan['advanced_stats'],
            'cloud_backup' => $freePlan['cloud_backup'],
            'no_ads' => $freePlan['no_ads'],
            'price' => $freePlan['price'],
            'current_count' => $currentCount,
            'current_custom_exercises' => $currentCustomExercises,
            'days_remaining' => null, // Piano Free non ha scadenza
            'computed_status' => 'active'
        ];
    }
    
    return null;
}

// MODIFICATA: Controlla i limiti dell'utente per schede, esercizi, ecc. con controllo scadenza
function checkUserLimits($userId, $resourceType) {
    global $conn;
    
    // PRIMA: Controlla e aggiorna eventuali subscription scadute
    checkAndUpdateExpiredSubscriptions($userId);
    
    $subscription = getUserSubscription($userId);
    
    if (!$subscription) {
        return [
            'success' => false,
            'message' => 'Nessun abbonamento trovato',
            'limit_reached' => true
        ];
    }
    
    // Se l'utente ha un piano a pagamento e il limite è NULL (illimitato) E la subscription non è scaduta
    if ($subscription['price'] > 0 && $subscription[$resourceType] === null && $subscription['computed_status'] === 'active') {
        return [
            'success' => true,
            'message' => 'Nessun limite per questo piano',
            'limit_reached' => false
        ];
    }
    
    // Controllo specifico per tipo di risorsa
    switch ($resourceType) {
        case 'max_workouts':
            // Usa la tabella schede e user_workout_assignments per contare le schede ATTIVE dell'utente
            $stmt = $conn->prepare("
                SELECT COUNT(*) as count 
                FROM schede s
                INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
                WHERE uwa.user_id = ? AND uwa.active = 1
            ");
            break;
            
        case 'max_custom_exercises':
            // Usa la tabella esercizi per contare gli esercizi creati dall'utente
            $stmt = $conn->prepare("
                SELECT COUNT(*) as count FROM esercizi 
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
    
    return [
        'success' => true,
        'current_count' => $count,
        'max_allowed' => $limit,
        'limit_reached' => $count >= $limit,
        'remaining' => max(0, $limit - $count),
        'subscription_status' => $subscription['computed_status'], // NUOVO: aggiungiamo lo status
        'days_remaining' => $subscription['days_remaining'] ?? null // NUOVO: giorni rimanenti
    ];
}

// Aggiorna il piano dell'utente
function updateUserPlan($userId, $planId) {
    global $conn;
    
    $conn->begin_transaction();
    
    try {
        // Annulla gli abbonamenti precedenti
        $cancelStmt = $conn->prepare("
            UPDATE user_subscriptions 
            SET status = 'cancelled', updated_at = NOW() 
            WHERE user_id = ? AND status = 'active'
        ");
        $cancelStmt->bind_param('i', $userId);
        $cancelStmt->execute();
        
        // Crea il nuovo abbonamento
        $insertStmt = $conn->prepare("
            INSERT INTO user_subscriptions 
            (user_id, plan_id, status, start_date, end_date) 
            VALUES (?, ?, 'active', NOW(), CONCAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ' 23:59:59'))
        ");
        $insertStmt->bind_param('ii', $userId, $planId);
        $insertStmt->execute();
        
        // Aggiorna il piano corrente nell'utente
        $updateUserStmt = $conn->prepare("
            UPDATE users SET current_plan_id = ? WHERE id = ?
        ");
        $updateUserStmt->bind_param('ii', $planId, $userId);
        $updateUserStmt->execute();
        
        $conn->commit();
        
        return [
            'success' => true,
            'message' => 'Piano aggiornato con successo'
        ];
    } catch (Exception $e) {
        $conn->rollback();
        return [
            'success' => false,
            'message' => 'Errore durante l\'aggiornamento del piano: ' . $e->getMessage()
        ];
    }
}

// Registra una donazione
function recordDonation($userId, $amount, $message, $displayName, $paymentProvider, $paymentReference) {
    global $conn;
    
    $stmt = $conn->prepare("
        INSERT INTO donations 
        (user_id, amount, message, display_name, payment_provider, payment_reference)
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    
    $stmt->bind_param('idisss', $userId, $amount, $message, $displayName, $paymentProvider, $paymentReference);
    
    if ($stmt->execute()) {
        return [
            'success' => true,
            'message' => 'Donazione registrata con successo'
        ];
    } else {
        return [
            'success' => false,
            'message' => 'Errore nella registrazione della donazione: ' . $stmt->error
        ];
    }
}

// NUOVA FUNZIONE: Endpoint per forzare il controllo delle subscription scadute
function forceCheckExpiredSubscriptions($userId = null) {
    global $conn;
    
    $whereClause = $userId ? "AND us.user_id = ?" : "";
    
    $stmt = $conn->prepare("
        SELECT us.id, us.user_id, us.plan_id, us.end_date 
        FROM user_subscriptions us
        WHERE us.status = 'active' AND us.end_date <= NOW() $whereClause
    ");
    
    if ($userId) {
        $stmt->bind_param('i', $userId);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $updatedCount = 0;
    while ($row = $result->fetch_assoc()) {
        // Aggiorna lo status a 'expired'
        $updateStmt = $conn->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = NOW() 
            WHERE id = ?
        ");
        $updateStmt->bind_param('i', $row['id']);
        $updateStmt->execute();
        
        // Aggiorna l'utente al piano Free
        $freePlanStmt = $conn->prepare("
            SELECT id FROM subscription_plans WHERE name = 'Free' LIMIT 1
        ");
        $freePlanStmt->execute();
        $freePlanResult = $freePlanStmt->get_result();
        
        if ($freePlanResult->num_rows > 0) {
            $freePlan = $freePlanResult->fetch_assoc();
            
            $updateUserStmt = $conn->prepare("
                UPDATE users SET current_plan_id = ? WHERE id = ?
            ");
            $updateUserStmt->bind_param('ii', $freePlan['id'], $row['user_id']);
            $updateUserStmt->execute();
        }
        
        $updatedCount++;
    }
    
    return [
        'success' => true,
        'message' => "Aggiornate $updatedCount subscription scadute",
        'updated_count' => $updatedCount
    ];
}

// Gestione della richiesta
$method = $_SERVER['REQUEST_METHOD'];

// Gestione delle richieste OPTIONS per CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

// Verifica l'autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);
$user = validateAuthToken($conn, $token);

if (!$user) {
    // Per gli endpoint pubblici, come l'elenco dei piani
    if ($method === 'GET' && isset($_GET['public']) && $_GET['public'] === 'plans') {
        echo json_encode([
            'success' => true,
            'plans' => getAvailablePlans()
        ]);
        exit;
    }
    
    handleError('Utente non autenticato', 401);
}

// Gestione delle diverse azioni in base al metodo e ai parametri
switch ($method) {
    case 'GET':
        if (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'get_plans':
                    echo json_encode([
                        'success' => true,
                        'plans' => getAvailablePlans()
                    ]);
                    break;
                    
                case 'current_subscription':
                    $subscription = getUserSubscription($user['user_id']);
                    echo json_encode([
                        'success' => true,
                        'data' => [
                            'subscription' => $subscription
                        ]
                    ]);
                    break;
                    
                case 'check_limits':
                    if (!isset($_GET['resource_type'])) {
                        handleError('Tipo di risorsa non specificato', 400);
                    }
                    
                    $limits = checkUserLimits($user['user_id'], $_GET['resource_type']);
                    echo json_encode([
                        'success' => $limits['success'],
                        'data' => $limits
                    ]);
                    break;
                
                // NUOVO ENDPOINT: Forza controllo subscription scadute
                case 'check_expired':
                    echo json_encode(forceCheckExpiredSubscriptions($user['user_id']));
                    break;
                    
                default:
                    handleError('Azione non valida', 400);
            }
        } else {
            handleError('Azione non specificata', 400);
        }
        break;
        
    case 'POST':
        $inputJson = file_get_contents('php://input');
        $input = json_decode($inputJson, true);
        
        if (!$input) {
            handleError('Dati JSON non validi', 400);
        }
        
        if (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'update_plan':
                    if (!isset($input['plan_id'])) {
                        handleError('ID piano non specificato', 400);
                    }
                    
                    $result = updateUserPlan($user['user_id'], $input['plan_id']);
                    echo json_encode([
                        'success' => $result['success'],
                        'data' => $result
                    ]);
                    break;
                    
                case 'donate':
                    if (!isset($input['amount'], $input['payment_provider'], $input['payment_reference'])) {
                        handleError('Dati di donazione incompleti', 400);
                    }
                    
                    $message = isset($input['message']) ? $input['message'] : '';
                    $displayName = isset($input['display_name']) ? (bool)$input['display_name'] : true;
                    
                    $result = recordDonation(
                        $user['user_id'],
                        $input['amount'],
                        $message,
                        $displayName,
                        $input['payment_provider'],
                        $input['payment_reference']
                    );
                    
                    echo json_encode($result);
                    break;
                    
                default:
                    handleError('Azione non valida', 400);
            }
        } else {
            handleError('Azione non specificata', 400);
        }
        break;
        
    default:
        handleError('Metodo non consentito', 405);
}

$conn->close();
?>