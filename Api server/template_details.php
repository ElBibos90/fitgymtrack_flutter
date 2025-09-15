<?php
// template_details.php - API per ottenere i dettagli completi di un template
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Includi configurazione database
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non supportato']);
        exit();
    }
    
    // Verifica parametro ID
    if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'ID template richiesto']);
        exit();
    }
    
    $templateId = intval($_GET['id']);
    
    // Query per ottenere i dettagli del template
    $query = "
        SELECT 
            wt.id,
            wt.name,
            wt.description,
            wt.category_id,
            tc.name as category_name,
            tc.icon as category_icon,
            tc.color as category_color,
            COALESCE(wt.difficulty_level, 0) as difficulty_level,
            wt.goal,
            COALESCE(wt.is_premium, 0) as is_premium,
            COALESCE(wt.is_featured, 0) as is_featured,
            COALESCE(wt.rating_average, 0) as rating_average,
            COALESCE(wt.rating_count, 0) as rating_count,
            COALESCE(wt.usage_count, 0) as usage_count,
            wt.created_at,
            wt.updated_at
        FROM workout_templates wt
        JOIN template_categories tc ON wt.category_id = tc.id
        WHERE wt.id = ? AND wt.is_active = 1
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $templateId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['error' => 'Template non trovato']);
        exit();
    }
    
    $template = $result->fetch_assoc();
    
    // 🔧 FIX: Query separata per le statistiche di rating
    $statsQuery = "
        SELECT 
            COALESCE(AVG(rating), 0) as rating_average,
            COUNT(*) as rating_count
        FROM user_template_ratings 
        WHERE template_id = ?
    ";
    $statsStmt = $conn->prepare($statsQuery);
    $statsStmt->bind_param('i', $templateId);
    $statsStmt->execute();
    $statsResult = $statsStmt->get_result();
    $stats = $statsResult->fetch_assoc();
    
    // Aggiorna le statistiche nel template
    $template['rating_average'] = number_format($stats['rating_average'], 2);
    $template['rating_count'] = intval($stats['rating_count']);
    
    // Query per ottenere gli esercizi del template
    $exercisesQuery = "
        SELECT 
            te.id,
            te.exercise_id,
            e.nome as exercise_name,
            e.descrizione as exercise_description,
            e.gruppo_muscolare as muscle_groups,
            COALESCE(e.attrezzatura, '') as equipment,
            COALESCE(e.immagine_url, '') as image_url,
            COALESCE(e.is_isometric, 0) as is_isometric,
            COALESCE(te.sets, 0) as sets,
            COALESCE(te.reps_min, 0) as reps_min,
            COALESCE(te.reps_max, 0) as reps_max,
            CAST(COALESCE(te.weight_percentage, 0) AS DECIMAL(5,2)) as weight_percentage,
            COALESCE(te.rest_seconds, 0) as rest_seconds,
            COALESCE(te.set_type, '') as set_type,
            COALESCE(te.order_index, 0) as order_index,
            COALESCE(te.linked_to_previous, 0) as linked_to_previous,
            COALESCE(te.is_rest_pause, 0) as is_rest_pause,
            CAST(COALESCE(te.rest_pause_reps, 0) AS UNSIGNED) as rest_pause_reps,
            COALESCE(te.rest_pause_rest_seconds, 0) as rest_pause_rest_seconds,
            COALESCE(te.notes, '') as notes
        FROM template_exercises te
        JOIN esercizi e ON te.exercise_id = e.id
        WHERE te.template_id = ?
        ORDER BY te.order_index ASC
    ";
    
    $stmt = $conn->prepare($exercisesQuery);
    $stmt->bind_param('i', $templateId);
    $stmt->execute();
    $exercisesResult = $stmt->get_result();
    
    $exercises = [];
    while ($row = $exercisesResult->fetch_assoc()) {
        $exercises[] = $row;
    }
    
    // Aggiungi esercizi al template
    $template['exercises'] = $exercises;
    $template['exercise_count'] = count($exercises);
    
    echo json_encode([
        'success' => true,
        'template' => $template
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Errore interno del server',
        'message' => $e->getMessage()
    ]);
}
?>