<?php
// database_info.php - Informazioni sul database per debug
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    $info = [];
    
    // 1. Controlla template
    $query = "SELECT COUNT(*) as count FROM workout_templates WHERE is_active = 1";
    $result = $conn->query($query);
    $info['templates'] = $result->fetch_assoc()['count'];
    
    // 2. Controlla esercizi
    $query = "SELECT COUNT(*) as count FROM esercizi";
    $result = $conn->query($query);
    $info['esercizi'] = $result->fetch_assoc()['count'];
    
    // 3. Controlla template_exercises
    $query = "SELECT COUNT(*) as count FROM template_exercises";
    $result = $conn->query($query);
    $info['template_exercises'] = $result->fetch_assoc()['count'];
    
    // 4. Mostra alcuni template con i loro esercizi
    $query = "
        SELECT 
            wt.id,
            wt.name,
            COUNT(te.id) as exercise_count
        FROM workout_templates wt
        LEFT JOIN template_exercises te ON wt.id = te.template_id
        WHERE wt.is_active = 1
        GROUP BY wt.id, wt.name
        LIMIT 5
    ";
    $result = $conn->query($query);
    $info['template_examples'] = [];
    while ($row = $result->fetch_assoc()) {
        $info['template_examples'][] = $row;
    }
    
    // 5. Mostra alcuni esercizi
    $query = "SELECT id, nome, gruppo_muscolare FROM esercizi LIMIT 5";
    $result = $conn->query($query);
    $info['esercizi_examples'] = [];
    while ($row = $result->fetch_assoc()) {
        $info['esercizi_examples'][] = $row;
    }
    
    // 6. Mostra collegamenti template-esercizi
    $query = "
        SELECT 
            te.template_id,
            wt.name as template_name,
            te.exercise_id,
            e.nome as exercise_name
        FROM template_exercises te
        JOIN workout_templates wt ON te.template_id = wt.id
        JOIN esercizi e ON te.exercise_id = e.id
        LIMIT 10
    ";
    $result = $conn->query($query);
    $info['template_exercise_links'] = [];
    while ($row = $result->fetch_assoc()) {
        $info['template_exercise_links'][] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'database_info' => $info
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>

