<?php
// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - accetta richieste da ambienti multipli
if (isset($_SERVER['HTTP_ORIGIN'])) {
    $allowed_origins = ['http://localhost:3000', 
        'http://192.168.1.113', 
        'http://104.248.103.182',
        'http://fitgymtrack.com',
        'https://fitgymtrack.com',
        'http://www.fitgymtrack.com',
        'https://www.fitgymtrack.com'];
    if (in_array($_SERVER['HTTP_ORIGIN'], $allowed_origins)) {
        header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 86400');    // cache per 1 giorno
    }
}

// Gestione richieste OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'])) {
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    }
    
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }

    exit(0);
}

header('Content-Type: application/json');

include 'config.php';
require_once 'auth_functions.php';

// Verifica autenticazione
$userData = authMiddleware($conn);
if (!$userData) {
    exit();
}

$userId = $userData['user_id'];

// Verifica se l'utente ha sottoscrizione premium per statistiche avanzate
function hasAdvancedStats($conn, $userId) {
    // Metodo 1: Verifica tramite current_plan_id dell'utente
    $stmt = $conn->prepare("
        SELECT sp.advanced_stats
        FROM users u
        JOIN subscription_plans sp ON u.current_plan_id = sp.id
        WHERE u.id = ?
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $plan = $result->fetch_assoc();
        return (bool)$plan['advanced_stats'];
    }
    
    // Metodo 2: Fallback tramite subscription attiva
    $stmt = $conn->prepare("
        SELECT sp.advanced_stats
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ? 
        AND us.status = 'active' 
        AND (us.end_date IS NULL OR us.end_date > NOW())
        ORDER BY us.created_at DESC 
        LIMIT 1
    ");
    
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $subscription = $result->fetch_assoc();
        return (bool)$subscription['advanced_stats'];
    }
    
    return false; // Default free user
}

