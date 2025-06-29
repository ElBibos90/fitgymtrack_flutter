<?php
// API per ottenere gli esercizi in attesa di approvazione (admin only)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

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