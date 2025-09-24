<?php
// ============================================================================
// API GESTIONE ABBONAMENTI CLIENTI PALESTRE
// Versione ricreata da zero per funzionare con webapp e Flutter
// ============================================================================

// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// 🔍 DEBUG: Log della richiesta
$logFile = __DIR__ . '/api_debug_log.txt';
$logMessage = "[" . date('Y-m-d H:i:s') . "] " . $_SERVER['REQUEST_METHOD'] . " - " . $_SERVER['REQUEST_URI'] . "\n";
$logMessage .= "Headers: " . json_encode(getallheaders()) . "\n";
$logMessage .= "GET params: " . json_encode($_GET) . "\n";
$logMessage .= "POST data: " . file_get_contents('php://input') . "\n";
$logMessage .= "---\n";
file_put_contents($logFile, $logMessage, FILE_APPEND | LOCK_EX);

error_log("🔍 [DEBUG] client_subscription_management.php accessed - Method: " . $_SERVER['REQUEST_METHOD']);
error_log("🔍 [DEBUG] Headers: " . json_encode(getallheaders()));
error_log("🔍 [DEBUG] GET params: " . json_encode($_GET));
error_log("🔍 [DEBUG] POST data: " . file_get_contents('php://input'));

// CORS headers - Supporta sia webapp che Flutter
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 86400');

// Gestisci preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Content-Type JSON
header('Content-Type: application/json');

// Include configurazione e funzioni
include 'config.php';
require_once 'auth_functions.php';

