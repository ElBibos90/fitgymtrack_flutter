<?php
// create_workout_from_template.php - API per creare una scheda di allenamento da un template
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'config.php';
require_once 'auth_functions.php';
require_once 'subscription_limits.php';

// Funzione di debug
function debug_log($message, $data = null) {
    error_log("CREATE_FROM_TEMPLATE_DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("CREATE_FROM_TEMPLATE_DATA: " . print_r($data, true));
    }
}

// Funzione per verificare se l'utente ha accesso ai template premium
function hasPremiumAccess($userId) {
    global $conn;
    
    // Verifica se l'utente ha un abbonamento Premium attivo
    $stmt = $conn->prepare("
        SELECT sp.name, sp.price
        FROM users u
        JOIN subscription_plans sp ON u.current_plan_id = sp.id
        WHERE u.id = ? AND u.current_plan_id IS NOT NULL
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $plan = $result->fetch_assoc();
        // Un piano è Premium se il nome non è 'Free' o se il prezzo è > 0
        return $plan['name'] !== 'Free' || $plan['price'] > 0;
    }
    
    // Fallback: verifica tramite subscription attiva
    $stmt = $conn->prepare("
        SELECT sp.name, sp.price
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ? 
        AND us.status = 'active' 
        AND (us.end_date IS NULL OR us.end_date > NOW())
        ORDER BY us.created_at DESC 
        LIMIT 1
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $subscription = $result->fetch_assoc();
        // Un piano è Premium se il nome non è 'Free' o se il prezzo è > 0
        return $subscription['name'] !== 'Free' || $subscription['price'] > 0;
    }
    
    return false; // Default: utente free
}

// Funzione per calcolare il peso iniziale basato sul livello utente
function calculateInitialWeight($weightPercentage, $difficultyLevel, $exerciseId) {
    // Pesi di base per principianti (in kg)
    $baseWeights = [
        // Esercizi principali
        1 => 20,  // Panca piana
        2 => 30,  // Squat
        3 => 40,  // Stacco
        4 => 15,  // Military press
        5 => 10,  // Curl bicipiti
        6 => 8,   // French press
        7 => 25,  // Lat machine
        8 => 20,  // Remata
        9 => 12,  // Alzate laterali
        10 => 8,  // Alzate posteriori
    ];
    
    $baseWeight = $baseWeights[$exerciseId] ?? 10; // Default 10kg
    
    // Moltiplicatori per difficoltà
    $multipliers = [
        'beginner' => 0.5,
        'intermediate' => 0.75,
        'advanced' => 1.0
    ];
    
    $multiplier = $multipliers[$difficultyLevel] ?? 0.5;
    $calculatedWeight = $baseWeight * $multiplier;
    
    // Applica la percentuale del template
    if ($weightPercentage) {
        $calculatedWeight = $calculatedWeight * ($weightPercentage / 100);
    }
    
    return round($calculatedWeight, 1);
}

// Funzione per adattare le ripetizioni al livello utente
function adaptReps($repsMin, $repsMax, $difficultyLevel) {
    $adaptations = [
        'beginner' => ['min' => 0.8, 'max' => 1.0], // Riduce le ripetizioni
        'intermediate' => ['min' => 1.0, 'max' => 1.0], // Mantiene le ripetizioni
        'advanced' => ['min' => 1.0, 'max' => 1.2] // Aumenta le ripetizioni
    ];
    
    $adaptation = $adaptations[$difficultyLevel] ?? $adaptations['beginner'];
    
    $newMin = max(1, round($repsMin * $adaptation['min']));
    $newMax = max($newMin, round($repsMax * $adaptation['max']));
    
    return ['min' => $newMin, 'max' => $newMax];
}

$method = $_SERVER['REQUEST_METHOD'];
debug_log("Richiesta ricevuta: $method");

