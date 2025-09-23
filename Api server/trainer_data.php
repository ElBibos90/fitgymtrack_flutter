<?php
// ============================================================================
// API DATI TRAINER
// Gestisce tutti i dati specifici per i trainer: clienti, schede, calendario, etc.
// ============================================================================

// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers
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
        header('Access-Control-Max-Age: 86400');
    }
}

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

$method = $_SERVER['REQUEST_METHOD'];

// Verifica autenticazione - Solo trainer e gym possono accedere
$user = authMiddleware($conn, ['trainer', 'gym', 'admin']);
if (!$user) {
    exit();
}

// Routing delle azioni
$action = $_GET['action'] ?? '';

switch($method) {
    case 'GET':
        switch($action) {
            case 'clients':
                getTrainerClients($conn, $user);
                break;
            case 'client_details':
                getClientDetails($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'workout_plans':
                getClientWorkoutPlans($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'client_history':
                getClientHistory($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'client_subscription':
                getClientSubscription($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'client_progress':
                getClientProgress($conn, $user, $_GET['client_id'] ?? null);
                break;
            case 'trainer_stats':
                getTrainerStats($conn, $user);
                break;
            case 'today_schedule':
                getTodaySchedule($conn, $user);
                break;
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata']);
        }
        break;
        
    case 'POST':
        switch($action) {
            case 'create_workout_plan':
                createWorkoutPlan($conn, $user);
                break;
            case 'create_appointment':
                createAppointment($conn, $user);
                break;
            case 'add_progress':
                addClientProgress($conn, $user);
                break;
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione POST non specificata']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

/**
 * Ottieni clienti del trainer
 */
function getTrainerClients($conn, $user) {
    try {
        $gym_id = getTrainerGymId($conn, $user);
        if (!$gym_id) {
            throw new Exception('Palestra non trovata');
        }
        
        $stmt = $conn->prepare("
            SELECT 
                u.id, u.username, u.name, u.email, u.created_at, u.last_login,
                gm.role_in_gym, gm.status as membership_status, gm.joined_at,
                cs.status as subscription_status,
                cs.end_date as subscription_end_date,
                cs.subscription_name
            FROM users u
            JOIN gym_memberships gm ON u.id = gm.user_id
            LEFT JOIN client_subscriptions cs ON u.id = cs.client_id AND cs.status = 'active'
            WHERE gm.gym_id = ? 
            AND gm.role_in_gym = 'member'
            AND gm.status = 'active'
            ORDER BY u.name ASC
        ");
        
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $clients = [];
        while ($row = $result->fetch_assoc()) {
            $clients[] = $row;
        }
        
        echo json_encode($clients);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero clienti: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni dettagli completi di un cliente
 */
function getClientDetails($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $gym_id = getTrainerGymId($conn, $user);
        
        // Verifica che il cliente appartenga alla palestra del trainer
        $stmt = $conn->prepare("
            SELECT 
                u.id, u.username, u.name, u.email, u.created_at, u.last_login,
                gm.role_in_gym, gm.status as membership_status, gm.joined_at
            FROM users u
            JOIN gym_memberships gm ON u.id = gm.user_id
            WHERE u.id = ? AND gm.gym_id = ? AND gm.role_in_gym = 'member'
        ");
        
        $stmt->bind_param("ii", $client_id, $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Cliente non trovato']);
            return;
        }
        
        $client = $result->fetch_assoc();
        echo json_encode($client);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dettagli cliente: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni schede allenamento di un cliente (USA TABELLE ESISTENTI)
 */
function getClientWorkoutPlans($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $trainer_id = $user['user_id'];
        
        error_log("DEBUG trainer_data.php: trainer_id = $trainer_id, client_id = $client_id");
        
        // Usa le tabelle esistenti: schede + user_workout_assignments
        // NOTA: Rimuoviamo il filtro trainer_id per ora, dato che nel sistema palestre 
        // i trainer possono vedere tutte le schede dei clienti della palestra
        $stmt = $conn->prepare("
            SELECT 
                s.id, s.nome as name, s.descrizione as description, 
                s.created_at, s.updated_at,
                COUNT(se.id) as total_exercises,
                uwa.assigned_date as assigned_at
            FROM schede s
            JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
            LEFT JOIN scheda_esercizi se ON s.id = se.scheda_id
            WHERE uwa.user_id = ? 
            AND uwa.active = 1
            GROUP BY s.id, uwa.assigned_date
            ORDER BY uwa.assigned_date DESC
        ");
        
        $stmt->bind_param("i", $client_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $workout_plans = [];
        while ($row = $result->fetch_assoc()) {
            $workout_plans[] = $row;
        }
        
        echo json_encode($workout_plans);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero schede: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni storico allenamenti cliente (USA TABELLE ESISTENTI)
 */
function getClientHistory($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $trainer_id = $user['user_id'];
        
        // Usa tabelle esistenti: allenamenti + schede
        $stmt = $conn->prepare("
            SELECT 
                a.id, a.data_allenamento as session_date, 
                a.durata_totale, a.note,
                s.nome as workout_plan_name,
                s.descrizione as workout_description
            FROM allenamenti a
            JOIN schede s ON a.scheda_id = s.id
            WHERE a.user_id = ? AND s.trainer_id = ?
            ORDER BY a.data_allenamento DESC
            LIMIT 50
        ");
        
        $stmt->bind_param("ii", $client_id, $trainer_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $sessions = [];
        while ($row = $result->fetch_assoc()) {
            $sessions[] = $row;
        }
        
        echo json_encode($sessions);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero storico: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni abbonamento cliente
 */
function getClientSubscription($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $gym_id = getTrainerGymId($conn, $user);
        
        // Abbonamento attivo
        $stmt = $conn->prepare("
            SELECT 
                cs.id, cs.subscription_type, cs.subscription_name, cs.price, cs.currency,
                cs.start_date, cs.end_date, cs.status, cs.payment_status, cs.auto_renew,
                cs.notes, cs.created_at
            FROM client_subscriptions cs
            WHERE cs.client_id = ? AND cs.gym_id = ? 
            ORDER BY cs.created_at DESC
            LIMIT 10
        ");
        
        $stmt->bind_param("ii", $client_id, $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $subscriptions = [];
        while ($row = $result->fetch_assoc()) {
            $subscriptions[] = $row;
        }
        
        echo json_encode([
            'current' => $subscriptions[0] ?? null,
            'history' => array_slice($subscriptions, 1)
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero abbonamento: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni progressi cliente
 */
function getClientProgress($conn, $user, $client_id) {
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID cliente mancante']);
        return;
    }
    
    try {
        $trainer_id = $user['user_id'];
        
        // Progressi fisici
        $stmt = $conn->prepare("
            SELECT 
                cp.id, cp.measurement_date, cp.weight, cp.height, cp.body_fat_percentage,
                cp.muscle_mass_percentage, cp.bmi, cp.notes, cp.measurements
            FROM client_progress cp
            WHERE cp.client_id = ? AND cp.trainer_id = ?
            ORDER BY cp.measurement_date DESC
            LIMIT 20
        ");
        
        $stmt->bind_param("ii", $client_id, $trainer_id);
        $stmt->execute();
        $progress_result = $stmt->get_result();
        
        $progress = [];
        while ($row = $progress_result->fetch_assoc()) {
            $progress[] = $row;
        }
        
        // Obiettivi
        $goals_stmt = $conn->prepare("
            SELECT 
                cg.id, cg.goal_type, cg.title, cg.description, cg.target_value,
                cg.current_value, cg.target_date, cg.status, cg.priority,
                cg.created_at, cg.completed_at
            FROM client_goals cg
            WHERE cg.client_id = ? AND cg.trainer_id = ?
            ORDER BY cg.priority DESC, cg.created_at DESC
        ");
        
        $goals_stmt->bind_param("ii", $client_id, $trainer_id);
        $goals_stmt->execute();
        $goals_result = $goals_stmt->get_result();
        
        $goals = [];
        while ($row = $goals_result->fetch_assoc()) {
            $goals[] = $row;
        }
        
        echo json_encode([
            'progress' => $progress,
            'goals' => $goals,
            'stats' => [
                'total_workouts' => getClientTotalWorkouts($conn, $client_id, $trainer_id),
                'active_goals' => count(array_filter($goals, fn($g) => $g['status'] === 'active')),
                'completed_goals' => count(array_filter($goals, fn($g) => $g['status'] === 'completed'))
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero progressi: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni statistiche trainer
 */
function getTrainerStats($conn, $user) {
    try {
        $trainer_id = $user['user_id'];
        
        $stmt = $conn->prepare("
            SELECT 
                total_clients, active_clients, active_workout_plans,
                workouts_this_month, appointments_today, avg_rating
            FROM trainer_stats 
            WHERE trainer_id = ?
        ");
        
        $stmt->bind_param("i", $trainer_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $stats = $result->fetch_assoc();
            echo json_encode($stats);
        } else {
            // Fallback se la vista non ha dati
            echo json_encode([
                'total_clients' => 0,
                'active_clients' => 0,
                'active_workout_plans' => 0,
                'workouts_this_month' => 0,
                'appointments_today' => 0,
                'avg_rating' => 0
            ]);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero statistiche: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni programma di oggi
 */
function getTodaySchedule($conn, $user) {
    try {
        $trainer_id = $user['user_id'];
        $today = date('Y-m-d');
        
        $stmt = $conn->prepare("
            SELECT 
                tc.id, tc.title, tc.description, tc.event_type,
                tc.start_datetime, tc.end_datetime, tc.status, tc.location,
                u.name as client_name, u.email as client_email
            FROM trainer_calendar tc
            LEFT JOIN users u ON tc.client_id = u.id
            WHERE tc.trainer_id = ? 
            AND DATE(tc.start_datetime) = ?
            AND tc.status IN ('scheduled', 'confirmed')
            ORDER BY tc.start_datetime ASC
        ");
        
        $stmt->bind_param("is", $trainer_id, $today);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $schedule = [];
        while ($row = $result->fetch_assoc()) {
            $schedule[] = $row;
        }
        
        echo json_encode($schedule);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero programma: ' . $e->getMessage()]);
    }
}

/**
 * Utility: Ottieni gym_id del trainer
 */
function getTrainerGymId($conn, $user) {
    if (hasRole($user, 'admin')) {
        return $_GET['gym_id'] ?? null;
    }
    
    if (hasRole($user, 'gym')) {
        $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
        $stmt->bind_param("i", $user['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->num_rows > 0 ? $result->fetch_assoc()['gym_id'] : null;
    }
    
    if (hasRole($user, 'trainer')) {
        $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
        $stmt->bind_param("i", $user['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->num_rows > 0 ? $result->fetch_assoc()['gym_id'] : null;
    }
    
    return null;
}

/**
 * Utility: Conta allenamenti totali cliente (USA TABELLE ESISTENTI)
 */
function getClientTotalWorkouts($conn, $client_id, $trainer_id) {
    $stmt = $conn->prepare("
        SELECT COUNT(*) as total 
        FROM allenamenti a
        JOIN schede s ON a.scheda_id = s.id
        WHERE a.user_id = ? AND s.trainer_id = ?
    ");
    $stmt->bind_param("ii", $client_id, $trainer_id);
    $stmt->execute();
    $result = $stmt->get_result();
    return $result->fetch_assoc()['total'] ?? 0;
}

$conn->close();
?>
