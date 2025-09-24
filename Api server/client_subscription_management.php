<?php
// API per la gestione degli abbonamenti clienti palestra
// Versione pulita senza logging di debug

// Configurazione errori
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Headers CORS per webapp e Flutter
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Gestione preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Includi file di configurazione
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_functions.php';

// Connessione al database (già creata in config.php)
// Verifica connessione
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Errore di connessione al database']);
    exit();
}

// Autenticazione
$user = authMiddleware($conn, ['trainer', 'gym', 'admin', 'user']);

if (!$user) {
    http_response_code(401);
    echo json_encode(['error' => 'Autenticazione richiesta']);
    exit();
}

// Routing delle azioni
$method = $_SERVER['REQUEST_METHOD'];
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
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata']);
                break;
        }
        break;
        
    case 'POST':
        switch($action) {
            case 'create_subscription':
                createClientSubscription($conn, $user);
                break;
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata']);
                break;
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
        break;
}

/**
 * Recupera l'abbonamento attivo di un cliente
 */
function getClientSubscription($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        // Verifica permessi di accesso
        if (!verifyClientAccess($conn, $client_id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato al cliente']);
            return;
        }
        
        // Query per recuperare l'abbonamento attivo dalla tabella client_subscriptions
        $sql = "SELECT cs.*, g.name as gym_name 
                FROM client_subscriptions cs 
                LEFT JOIN gyms g ON cs.gym_id = g.id 
                WHERE cs.client_id = ? AND cs.status = 'active'";
        
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $client_id);
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
            
            $response = [
                'success' => true,
                'subscription' => [
                    'id' => $subscription['id'],
                    'client_id' => $subscription['client_id'],
                    'gym_id' => $subscription['gym_id'],
                    'gym_name' => $subscription['gym_name'],
                    'subscription_name' => $subscription['subscription_name'],
                    'subscription_type' => $subscription['subscription_type'],
                    'price' => $subscription['price'],
                    'currency' => $subscription['currency'],
                    'start_date' => $subscription['start_date'],
                    'end_date' => $subscription['end_date'],
                    'status' => $subscription['status'],
                    'payment_status' => $subscription['payment_status'],
                    'auto_renew' => $subscription['auto_renew'],
                    'days_remaining' => $days_remaining,
                    'notes' => $subscription['notes']
                ]
            ];
            echo json_encode($response);
        } else {
            $response = [
                'success' => false,
                'message' => 'Nessun abbonamento attivo trovato'
            ];
            echo json_encode($response);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dell\'abbonamento: ' . $e->getMessage()]);
    }
}

/**
 * Recupera la cronologia degli abbonamenti di un cliente
 */
