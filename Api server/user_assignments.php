<?php
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

// Gestione richieste OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization");
    exit(0);
}

header('Content-Type: application/json');

include 'config.php';
require_once 'auth_functions.php';

// Verifica autenticazione
$userData = authMiddleware($conn);
if (!$userData) {
    http_response_code(401);
    echo json_encode(['error' => 'Autenticazione richiesta']);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        try {
            // Se è specificato un user_id, recupera le sue assegnazioni
            if (isset($_GET['user_id'])) {
                $requestedUserId = intval($_GET['user_id']);
                
                // Verifica permessi
                if (!hasAccessToUser($userData, $requestedUserId, $conn)) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Non autorizzato']);
                    exit;
                }
    
                // MODIFICATO: usa CAST per forzare il tipo di dato e includi data_creazione e active
                $stmt = $conn->prepare("
                    SELECT uwa.id, uwa.user_id, uwa.scheda_id, 
                           CAST(uwa.active AS SIGNED) as assignment_active, 
                           uwa.assigned_date, uwa.expiry_date, uwa.notes, 
                           s.nome as scheda_nome, s.descrizione as scheda_descrizione, 
                           s.data_creazione, s.active as scheda_active
                    FROM user_workout_assignments uwa
                    JOIN schede s ON uwa.scheda_id = s.id
                    WHERE uwa.user_id = ?
                    ORDER BY uwa.assigned_date DESC
                ");
                $stmt->bind_param("i", $requestedUserId);
                $stmt->execute();
                $result = $stmt->get_result();
    
                $assignments = [];
                while ($row = $result->fetch_assoc()) {
                    // MODIFICATO: Log per debug e conversione esplicita
                    error_log("User ID: {$requestedUserId}, Scheda: {$row['scheda_nome']}, Assignment Active: {$row['assignment_active']}, Scheda Active: {$row['scheda_active']}");
                    
                    // MODIFICATO: Calcola lo stato active finale (attivo solo se entrambi sono attivi)
                    $row['active'] = (int)$row['assignment_active'] && (int)$row['scheda_active'];
                    $assignments[] = $row;
                }
    
                echo json_encode($assignments);
            } else {
                // Recupera le assegnazioni dell'utente corrente
                // MODIFICATO: usa CAST per forzare il tipo di dato e includi data_creazione e active
                $stmt = $conn->prepare("
                    SELECT uwa.id, uwa.user_id, uwa.scheda_id, 
                           CAST(uwa.active AS SIGNED) as assignment_active, 
                           uwa.assigned_date, uwa.expiry_date, uwa.notes, 
                           s.nome as scheda_nome, s.descrizione as scheda_descrizione, 
                           s.data_creazione, s.active as scheda_active
                    FROM user_workout_assignments uwa
                    JOIN schede s ON uwa.scheda_id = s.id
                    WHERE uwa.user_id = ?
                    ORDER BY uwa.assigned_date DESC
                ");
                $stmt->bind_param("i", $userData['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
    
                $assignments = [];
                while ($row = $result->fetch_assoc()) {
                    // MODIFICATO: Log per debug e conversione esplicita
                    error_log("Current User, Scheda: {$row['scheda_nome']}, Assignment Active: {$row['assignment_active']}, Scheda Active: {$row['scheda_active']}");
                    
                    // MODIFICATO: Calcola lo stato active finale (attivo solo se entrambi sono attivi)
                    $row['active'] = (int)$row['assignment_active'] && (int)$row['scheda_active'];
                    $assignments[] = $row;
                }
    
                echo json_encode($assignments);
            }
        } catch (Exception $e) {
            error_log("Errore nel recupero delle assegnazioni: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => 'Errore interno del server']);
        }
        break;
        
        case 'POST':
            try {
                $data = json_decode(file_get_contents("php://input"), true);
                
                // Log dettagliato
                error_log("Richiesta assegnazione scheda: " . json_encode($data));
                
                // Validazione dati
                if (!isset($data['user_id']) || !isset($data['scheda_id'])) {
                    http_response_code(400);
                    echo json_encode(['error' => 'user_id e scheda_id sono obbligatori']);
                    return;
                }
        
                // Verifica permessi
                $isAdmin = hasRole($userData, 'admin');
                $isTrainer = hasRole($userData, 'trainer');
                $isGym = hasRole($userData, 'gym');
                
                error_log("Ruoli - Admin: " . ($isAdmin ? 'Sì' : 'No') . ", Trainer: " . ($isTrainer ? 'Sì' : 'No') . ", Gym: " . ($isGym ? 'Sì' : 'No'));
        
                // Verifica se l'utente può assegnare la scheda (sistema palestre)
                if (!$isAdmin) {
                    // Per trainer e gym: verifica che il cliente appartenga alla stessa palestra
                    $accessStmt = $conn->prepare("
                        SELECT u1.id 
                        FROM users u1 
                        JOIN users u2 ON u1.gym_id = u2.gym_id
                        WHERE u1.id = ? AND u2.id = ? AND u1.gym_id IS NOT NULL
                    ");
                    $accessStmt->bind_param("ii", $data['user_id'], $userData['user_id']);
                    $accessStmt->execute();
                    $accessResult = $accessStmt->get_result();
            
                    if ($accessResult->num_rows === 0) {
                        error_log("Trainer non autorizzato ad assegnare schede a questo cliente");
                        http_response_code(403);
                        echo json_encode(['error' => 'Non autorizzato ad assegnare schede a questo cliente']);
                        return;
                    }
                }
        
                // Verifica esistenza utente e scheda
                $checkStmt = $conn->prepare("
                    SELECT u.id AS user_exists, s.id AS scheda_exists 
                    FROM users u, schede s 
                    WHERE u.id = ? AND s.id = ?
                ");
                $checkStmt->bind_param("ii", $data['user_id'], $data['scheda_id']);
                $checkStmt->execute();
                $checkResult = $checkStmt->get_result();
                
                if ($checkResult->num_rows === 0) {
                    error_log("Utente o scheda non trovati");
                    http_response_code(404);
                    echo json_encode(['error' => 'Utente o scheda non trovati']);
                    return;
                }
        
                // Inserimento con sostituzione se esiste già
                $stmt = $conn->prepare("
                    INSERT INTO user_workout_assignments 
                    (user_id, scheda_id, active, assigned_date) 
                    VALUES (?, ?, 1, NOW())
                    ON DUPLICATE KEY UPDATE 
                    active = 1, 
                    assigned_date = NOW()
                ");
                $stmt->bind_param("ii", $data['user_id'], $data['scheda_id']);
                
                if (!$stmt->execute()) {
                    error_log("Errore inserimento/aggiornamento: " . $stmt->error);
                    throw new Exception("Errore nell'assegnazione scheda");
                }
        
                error_log("Scheda assegnata con successo");
                echo json_encode([
                    'message' => 'Scheda assegnata con successo',
                    'active' => 1
                ]);
            } catch (Exception $e) {
                error_log("Errore completo nell'assegnazione scheda: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Errore interno del server']);
            }
            break;
    
        default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

$conn->close();