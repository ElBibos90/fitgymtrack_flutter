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

/**
 * Calcola le date di inizio e fine per il periodo richiesto
 */
function calculatePeriodDates($period) {
    $today = new DateTime();
    
    switch ($period) {
        case 'week':
            $startDate = clone $today;
            $startDate->modify('last monday'); // Lunedì della settimana corrente
            $endDate = clone $startDate;
            $endDate->modify('+6 days'); // Domenica
            break;
            
        case 'month':
            $startDate = new DateTime($today->format('Y-m-01')); // Primo del mese
            $endDate = clone $startDate;
            $endDate->modify('last day of this month'); // Ultimo del mese
            break;
            
        case 'year':
            $startDate = new DateTime($today->format('Y-01-01')); // Primo gennaio
            $endDate = new DateTime($today->format('Y-12-31')); // 31 dicembre
            break;
            
        case 'last_week':
            $startDate = new DateTime();
            $startDate->modify('last monday')->modify('-7 days');
            $endDate = clone $startDate;
            $endDate->modify('+6 days');
            break;
            
        case 'last_month':
            $startDate = new DateTime();
            $startDate->modify('first day of last month');
            $endDate = new DateTime();
            $endDate->modify('last day of last month');
            break;
            
        case 'last_year':
            $lastYear = (int)$today->format('Y') - 1;
            $startDate = new DateTime($lastYear . '-01-01');
            $endDate = new DateTime($lastYear . '-12-31');
            break;
            
        default:
            throw new Exception("Periodo non valido: $period");
    }
    
    return [
        'start' => $startDate->format('Y-m-d'),
        'end' => $endDate->format('Y-m-d')
    ];
}

/**
 * Ottiene il periodo precedente per il confronto
 */
function getPreviousPeriod($period) {
    switch ($period) {
        case 'week': return 'last_week';
        case 'month': return 'last_month';
        case 'year': return 'last_year';
        default: return null;
    }
}

/**
 * Calcola la percentuale di miglioramento
 */
function calculateImprovementPercentage($current, $previous) {
    if ($previous == 0) return $current > 0 ? 100 : 0;
    return round((($current - $previous) / $previous) * 100, 1);
}

