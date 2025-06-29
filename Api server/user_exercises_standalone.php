<?php
// Abilita errori per debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

// Gestione della richiesta GET per ottenere gli esercizi dell'utente
if ($method === 'GET') {
    if (!isset($_GET['user_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID utente mancante']);
        exit;
    }

    $user_id = intval($_GET['user_id']);

    try {
        // Ottieni gli esercizi creati dall'utente
        $query = "
            SELECT * FROM esercizi 
            WHERE created_by_user_id = ?
            ORDER BY nome ASC
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param('i', $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $exercises = [];
        while ($row = $result->fetch_assoc()) {
            $exercises[] = $row;
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'exercises' => $exercises
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Errore durante il recupero degli esercizi: ' . $e->getMessage()]);
    }
} 
// Gestione della richiesta DELETE (ridireziona a custom_exercise_standalone.php)
else if ($method === 'DELETE') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Aggiungiamo l'ID utente se presente nella query
    if (isset($_GET['user_id'])) {
        $input['user_id'] = intval($_GET['user_id']);
    }
    
    // Reindirizza alla API principale per gli esercizi
    require 'custom_exercise_standalone.php';
}
// Metodo non consentito
else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
}

$conn->close();
?>