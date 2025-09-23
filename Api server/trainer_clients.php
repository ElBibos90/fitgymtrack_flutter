<?php
// ============================================================================
// API CLIENTI TRAINER
// Ottiene la lista dei clienti di un trainer
// ============================================================================

// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - Permissivo per sviluppo
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header('Access-Control-Allow-Credentials: false');

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

try {
    include 'config.php';
    require_once 'auth_functions.php';
} catch (Exception $e) {
    error_log("trainer_clients.php - Errore critico nell'inclusione: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore critico: ' . $e->getMessage()]);
    exit();
}

try {
    // Verifica autenticazione - Solo trainer, gym e admin possono accedere
    $user = authMiddleware($conn, ['trainer', 'gym', 'admin']);
    if (!$user) {
        error_log("trainer_clients.php - Autenticazione fallita o ruolo non autorizzato");
        http_response_code(403);
        echo json_encode(['error' => 'Accesso negato. Solo trainer, gym e admin possono accedere']);
        exit();
    }

    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
        exit();
    }

    $trainer_id = $user['user_id'];
    
    // Query per ottenere i clienti del trainer
    // Un cliente è un utente con role_id=2 (user) che appartiene alla stessa palestra del trainer
    
    // Prima otteniamo il gym_id del trainer
    $trainer_stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
    if (!$trainer_stmt) {
        throw new Exception("Errore preparazione query trainer: " . $conn->error);
    }
    $trainer_stmt->bind_param("i", $trainer_id);
    $trainer_stmt->execute();
    $trainer_result = $trainer_stmt->get_result();
    
    if ($trainer_row = $trainer_result->fetch_assoc()) {
        $gym_id = $trainer_row['gym_id'];
    } else {
        throw new Exception("Trainer non trovato");
    }
    
    // Ora otteniamo tutti gli utenti della palestra con role_id=2
    $stmt = $conn->prepare("
        SELECT DISTINCT 
            u.id, u.name, u.email
        FROM users u
        WHERE u.gym_id = ? AND u.role_id = 2
        ORDER BY u.name ASC
    ");
    
    if (!$stmt) {
        throw new Exception("Errore preparazione query: " . $conn->error);
    }
    
    $stmt->bind_param("i", $gym_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $clients = [];
    while ($row = $result->fetch_assoc()) {
        $clients[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'email' => $row['email']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'clients' => $clients,
        'count' => count($clients)
    ]);

} catch (Exception $e) {
    error_log("trainer_clients.php - Errore: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore nel recupero clienti: ' . $e->getMessage()]);
}
?>
