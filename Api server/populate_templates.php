<?php
// populate_templates.php - Popola i template con esercizi appropriati
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    // Prima svuota la tabella template_exercises
    $conn->query("DELETE FROM template_exercises");
    
    // Template 1: Full Body Principiante
    $template1_exercises = [
        ['exercise_id' => 196, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 1], // Squat
        ['exercise_id' => 151, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 15, 'rest_seconds' => 60, 'order_index' => 2], // Push-up
        ['exercise_id' => 158, 'sets' => 3, 'reps_min' => 5, 'reps_max' => 10, 'rest_seconds' => 90, 'order_index' => 3], // Trazioni
        ['exercise_id' => 200, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 60, 'order_index' => 4], // Affondi
        ['exercise_id' => 207, 'sets' => 3, 'reps_min' => 30, 'reps_max' => 60, 'rest_seconds' => 45, 'order_index' => 5], // Plank
    ];
    
    // Template 2: Push/Pull/Legs Base
    $template2_exercises = [
        // Push Day
        ['exercise_id' => 146, 'sets' => 4, 'reps_min' => 6, 'reps_max' => 10, 'rest_seconds' => 120, 'order_index' => 1], // Panca Piana
        ['exercise_id' => 166, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 2], // Military Press
        ['exercise_id' => 149, 'sets' => 3, 'reps_min' => 10, 'reps_max' => 15, 'rest_seconds' => 60, 'order_index' => 3], // Croci
        ['exercise_id' => 186, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 4], // French Press
        ['exercise_id' => 167, 'sets' => 3, 'reps_min' => 10, 'reps_max' => 15, 'rest_seconds' => 60, 'order_index' => 5], // Alzate Laterali
    ];
    
    // Template 3: Upper/Lower Principiante
    $template3_exercises = [
        // Upper Day
        ['exercise_id' => 146, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 1], // Panca Piana
        ['exercise_id' => 157, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 2], // Rematore
        ['exercise_id' => 166, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 3], // Military Press
        ['exercise_id' => 176, 'sets' => 3, 'reps_min' => 10, 'reps_max' => 15, 'rest_seconds' => 60, 'order_index' => 4], // Curl
        ['exercise_id' => 186, 'sets' => 3, 'reps_min' => 10, 'reps_max' => 15, 'rest_seconds' => 60, 'order_index' => 5], // French Press
    ];
    
    // Template 4: Push/Pull/Legs Avanzato
    $template4_exercises = [
        // Push Day Avanzato
        ['exercise_id' => 146, 'sets' => 5, 'reps_min' => 3, 'reps_max' => 6, 'rest_seconds' => 180, 'order_index' => 1], // Panca Piana
        ['exercise_id' => 147, 'sets' => 4, 'reps_min' => 6, 'reps_max' => 10, 'rest_seconds' => 120, 'order_index' => 2], // Panca Inclinata
        ['exercise_id' => 166, 'sets' => 4, 'reps_min' => 6, 'reps_max' => 10, 'rest_seconds' => 120, 'order_index' => 3], // Military Press
        ['exercise_id' => 149, 'sets' => 3, 'reps_min' => 12, 'reps_max' => 20, 'rest_seconds' => 60, 'order_index' => 4], // Croci
        ['exercise_id' => 186, 'sets' => 4, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 5], // French Press
        ['exercise_id' => 167, 'sets' => 3, 'reps_min' => 12, 'reps_max' => 20, 'rest_seconds' => 60, 'order_index' => 6], // Alzate Laterali
    ];
    
    // Template 5: Powerlifting Base
    $template5_exercises = [
        ['exercise_id' => 196, 'sets' => 5, 'reps_min' => 3, 'reps_max' => 5, 'rest_seconds' => 240, 'order_index' => 1], // Squat
        ['exercise_id' => 146, 'sets' => 5, 'reps_min' => 3, 'reps_max' => 5, 'rest_seconds' => 240, 'order_index' => 2], // Panca Piana
        ['exercise_id' => 156, 'sets' => 5, 'reps_min' => 3, 'reps_max' => 5, 'rest_seconds' => 240, 'order_index' => 3], // Stacco da Terra
        ['exercise_id' => 197, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 4], // Leg Press
        ['exercise_id' => 157, 'sets' => 3, 'reps_min' => 8, 'reps_max' => 12, 'rest_seconds' => 90, 'order_index' => 5], // Rematore
    ];
    
    $templates = [
        1 => $template1_exercises,
        2 => $template2_exercises,
        3 => $template3_exercises,
        4 => $template4_exercises,
        5 => $template5_exercises
    ];
    
    $total_inserted = 0;
    
    foreach ($templates as $template_id => $exercises) {
        foreach ($exercises as $exercise) {
            $stmt = $conn->prepare("INSERT INTO template_exercises (template_id, exercise_id, sets, reps_min, reps_max, rest_seconds, order_index) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->bind_param("iiiiiii", 
                $template_id,
                $exercise['exercise_id'],
                $exercise['sets'],
                $exercise['reps_min'],
                $exercise['reps_max'],
                $exercise['rest_seconds'],
                $exercise['order_index']
            );
            
            if ($stmt->execute()) {
                $total_inserted++;
            }
            $stmt->close();
        }
    }
    
    // Verifica il risultato
    $result = $conn->query("SELECT COUNT(*) as total FROM template_exercises");
    $count = $result->fetch_assoc()['total'];
    
    echo json_encode([
        'success' => true,
        'message' => 'Template popolati con successo!',
        'total_inserted' => $total_inserted,
        'total_template_exercises' => $count,
        'templates_populated' => array_keys($templates)
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>






