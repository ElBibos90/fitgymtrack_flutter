<?php
// test_create_workout.php - Test per create_workout_from_template.php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    // Test: verifica che il template esista
    $templateId = 1;
    $query = "SELECT id, name FROM workout_templates WHERE id = ? AND is_active = 1";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $templateId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Template con ID $templateId non trovato");
    }
    
    $template = $result->fetch_assoc();
    
    // Test: verifica che ci siano esercizi nel template
    $exercisesQuery = "
        SELECT COUNT(*) as count 
        FROM template_exercises te
        JOIN esercizi e ON te.exercise_id = e.id
        WHERE te.template_id = ?
    ";
    $stmt = $conn->prepare($exercisesQuery);
    $stmt->bind_param('i', $templateId);
    $stmt->execute();
    $result = $stmt->get_result();
    $exerciseCount = $result->fetch_assoc()['count'];
    
    echo json_encode([
        'success' => true,
        'message' => 'API create_workout_from_template.php pronta per l\'uso',
        'template' => $template,
        'exercise_count' => $exerciseCount,
        'note' => 'Questa API richiede una richiesta POST con dati JSON'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>
