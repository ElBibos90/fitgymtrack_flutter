<?php
// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - accetta richieste da ambienti multipli
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

header('Content-Type: application/json');

include 'config.php';
require_once 'auth_functions.php';

// Verifica autenticazione
$userData = authMiddleware($conn);
if (!$userData) {
    exit();
}

// Ottieni l'ID dell'utente autenticato
$userId = $userData['user_id'];

// Verifica che sia una richiesta GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
    exit();
}

try {
    // Verifica se l'utente ha un allenamento in sospeso (durata_totale IS NULL)
    $stmt = $conn->prepare("
        SELECT 
            a.id as allenamento_id,
            a.scheda_id,
            a.data_allenamento,
            a.user_id,
            s.nome as scheda_nome,
            TIMESTAMPDIFF(MINUTE, a.data_allenamento, NOW()) as elapsed_minutes
        FROM allenamenti a
        JOIN schede s ON a.scheda_id = s.id
        WHERE a.user_id = ? 
        AND a.durata_totale IS NULL
        ORDER BY a.data_allenamento DESC
        LIMIT 1
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $pendingWorkout = $result->fetch_assoc();
        
        echo json_encode([
            'success' => true,
            'has_pending' => true,
            'pending_workout' => $pendingWorkout,
            'message' => 'Allenamento in sospeso trovato'
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'has_pending' => false,
            'pending_workout' => null,
            'message' => 'Nessun allenamento in sospeso trovato'
        ]);
    }
    
} catch (Exception $e) {
    error_log("Errore in check_pending_workout: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Errore del server: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
