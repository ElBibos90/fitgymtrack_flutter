<?php
/**
 * android_subscription_api.php
 * API per la gestione degli abbonamenti nella versione Android
 * AGGIORNATA con controllo scadenze
 */

// Impostazione esplicita degli header CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Max-Age: 3600");
header('Content-Type: application/json; charset=UTF-8');

// Gestione richieste OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit; // Termina qui per le richieste OPTIONS
}

// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

require_once 'config.php';
require_once 'auth_functions.php';
require_once 'subscription_limits.php';

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

// NUOVO: Funzione per controllare e aggiornare le subscription scadute
function checkAndUpdateExpiredSubscriptions($userId = null) {
    global $conn;
    
    $whereClause = $userId ? "AND us.user_id = ?" : "";
    
    // Log del controllo
    error_log("🔍 Controllo subscription scadute" . ($userId ? " per utente $userId" : " per tutti"));
    
    $stmt = $conn->prepare("
        SELECT us.id, us.user_id, us.plan_id, us.end_date, sp.name as plan_name
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.status = 'active' AND DATE(us.end_date) < CURDATE() $whereClause
    ");
    
    if ($userId) {
        $stmt->bind_param('i', $userId);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $expiredCount = 0;
    while ($row = $result->fetch_assoc()) {
        error_log("🚨 SUBSCRIPTION SCADUTA: ID={$row['id']}, User={$row['user_id']}, Piano={$row['plan_name']}, Scadenza={$row['end_date']}");
        
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
            
            error_log("✅ Utente {$row['user_id']} riportato al piano Free");
        }
        
        $expiredCount++;
    }
    
    if ($expiredCount > 0) {
        error_log("📊 Totale subscription scadute processate: $expiredCount");
    } else {
        error_log("✅ Nessuna subscription scaduta trovata");
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

// MODIFICATA: Ottieni l'abbonamento attuale dell'utente con controllo scadenze
function getUserSubscription($userId) {
    global $conn;
    
    // PRIMO: Controlla e aggiorna eventuali subscription scadute
    $expiredCount = checkAndUpdateExpiredSubscriptions($userId);
    
    // Log dello stato iniziale
    error_log("🔍 Recupero subscription per utente $userId");
    
    // MODIFICATA: Query che usa la stessa logica di scadenza
    // Scade solo il giorno DOPO la data di scadenza
    $stmt = $conn->prepare("
        SELECT us.*, sp.name as plan_name, sp.max_workouts, sp.max_custom_exercises, 
               sp.advanced_stats, sp.cloud_backup, sp.no_ads, sp.price,
               DATEDIFF(us.end_date, CURDATE()) as days_remaining,
               CASE 
                   WHEN DATE(us.end_date) < CURDATE() THEN 'expired'
                   ELSE us.status 
               END as computed_status
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ? AND us.status = 'active' AND DATE(us.end_date) >= CURDATE()
        ORDER BY sp.price DESC, us.created_at DESC 
        LIMIT 1
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $subscription = $result->fetch_assoc();
        
        // Log della subscription trovata
        error_log("✅ Subscription ATTIVA trovata: Piano={$subscription['plan_name']}, Prezzo={$subscription['price']}, Giorni rimanenti={$subscription['days_remaining']}, Scadenza={$subscription['end_date']}");
        
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
    error_log("⚠️  Nessuna subscription attiva trovata per utente $userId - assegnazione piano Free");
    
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
        
        error_log("📋 Piano Free assegnato: Schede={$currentCount}/{$freePlan['max_workouts']}, Esercizi={$currentCustomExercises}/{$freePlan['max_custom_exercises']}");
        
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
    
    error_log("❌ ERRORE: Impossibile trovare il piano Free per utente $userId");
    return null;
}

// MODIFICATA: Controlla i limiti dell'utente con informazioni di scadenza
function checkUserLimits($userId, $resourceType) {
    global $conn;
    
    // PRIMO: Controlla e aggiorna eventuali subscription scadute
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
    if ($subscription['price'] > 0 && $subscription[$resourceType] === null && 
        (!isset($subscription['computed_status']) || $subscription['computed_status'] === 'active')) {
        return [
            'success' => true,
            'message' => 'Nessun limite per questo piano',
            'limit_reached' => false,
            'current_count' => 0,
            'max_allowed' => null,
            'remaining' => null,
            'subscription_status' => $subscription['computed_status'] ?? 'active', // NUOVO
            'days_remaining' => $subscription['days_remaining'] ?? null // NUOVO
        ];
    }
    
    // Controllo specifico per tipo di risorsa
    switch ($resourceType) {
        case 'max_workouts':
            $stmt = $conn->prepare("
                SELECT COUNT(*) as count 
                FROM schede s
                INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
                WHERE uwa.user_id = ? AND uwa.active = 1
            ");
            break;
            
        case 'max_custom_exercises':
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
        'subscription_status' => $subscription['computed_status'] ?? 'active', // NUOVO
        'days_remaining' => $subscription['days_remaining'] ?? null // NUOVO
    ];
}

// Aggiorna il piano dell'utente
function updateUserPlan($userId, $planId) {
    global $conn;
    
    $conn->begin_transaction();
    
    try {
        // Verifica che il piano esista
        $planStmt = $conn->prepare("SELECT * FROM subscription_plans WHERE id = ?");
        $planStmt->bind_param('i', $planId);
        $planStmt->execute();
        $planResult = $planStmt->get_result();
        
        if ($planResult->num_rows == 0) {
            $conn->rollback();
            return [
                'success' => false,
                'message' => 'Piano non trovato'
            ];
        }
        
        // Annulla gli abbonamenti precedenti
        $cancelStmt = $conn->prepare("
            UPDATE user_subscriptions 
            SET status = 'cancelled', end_date = NOW() 
            WHERE user_id = ? AND status = 'active'
        ");
        $cancelStmt->bind_param('i', $userId);
        $cancelStmt->execute();
        
        // Crea il nuovo abbonamento
		$insertStmt = $conn->prepare("
			INSERT INTO user_subscriptions 
			(user_id, plan_id, status, start_date, end_date) 
			VALUES (?, ?, 'active', NOW(), 
				DATE_ADD(DATE_ADD(DATE(NOW()), INTERVAL 1 MONTH), INTERVAL '23:59:59' HOUR_SECOND)
			)
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
        
        error_log("✅ Piano aggiornato con successo per utente $userId al piano $planId");
        
        // Recupera i dettagli aggiornati dell'abbonamento
        $updatedSubscription = getUserSubscription($userId);
        
        return [
            'success' => true,
            'message' => 'Piano aggiornato con successo',
            'subscription' => $updatedSubscription
        ];
    } catch (Exception $e) {
        $conn->rollback();
        error_log("❌ Errore aggiornamento piano per utente $userId: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Errore durante l\'aggiornamento del piano: ' . $e->getMessage()
        ];
    }
}

// NUOVO: Endpoint per forzare il controllo delle subscription scadute
function forceCheckExpiredSubscriptions($userId = null) {
    $updatedCount = checkAndUpdateExpiredSubscriptions($userId);
    
    return [
        'success' => true,
        'message' => "Controllo completato",
        'updated_count' => $updatedCount
    ];
}

// Verifica l'autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);
$user = validateAuthToken($conn, $token);

if (!$user) {
    // Per gli endpoint pubblici, come l'elenco dei piani
    if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action']) && $_GET['action'] === 'get_plans') {
        sendResponse(true, ['plans' => getAvailablePlans()], 'Piani recuperati con successo');
        exit;
    }
    
    sendResponse(false, null, 'Utente non autenticato', 401);
}

// Ottieni il metodo della richiesta
$method = $_SERVER['REQUEST_METHOD'];

// Gestione delle diverse azioni in base al metodo e ai parametri
switch ($method) {
    case 'GET':
        if (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'get_plans':
                    sendResponse(true, ['plans' => getAvailablePlans()], 'Piani recuperati con successo');
                    break;
                    
                case 'current_subscription':
                    $subscription = getUserSubscription($user['user_id']);
                    sendResponse(true, ['subscription' => $subscription], 'Abbonamento recuperato con successo');
                    break;
                
                // NUOVO ENDPOINT: Forza controllo subscription scadute
                case 'check_expired':
                    $result = forceCheckExpiredSubscriptions($user['user_id']);
                    sendResponse(true, $result, $result['message']);
                    break;
                    
                case 'check_limits':
                    if (!isset($_GET['resource_type'])) {
                        sendResponse(false, null, 'Tipo di risorsa non specificato', 400);
                    }
                    
                    $result = checkUserLimits($user['user_id'], $_GET['resource_type']);
                    sendResponse($result['success'], $result, isset($result['message']) ? $result['message'] : null);
                    break;
                    
                default:
                    sendResponse(false, null, 'Azione non valida', 400);
            }
        } else {
            sendResponse(false, null, 'Azione non specificata', 400);
        }
        break;
        
    case 'POST':
        $inputJson = file_get_contents('php://input');
        $input = json_decode($inputJson, true);
        
        if (!$input) {
            sendResponse(false, null, 'Dati JSON non validi', 400);
        }
        
        if (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'update_plan':
                    if (!isset($input['plan_id'])) {
                        sendResponse(false, null, 'ID piano non specificato', 400);
                    }
                    
                    $result = updateUserPlan($user['user_id'], $input['plan_id']);
                    sendResponse($result['success'], 
                                isset($result['subscription']) ? ['subscription' => $result['subscription']] : null, 
                                $result['message'],
                                $result['success'] ? 200 : 400);
                    break;
                    
                default:
                    sendResponse(false, null, 'Azione non valida', 400);
            }
        } else {
            sendResponse(false, null, 'Azione non specificata', 400);
        }
        break;
        
    default:
        sendResponse(false, null, 'Metodo non consentito', 405);
}

$conn->close();
?>