try {
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method !== 'GET') {
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
        exit();
    }
    
    // Verifica parametro period
    $period = $_GET['period'] ?? 'week';
    $allowedPeriods = ['week', 'month', 'year', 'last_week', 'last_month', 'last_year'];
    
    if (!in_array($period, $allowedPeriods)) {
        http_response_code(400);
        echo json_encode(['error' => 'Periodo non valido. Valori ammessi: ' . implode(', ', $allowedPeriods)]);
        exit();
    }
    
    $isPremium = hasAdvancedStats($conn, $userId);
    $dates = calculatePeriodDates($period);
    
    // === STATISTICHE BASE PER PERIODO (Free + Premium) ===
    
    // 1. Count allenamenti nel periodo (completati = durata_totale > 0)
    $stmt = $conn->prepare("
        SELECT COUNT(*) as workout_count 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
        AND data_allenamento >= ? AND data_allenamento <= ?
    ");
    $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
    $stmt->execute();
    $workoutCount = $stmt->get_result()->fetch_assoc()['workout_count'];
    
    // 2. Durata totale nel periodo
    $stmt = $conn->prepare("
        SELECT COALESCE(SUM(durata_totale), 0) as total_duration 
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
        AND data_allenamento >= ? AND data_allenamento <= ?
    ");
    $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
    $stmt->execute();
    $totalDuration = $stmt->get_result()->fetch_assoc()['total_duration'];
    
    // 3. Serie totali nel periodo
    $stmt = $conn->prepare("
        SELECT COUNT(*) as total_series 
        FROM serie_completate sc
        JOIN allenamenti a ON sc.allenamento_id = a.id
        WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1
        AND a.data_allenamento >= ? AND a.data_allenamento <= ?
    ");
    $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
    $stmt->execute();
    $totalSeries = $stmt->get_result()->fetch_assoc()['total_series'];
    
    // 4. Peso totale sollevato nel periodo
    $stmt = $conn->prepare("
        SELECT COALESCE(SUM(sc.peso * sc.ripetizioni), 0) as total_weight 
        FROM serie_completate sc
        JOIN allenamenti a ON sc.allenamento_id = a.id
        WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1 AND sc.peso IS NOT NULL
        AND a.data_allenamento >= ? AND a.data_allenamento <= ?
    ");
    $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
    $stmt->execute();
    $totalWeight = $stmt->get_result()->fetch_assoc()['total_weight'];
    
    // 5. Durata media allenamento
    $averageDuration = $workoutCount > 0 ? ($totalDuration / $workoutCount) : 0;
    
    // 6. Giorno più attivo nel periodo
    $stmt = $conn->prepare("
        SELECT DAYNAME(data_allenamento) as day_name, COUNT(*) as workout_count
        FROM allenamenti 
        WHERE user_id = ? AND durata_totale > 0
        AND data_allenamento >= ? AND data_allenamento <= ?
        GROUP BY DAYNAME(data_allenamento), DAYOFWEEK(data_allenamento)
        ORDER BY workout_count DESC
        LIMIT 1
    ");
    $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
    $stmt->execute();
    $mostActiveResult = $stmt->get_result()->fetch_assoc();
    $mostActiveDay = $mostActiveResult['day_name'] ?? null;
    
    // Costruisci la risposta base
    $stats = [
        'period' => $period,
        'start_date' => $dates['start'],
        'end_date' => $dates['end'],
        'workout_count' => (int)$workoutCount,
        'total_duration_minutes' => (int)$totalDuration,
        'total_series' => (int)$totalSeries,
        'total_weight_kg' => round($totalWeight, 2),
        'average_duration' => round($averageDuration, 1),
        'most_active_day' => $mostActiveDay
    ];
    
    // === STATISTICHE AVANZATE PER PERIODO (Solo Premium) ===
    if ($isPremium) {
        // 7. Distribuzione per giorno della settimana
        $stmt = $conn->prepare("
            SELECT 
                DAYNAME(data_allenamento) as day_name,
                DAYOFWEEK(data_allenamento) as day_number,
                COUNT(*) as workout_count,
                SUM(durata_totale) as total_duration,
                AVG(durata_totale) as avg_duration
            FROM allenamenti 
            WHERE user_id = ? AND durata_totale > 0
            AND data_allenamento >= ? AND data_allenamento <= ?
            GROUP BY DAYNAME(data_allenamento), DAYOFWEEK(data_allenamento)
            ORDER BY day_number
        ");
        $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
        $stmt->execute();
        $weeklyDistribution = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stats['weekly_distribution'] = $weeklyDistribution;
        
        // 8. Gruppi muscolari allenati nel periodo
        $stmt = $conn->prepare("
            SELECT 
                e.gruppo_muscolare,
                COUNT(DISTINCT a.id) as sessions_count,
                COUNT(sc.id) as series_count,
                SUM(sc.peso * sc.ripetizioni) as total_volume
            FROM serie_completate sc
            JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
            JOIN esercizi e ON se.esercizio_id = e.id
            JOIN allenamenti a ON sc.allenamento_id = a.id
            WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1
            AND a.data_allenamento >= ? AND a.data_allenamento <= ?
            GROUP BY e.gruppo_muscolare
            ORDER BY total_volume DESC
        ");
        $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
        $stmt->execute();
        $muscleGroupStats = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stats['muscle_group_distribution'] = $muscleGroupStats;
        
        // 9. Progressione nel periodo (solo per periodi lunghi)
        if (in_array($period, ['month', 'year', 'last_month', 'last_year'])) {
            if ($period === 'year' || $period === 'last_year') {
                // Raggruppa per mese - QUERY CORRETTA
                $stmt = $conn->prepare("
                    SELECT 
                        DATE_FORMAT(data_allenamento, '%Y-%m') as period_group,
                        DATE_FORMAT(data_allenamento, '%Y-%m') as workout_date,
                        COUNT(*) as daily_workouts,
                        SUM(durata_totale) as daily_duration,
                        SUM((SELECT COUNT(*) FROM serie_completate WHERE allenamento_id = a.id AND completata = 1)) as daily_series
                    FROM allenamenti a
                    WHERE user_id = ? AND durata_totale > 0
                    AND data_allenamento >= ? AND data_allenamento <= ?
                    GROUP BY DATE_FORMAT(data_allenamento, '%Y-%m')
                    ORDER BY period_group
                ");
            } else {
                // Raggruppa per giorno
                $stmt = $conn->prepare("
                    SELECT 
                        DATE(data_allenamento) as workout_date,
                        COUNT(*) as daily_workouts,
                        SUM(durata_totale) as daily_duration,
                        SUM((SELECT COUNT(*) FROM serie_completate WHERE allenamento_id = a.id AND completata = 1)) as daily_series
                    FROM allenamenti a
                    WHERE user_id = ? AND durata_totale > 0
                    AND data_allenamento >= ? AND data_allenamento <= ?
                    GROUP BY DATE(data_allenamento)
                    ORDER BY workout_date
                ");
            }
            
            $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
            $stmt->execute();
            $progressionData = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
            $stats['progression_data'] = $progressionData;
        }
        
        // 10. Top esercizi per volume nel periodo
        $stmt = $conn->prepare("
            SELECT 
                e.nome as exercise_name,
                COUNT(sc.id) as series_performed,
                SUM(sc.peso * sc.ripetizioni) as total_volume,
                AVG(sc.peso) as avg_weight,
                MAX(sc.peso) as max_weight
            FROM serie_completate sc
            JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
            JOIN esercizi e ON se.esercizio_id = e.id
            JOIN allenamenti a ON sc.allenamento_id = a.id
            WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1 AND sc.peso IS NOT NULL
            AND a.data_allenamento >= ? AND a.data_allenamento <= ?
            GROUP BY e.id, e.nome
            ORDER BY total_volume DESC
            LIMIT 10
        ");
        $stmt->bind_param("iss", $userId, $dates['start'], $dates['end']);
        $stmt->execute();
        $topExercises = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stats['top_exercises_period'] = $topExercises;
        
        // 11. Confronto con periodo precedente (solo per premium)
        $previousPeriod = getPreviousPeriod($period);
        if ($previousPeriod) {
            $prevDates = calculatePeriodDates($previousPeriod);
            
            $stmt = $conn->prepare("
                SELECT 
                    COUNT(DISTINCT a.id) as prev_workout_count,
                    COALESCE(SUM(a.durata_totale), 0) as prev_total_duration
                FROM allenamenti a
                WHERE a.user_id = ? AND a.durata_totale > 0
                AND a.data_allenamento >= ? AND a.data_allenamento <= ?
            ");
            $stmt->bind_param("iss", $userId, $prevDates['start'], $prevDates['end']);
            $stmt->execute();
            $previousStats = $stmt->get_result()->fetch_assoc();
            
            // Serie del periodo precedente (query separata per evitare problemi GROUP BY)
            $stmt = $conn->prepare("
                SELECT COUNT(*) as prev_total_series
                FROM serie_completate sc
                JOIN allenamenti a ON sc.allenamento_id = a.id
                WHERE a.user_id = ? AND a.durata_totale > 0 AND sc.completata = 1
                AND a.data_allenamento >= ? AND a.data_allenamento <= ?
            ");
            $stmt->bind_param("iss", $userId, $prevDates['start'], $prevDates['end']);
            $stmt->execute();
            $prevSeriesResult = $stmt->get_result()->fetch_assoc();
            $previousStats['prev_total_series'] = $prevSeriesResult['prev_total_series'];
            
            $stats['comparison_with_previous'] = [
                'previous_period' => $previousPeriod,
                'previous_start_date' => $prevDates['start'],
                'previous_end_date' => $prevDates['end'],
                'workout_count_diff' => (int)$workoutCount - (int)$previousStats['prev_workout_count'],
                'duration_diff_minutes' => (int)$totalDuration - (int)$previousStats['prev_total_duration'],
                'improvement_percentage' => calculateImprovementPercentage($workoutCount, $previousStats['prev_workout_count'])
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'period_stats' => $stats,
        'is_premium' => $isPremium,
        'message' => $isPremium ? 'Statistiche avanzate del periodo caricate' : 'Statistiche base del periodo caricate'
    ]);

} catch (Exception $e) {
    error_log("Errore nel recupero delle statistiche per periodo: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

$conn->close();
?>