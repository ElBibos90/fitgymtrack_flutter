<?php
// API per ottenere gli esercizi in attesa di approvazione (admin only)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
// CORS headers - accetta richieste da localhost:3000
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
        header('Access-Control-Max-Age: 86400');    // cache per 1 giorno
    }
}

// Gestione richieste OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'])) {
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    }
    
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }

    exit(0);
}
include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

// Recupera il token di autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);

// Verifica l'autenticazione e il ruolo dell'utente
$user = validateAuthToken($conn, $token);

// Controllo accesso: solo gli admin possono vedere gli esercizi in attesa
if (!$user || !hasRole($user, 'admin')) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Accesso non autorizzato. Questa operazione richiede privilegi di amministratore.']);
    exit;
}

try {
    // Ottieni gli esercizi che hanno un valore nel campo created_by_user_id
    // Questi sono gli esercizi creati dagli utenti standalone
    $query = "
        SELECT e.*, u.username as user_username 
        FROM esercizi e
        LEFT JOIN users u ON e.created_by_user_id = u.id
        WHERE e.created_by_user_id IS NOT NULL
        ORDER BY 
            CASE 
                WHEN e.status = 'pending_review' THEN 1
                WHEN e.status = 'approved' THEN 2
                ELSE 3
            END,
            e.nome ASC
    ";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Errore nella query: " . $conn->error);
    }
    
    $exercises = [];
    while ($row = $result->fetch_assoc()) {
        if (isset($row['is_isometric'])) {
            $row['is_isometric'] = (int)$row['is_isometric'];
        }
        $exercises[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'exercises' => $exercises
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Errore: ' . $e->getMessage()
    ]);
}

$conn->close();
?>