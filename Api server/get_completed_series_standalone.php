<?php
ini_set('display_errors', 1); // Abilita la visualizzazione degli errori per debug
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

try {
    if (!isset($_GET['allenamento_id'])) {
        throw new Exception('ID allenamento mancante');
    }

    $allenamento_id = intval($_GET['allenamento_id']);

    // Query corretta per includere il nome dell'esercizio tramite JOIN con scheda_esercizi
    $query = "
        SELECT sc.*, 
               sc.scheda_esercizio_id as esercizio_id,
               sc.serie_number as real_serie_number,
               sc.is_rest_pause,
               sc.rest_pause_reps,
               sc.rest_pause_rest_seconds,
               e.nome as esercizio_nome               
        FROM serie_completate sc
        LEFT JOIN scheda_esercizi se ON se.id = sc.scheda_esercizio_id
        LEFT JOIN esercizi e ON e.id = se.esercizio_id
        WHERE sc.allenamento_id = ?
        ORDER BY sc.timestamp ASC
    ";

    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        throw new Exception('Errore nella preparazione della query: ' . $conn->error);
    }
    
    $stmt->bind_param('i', $allenamento_id);
    
    if (!$stmt->execute()) {
        throw new Exception('Errore nell\'esecuzione della query: ' . $stmt->error);
    }
    
    $result = $stmt->get_result();
    
    $serie = array();
    while ($row = $result->fetch_assoc()) {
        // Conversioni per compatibilità JSON
        $row['is_rest_pause'] = intval($row['is_rest_pause']);
        $row['rest_pause_rest_seconds'] = $row['rest_pause_rest_seconds'] ? intval($row['rest_pause_rest_seconds']) : null;
        
        $serie[] = $row;
    }
    
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'serie' => $serie,
        'count' => count($serie)
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>