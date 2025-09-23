<?php
// ============================================================================
// API GESTIONE ABBONAMENTI CLIENTI PALESTRE
// Per gestire gli abbonamenti dei clienti nelle palestre
// ============================================================================

// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers
if (isset($_SERVER['HTTP_ORIGIN'])) {
    $allowed_origins = ['http://localhost:3000', 
        'http://192.168.1.113', 
        'http://104.248.103.182',
        'http://fitgymtrack.com',
        'https://fitgymtrack.com',
        'http://www.fitgymtrack.com',
        'https://www.fitgymtrack.com'];
    if (in_array($_SERVER['HTTP_ORIGIN'], $allowed_origins)) {
        header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 86400');
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'])) {
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    }
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }
    exit(0);
}

header('Content-Type: application/json');

include 'config.php';
require_once 'auth_functions.php';

$method = $_SERVER['REQUEST_METHOD'];

// Verifica autenticazione - Solo trainer, gym e admin possono accedere
$user = authMiddleware($conn, ['trainer', 'gym', 'admin']);
if (!$user) {
    exit();
}

// Routing delle azioni
$action = $_GET['action'] ?? '';

switch($method) {
    case 'GET':
        switch($action) {
            case 'client_subscription':
                getClientSubscription($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'client_subscription_history':
                getClientSubscriptionHistory($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'subscription_stats':
                getSubscriptionStats($conn, $user);
                break;
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata']);
        }
        break;
        
    case 'POST':
        switch($action) {
            case 'create_subscription':
                createClientSubscription($conn, $user);
                break;
            case 'renew_subscription':
                renewClientSubscription($conn, $user);
                break;
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione POST non specificata']);
        }
        break;
        
    case 'PUT':
        switch($action) {
            case 'update_subscription':
                updateClientSubscription($conn, $user);
                break;
            case 'cancel_subscription':
                cancelClientSubscription($conn, $user);
                break;
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione PUT non specificata']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

/**
 * Ottieni abbonamento attuale di un cliente
 */
function getClientSubscription($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $gym_id = getTrainerGymId($conn, $user);
        
        // Verifica che il cliente appartenga alla palestra del trainer
        if (!verifyClientAccess($conn, $client_id, $gym_id)) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato al cliente']);
            return;
        }
        
        // Abbonamento attivo
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
        $stmt->execute();
        $result = $stmt->get_result();
        
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
            
            echo json_encode([
                'success' => true,
                'subscription' => $subscription
            ]);
        } else {
            echo json_encode([
                'success' => true,
                'subscription' => null,
                'message' => 'Nessun abbonamento attivo'
            ]);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero abbonamento: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni storico abbonamenti di un cliente
 */
function getClientSubscriptionHistory($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $gym_id = getTrainerGymId($conn, $user);
        
        // Verifica accesso
        if (!verifyClientAccess($conn, $client_id, $gym_id)) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato al cliente']);
            return;
        }
        
        $stmt = $conn->prepare("
            SELECT 
                cs.id, cs.subscription_type, cs.subscription_name, cs.price, cs.currency,
                cs.start_date, cs.end_date, cs.status, cs.payment_status, cs.auto_renew,
                cs.notes, cs.created_at
            FROM client_subscriptions cs
            WHERE cs.client_id = ? AND cs.gym_id = ? 
            ORDER BY cs.created_at DESC
            LIMIT 20
        ");
        
        $stmt->bind_param("ii", $client_id, $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $history = [];
        while ($row = $result->fetch_assoc()) {
            $history[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'history' => $history
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero storico: ' . $e->getMessage()]);
    }
}

/**
 * Crea nuovo abbonamento per un cliente
 */
function createClientSubscription($conn, $user) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $required_fields = ['client_id', 'subscription_name', 'price', 'start_date', 'end_date'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            http_response_code(400);
            echo json_encode(['error' => "Campo obbligatorio mancante: $field"]);
            return;
        }
    }
    
    try {
        $gym_id = getTrainerGymId($conn, $user);
        $trainer_id = hasRole($user, 'trainer') ? $user['user_id'] : null;
        
        // Verifica accesso
        if (!verifyClientAccess($conn, $input['client_id'], $gym_id)) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato al cliente']);
            return;
        }
        
        $conn->begin_transaction();
        
        // Annulla abbonamenti attivi esistenti
        $cancel_stmt = $conn->prepare("
            UPDATE client_subscriptions 
            SET status = 'cancelled', updated_at = NOW() 
            WHERE client_id = ? AND gym_id = ? AND status = 'active'
        ");
        $cancel_stmt->bind_param("ii", $input['client_id'], $gym_id);
        $cancel_stmt->execute();
        
        // Crea nuovo abbonamento
        $stmt = $conn->prepare("
            INSERT INTO client_subscriptions (
                client_id, gym_id, trainer_id, subscription_type, subscription_name,
                price, currency, start_date, end_date, status, payment_status,
                auto_renew, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 'paid', ?, ?)
        ");
        
        $subscription_type = $input['subscription_type'] ?? 'monthly';
        $currency = $input['currency'] ?? 'EUR';
        $auto_renew = $input['auto_renew'] ?? 1;
        $notes = $input['notes'] ?? '';
        
        $stmt->bind_param("iiissssssss", 
            $input['client_id'], $gym_id, $trainer_id, $subscription_type,
            $input['subscription_name'], $input['price'], $currency,
            $input['start_date'], $input['end_date'], $auto_renew, $notes
        );
        
        $stmt->execute();
        $subscription_id = $conn->insert_id;
        
        $conn->commit();
        
        echo json_encode([
            'success' => true,
            'subscription_id' => $subscription_id,
            'message' => 'Abbonamento creato con successo'
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione abbonamento: ' . $e->getMessage()]);
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