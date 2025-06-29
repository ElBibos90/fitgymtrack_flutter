<?php
// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Funzione per gestire gli errori e restituire JSON appropriato
function handleError($message, $errorCode = 500) {
    header('Content-Type: application/json');
    http_response_code($errorCode);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

try {
    include 'config.php';
    require_once 'auth_functions.php';

    header('Content-Type: application/json');

    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        handleError('Metodo non consentito', 405);
    }

    if (!isset($_GET['user_id'])) {
        handleError('ID utente mancante', 400);
    }

    $user_id = intval($_GET['user_id']);
    
    if (!$conn) {
        handleError('Errore di connessione al database', 500);
    }

    // Query per ottenere gli allenamenti dell'utente
    // Recuperiamo anche il nome della scheda per ogni allenamento
    $query = "
        SELECT a.*, s.nome as scheda_nome
        FROM allenamenti a
        LEFT JOIN schede s ON a.scheda_id = s.id
        WHERE a.user_id = ?
        ORDER BY a.data_allenamento DESC
    ";

    $stmt = $conn->prepare($query);
    if (!$stmt) {
        handleError('Errore di preparazione query: ' . $conn->error, 500);
    }

    $stmt->bind_param('i', $user_id);
    
    if (!$stmt->execute()) {
        handleError('Errore di esecuzione query: ' . $stmt->error, 500);
    }

    $result = $stmt->get_result();
    $allenamenti = [];
    
    while ($row = $result->fetch_assoc()) {
        $allenamenti[] = $row;
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true, 
        'allenamenti' => $allenamenti,
        'count' => count($allenamenti)
    ]);

} catch (Exception $e) {
    handleError('Eccezione: ' . $e->getMessage(), 500);
}
?>