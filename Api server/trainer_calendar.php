<?php
// ============================================================================
// API CALENDARIO TRAINER - VERSIONE CORRETTA
// Gestisce appuntamenti e calendario per trainer
// ============================================================================

// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - Permissivo per sviluppo
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header('Access-Control-Allow-Credentials: false');

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

try {
    include 'config.php';
    require_once 'auth_functions.php';
} catch (Exception $e) {
    error_log("trainer_calendar.php - Errore critico nell'inclusione: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore critico: ' . $e->getMessage()]);
    exit();
}

// ============================================================================
// DEFINIZIONI DELLE FUNZIONI (PRIMA DEL ROUTING)
// ============================================================================

/**
 * Ottieni programma di oggi
 */
function getTodaySchedule($conn, $user) {
    try {
        $trainer_id = $user['user_id'];
        $today = date('Y-m-d');
        
        error_log("getTodaySchedule - trainer_id: $trainer_id, today: $today");
        
        $stmt = $conn->prepare("
            SELECT 
                tc.id, tc.title, tc.description, tc.event_type,
                tc.start_datetime, tc.end_datetime, tc.status, tc.location, tc.notes,
                u.name as client_name, u.email as client_email
            FROM trainer_calendar tc
            LEFT JOIN users u ON tc.client_id = u.id
            WHERE tc.trainer_id = ? 
            AND DATE(tc.start_datetime) = ?
            ORDER BY tc.start_datetime ASC
        ");
        
        if (!$stmt) {
            error_log("getTodaySchedule - Errore preparazione query: " . $conn->error);
            throw new Exception("Errore preparazione query: " . $conn->error);
        }
        
        $stmt->bind_param("is", $trainer_id, $today);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $schedule = [];
        while ($row = $result->fetch_assoc()) {
            // Formatta i dati per il frontend
            $row['time'] = date('H:i', strtotime($row['start_datetime']));
            $row['end_time'] = date('H:i', strtotime($row['end_datetime']));
            $row['client'] = $row['client_name'] ?: 'Senza cliente';
            $row['type'] = ucfirst(str_replace('_', ' ', $row['event_type']));
            
            $schedule[] = $row;
        }
        
        error_log("getTodaySchedule - Trovati " . count($schedule) . " appuntamenti");
        echo json_encode($schedule);
        
    } catch (Exception $e) {
        error_log("getTodaySchedule - Errore: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero programma: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni programma della settimana
 */
function getWeekSchedule($conn, $user) {
    try {
        $trainer_id = $user['user_id'];
        $start_week = date('Y-m-d', strtotime('monday this week'));
        $end_week = date('Y-m-d', strtotime('sunday this week'));
        
        $stmt = $conn->prepare("
            SELECT 
                tc.id, tc.title, tc.description, tc.event_type,
                tc.start_datetime, tc.end_datetime, tc.status, tc.location,
                u.name as client_name
            FROM trainer_calendar tc
            LEFT JOIN users u ON tc.client_id = u.id
            WHERE tc.trainer_id = ? 
            AND DATE(tc.start_datetime) BETWEEN ? AND ?
            ORDER BY tc.start_datetime ASC
        ");
        
        $stmt->bind_param("iss", $trainer_id, $start_week, $end_week);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $schedule = [];
        while ($row = $result->fetch_assoc()) {
            $schedule[] = $row;
        }
        
        echo json_encode($schedule);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero programma settimanale: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni programma del mese
 */
function getMonthSchedule($conn, $user) {
    try {
        $trainer_id = $user['user_id'];
        $start_month = date('Y-m-01'); // Primo giorno del mese corrente
        $end_month = date('Y-m-t'); // Ultimo giorno del mese corrente
        
        $stmt = $conn->prepare("
            SELECT 
                tc.id, tc.title, tc.description, tc.event_type,
                tc.start_datetime, tc.end_datetime, tc.status, tc.location, tc.notes,
                u.name as client_name, u.email as client_email
            FROM trainer_calendar tc
            LEFT JOIN users u ON tc.client_id = u.id
            WHERE tc.trainer_id = ? 
            AND DATE(tc.start_datetime) BETWEEN ? AND ?
            ORDER BY tc.start_datetime ASC
        ");
        
        $stmt->bind_param("iss", $trainer_id, $start_month, $end_month);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $schedule = [];
        while ($row = $result->fetch_assoc()) {
            // Formatta i dati per il frontend
            $row['time'] = date('H:i', strtotime($row['start_datetime']));
            $row['end_time'] = date('H:i', strtotime($row['end_datetime']));
            $row['date'] = date('Y-m-d', strtotime($row['start_datetime']));
            $row['client'] = $row['client_name'] ?: 'Senza cliente';
            $row['type'] = ucfirst(str_replace('_', ' ', $row['event_type']));
            
            $schedule[] = $row;
        }
        
        echo json_encode($schedule);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero programma mensile: ' . $e->getMessage()]);
    }
}

/**
 * Crea nuovo appuntamento
 */
function createAppointment($conn, $user, $data) {
    try {
        $trainer_id = $user['user_id'];
        
        $required_fields = ['title', 'start_datetime', 'end_datetime', 'event_type'];
        foreach ($required_fields as $field) {
            if (empty($data[$field])) {
                throw new Exception("Campo obbligatorio mancante: $field");
            }
        }
        
        $stmt = $conn->prepare("
            INSERT INTO trainer_calendar 
            (trainer_id, gym_id, title, description, start_datetime, end_datetime, event_type, status, location, notes, client_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $status = $data['status'] ?? 'scheduled';
        $client_id = !empty($data['client_id']) ? $data['client_id'] : null;
        
        // Ottieni il gym_id del trainer
        $gym_stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
        $gym_stmt->bind_param("i", $trainer_id);
        $gym_stmt->execute();
        $gym_result = $gym_stmt->get_result();
        
        if ($gym_row = $gym_result->fetch_assoc()) {
            $gym_id = $gym_row['gym_id'];
        } else {
            throw new Exception("Trainer non trovato");
        }
        
        // Prepara i valori per bind_param
        $description = $data['description'] ?? '';
        $location = $data['location'] ?? '';
        $notes = $data['notes'] ?? '';
        
        $stmt->bind_param("iissssssssi", 
            $trainer_id,
            $gym_id,
            $data['title'],
            $description,
            $data['start_datetime'],
            $data['end_datetime'],
            $data['event_type'],
            $status,
            $location,
            $notes,
            $client_id
        );
        
        if ($stmt->execute()) {
            $appointment_id = $conn->insert_id;
            echo json_encode([
                'success' => true,
                'message' => 'Appuntamento creato con successo',
                'appointment_id' => $appointment_id
            ]);
        } else {
            throw new Exception("Errore nella creazione dell'appuntamento: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione: ' . $e->getMessage()]);
    }
}

/**
 * Aggiorna appuntamento esistente
 */
function updateAppointment($conn, $user, $appointment_id, $data) {
    try {
        // Verifica che l'appuntamento appartenga al trainer
        $check_stmt = $conn->prepare("SELECT id FROM trainer_calendar WHERE id = ? AND trainer_id = ?");
        $check_stmt->bind_param("ii", $appointment_id, $user['user_id']);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception("Appuntamento non trovato o non autorizzato");
        }
        
        $fields = [];
        $values = [];
        $types = '';
        
        $allowed_fields = ['title', 'description', 'start_datetime', 'end_datetime', 'event_type', 'status', 'location', 'notes', 'client_id'];
        
        foreach ($allowed_fields as $field) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
                $types .= $field === 'client_id' ? 'i' : 's';
            }
        }
        
        if (empty($fields)) {
            throw new Exception("Nessun campo da aggiornare");
        }
        
        $values[] = $appointment_id;
        $values[] = $user['user_id'];
        
        $sql = "UPDATE trainer_calendar SET " . implode(', ', $fields) . " WHERE id = ? AND trainer_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types . 'ii', ...$values);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Appuntamento aggiornato con successo']);
        } else {
            throw new Exception("Errore nell'aggiornamento: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento: ' . $e->getMessage()]);
    }
}

/**
 * Elimina appuntamento
 */
function deleteAppointment($conn, $user, $appointment_id) {
    try {
        $stmt = $conn->prepare("DELETE FROM trainer_calendar WHERE id = ? AND trainer_id = ?");
        $stmt->bind_param("ii", $appointment_id, $user['user_id']);
        
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(['success' => true, 'message' => 'Appuntamento eliminato con successo']);
            } else {
                throw new Exception("Appuntamento non trovato o non autorizzato");
            }
        } else {
            throw new Exception("Errore nell'eliminazione: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione: ' . $e->getMessage()]);
    }
}

// ============================================================================
// ROUTING PRINCIPALE
// ============================================================================

try {
    $method = $_SERVER['REQUEST_METHOD'];

    // Debug: Log della richiesta
    error_log("trainer_calendar.php - Metodo: $method, Action: " . ($_GET['action'] ?? 'none'));

    // Verifica autenticazione - Solo trainer e gym possono accedere
    $user = authMiddleware($conn, ['trainer', 'gym', 'admin']);
    if (!$user) {
        error_log("trainer_calendar.php - Autenticazione fallita o ruolo non autorizzato");
        http_response_code(403);
        echo json_encode(['error' => 'Accesso negato. Solo trainer, gym e admin possono accedere al calendario']);
        exit();
    }

    error_log("trainer_calendar.php - Utente autenticato: " . $user['username'] . " (ID: " . $user['user_id'] . ", Ruolo: " . $user['role_name'] . ")");

} catch (Exception $e) {
    error_log("trainer_calendar.php - Errore nell'autenticazione: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore nell\'autenticazione: ' . $e->getMessage()]);
    exit();
}

// Routing delle azioni
try {
    $action = $_GET['action'] ?? '';

    switch($method) {
        case 'GET':
            switch($action) {
                case 'today':
                    getTodaySchedule($conn, $user);
                    break;
                case 'week':
                    getWeekSchedule($conn, $user);
                    break;
                case 'month':
                    getMonthSchedule($conn, $user);
                    break;
                default:
                    echo json_encode(['error' => 'Azione non supportata']);
            }
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            createAppointment($conn, $user, $input);
            break;
            
        case 'PUT':
            $appointment_id = $_GET['id'] ?? null;
            if (!$appointment_id) {
                http_response_code(400);
                echo json_encode(['error' => 'ID appuntamento richiesto']);
                break;
            }
            $input = json_decode(file_get_contents('php://input'), true);
            updateAppointment($conn, $user, $appointment_id, $input);
            break;
            
        case 'DELETE':
            $appointment_id = $_GET['id'] ?? null;
            if (!$appointment_id) {
                http_response_code(400);
                echo json_encode(['error' => 'ID appuntamento richiesto']);
                break;
            }
            deleteAppointment($conn, $user, $appointment_id);
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['error' => 'Metodo non consentito']);
    }
} catch (Exception $e) {
    error_log("trainer_calendar.php - Errore nel routing: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore nel routing: ' . $e->getMessage()]);
}
?>