function getClientSubscriptionHistory($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        // Verifica permessi di accesso
        if (!verifyClientAccess($conn, $client_id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato al cliente']);
            return;
        }
        
        // Query per recuperare la cronologia dalla tabella client_subscriptions
        $sql = "SELECT cs.*, g.name as gym_name 
                FROM client_subscriptions cs 
                LEFT JOIN gyms g ON cs.gym_id = g.id 
                WHERE cs.client_id = ? 
                ORDER BY cs.created_at DESC";
        
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $client_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $history = [];
        while ($row = $result->fetch_assoc()) {
            // Calcola giorni rimanenti
            $end_date = new DateTime($row['end_date']);
            $today = new DateTime();
            $days_remaining = $today->diff($end_date)->days;
            
            if ($end_date < $today) {
                $days_remaining = 0;
            }
            
            $history[] = [
                'id' => $row['id'],
                'client_id' => $row['client_id'],
                'gym_id' => $row['gym_id'],
                'gym_name' => $row['gym_name'],
                'subscription_name' => $row['subscription_name'],
                'subscription_type' => $row['subscription_type'],
                'price' => $row['price'],
                'currency' => $row['currency'],
                'start_date' => $row['start_date'],
                'end_date' => $row['end_date'],
                'status' => $row['status'],
                'payment_status' => $row['payment_status'],
                'auto_renew' => $row['auto_renew'],
                'days_remaining' => $days_remaining,
                'notes' => $row['notes'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at']
            ];
        }
        
        $response = [
            'success' => true,
            'history' => $history
        ];
        echo json_encode($response);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero della cronologia: ' . $e->getMessage()]);
    }
}

/**
 * Crea un nuovo abbonamento per un cliente
 */
function createClientSubscription($conn, $user) {
    // Solo trainer, gym e admin possono creare abbonamenti
    if (!in_array($user['role_name'], ['trainer', 'gym', 'admin'])) {
        http_response_code(403);
        echo json_encode(['error' => 'Permessi insufficienti per creare abbonamenti']);
        return;
    }
    
    try {
        // Leggi i dati POST
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            http_response_code(400);
            echo json_encode(['error' => 'Dati mancanti']);
            return;
        }
        
        $client_id = $input['client_id'] ?? null;
        $subscription_name = $input['subscription_name'] ?? '';
        $subscription_type = $input['subscription_type'] ?? 'monthly';
        $price = $input['price'] ?? 0;
        $start_date = $input['start_date'] ?? date('Y-m-d');
        $end_date = $input['end_date'] ?? null;
        $auto_renew = 0; // Sempre disabilitato
        $notes = $input['notes'] ?? '';
        
        if (!$client_id || !$subscription_name || !$end_date) {
            http_response_code(400);
            echo json_encode(['error' => 'Dati obbligatori mancanti']);
            return;
        }
        
        // Ottieni gym_id del trainer
        $gym_id = getTrainerGymId($conn, $user);
        
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Palestra non trovata']);
            return;
        }
        
        // Verifica che il cliente appartenga alla palestra
        if (!verifyClientAccess($conn, $client_id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato al cliente']);
            return;
        }
        
        // 1. Disattiva eventuali abbonamenti attivi esistenti
        $deactivateStmt = $conn->prepare("
            UPDATE client_subscriptions 
            SET status = 'expired', updated_at = NOW(),
                notes = CONCAT(IFNULL(notes, ''), '\n', 'Sostituito da nuovo abbonamento il ', NOW())
            WHERE client_id = ? AND gym_id = ? AND status = 'active'
        ");
        $deactivateStmt->bind_param("ii", $client_id, $gym_id);
        $deactivateStmt->execute();
        
        // 2. Inserisci nuovo abbonamento
        $stmt = $conn->prepare("
            INSERT INTO client_subscriptions 
            (client_id, gym_id, trainer_id, subscription_type, subscription_name, price, currency, 
             start_date, end_date, status, payment_status, auto_renew, notes, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, 'EUR', ?, ?, 'active', 'paid', ?, ?, NOW(), NOW())
        ");
        
        $trainer_id = $user['user_id'];
        $stmt->bind_param("iiisssssis", 
            $client_id, $gym_id, $trainer_id, $subscription_type, $subscription_name, 
            $price, $start_date, $end_date, $auto_renew, $notes
        );
        
        if ($stmt->execute()) {
            $subscription_id = $conn->insert_id;
            
            $response = [
                'success' => true,
                'message' => 'Abbonamento creato con successo',
                'subscription_id' => $subscription_id
            ];
            echo json_encode($response);
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Errore nella creazione dell\'abbonamento']);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione dell\'abbonamento: ' . $e->getMessage()]);
    }
}

/**
 * Verifica se l'utente può accedere ai dati del cliente
 */
function verifyClientAccess($conn, $client_id, $user) {
    // Se l'utente è un cliente (role_id: 2), può accedere solo ai propri dati
    if ($user['role_name'] === 'user') {
        return $user['user_id'] == $client_id;
    }
    
    // Per trainer, gym e admin, verifica che il cliente appartenga alla loro palestra
    $gym_id = getTrainerGymId($conn, $user);
    if (!$gym_id) {
        return false;
    }
    
    // Verifica che il cliente abbia abbonamenti nella palestra
    $stmt = $conn->prepare("SELECT id FROM client_subscriptions WHERE client_id = ? AND gym_id = ?");
    $stmt->bind_param("ii", $client_id, $gym_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    return $result->num_rows > 0;
}

/**
 * Ottiene l'ID della palestra del trainer
 */
function getTrainerGymId($conn, $user) {
    if ($user['role_name'] === 'gym') {
        return $user['gym_id'];
    }
    
    // Usa la tabella users (che ha il campo gym_id)
    $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
    $stmt->bind_param("i", $user['user_id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        return $row['gym_id'];
    }
    
    return null;
}

// Chiudi connessione
$conn->close();
?>