try {
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method !== 'GET') {
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
        exit();
    }
    
    $isPremium = hasAdvancedStats($conn, $userId);
    
    // === STATISTICHE BASE (Free + Premium) ===
    
    // 1. Total workouts (completati = durata_totale > 0)
    $stmt = $conn->prepare("
        SELECT COUNT(*) as total_workouts 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $totalWorkouts = $stmt->get_result()->fetch_assoc()['total_workouts'];
    
    // 2. Total duration in minutes
    $stmt = $conn->prepare("
        SELECT COALESCE(SUM(durata_totale), 0) as total_duration 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $totalDuration = $stmt->get_result()->fetch_assoc()['total_duration'];
    
    // 3. Total series
    $stmt = $conn->prepare("
        SELECT COUNT(*) as total_series 
        FROM serie_completate sc
        JOIN allenamenti a ON sc.allenamento_id = a.id
        WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $totalSeries = $stmt->get_result()->fetch_assoc()['total_series'];
    
    // 4. Current streak (giorni consecutivi)
    $stmt = $conn->prepare("
        SELECT DATE(data_allenamento) as workout_date
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
        ORDER BY data_allenamento DESC
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $workoutDates = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    
    $currentStreak = calculateCurrentStreak($workoutDates);
    $longestStreak = calculateLongestStreak($workoutDates);
    
    // 5. Workouts this week
    $stmt = $conn->prepare("
        SELECT COUNT(*) as workouts_this_week 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
        AND data_allenamento >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
        AND data_allenamento < DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY)
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $workoutsThisWeek = $stmt->get_result()->fetch_assoc()['workouts_this_week'];
    
    // 6. Workouts this month
    $stmt = $conn->prepare("
        SELECT COUNT(*) as workouts_this_month 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
        AND YEAR(data_allenamento) = YEAR(CURDATE()) 
        AND MONTH(data_allenamento) = MONTH(CURDATE())
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $workoutsThisMonth = $stmt->get_result()->fetch_assoc()['workouts_this_month'];
    
    // 7. Average workout duration
    $averageDuration = $totalWorkouts > 0 ? ($totalDuration / $totalWorkouts) : 0;
    
    // 8. Total weight lifted
    $stmt = $conn->prepare("
        SELECT COALESCE(SUM(sc.peso * sc.ripetizioni), 0) as total_weight 
        FROM serie_completate sc
        JOIN allenamenti a ON sc.allenamento_id = a.id
        WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1 AND sc.peso IS NOT NULL
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $totalWeight = $stmt->get_result()->fetch_assoc()['total_weight'];
    
    // 9. First and last workout dates
    $stmt = $conn->prepare("
        SELECT DATE(MIN(data_allenamento)) as first_date, DATE(MAX(data_allenamento)) as last_date 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $dates = $stmt->get_result()->fetch_assoc();
    
    // Costruisci la risposta base
    $stats = [
        'total_workouts' => (int)$totalWorkouts,
        'total_duration_minutes' => (int)$totalDuration,
        'total_series' => (int)$totalSeries,
        'current_streak' => $currentStreak,
        'longest_streak' => $longestStreak,
        'workouts_this_week' => (int)$workoutsThisWeek,
        'workouts_this_month' => (int)$workoutsThisMonth,
        'average_workout_duration' => round($averageDuration, 1),
        'total_weight_lifted_kg' => round($totalWeight, 2),
        'first_workout_date' => $dates['first_date'],
        'last_workout_date' => $dates['last_date']
    ];
    
    // === STATISTICHE AVANZATE (Solo Premium) ===
    if ($isPremium) {
        // 10. Most trained muscle group
        $stmt = $conn->prepare("
            SELECT e.gruppo_muscolare, COUNT(*) as count
            FROM serie_completate sc
            JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
            JOIN esercizi e ON se.esercizio_id = e.id
            JOIN allenamenti a ON sc.allenamento_id = a.id
            WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1
            GROUP BY e.gruppo_muscolare
            ORDER BY count DESC
            LIMIT 1
        ");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $mostTrainedResult = $stmt->get_result()->fetch_assoc();
        $stats['most_trained_muscle_group'] = $mostTrainedResult['gruppo_muscolare'] ?? null;
        
        // 11. Favorite exercise (most performed)
        $stmt = $conn->prepare("
            SELECT e.nome, COUNT(*) as count
            FROM serie_completate sc
            JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
            JOIN esercizi e ON se.esercizio_id = e.id
            JOIN allenamenti a ON sc.allenamento_id = a.id
            WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1
            GROUP BY e.id, e.nome
            ORDER BY count DESC
            LIMIT 1
        ");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $favoriteResult = $stmt->get_result()->fetch_assoc();
        $stats['favorite_exercise'] = $favoriteResult['nome'] ?? null;
        
        // 12. Progress trends (ultimi 30 giorni)
        $stmt = $conn->prepare("
            SELECT 
                DATE(a.data_allenamento) as workout_date,
                COUNT(DISTINCT a.id) as workout_count,
                SUM(a.durata_totale) as total_duration,
                COUNT(sc.id) as series_count,
                SUM(sc.peso * sc.ripetizioni) as total_volume
            FROM allenamenti a
            LEFT JOIN serie_completate sc ON a.id = sc.allenamento_id AND sc.completata = 1
            WHERE a.user_id = ? AND a.durata_totale > 0
            AND a.data_allenamento >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(a.data_allenamento)
            ORDER BY workout_date DESC
        ");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $progressData = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stats['progress_trend_30_days'] = $progressData;
        
        // 13. Top 5 exercises by volume
        $stmt = $conn->prepare("
            SELECT 
                e.nome as exercise_name,
                SUM(sc.peso * sc.ripetizioni) as total_volume,
                COUNT(sc.id) as series_count,
                AVG(sc.peso) as avg_weight,
                AVG(sc.ripetizioni) as avg_reps
            FROM serie_completate sc
            JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
            JOIN esercizi e ON se.esercizio_id = e.id
            JOIN allenamenti a ON sc.allenamento_id = a.id
            WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1 AND sc.peso IS NOT NULL
            GROUP BY e.id, e.nome
            ORDER BY total_volume DESC
            LIMIT 5
        ");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $topExercises = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stats['top_exercises_by_volume'] = $topExercises;
        
        // 14. Weekly comparison (this week vs last week)
        $stmt = $conn->prepare("
            SELECT 
                CASE 
                    WHEN a.data_allenamento >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) THEN 'this_week'
                    ELSE 'last_week'
                END as week_period,
                COUNT(DISTINCT a.id) as workout_count,
                SUM(a.durata_totale) as total_duration,
                COUNT(sc.id) as series_count,
                SUM(sc.peso * sc.ripetizioni) as total_volume
            FROM allenamenti a
            LEFT JOIN serie_completate sc ON a.id = sc.allenamento_id AND sc.completata = 1
            WHERE a.user_id = ? AND a.durata_totale > 0
            AND a.data_allenamento >= DATE_SUB(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 7 DAY)
            GROUP BY CASE 
                WHEN a.data_allenamento >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) THEN 'this_week'
                ELSE 'last_week'
            END
        ");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $weeklyComparison = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stats['weekly_comparison'] = $weeklyComparison;
    }
    
    echo json_encode([
        'success' => true,
        'stats' => $stats,
        'is_premium' => $isPremium,
        'message' => $isPremium ? 'Statistiche avanzate caricate' : 'Statistiche base caricate'
    ]);

} catch (Exception $e) {
    error_log("Errore nel recupero delle statistiche utente: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

/**
 * Calcola la streak corrente (giorni consecutivi di allenamento)
 */
function calculateCurrentStreak($workoutDates) {
    if (empty($workoutDates)) return 0;
    
    $streak = 0;
    $lastDate = null;
    
    foreach ($workoutDates as $workout) {
        $currentDate = new DateTime($workout['workout_date']);
        
        if ($lastDate === null) {
            // Primo allenamento
            $today = new DateTime();
            $daysDiff = $today->diff($currentDate)->days;
            
            // Se l'ultimo allenamento è oggi o ieri, inizia la streak
            if ($daysDiff <= 1) {
                $streak = 1;
                $lastDate = $currentDate;
            } else {
                break; // Troppo tempo fa, nessuna streak
            }
        } else {
            // Verifica se è consecutivo
            $daysDiff = $lastDate->diff($currentDate)->days;
            
            if ($daysDiff === 1) {
                $streak++;
                $lastDate = $currentDate;
            } else {
                break; // Fine della streak
            }
        }
    }
    
    return $streak;
}

/**
 * Calcola la streak più lunga nella storia
 */
function calculateLongestStreak($workoutDates) {
    if (empty($workoutDates)) return 0;
    
    $longestStreak = 0;
    $currentStreak = 1;
    $lastDate = null;
    
    // Ordina le date in ordine cronologico
    usort($workoutDates, function($a, $b) {
        return strtotime($a['workout_date']) - strtotime($b['workout_date']);
    });
    
    foreach ($workoutDates as $workout) {
        $currentDate = new DateTime($workout['workout_date']);
        
        if ($lastDate !== null) {
            $daysDiff = $lastDate->diff($currentDate)->days;
            
            if ($daysDiff === 1) {
                $currentStreak++;
            } else {
                $longestStreak = max($longestStreak, $currentStreak);
                $currentStreak = 1;
            }
        }
        
        $lastDate = $currentDate;
    }
    
    return max($longestStreak, $currentStreak);
}

$conn->close();
?>