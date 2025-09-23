<?php
// ============================================================================
// UTILITY PER AGGIORNAMENTO STATISTICHE PALESTRE
// Chiamata manuale delle stored procedures per aggiornare le statistiche
// ============================================================================

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

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
        header("Access-Control-Allow-Methods: POST, OPTIONS");
    }
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }
    exit(0);
}

// Solo POST consentito
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Metodo non consentito']);
    exit;
}

// Verifica autenticazione
$user = authMiddleware($conn, ['admin', 'gym']);
if (!$user) {
    exit();
}

/**
 * Aggiorna statistiche per una palestra specifica
 */
function updateGymStats($conn, $gym_id) {
    try {
        // Chiama la stored procedure
        $stmt = $conn->prepare("CALL UpdateGymStats(?)");
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        
        // Chiudi il result set della stored procedure
        $stmt->close();
        
        return true;
    } catch (Exception $e) {
        error_log("Errore aggiornamento statistiche palestra $gym_id: " . $e->getMessage());
        return false;
    }
}

/**
 * Aggiorna statistiche per tutte le palestre
 */
function updateAllGymStats($conn) {
    try {
        // Chiama la stored procedure
        $stmt = $conn->prepare("CALL UpdateAllGymStats()");
        $stmt->execute();
        $stmt->close();
        
        return true;
    } catch (Exception $e) {
        error_log("Errore aggiornamento tutte le statistiche: " . $e->getMessage());
        return false;
    }
}

// Gestione richiesta
$data = json_decode(file_get_contents("php://input"), true);

if (isset($data['gym_id'])) {
    // Aggiorna statistiche per palestra specifica
    $gym_id = (int)$data['gym_id'];
    
    // Verifica permessi
    if (!hasRole($user, 'admin') && !canAccessGym($conn, $gym_id, $user)) {
        http_response_code(403);
        echo json_encode(['error' => 'Non hai permessi per questa palestra']);
        exit;
    }
    
    if (updateGymStats($conn, $gym_id)) {
        echo json_encode([
            'success' => true,
            'message' => "Statistiche aggiornate per palestra ID $gym_id"
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento delle statistiche']);
    }
    
} elseif (isset($data['all']) && $data['all'] === true) {
    // Aggiorna statistiche per tutte le palestre (solo admin)
    if (!hasRole($user, 'admin')) {
        http_response_code(403);
        echo json_encode(['error' => 'Solo gli admin possono aggiornare tutte le statistiche']);
        exit;
    }
    
    if (updateAllGymStats($conn)) {
        echo json_encode([
            'success' => true,
            'message' => 'Statistiche aggiornate per tutte le palestre'
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento delle statistiche']);
    }
    
} else {
    http_response_code(400);
    echo json_encode(['error' => 'Parametri mancanti. Specifica gym_id o all=true']);
}

/**
 * Verifica se l'utente può accedere alla palestra
 */
function canAccessGym($conn, $gym_id, $user) {
    if (hasRole($user, 'admin')) {
        return true;
    }
    
    if (hasRole($user, 'gym')) {
        $stmt = $conn->prepare("SELECT id FROM gyms WHERE id = ? AND owner_user_id = ?");
        $stmt->bind_param("ii", $gym_id, $user['user_id']);
        $stmt->execute();
        return $stmt->get_result()->num_rows > 0;
    }
    
    return false;
}

$conn->close();
?>
