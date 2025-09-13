<?php
// test_workout_templates.php - Versione semplificata per test
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Funzione di debug
function debug_log($message, $data = null) {
    error_log("TEST_TEMPLATE_DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("TEST_TEMPLATE_DATA: " . print_r($data, true));
    }
}

try {
    debug_log("=== INIZIO TEST WORKOUT TEMPLATES ===");
    
    // Test connessione database
    include 'config.php';
    debug_log("Config incluso");
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    debug_log("Connessione database OK");
    
    // Test query semplice
    $query = "SELECT COUNT(*) as total FROM workout_templates";
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query fallita: " . $conn->error);
    }
    
    $row = $result->fetch_assoc();
    debug_log("Template totali: " . $row['total']);
    
    // Test query completa
    $query = "
        SELECT 
            wt.id,
            wt.name,
            wt.description,
            wt.category_id,
            tc.name as category_name,
            wt.difficulty_level,
            wt.goal,
            wt.is_premium,
            wt.is_featured,
            wt.rating_average,
            wt.rating_count,
            wt.usage_count
        FROM workout_templates wt
        JOIN template_categories tc ON wt.category_id = tc.id
        WHERE wt.is_active = 1
        ORDER BY wt.is_featured DESC, wt.rating_average DESC
        LIMIT 10
    ";
    
    debug_log("Eseguendo query: $query");
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query template fallita: " . $conn->error);
    }
    
    $templates = [];
    while ($row = $result->fetch_assoc()) {
        $templates[] = $row;
    }
    
    debug_log("Template recuperati: " . count($templates));
    
    echo json_encode([
        'success' => true,
        'templates' => $templates,
        'total' => count($templates),
        'debug' => 'Test completato con successo'
    ]);
    
} catch (Exception $e) {
    debug_log("ERRORE: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'error' => 'Errore interno del server',
        'debug' => $e->getMessage()
    ]);
}
?>