// Verifica connessione database
if (!$conn) {
    error_log("❌ [ERROR] Database connection failed");
    http_response_code(500);
    echo json_encode(['error' => 'Errore connessione database']);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

error_log("🔍 [DEBUG] Method: $method, Action: $action");

// Verifica autenticazione
error_log("🔍 [DEBUG] About to call authMiddleware");
$user = authMiddleware($conn, ['trainer', 'gym', 'admin', 'user']);
error_log("🔍 [DEBUG] authMiddleware result: " . json_encode($user));

// Log nel file
$authLogMessage = "[" . date('Y-m-d H:i:s') . "] AUTH - authMiddleware result: " . json_encode($user) . "\n";
file_put_contents($logFile, $authLogMessage, FILE_APPEND | LOCK_EX);

if (!$user) {
    error_log("❌ [DEBUG] authMiddleware failed - user not authenticated");
    $errorLogMessage = "[" . date('Y-m-d H:i:s') . "] ERROR - authMiddleware failed\n";
    file_put_contents($logFile, $errorLogMessage, FILE_APPEND | LOCK_EX);
    http_response_code(401);
    echo json_encode(['error' => 'Autenticazione richiesta']);
    exit();
}

error_log("✅ [DEBUG] User authenticated: " . json_encode($user));
$successLogMessage = "[" . date('Y-m-d H:i:s') . "] SUCCESS - User authenticated: " . json_encode($user) . "\n";
file_put_contents($logFile, $successLogMessage, FILE_APPEND | LOCK_EX);

// Routing delle azioni
$routingLogMessage = "[" . date('Y-m-d H:i:s') . "] ROUTING - Method: $method, Action: $action\n";
file_put_contents($logFile, $routingLogMessage, FILE_APPEND | LOCK_EX);

switch($method) {
    case 'GET':
        switch($action) {
            case 'client_subscription':
                $functionLogMessage = "[" . date('Y-m-d H:i:s') . "] CALLING - getClientSubscription with client_id: " . ($_GET['client_id'] ?? 'null') . "\n";
                file_put_contents($logFile, $functionLogMessage, FILE_APPEND | LOCK_EX);
                getClientSubscription($conn, $user, $_GET['client_id'] ?? null);
                break;
            default:
                $errorLogMessage = "[" . date('Y-m-d H:i:s') . "] ERROR - Action not specified: $action\n";
                file_put_contents($logFile, $errorLogMessage, FILE_APPEND | LOCK_EX);
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata']);
        }
        break;
        
    default:
        $errorLogMessage = "[" . date('Y-m-d H:i:s') . "] ERROR - Method not allowed: $method\n";
        file_put_contents($logFile, $errorLogMessage, FILE_APPEND | LOCK_EX);
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

/**
 * Ottieni abbonamento attuale di un cliente
 */
function getClientSubscription($conn, $user, $client_id) {
    global $logFile;
    
    $functionStartLog = "[" . date('Y-m-d H:i:s') . "] FUNCTION START - getClientSubscription called with client_id: $client_id, user_id: {$user['user_id']}, role: {$user['role_name']}\n";
    file_put_contents($logFile, $functionStartLog, FILE_APPEND | LOCK_EX);
    
    error_log("🔍 [DEBUG] getClientSubscription called with client_id: $client_id, user_id: {$user['user_id']}, role: {$user['role_name']}");
    
    if (!$client_id) {
        $errorLog = "[" . date('Y-m-d H:i:s') . "] ERROR - Missing client_id\n";
        file_put_contents($logFile, $errorLog, FILE_APPEND | LOCK_EX);
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        // Se l'utente è un user normale, può accedere solo ai propri dati
        if ($user['role_name'] === 'user') {
            $user_id = $user['user_id'] ?? $user['id'] ?? null;
            if ($user_id != $client_id) {
                http_response_code(403);
                echo json_encode(['error' => 'Accesso negato: puoi accedere solo ai tuoi dati']);
                return;
            }
            $gym_id = null; // Per gli utenti normali, non filtriamo per gym_id
        } else {
            // Per trainer, gym e admin, usa la logica esistente
            $gym_id = getTrainerGymId($conn, $user);
            
            // Verifica che il cliente appartenga alla palestra del trainer
            if (!verifyClientAccess($conn, $client_id, $gym_id)) {
                http_response_code(403);
                echo json_encode(['error' => 'Accesso negato al cliente']);
                return;
            }
        }
        
        // Query per abbonamento attivo
        if ($gym_id !== null) {
            // Per trainer, gym e admin - filtra per gym_id
            $stmt = $conn->prepare("
                SELECT 
                    cs.id, cs.subscription_type, cs.subscription_name, cs.price, cs.currency,
                    cs.start_date, cs.end_date, cs.status, cs.payment_status, cs.auto_renew,
                    cs.notes, cs.created_at, cs.updated_at,
                    u.name as client_name, u.email as client_email
                FROM client_subscriptions cs
                JOIN users u ON cs.client_id = u.id
                WHERE cs.client_id = ? AND cs.gym_id = ? 
                AND cs.status = 'active'
                ORDER BY cs.created_at DESC
                LIMIT 1
            ");
            $stmt->bind_param("ii", $client_id, $gym_id);
        } else {
            // Per utenti normali - non filtra per gym_id
            error_log("🔍 [DEBUG] Executing query for user (no gym_id filter)");
            $stmt = $conn->prepare("
                SELECT 
                    cs.id, cs.subscription_type, cs.subscription_name, cs.price, cs.currency,
                    cs.start_date, cs.end_date, cs.status, cs.payment_status, cs.auto_renew,
                    cs.notes, cs.created_at, cs.updated_at,
                    u.name as client_name, u.email as client_email
                FROM client_subscriptions cs
                JOIN users u ON cs.client_id = u.id
                WHERE cs.client_id = ? 
                AND cs.status = 'active'
                ORDER BY cs.created_at DESC
                LIMIT 1
            ");
            $stmt->bind_param("i", $client_id);
        }
        
        error_log("🔍 [DEBUG] About to execute query");
        $stmt->execute();
        $result = $stmt->get_result();
        error_log("🔍 [DEBUG] Query executed, num_rows: " . $result->num_rows);
        
        if ($result->num_rows > 0) {
            $subscription = $result->fetch_assoc();
            
            // Calcola giorni rimanenti
            $end_date = new DateTime($subscription['end_date']);
            $today = new DateTime();
            $days_remaining = $today->diff($end_date)->days;
            if ($end_date < $today) {
                $days_remaining = 0;
            }
            $subscription['days_remaining'] = $days_remaining;
            
            error_log("✅ [DEBUG] Subscription found: " . json_encode($subscription));
            $response = [
                'success' => true,
                'subscription' => $subscription
            ];
            $responseLogMessage = "[" . date('Y-m-d H:i:s') . "] RESPONSE - Subscription found: " . json_encode($response) . "\n";
            file_put_contents($logFile, $responseLogMessage, FILE_APPEND | LOCK_EX);
            echo json_encode($response);
        } else {
            error_log("ℹ️ [DEBUG] No active subscription found");
            echo json_encode([
                'success' => true,
                'subscription' => null,
                'message' => 'Nessun abbonamento attivo'
            ]);
        }
        
    } catch (Exception $e) {
        error_log("❌ [ERROR] Exception in getClientSubscription: " . $e->getMessage());
        error_log("❌ [ERROR] Stack trace: " . $e->getTraceAsString());
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero abbonamento: ' . $e->getMessage()]);
    }
}

/**
 * Utility: Ottieni gym_id del trainer
 */
function getTrainerGymId($conn, $user) {
    if (hasRole($user, 'admin')) {
        return $_GET['gym_id'] ?? null;
    }
    
    if (hasRole($user, 'gym') || hasRole($user, 'trainer')) {
        $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
        $stmt->bind_param("i", $user['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->num_rows > 0 ? $result->fetch_assoc()['gym_id'] : null;
    }
    
    return null;
}

/**
 * Utility: Verifica accesso al cliente
 */
function verifyClientAccess($conn, $client_id, $gym_id) {
    $stmt = $conn->prepare("
        SELECT 1 FROM gym_memberships 
        WHERE user_id = ? AND gym_id = ? AND role_in_gym = 'member'
    ");
    $stmt->bind_param("ii", $client_id, $gym_id);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->num_rows > 0;
}

$conn->close();
?>