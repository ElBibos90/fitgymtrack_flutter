<?php
// ============================================================================
// API GESTIONE CORSI GYM
// ============================================================================
// Descrizione: API per gestione corsi, sessioni e iscrizioni
// Versione: 1.0.0
// Data: 01/10/2025
// ============================================================================

// Abilita error reporting per debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers
if (isset($_SERVER['HTTP_ORIGIN'])) {
    $allowed_origins = [
        'http://localhost:3000', 
        'http://192.168.1.113', 
        'http://104.248.103.182',
        'http://fitgymtrack.com',
        'https://fitgymtrack.com',
        'http://www.fitgymtrack.com',
        'https://www.fitgymtrack.com'
    ];
    if (in_array($_SERVER['HTTP_ORIGIN'], $allowed_origins)) {
        header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 86400');
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

// ============================================================================
// FUNZIONI HELPER
// ============================================================================

/**
 * Verifica che l'utente sia GYM owner
 */
function verifyGymAccess($user) {
    if (!hasRole($user, 'gym')) {
        http_response_code(403);
        echo json_encode(['error' => 'Solo i gestori palestra possono accedere a questa risorsa']);
        exit();
    }
}

/**
 * Ottieni gym_id dell'utente
 */
function getGymId($conn, $user_id) {
    $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        return $row['gym_id'];
    }
    
    return null;
}

/**
 * Genera sessioni ricorrenti per un corso (usa trainer_calendar)
 */
function generateRecurringSessions($conn, $course_id, $course_data) {
    if (!$course_data['is_recurring']) {
        return ['success' => true, 'message' => 'Corso non ricorrente'];
    }
    
    $recurrence_days = json_decode($course_data['recurrence_days'], true);
    if (!$recurrence_days || empty($recurrence_days)) {
        return ['success' => false, 'error' => 'Giorni ricorrenza non validi'];
    }
    
    $start_date = new DateTime();
    $end_date = new DateTime($course_data['recurrence_end_date']);
    
    // Mappa giorni settimana
    $day_map = [
        'monday' => 1,
        'tuesday' => 2,
        'wednesday' => 3,
        'thursday' => 4,
        'friday' => 5,
        'saturday' => 6,
        'sunday' => 0
    ];
    
    $sessions_created = 0;
    
    // Ottieni il titolo del corso
    $course_title = $course_data['title'] ?? 'Corso';
    $course_description = $course_data['description'] ?? null;
    $course_color = $course_data['color'] ?? '#3B82F6';
    
    // Genera sessioni per ogni giorno fino alla data fine
    while ($start_date <= $end_date) {
        $current_day = (int)$start_date->format('w'); // 0 = domenica, 6 = sabato
        
        // Controlla se il giorno corrente è nei giorni ricorrenti
        foreach ($recurrence_days as $day) {
            $day_lower = strtolower($day);
            if (isset($day_map[$day_lower]) && $day_map[$day_lower] === $current_day) {
                // Crea sessione in trainer_calendar
                $stmt = $conn->prepare("
                    INSERT INTO trainer_calendar 
                    (trainer_id, gym_id, title, description, start_datetime, end_datetime, 
                     event_type, status, course_id, max_participants, is_course, color)
                    VALUES (NULL, ?, ?, ?, ?, ?, 'course', 'scheduled', ?, ?, TRUE, ?)
                ");
                
                $session_date = $start_date->format('Y-m-d');
                $start_datetime = $session_date . ' ' . $course_data['standard_start_time'];
                $end_datetime = $session_date . ' ' . $course_data['standard_end_time'];
                
                $stmt->bind_param("issssiis", 
                    $course_data['gym_id'],
                    $course_title,
                    $course_description,
                    $start_datetime,
                    $end_datetime,
                    $course_id,
                    $course_data['max_participants'],
                    $course_color
                );
                
                if ($stmt->execute()) {
                    $sessions_created++;
                }
                
                break; // Esci dal foreach dopo aver trovato il giorno
            }
        }
        
        $start_date->modify('+1 day');
    }
    
    return [
        'success' => true, 
        'sessions_created' => $sessions_created,
        'message' => "Generate $sessions_created sessioni"
    ];
}

// ============================================================================
// ENDPOINTS - CORSI
// ============================================================================

/**
 * GET: Lista corsi della palestra
 */
function listCourses($conn, $user) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        if (!$gym_id) {
            throw new Exception("Palestra non trovata");
        }
        
        $stmt = $conn->prepare("
            SELECT 
                gc.*,
                u.name as created_by_name,
                (SELECT COUNT(*) FROM trainer_calendar WHERE course_id = gc.id AND is_course = TRUE) as total_sessions,
                (SELECT COUNT(*) FROM trainer_calendar WHERE course_id = gc.id AND is_course = TRUE AND status = 'scheduled') as upcoming_sessions
            FROM gym_courses gc
            LEFT JOIN users u ON gc.created_by = u.id
            WHERE gc.gym_id = ?
            ORDER BY gc.created_at DESC
        ");
        
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $courses = [];
        while ($row = $result->fetch_assoc()) {
            // Decodifica JSON fields
            if ($row['recurrence_days']) {
                $row['recurrence_days'] = json_decode($row['recurrence_days'], true);
            }
            $courses[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'courses' => $courses
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * GET: Dettagli singolo corso
 */
function getCourse($conn, $user, $course_id) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        $stmt = $conn->prepare("
            SELECT 
                gc.*,
                u.name as created_by_name
            FROM gym_courses gc
            LEFT JOIN users u ON gc.created_by = u.id
            WHERE gc.id = ? AND gc.gym_id = ?
        ");
        
        $stmt->bind_param("ii", $course_id, $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($row = $result->fetch_assoc()) {
            if ($row['recurrence_days']) {
                $row['recurrence_days'] = json_decode($row['recurrence_days'], true);
            }
            
            // Calcola total_sessions e upcoming_sessions
            $sessions_stmt = $conn->prepare("
                SELECT COUNT(*) as total_sessions
                FROM trainer_calendar 
                WHERE course_id = ? AND is_course = TRUE
            ");
            $sessions_stmt->bind_param("i", $course_id);
            $sessions_stmt->execute();
            $sessions_result = $sessions_stmt->get_result();
            $sessions_data = $sessions_result->fetch_assoc();
            $row['total_sessions'] = $sessions_data['total_sessions'];
            
            // Calcola upcoming_sessions (sessioni future)
            $upcoming_stmt = $conn->prepare("
                SELECT COUNT(*) as upcoming_sessions
                FROM trainer_calendar 
                WHERE course_id = ? AND is_course = TRUE 
                AND DATE(start_datetime) >= CURDATE()
            ");
            $upcoming_stmt->bind_param("i", $course_id);
            $upcoming_stmt->execute();
            $upcoming_result = $upcoming_stmt->get_result();
            $upcoming_data = $upcoming_result->fetch_assoc();
            $row['upcoming_sessions'] = $upcoming_data['upcoming_sessions'];
            
            echo json_encode([
                'success' => true,
                'course' => $row
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Corso non trovato']);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * POST: Crea nuovo corso
 */
function createCourse($conn, $user, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        if (!$gym_id) {
            throw new Exception("Palestra non trovata");
        }
        
        // Validazione campi obbligatori
        if (empty($data['title'])) {
            throw new Exception("Titolo corso obbligatorio");
        }
        
        // Prepara dati - Assegna tutti i valori a variabili per bind_param
        $is_recurring = isset($data['is_recurring']) ? (bool)$data['is_recurring'] : false;
        $is_unlimited = isset($data['is_unlimited']) ? (bool)$data['is_unlimited'] : false;
        $max_participants = $is_unlimited ? null : ($data['max_participants'] ?? null);
        $recurrence_days = isset($data['recurrence_days']) ? json_encode($data['recurrence_days']) : null;
        
        // Assegna valori a variabili per evitare errore bind_param
        $title = $data['title'];
        $description = $data['description'] ?? null;
        $category = $data['category'] ?? null;
        $recurrence_type = $data['recurrence_type'] ?? 'none';
        $recurrence_end_date = $data['recurrence_end_date'] ?? null;
        $standard_start_time = $data['standard_start_time'] ?? null;
        $standard_end_time = $data['standard_end_time'] ?? null;
        $color = $data['color'] ?? '#3B82F6';
        
        $stmt = $conn->prepare("
            INSERT INTO gym_courses 
            (gym_id, created_by, title, description, category, max_participants, is_unlimited,
             is_recurring, recurrence_type, recurrence_days, recurrence_end_date,
             standard_start_time, standard_end_time, color, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
        ");
        
        $stmt->bind_param("iisssiiissssss",
            $gym_id,
            $user['user_id'],
            $title,
            $description,
            $category,
            $max_participants,
            $is_unlimited,
            $is_recurring,
            $recurrence_type,
            $recurrence_days,
            $recurrence_end_date,
            $standard_start_time,
            $standard_end_time,
            $color
        );
        
        if ($stmt->execute()) {
            $course_id = $conn->insert_id;
            
            // Se ricorrente, genera sessioni automaticamente
            if ($is_recurring && isset($data['recurrence_end_date'])) {
                $course_data = [
                    'gym_id' => $gym_id,
                    'title' => $title,
                    'description' => $description,
                    'color' => $color,
                    'is_recurring' => $is_recurring,
                    'recurrence_days' => $recurrence_days,
                    'recurrence_end_date' => $data['recurrence_end_date'],
                    'standard_start_time' => $data['standard_start_time'],
                    'standard_end_time' => $data['standard_end_time'],
                    'max_participants' => $max_participants
                ];
                
                $generation_result = generateRecurringSessions($conn, $course_id, $course_data);
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Corso creato con successo',
                'course_id' => $course_id,
                'sessions_generated' => $generation_result ?? null
            ]);
        } else {
            throw new Exception("Errore nella creazione del corso: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * PUT: Aggiorna corso esistente
 */
function updateCourse($conn, $user, $course_id, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        // Verifica che il corso appartenga alla palestra
        $check_stmt = $conn->prepare("SELECT id FROM gym_courses WHERE id = ? AND gym_id = ?");
        $check_stmt->bind_param("ii", $course_id, $gym_id);
        $check_stmt->execute();
        
        if ($check_stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Corso non trovato']);
            return;
        }
        
        $fields = [];
        $values = [];
        $types = '';
        
        // Campi modificabili
        $allowed_fields = [
            'title' => 's',
            'description' => 's',
            'category' => 's',
            'max_participants' => 'i',
            'is_unlimited' => 'i',
            'color' => 's',
            'status' => 's',
            'standard_start_time' => 's',
            'standard_end_time' => 's'
        ];
        
        foreach ($allowed_fields as $field => $type) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
                $types .= $type;
            }
        }
        
        // Gestione recurrence_days (JSON)
        if (isset($data['recurrence_days'])) {
            $fields[] = "recurrence_days = ?";
            $values[] = json_encode($data['recurrence_days']);
            $types .= 's';
        }
        
        if (empty($fields)) {
            throw new Exception("Nessun campo da aggiornare");
        }
        
        $values[] = $course_id;
        $types .= 'i';
        
        $sql = "UPDATE gym_courses SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$values);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Corso aggiornato con successo'
            ]);
        } else {
            throw new Exception("Errore nell'aggiornamento: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * DELETE: Elimina corso
 */
function deleteCourse($conn, $user, $course_id) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        $stmt = $conn->prepare("DELETE FROM gym_courses WHERE id = ? AND gym_id = ?");
        $stmt->bind_param("ii", $course_id, $gym_id);
        
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Corso eliminato con successo'
                ]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Corso non trovato']);
            }
        } else {
            throw new Exception("Errore nell'eliminazione: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// ============================================================================
// ENDPOINTS - SESSIONI
// ============================================================================

/**
 * GET: Lista sessioni per mese (per calendario) - usa trainer_calendar
 */
function listSessions($conn, $user, $month = null, $course_id = null) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        
        // Se non specificato, usa mese corrente
        if (!$month) {
            $month = date('Y-m');
        }
        
        $start_date = $month . '-01';
        $end_date = date('Y-m-t', strtotime($start_date));
        
        // Costruisci la query con filtro opzionale per course_id
        $where_conditions = "tc.gym_id = ? AND tc.is_course = TRUE AND DATE(tc.start_datetime) BETWEEN ? AND ?";
        $bind_params = [$gym_id, $start_date, $end_date];
        $bind_types = "iss";
        
        if ($course_id) {
            $where_conditions .= " AND tc.course_id = ?";
            $bind_params[] = $course_id;
            $bind_types .= "i";
        }
        
        
        $stmt = $conn->prepare("
            SELECT 
                tc.id,
                tc.course_id,
                tc.gym_id,
                DATE(tc.start_datetime) as session_date,
                TIME(tc.start_datetime) as start_time,
                TIME(tc.end_datetime) as end_time,
                tc.max_participants,
                tc.current_participants,
                tc.trainer_id,
                tc.location,
                tc.notes,
                tc.status,
                tc.color,
                gc.title as course_title,
                gc.category,
                u.name as trainer_name,
                tc.current_participants as enrolled_count
            FROM trainer_calendar tc
            INNER JOIN gym_courses gc ON tc.course_id = gc.id
            LEFT JOIN users u ON tc.trainer_id = u.id
            WHERE $where_conditions
            ORDER BY tc.start_datetime ASC
        ");
        
        $stmt->bind_param($bind_types, ...$bind_params);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $sessions = [];
        while ($row = $result->fetch_assoc()) {
            $sessions[] = $row;
        }
        
        
        echo json_encode([
            'success' => true,
            'sessions' => $sessions,
            'month' => $month,
            'course_id' => $course_id
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * GET: Dettagli sessione singola con iscritti - usa trainer_calendar
 */
function getSession($conn, $user, $session_id) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        // Dettagli sessione
        $stmt = $conn->prepare("
            SELECT 
                tc.id,
                tc.course_id,
                tc.gym_id,
                DATE(tc.start_datetime) as session_date,
                TIME(tc.start_datetime) as start_time,
                TIME(tc.end_datetime) as end_time,
                tc.max_participants,
                tc.current_participants,
                tc.trainer_id,
                tc.location,
                tc.notes,
                tc.status,
                tc.color,
                gc.title as course_title,
                gc.category,
                u.name as trainer_name
            FROM trainer_calendar tc
            INNER JOIN gym_courses gc ON tc.course_id = gc.id
            LEFT JOIN users u ON tc.trainer_id = u.id
            WHERE tc.id = ? AND tc.gym_id = ? AND tc.is_course = TRUE
        ");
        
        $stmt->bind_param("ii", $session_id, $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($session = $result->fetch_assoc()) {
            // Lista iscritti
            $enrollments_stmt = $conn->prepare("
                SELECT 
                    gce.*,
                    u.name as user_name,
                    u.email as user_email
                FROM gym_course_enrollments gce
                INNER JOIN users u ON gce.user_id = u.id
                WHERE gce.session_id = ?
                ORDER BY gce.enrolled_at DESC
            ");
            
            $enrollments_stmt->bind_param("i", $session_id);
            $enrollments_stmt->execute();
            $enrollments_result = $enrollments_stmt->get_result();
            
            $enrollments = [];
            while ($enrollment = $enrollments_result->fetch_assoc()) {
                $enrollments[] = $enrollment;
            }
            
            $session['enrollments'] = $enrollments;
            
            echo json_encode([
                'success' => true,
                'session' => $session
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Sessione non trovata']);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * POST: Crea sessione singola manualmente - usa trainer_calendar
 */
function createSession($conn, $user, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        // Validazione
        if (empty($data['course_id']) || empty($data['session_date']) || 
            empty($data['start_time']) || empty($data['end_time'])) {
            throw new Exception("Campi obbligatori mancanti");
        }
        
        // Verifica che il corso appartenga alla palestra
        $check_stmt = $conn->prepare("SELECT id, title, description, max_participants, color FROM gym_courses WHERE id = ? AND gym_id = ?");
        $check_stmt->bind_param("ii", $data['course_id'], $gym_id);
        $check_stmt->execute();
        $course_result = $check_stmt->get_result();
        
        if ($course_result->num_rows === 0) {
            throw new Exception("Corso non trovato");
        }
        
        $course = $course_result->fetch_assoc();
        
        // Crea sessione in trainer_calendar
        $stmt = $conn->prepare("
            INSERT INTO trainer_calendar 
            (trainer_id, gym_id, title, description, start_datetime, end_datetime, 
             event_type, status, course_id, max_participants, is_course, location, notes, color)
            VALUES (?, ?, ?, ?, ?, ?, 'course', 'scheduled', ?, ?, TRUE, ?, ?, ?)
        ");
        
        $max_participants = $data['max_participants'] ?? $course['max_participants'];
        $start_datetime = $data['session_date'] . ' ' . $data['start_time'] . ':00';
        $end_datetime = $data['session_date'] . ' ' . $data['end_time'] . ':00';
        $trainer_id = $data['trainer_id'] ?? null;
        $location = $data['location'] ?? null;
        $notes = $data['notes'] ?? null;
        
        $stmt->bind_param("iissssisss",
            $trainer_id,
            $gym_id,
            $course['title'],
            $course['description'],
            $start_datetime,
            $end_datetime,
            $data['course_id'],
            $max_participants,
            $location,
            $notes,
            $course['color']
        );
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Sessione creata con successo',
                'session_id' => $conn->insert_id
            ]);
        } else {
            throw new Exception("Errore nella creazione della sessione: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * PUT: Aggiorna sessione - usa trainer_calendar
 */
function updateSession($conn, $user, $session_id, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        // Verifica che la sessione appartenga alla palestra
        $check_stmt = $conn->prepare("SELECT id FROM trainer_calendar WHERE id = ? AND gym_id = ? AND is_course = TRUE");
        $check_stmt->bind_param("ii", $session_id, $gym_id);
        $check_stmt->execute();
        
        if ($check_stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Sessione non trovata']);
            return;
        }
        
        $fields = [];
        $values = [];
        $types = '';
        
        // Gestione campi con conversione datetime
        if (isset($data['session_date']) || isset($data['start_time'])) {
            // Ottieni valori correnti
            $current_stmt = $conn->prepare("SELECT start_datetime, end_datetime FROM trainer_calendar WHERE id = ?");
            $current_stmt->bind_param("i", $session_id);
            $current_stmt->execute();
            $current = $current_stmt->get_result()->fetch_assoc();
            
            $current_date = substr($current['start_datetime'], 0, 10);
            $current_start = substr($current['start_datetime'], 11, 8);
            $current_end = substr($current['end_datetime'], 11, 8);
            
            $new_date = $data['session_date'] ?? $current_date;
            $new_start = isset($data['start_time']) ? $data['start_time'] . ':00' : $current_start;
            $new_end = isset($data['end_time']) ? $data['end_time'] . ':00' : $current_end;
            
            $fields[] = "start_datetime = ?";
            $values[] = $new_date . ' ' . $new_start;
            $types .= 's';
            
            $fields[] = "end_datetime = ?";
            $values[] = $new_date . ' ' . $new_end;
            $types .= 's';
        }
        
        $allowed_fields = [
            'max_participants' => 'i',
            'trainer_id' => 'i',
            'location' => 's',
            'notes' => 's',
            'status' => 's'
        ];
        
        foreach ($allowed_fields as $field => $type) {
            if (isset($data[$field])) {
                $fields[] = "$field = ?";
                $values[] = $data[$field];
                $types .= $type;
            }
        }
        
        if (empty($fields)) {
            throw new Exception("Nessun campo da aggiornare");
        }
        
        $values[] = $session_id;
        $types .= 'i';
        
        $sql = "UPDATE trainer_calendar SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$values);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Sessione aggiornata con successo'
            ]);
        } else {
            throw new Exception("Errore nell'aggiornamento: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * DELETE: Elimina sessione - usa trainer_calendar
 */
function deleteSession($conn, $user, $session_id) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        $stmt = $conn->prepare("DELETE FROM trainer_calendar WHERE id = ? AND gym_id = ? AND is_course = TRUE");
        $stmt->bind_param("ii", $session_id, $gym_id);
        
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Sessione eliminata con successo'
                ]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Sessione non trovata']);
            }
        } else {
            throw new Exception("Errore nell'eliminazione: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// ============================================================================
// ENDPOINTS - ISCRIZIONI (GYM)
// ============================================================================

/**
 * POST: Iscrive utenti a una sessione (solo GYM)
 */
function enrollUsers($conn, $user, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        if (empty($data['session_id']) || empty($data['user_ids']) || !is_array($data['user_ids'])) {
            throw new Exception("Parametri non validi");
        }
        
        $session_id = $data['session_id'];
        $user_ids = $data['user_ids'];
        $send_notification = $data['send_notification'] ?? false;
        
        // Verifica che la sessione appartenga alla palestra - usa trainer_calendar
        $session_stmt = $conn->prepare("
            SELECT tc.*, gc.title as course_title, gc.max_participants as course_max_participants
            FROM trainer_calendar tc
            INNER JOIN gym_courses gc ON tc.course_id = gc.id
            WHERE tc.id = ? AND tc.gym_id = ? AND tc.is_course = TRUE
        ");
        $session_stmt->bind_param("ii", $session_id, $gym_id);
        $session_stmt->execute();
        $session_result = $session_stmt->get_result();
        
        if ($session_result->num_rows === 0) {
            throw new Exception("Sessione non trovata");
        }
        
        $session = $session_result->fetch_assoc();
        $max_participants = $session['max_participants'] ?? $session['course_max_participants'];
        
        $enrolled_count = 0;
        $errors = [];
        $notification_ids = [];
        $notification_details = []; // DEBUG: Dettagli notifiche
        
        foreach ($user_ids as $enroll_user_id) {
            try {
                // Verifica limite partecipanti
                if ($max_participants && $session['current_participants'] >= $max_participants) {
                    $errors[] = "Limite partecipanti raggiunto per sessione";
                    break;
                }
                
                // Inserisci iscrizione
                $stmt = $conn->prepare("
                    INSERT INTO gym_course_enrollments 
                    (session_id, user_id, gym_id, status)
                    VALUES (?, ?, ?, 'enrolled')
                ");
                
                $stmt->bind_param("iii", $session_id, $enroll_user_id, $gym_id);
                
                if ($stmt->execute()) {
                    $enrollment_id = $conn->insert_id;
                    $enrolled_count++;
                    
                    // Invia notifica se richiesto
                    if ($send_notification) {
                        
                        // Ottieni info complete per debug
                        $notification_result = sendCourseNotificationWithDetails($conn, $user, $enroll_user_id, $session, 'enrollment');
                        
                        if ($notification_result && isset($notification_result['notification_id'])) {
                            $notification_id = $notification_result['notification_id'];
                            
                            // Aggiorna enrollment con notification_id
                            $update_notif = $conn->prepare("UPDATE gym_course_enrollments SET notified = 1, notification_id = ? WHERE id = ?");
                            $update_notif->bind_param("ii", $notification_id, $enrollment_id);
                            $update_notif->execute();
                            
                            $notification_ids[] = $notification_id;
                            $notification_details[] = [
                                'user_id' => $enroll_user_id,
                                'notification_id' => $notification_id,
                                'db_saved' => true,
                                'push_sent' => $notification_result['push_sent'] ?? false,
                                'push_result' => $notification_result['push_result'] ?? null
                            ];
                        } else {
                            $errors[] = "Notifica non inviata a user $enroll_user_id";
                            $notification_details[] = [
                                'user_id' => $enroll_user_id,
                                'notification_id' => null,
                                'db_saved' => false,
                                'push_sent' => false,
                                'error' => 'Notification creation failed'
                            ];
                        }
                    }
                } else {
                    if ($stmt->errno == 1062) {
                        $errors[] = "Utente $enroll_user_id già iscritto";
                    } else {
                        $errors[] = "Errore iscrizione utente $enroll_user_id: " . $stmt->error;
                    }
                }
            } catch (Exception $e) {
                $errors[] = $e->getMessage();
            }
        }
        
        echo json_encode([
            'success' => true,
            'enrolled_count' => $enrolled_count,
            'errors' => $errors,
            'notifications_sent' => count($notification_ids),
            'notification_details' => $notification_details // DEBUG
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * POST: Annulla iscrizione
 */
function cancelEnrollment($conn, $user, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        if (empty($data['enrollment_id'])) {
            throw new Exception("ID iscrizione mancante");
        }
        
        $stmt = $conn->prepare("
            UPDATE gym_course_enrollments 
            SET status = 'cancelled', cancelled_at = NOW()
            WHERE id = ? AND gym_id = ?
        ");
        
        $stmt->bind_param("ii", $data['enrollment_id'], $gym_id);
        
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Iscrizione annullata con successo'
                ]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Iscrizione non trovata']);
            }
        } else {
            throw new Exception("Errore nell'annullamento: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * POST: Segna presenza/assenza
 */
function markAttendance($conn, $user, $data) {
    try {
        $gym_id = getGymId($conn, $user['user_id']);
        
        if (empty($data['enrollment_id']) || empty($data['status'])) {
            throw new Exception("Parametri mancanti");
        }
        
        $allowed_status = ['attended', 'absent'];
        if (!in_array($data['status'], $allowed_status)) {
            throw new Exception("Status non valido");
        }
        
        $attended_at = ($data['status'] === 'attended') ? 'NOW()' : 'NULL';
        
        $stmt = $conn->prepare("
            UPDATE gym_course_enrollments 
            SET status = ?, attended_at = $attended_at
            WHERE id = ? AND gym_id = ?
        ");
        
        $stmt->bind_param("sii", $data['status'], $data['enrollment_id'], $gym_id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Presenza aggiornata con successo'
            ]);
        } else {
            throw new Exception("Errore nell'aggiornamento: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

// ============================================================================
// ENDPOINTS - ISCRIZIONI SELF-SERVICE (UTENTI)
// ============================================================================

/**
 * POST: Utente si iscrive autonomamente a una sessione
 */
function selfEnroll($conn, $user, $data) {
    try {
        if (empty($data['session_id'])) {
            throw new Exception("ID sessione mancante");
        }
        
        $session_id = $data['session_id'];
        $user_id = $user['user_id'];
        
        // Ottieni gym_id dell'utente
        $user_gym_stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
        $user_gym_stmt->bind_param("i", $user_id);
        $user_gym_stmt->execute();
        $user_result = $user_gym_stmt->get_result();
        
        if ($user_row = $user_result->fetch_assoc()) {
            $gym_id = $user_row['gym_id'];
        } else {
            throw new Exception("Utente non trovato");
        }
        
        // Verifica che la sessione esista e appartenga alla stessa palestra
        $session_stmt = $conn->prepare("
            SELECT tc.*, gc.title as course_title, gc.max_participants as course_max_participants
            FROM trainer_calendar tc
            INNER JOIN gym_courses gc ON tc.course_id = gc.id
            WHERE tc.id = ? AND tc.gym_id = ? AND tc.is_course = TRUE AND tc.status = 'scheduled'
        ");
        $session_stmt->bind_param("ii", $session_id, $gym_id);
        $session_stmt->execute();
        $session_result = $session_stmt->get_result();
        
        if ($session_result->num_rows === 0) {
            throw new Exception("Sessione non trovata o non disponibile");
        }
        
        $session = $session_result->fetch_assoc();
        $max_participants = $session['max_participants'] ?? $session['course_max_participants'];
        
        // Verifica limite partecipanti
        if ($max_participants && $session['current_participants'] >= $max_participants) {
            throw new Exception("Posti esauriti per questa sessione");
        }
        
        // Verifica che non sia già iscritto (solo iscrizioni attive)
        $check_stmt = $conn->prepare("
            SELECT id FROM gym_course_enrollments 
            WHERE session_id = ? AND user_id = ? AND status = 'enrolled'
        ");
        $check_stmt->bind_param("ii", $session_id, $user_id);
        $check_stmt->execute();
        
        if ($check_stmt->get_result()->num_rows > 0) {
            throw new Exception("Sei già iscritto a questa sessione");
        }
        
        // Inserisci iscrizione
        $enroll_stmt = $conn->prepare("
            INSERT INTO gym_course_enrollments 
            (session_id, user_id, gym_id, status)
            VALUES (?, ?, ?, 'enrolled')
        ");
        
        $enroll_stmt->bind_param("iii", $session_id, $user_id, $gym_id);
        
        if ($enroll_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Iscrizione completata con successo',
                'enrollment_id' => $conn->insert_id
            ]);
        } else {
            throw new Exception("Errore nell'iscrizione: " . $enroll_stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => $e->getMessage()
        ]);
    }
}

/**
 * GET: Le mie iscrizioni (per l'utente loggato)
 */
function myEnrollments($conn, $user) {
    try {
        $user_id = $user['user_id'];
        
        $stmt = $conn->prepare("
            SELECT 
                gce.id as enrollment_id,
                gce.status as enrollment_status,
                gce.enrolled_at,
                gce.attended_at,
                tc.id as session_id,
                DATE(tc.start_datetime) as session_date,
                TIME(tc.start_datetime) as start_time,
                TIME(tc.end_datetime) as end_time,
                tc.location,
                tc.status as session_status,
                tc.current_participants,
                tc.max_participants,
                gc.id as course_id,
                gc.title as course_title,
                gc.description as course_description,
                gc.category,
                gc.color
            FROM gym_course_enrollments gce
            INNER JOIN trainer_calendar tc ON gce.session_id = tc.id
            INNER JOIN gym_courses gc ON tc.course_id = gc.id
            WHERE gce.user_id = ? AND gce.status != 'cancelled'
            ORDER BY tc.start_datetime ASC
        ");
        
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $enrollments = [];
        while ($row = $result->fetch_assoc()) {
            $enrollments[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'enrollments' => $enrollments,
            'count' => count($enrollments)
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
}

/**
 * POST: Annulla la mia iscrizione (self-cancel)
 */
function selfCancel($conn, $user, $data) {
    try {
        if (empty($data['enrollment_id'])) {
            throw new Exception("ID iscrizione mancante");
        }
        
        $enrollment_id = $data['enrollment_id'];
        $user_id = $user['user_id'];
        
        // Verifica che l'iscrizione appartenga all'utente
        $check_stmt = $conn->prepare("
            SELECT id, session_id FROM gym_course_enrollments 
            WHERE id = ? AND user_id = ?
        ");
        $check_stmt->bind_param("ii", $enrollment_id, $user_id);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception("Iscrizione non trovata");
        }
        
        // Elimina completamente l'iscrizione
        $stmt = $conn->prepare("
            DELETE FROM gym_course_enrollments 
            WHERE id = ? AND user_id = ?
        ");
        
        $stmt->bind_param("ii", $enrollment_id, $user_id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Iscrizione rimossa con successo'
            ]);
        } else {
            throw new Exception("Errore nella rimozione: " . $stmt->error);
        }
        
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => $e->getMessage()
        ]);
    }
}

// ============================================================================
// HELPER - NOTIFICHE
// ============================================================================

/**
 * Invia notifica per corso con dettagli completi (per debug)
 */
function sendCourseNotificationWithDetails($conn, $sender, $recipient_id, $session, $type = 'enrollment') {
    try {
        $title = '';
        $message = '';
        
        // Estrai data e ora da start_datetime (formato: YYYY-MM-DD HH:MM:SS)
        $session_date = isset($session['session_date']) ? $session['session_date'] : date('Y-m-d', strtotime($session['start_datetime']));
        $start_time = isset($session['start_time']) ? $session['start_time'] : date('H:i', strtotime($session['start_datetime']));
        
        switch ($type) {
            case 'enrollment':
                $title = "🎓 Iscrizione Corso: {$session['course_title']}";
                $message = "Sei stato iscritto al corso '{$session['course_title']}' del " . 
                          date('d/m/Y', strtotime($session_date)) . 
                          " alle ore " . substr($start_time, 0, 5);
                break;
            case 'cancellation':
                $title = "❌ Corso Annullato: {$session['course_title']}";
                $message = "Il corso '{$session['course_title']}' del " . 
                          date('d/m/Y', strtotime($session_date)) . 
                          " è stato annullato";
                break;
        }
        
        // 1. Salva notifica nel database
        $notif_stmt = $conn->prepare("
            INSERT INTO notifications 
            (sender_id, sender_type, recipient_id, title, message, type, priority, status)
            VALUES (?, 'gym', ?, ?, ?, 'announcement', 'normal', 'sent')
        ");
        
        $notif_stmt->bind_param("iiss", 
            $sender['user_id'],
            $recipient_id,
            $title,
            $message
        );
        
        if (!$notif_stmt->execute()) {
            return null;
        }
        
        $notification_id = $conn->insert_id;
        
        // 2. Invia push notification Firebase
        $push_result = sendCoursePushNotification($conn, $recipient_id, $title, $message, 'announcement', 'normal');
        
        return [
            'notification_id' => $notification_id,
            'push_sent' => $push_result ? $push_result['success'] : false,
            'push_result' => $push_result
        ];
        
    } catch (Exception $e) {
        return null;
    }
}

/**
 * Invia notifica per corso (integrazione con sistema notifiche esistente + Firebase Push)
 */
function sendCourseNotification($conn, $sender, $recipient_id, $session, $type = 'enrollment') {
    try {
        $title = '';
        $message = '';
        
        // Estrai data e ora da start_datetime (formato: YYYY-MM-DD HH:MM:SS)
        $session_date = isset($session['session_date']) ? $session['session_date'] : date('Y-m-d', strtotime($session['start_datetime']));
        $start_time = isset($session['start_time']) ? $session['start_time'] : date('H:i', strtotime($session['start_datetime']));
        
        switch ($type) {
            case 'enrollment':
                $title = "🎓 Iscrizione Corso: {$session['course_title']}";
                $message = "Sei stato iscritto al corso '{$session['course_title']}' del " . 
                          date('d/m/Y', strtotime($session_date)) . 
                          " alle ore " . substr($start_time, 0, 5);
                break;
            case 'cancellation':
                $title = "❌ Corso Annullato: {$session['course_title']}";
                $message = "Il corso '{$session['course_title']}' del " . 
                          date('d/m/Y', strtotime($session_date)) . 
                          " è stato annullato";
                break;
        }
        
        // 1. Salva notifica nel database
        $notif_stmt = $conn->prepare("
            INSERT INTO notifications 
            (sender_id, sender_type, recipient_id, title, message, type, priority, status)
            VALUES (?, 'gym', ?, ?, ?, 'announcement', 'normal', 'sent')
        ");
        
        $notif_stmt->bind_param("iiss", 
            $sender['user_id'],
            $recipient_id,
            $title,
            $message
        );
        
        if (!$notif_stmt->execute()) {
            return null;
        }
        
        $notification_id = $conn->insert_id;
        
        // 2. Invia push notification Firebase
        $push_result = sendCoursePushNotification($conn, $recipient_id, $title, $message, 'announcement', 'normal');
        
        // Log risultato push per debug
        
        return $notification_id;
        
    } catch (Exception $e) {
        return null;
    }
}

/**
 * Invia push Firebase per notifica corso
 */
function sendCoursePushNotification($conn, $recipient_id, $title, $message, $type, $priority) {
    try {
        
        // Ottieni FCM token del destinatario
        $tokenStmt = $conn->prepare("
            SELECT fcm_token 
            FROM user_fcm_tokens 
            WHERE user_id = ? AND fcm_token IS NOT NULL
            ORDER BY updated_at DESC
            LIMIT 1
        ");
        
        $tokenStmt->bind_param("i", $recipient_id);
        $tokenStmt->execute();
        $result = $tokenStmt->get_result();
        
        if ($row = $result->fetch_assoc()) {
            $fcm_token = $row['fcm_token'];
            
            // Invia push notification usando funzione Firebase
            $push_result = sendFCMPush($fcm_token, $title, $message, $type, $priority);
            
            
            return $push_result;
        } else {
            return null;
        }
        
    } catch (Exception $e) {
        return null;
    }
}

/**
 * Invia notifica FCM (Firebase Cloud Messaging)
 */
function sendFCMPush($token, $title, $message, $type, $priority) {
    
    // Configurazione Service Account Firebase
    $service_account = [
        'type' => 'service_account',
        'project_id' => 'fitgymtrack-1c62f',
        'private_key_id' => '546104d0ff9466ccc09e3abc40fceb19328a4dc1',
        'private_key' => "-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDT0kTvPTpvw8sI
xdK4K8Bzw95UggsWnIsCBxHziV6y85ISYKoirpn4Ew6kNNFJierObkJoSHCUe3Tu
+ATUWdlQxFro1IJsquqkUMexuOdU5bOzYDQI5mTeK0PmaE00hC1D8wEzRCVmHmGJ
tM0Qc83uJTpIYQZbi+TvR9RcLbPc8Qjp4ffsBkuJm4SxlANZ7ZGfPs6ijQPmVFFS
fegDmdiqDycTQG8RuMnXM3NPMwgNHTKQL6MTlk+ws4VrDtkzRc3Emyod46wR25DE
QrN9VtbtkG56bd7AZMVc3nqiGKdcFAYsUnQI6/McHJN8dk0VuzObc1G6YVWU7Kyt
QxzBaUjhAgMBAAECggEARDQaOiYu4LnccDCyTtbXmu7gcbmFtHwnTjnUj+QVd+1x
hTVW0uABd507Q6g2E0WzM1DRVR6uEUFHP4Lgmzdq/9SZqQp0DGVkNBBGnHT7F5z2
pbU+S/dTVy37KP9AjL5ajNx78HPqztzNbzemJ7wB/MJD5/ZFw8hhqKIqQJv+pA7q
ZdeXBFj7znzJ9JfuSSXYYifAGnP9JKCOXWjIo7ux/mYqaE9wSbDA+hL7ON5ifpiK
RB3pcftr/l8SUqS1jgMiUAX3nocKsRAB0s/LXva40ESEe8COaivmd/2uKiQQC3fh
DvVB83zSSraYA3eTjgihNP11sjn0T/poYkLFY3rVmQKBgQDrOc13v5N3X2dvJ0Jc
jzF2DiB/A08CdKvvGTKN0pc3VmdUlp6t2rnbQZg7Txz+TjTjtMR4GxJJbhKzu3GC
LhFrE4LtZr5gKLOL8LiXUZa91pXavFxL7Zpye4V4tXDGlI2FcvdcG6mrZdmH+Jle
nP2LXkpDJFThDUnqr99pMk0X4wKBgQDmh1F2o5STrhDyH6jkF3o2+/J9HOZS3QzF
uip/3aNgZcc1eXrBte2AwnHude/OoQC0zX1MNmZ/HgbJ2jt8A0eMpyS2di9yrpOj
pIWxIxyRQL5lQEau9bN8Ae5kwA6z7DAYdJDsGT0Q9K4b9vjexzSap/uUYG5yhE2Q
zOXUJC4PawKBgQDT+ZQKrM7EjWoVxehMpxHolFR+gUnLKb7jSe6/1Z5F1QxrMwyu
GWTRjGwWTnYPSgTpirZeke7J03LxGyLwMHmr57peG+/FkggzPOvsGS9hxiXnJ0V5
exZqwpuGKuQFYEukjfURwTAGcFM28DWuCIWH+aGsneoLoUESSAlpsFW/BwKBgQCK
zGC1IOqdPEnBrmQ+6Q/RuUKYJ+VZcPR2vI9IK4dpy/30aW8K4OHeC7UTUXkQnQnS
0oKld3+g+9A0iqwUD9lti1lkbqZE023bMny4WZ6iqiu4xMmKIC9v8624hZaUqBmR
L+Xt8Yg+BEQsXDgd0i0PDSNBhAob8yLMk0GxyBLffwKBgQDlvk+qn8GIDzKAOn6w
sN9hKLB7bsycvWbB4bxrbP1MgoA1rkbSIkYhs6a2icVPub1W/pit4+IPJ+BJj1lQ
3NEWt38jfVGW7kHVuY0RHLU0ISfrZUkZkQTx9d+VRAAQhHlsDWsa4iReMYE1szLi
+0NpA+4y/TDEe/Nc/NKYH5KSDA==
-----END PRIVATE KEY-----",
        'client_email' => 'firebase-adminsdk-fbsvc@fitgymtrack-1c62f.iam.gserviceaccount.com',
        'client_id' => '117563980715722095403',
        'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
        'token_uri' => 'https://oauth2.googleapis.com/token'
    ];
    
    // Ottieni access token
    $access_token = getFCMAccessToken($service_account);
    if (!$access_token) {
        return ['success' => false, 'error' => 'Failed to get access token'];
    }
    
    
    // Prepara payload per Firebase V1 API
    $data = [
        'message' => [
            'token' => $token,
            'notification' => [
                'title' => $title,
                'body' => $message
            ],
            'data' => [
                'type' => $type,
                'priority' => $priority,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ],
            'android' => [
                'priority' => $priority === 'high' ? 'high' : 'normal'
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1
                    ]
                ]
            ]
        ]
    ];
    
    $headers = [
        'Authorization: Bearer ' . $access_token,
        'Content-Type: application/json'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/v1/projects/fitgymtrack-1c62f/messages:send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    
    $success = $http_code === 200;
    if (!$success) {
    }
    
    return [
        'success' => $success,
        'response' => $response,
        'http_code' => $http_code
    ];
}

/**
 * Ottieni Access Token Firebase
 */
function getFCMAccessToken($service_account) {
    $jwt = createFCMJWT($service_account);
    
    $data = [
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($http_code === 200) {
        $result = json_decode($response, true);
        return $result['access_token'] ?? null;
    }
    
    return null;
}

/**
 * Crea JWT per autenticazione Firebase
 */
function createFCMJWT($service_account) {
    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    
    $now = time();
    $payload = [
        'iss' => $service_account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ];
    
    $header_encoded = fcm_base64url_encode(json_encode($header));
    $payload_encoded = fcm_base64url_encode(json_encode($payload));
    
    $signature = '';
    openssl_sign(
        $header_encoded . '.' . $payload_encoded,
        $signature,
        $service_account['private_key'],
        OPENSSL_ALGO_SHA256
    );
    
    $signature_encoded = fcm_base64url_encode($signature);
    
    return $header_encoded . '.' . $payload_encoded . '.' . $signature_encoded;
}

/**
 * Base64 URL encode per Firebase
 */
function fcm_base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

// ============================================================================
// HELPER - AUTENTICAZIONE BYPASS PER UTENTI
// ============================================================================

/**
 * Autenticazione per endpoint self-service utenti (bypass controllo piattaforma)
 */
function authMiddlewareForUsers($conn) {
    $authHeader = getAuthorizationHeader();
    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(['error' => 'Autenticazione richiesta']);
        return false;
    }
    
    // Estrai il token dall'header
    $token = str_replace('Bearer ', '', $authHeader);
    
    $userData = validateAuthToken($conn, $token);
    if (!$userData) {
        http_response_code(401);
        echo json_encode(['error' => 'Token non valido o scaduto']);
        return false;
    }
    
    // BYPASS: Permetti role 'user', 'gym', 'admin' per questi endpoint
    if (!in_array($userData['role_name'], ['user', 'gym', 'admin'])) {
        http_response_code(403);
        echo json_encode(['error' => 'Accesso negato']);
        return false;
    }
    
    return $userData;
}

// ============================================================================
// ROUTING PRINCIPALE
// ============================================================================

try {
    $method = $_SERVER['REQUEST_METHOD'];
    $action = $_GET['action'] ?? '';
    
    // Endpoint self-service per utenti normali
    $user_endpoints = ['my_enrollments', 'self_enroll', 'self_cancel', 'list_courses', 'list_sessions', 'get_course', 'get_session'];
    
    if (in_array($action, $user_endpoints)) {
        // BYPASS: Per endpoint utenti, usa autenticazione diretta senza controllo piattaforma
        $user = authMiddlewareForUsers($conn);
    } else {
        // Per tutti gli altri endpoint: solo gym/admin (webapp)
        $user = authMiddleware($conn, ['gym', 'admin']);
    }
    
    if (!$user) {
        http_response_code(403);
        echo json_encode(['error' => 'Accesso negato']);
        exit();
    }
    
    // NOTA: La verifica GYM-only viene fatta nei singoli endpoint quando necessario
    
    // Routing
    switch ($method) {
        case 'GET':
            switch ($action) {
                case 'list_courses':
                    listCourses($conn, $user);
                    break;
                case 'get_course':
                    if (!isset($_GET['id'])) {
                        throw new Exception("ID corso mancante");
                    }
                    getCourse($conn, $user, $_GET['id']);
                    break;
                case 'list_sessions':
                    listSessions($conn, $user, $_GET['month'] ?? null, $_GET['course_id'] ?? null);
                    break;
                case 'get_session':
                    if (!isset($_GET['id'])) {
                        throw new Exception("ID sessione mancante");
                    }
                    getSession($conn, $user, $_GET['id']);
                    break;
                case 'my_enrollments':
                    // Endpoint per utenti normali - le mie iscrizioni
                    myEnrollments($conn, $user);
                    break;
                default:
                    http_response_code(400);
                    echo json_encode(['error' => 'Azione non riconosciuta']);
            }
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            
            switch ($action) {
                // Endpoint GYM/ADMIN only
                case 'create_course':
                    verifyGymAccess($user);
                    createCourse($conn, $user, $input);
                    break;
                case 'create_session':
                    verifyGymAccess($user);
                    createSession($conn, $user, $input);
                    break;
                case 'enroll_users':
                    verifyGymAccess($user);
                    enrollUsers($conn, $user, $input);
                    break;
                case 'cancel_enrollment':
                    verifyGymAccess($user);
                    cancelEnrollment($conn, $user, $input);
                    break;
                case 'mark_attendance':
                    verifyGymAccess($user);
                    markAttendance($conn, $user, $input);
                    break;
                
                // Endpoint SELF-SERVICE per utenti normali
                case 'self_enroll':
                    selfEnroll($conn, $user, $input);
                    break;
                case 'self_cancel':
                    selfCancel($conn, $user, $input);
                    break;
                    
                default:
                    http_response_code(400);
                    echo json_encode(['error' => 'Azione non riconosciuta']);
            }
            break;
            
        case 'PUT':
            $input = json_decode(file_get_contents('php://input'), true);
            
            switch ($action) {
                case 'update_course':
                    verifyGymAccess($user);
                    if (!isset($_GET['id'])) {
                        throw new Exception("ID corso mancante");
                    }
                    updateCourse($conn, $user, $_GET['id'], $input);
                    break;
                case 'update_session':
                    verifyGymAccess($user);
                    if (!isset($_GET['id'])) {
                        throw new Exception("ID sessione mancante");
                    }
                    updateSession($conn, $user, $_GET['id'], $input);
                    break;
                default:
                    http_response_code(400);
                    echo json_encode(['error' => 'Azione non riconosciuta']);
            }
            break;
            
        case 'DELETE':
            switch ($action) {
                case 'delete_course':
                    verifyGymAccess($user);
                    if (!isset($_GET['id'])) {
                        throw new Exception("ID corso mancante");
                    }
                    deleteCourse($conn, $user, $_GET['id']);
                    break;
                case 'delete_session':
                    verifyGymAccess($user);
                    if (!isset($_GET['id'])) {
                        throw new Exception("ID sessione mancante");
                    }
                    deleteSession($conn, $user, $_GET['id']);
                    break;
                default:
                    http_response_code(400);
                    echo json_encode(['error' => 'Azione non riconosciuta']);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['error' => 'Metodo non consentito']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

$conn->close();
?>