try {
    if ($method === 'POST') {
        // Verifica autenticazione
        $userData = authMiddleware($conn);
        if (!$userData) {
            exit();
        }
        
        $userId = $userData['user_id'];
        $hasPremium = hasPremiumAccess($userId);
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        // Validazione input
        if (!isset($input['template_id']) || !isset($input['workout_name'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Template ID e nome scheda richiesti']);
            exit();
        }
        
        $templateId = intval($input['template_id']);
        $workoutName = trim($input['workout_name']);
        $workoutDescription = isset($input['workout_description']) ? trim($input['workout_description']) : null;
        
        if (empty($workoutName)) {
            http_response_code(400);
            echo json_encode(['error' => 'Nome scheda non può essere vuoto']);
            exit();
        }
        
        // Verifica limiti abbonamento
        $limitCheck = checkWorkoutLimit($userId);
        if ($limitCheck['limit_reached']) {
            http_response_code(403);
            echo json_encode([
                'error' => 'Limite schede raggiunto',
                'limit_info' => $limitCheck
            ]);
            exit();
        }
        
        // Verifica che il template esista e l'utente abbia accesso
        $stmt = $conn->prepare("
            SELECT wt.*, tc.name as category_name
            FROM workout_templates wt
            JOIN template_categories tc ON wt.category_id = tc.id
            WHERE wt.id = ? AND wt.is_active = 1
        ");
        $stmt->bind_param('i', $templateId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Template non trovato']);
            exit();
        }
        
        $template = $result->fetch_assoc();
        
        if ($template['is_premium'] && !$hasPremium) {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato. Template premium richiesto.']);
            exit();
        }
        
        // Ottieni gli esercizi del template
        $exercisesStmt = $conn->prepare("
            SELECT 
                te.exercise_id,
                te.order_index,
                te.sets,
                te.reps_min,
                te.reps_max,
                te.weight_percentage,
                te.rest_seconds,
                te.set_type,
                te.linked_to_previous,
                te.is_rest_pause,
                te.rest_pause_reps,
                te.rest_pause_rest_seconds,
                te.notes
            FROM template_exercises te
            WHERE te.template_id = ?
            ORDER BY te.order_index
        ");
        
        $exercisesStmt->bind_param('i', $templateId);
        $exercisesStmt->execute();
        $exercisesResult = $exercisesStmt->get_result();
        
        if ($exercisesResult->num_rows === 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Template non contiene esercizi']);
            exit();
        }
        
        $templateExercises = [];
        while ($exercise = $exercisesResult->fetch_assoc()) {
            $templateExercises[] = $exercise;
        }
        
        // Inizia transazione
        $conn->begin_transaction();
        
        try {
            // Crea la scheda
            $createSchedaStmt = $conn->prepare("
                INSERT INTO schede (nome, descrizione, data_creazione, active) 
                VALUES (?, ?, NOW(), 1)
            ");
            $createSchedaStmt->bind_param('ss', $workoutName, $workoutDescription);
            $createSchedaStmt->execute();
            $schedaId = $conn->insert_id;
            
            // Crea l'associazione utente-scheda
            $assignStmt = $conn->prepare("
                INSERT INTO user_workout_assignments (user_id, scheda_id, active, assigned_date) 
                VALUES (?, ?, 1, NOW())
            ");
            $assignStmt->bind_param('ii', $userId, $schedaId);
            $assignStmt->execute();
            
            // Aggiungi gli esercizi alla scheda
            foreach ($templateExercises as $templateExercise) {
                // Adatta le ripetizioni al livello utente
                $adaptedReps = adaptReps(
                    $templateExercise['reps_min'], 
                    $templateExercise['reps_max'], 
                    $template['difficulty_level']
                );
                
                // Calcola il peso iniziale
                $initialWeight = calculateInitialWeight(
                    $templateExercise['weight_percentage'],
                    $template['difficulty_level'],
                    $templateExercise['exercise_id']
                );
                
                // Usa le ripetizioni adattate (media tra min e max)
                $reps = round(($adaptedReps['min'] + $adaptedReps['max']) / 2);
                
                // Prepara i dati per l'inserimento
                $sets = $templateExercise['sets'];
                $restSeconds = $templateExercise['rest_seconds'];
                $setType = $templateExercise['set_type'];
                $linkedToPrevious = $templateExercise['linked_to_previous'] ? 1 : 0;
                $isRestPause = $templateExercise['is_rest_pause'] ? 1 : 0;
                $restPauseReps = $templateExercise['rest_pause_reps'];
                $restPauseRestSeconds = $templateExercise['rest_pause_rest_seconds'];
                $notes = $templateExercise['notes'];
                $orderIndex = $templateExercise['order_index'];
                
                $insertExerciseStmt = $conn->prepare("
                    INSERT INTO scheda_esercizi 
                    (scheda_id, esercizio_id, serie, ripetizioni, peso, note, tempo_recupero, 
                     set_type, linked_to_previous, ordine, is_rest_pause, rest_pause_reps, rest_pause_rest_seconds) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ");
                
                $insertExerciseStmt->bind_param(
                    'iiiisissiiisi',
                    $schedaId,
                    $templateExercise['exercise_id'],
                    $sets,
                    $reps,
                    $initialWeight,
                    $notes,
                    $restSeconds,
                    $setType,
                    $linkedToPrevious,
                    $orderIndex,
                    $isRestPause,
                    $restPauseReps,
                    $restPauseRestSeconds
                );
                
                $insertExerciseStmt->execute();
            }
            
            // Registra l'utilizzo del template
            $logStmt = $conn->prepare("
                INSERT INTO template_usage_log (user_id, template_id, action) 
                VALUES (?, ?, 'created_workout')
            ");
            $logStmt->bind_param('ii', $userId, $templateId);
            $logStmt->execute();
            
            // Incrementa manualmente il conteggio utilizzi del template
            $updateUsageStmt = $conn->prepare("
                UPDATE workout_templates 
                SET usage_count = usage_count + 1 
                WHERE id = ?
            ");
            $updateUsageStmt->bind_param('i', $templateId);
            $updateUsageStmt->execute();
            
            // Commit transazione
            $conn->commit();
            
            // Recupera la scheda creata con tutti i dettagli
            $schedaStmt = $conn->prepare("
                SELECT s.*, 
                       COUNT(se.id) as total_exercises
                FROM schede s
                LEFT JOIN scheda_esercizi se ON s.id = se.scheda_id
                WHERE s.id = ?
                GROUP BY s.id
            ");
            $schedaStmt->bind_param('i', $schedaId);
            $schedaStmt->execute();
            $schedaResult = $schedaStmt->get_result();
            $scheda = $schedaResult->fetch_assoc();
            
            debug_log("Scheda creata con successo", [
                'scheda_id' => $schedaId,
                'template_id' => $templateId,
                'user_id' => $userId,
                'total_exercises' => $scheda['total_exercises']
            ]);
            
            echo json_encode([
                'success' => true,
                'message' => 'Scheda creata con successo dal template',
                'workout' => $scheda,
                'template_used' => [
                    'id' => $template['id'],
                    'name' => $template['name'],
                    'category' => $template['category_name']
                ]
            ]);
            
        } catch (Exception $e) {
            $conn->rollback();
            throw $e;
        }
        
    } else {
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non supportato']);
    }
    
} catch (Exception $e) {
    debug_log("Errore: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore interno del server: ' . $e->getMessage()]);
}
?>
