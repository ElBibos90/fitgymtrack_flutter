<?php
// populate_template_exercises.php - Popola i template con esercizi
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    // Prima mostra alcuni esercizi disponibili
    $query = "SELECT id, nome, gruppo_muscolare FROM esercizi ORDER BY nome LIMIT 20";
    $result = $conn->query($query);
    $esercizi = [];
    while ($row = $result->fetch_assoc()) {
        $esercizi[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Esercizi disponibili per popolare i template',
        'esercizi' => $esercizi,
        'note' => 'Usa questi ID per popolare template_exercises'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>

