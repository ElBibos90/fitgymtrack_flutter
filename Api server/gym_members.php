<?php
// ============================================================================
// API GESTIONE MEMBRI PALESTRE
// Permette ai gestori palestre di gestire utenti e trainer
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

// Verifica autenticazione - Admin o Gym possono accedere
$user = authMiddleware($conn, ['admin', 'gym']);
if (!$user) {
    exit();
}

switch($method) {
    case 'POST':
        if (isset($_GET['action']) && $_GET['action'] === 'add') {
            addMemberToGym($conn, $user);
        } else {
            createGymUser($conn, $user);
        }
        break;
        
    case 'PUT':
        if (!isset($_GET['user_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID utente mancante']);
            break;
        }
        updateGymMember($conn, $_GET['user_id'], $user);
        break;
        
    case 'DELETE':
        if (!isset($_GET['user_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID utente mancante']);
            break;
        }
        removeMemberFromGym($conn, $_GET['user_id'], $user);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

/**
 * Crea un nuovo utente per la palestra
 */
function createGymUser($conn, $user) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Validazione dati
        $required = ['username', 'password', 'email', 'name', 'role_in_gym'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['error' => "Campo '$field' obbligatorio"]);
                return;
            }
        }
        
        // Ottieni gym_id dell'utente corrente
        $gym_id = getGymIdForUser($conn, $user);
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Palestra non trovata per l\'utente corrente']);
            return;
        }
        
        // Verifica limiti palestra
        if (!checkGymLimits($conn, $gym_id, $data['role_in_gym'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Raggiunto il limite massimo per questo tipo di utente']);
            return;
        }
        
        // Verifica che username e email non esistano
        $checkStmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
        $checkStmt->bind_param("ss", $data['username'], $data['email']);
        $checkStmt->execute();
        if ($checkStmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Username o email già in uso']);
            return;
        }
        
        // Determina role_id basato su role_in_gym
        $role_id = getRoleIdFromGymRole($conn, $data['role_in_gym']);
        if (!$role_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Ruolo non valido']);
            return;
        }
        
        // Hash password
        $hashedPassword = password_hash($data['password'], PASSWORD_BCRYPT);
        
        // Inizia transazione
        $conn->begin_transaction();
        
        // Crea utente
        $stmt = $conn->prepare("
            INSERT INTO users (username, password, email, name, role_id, active, gym_id, current_plan_id)
            VALUES (?, ?, ?, ?, ?, 1, ?, 4)
        ");
        
        $stmt->bind_param("ssssii", 
            $data['username'], 
            $hashedPassword, 
            $data['email'], 
            $data['name'],
            $role_id,
            $gym_id
        );
        
        if (!$stmt->execute()) {
            $conn->rollback();
            throw new Exception($stmt->error);
        }
        
        $user_id = $stmt->insert_id;
        
        // Crea membership
        $membershipStmt = $conn->prepare("
            INSERT INTO gym_memberships (gym_id, user_id, role_in_gym, status)
            VALUES (?, ?, ?, 'active')
        ");
        
        $membershipStmt->bind_param("iis", $gym_id, $user_id, $data['role_in_gym']);
        
        if (!$membershipStmt->execute()) {
            $conn->rollback();
            throw new Exception($membershipStmt->error);
        }
        
        // Se è un trainer, imposta trainer_id per se stesso
        if ($data['role_in_gym'] === 'trainer') {
            $updateTrainerStmt = $conn->prepare("UPDATE users SET trainer_id = ? WHERE id = ?");
            $updateTrainerStmt->bind_param("ii", $user_id, $user_id);
            $updateTrainerStmt->execute();
        }
        
        $conn->commit();
        
        // Aggiorna statistiche palestra
        updateGymStatsManually($conn, $gym_id);
        
        // Recupera utente creato con info complete
        $newUser = getCompleteUserInfo($conn, $user_id);
        
        http_response_code(201);
        echo json_encode([
            'message' => 'Utente creato con successo',
            'user' => $newUser
        ]);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione dell\'utente: ' . $e->getMessage()]);
    }
}

/**
 * Aggiungi utente esistente alla palestra
 */
function addMemberToGym($conn, $user) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['user_id']) || !isset($data['role_in_gym'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID utente e ruolo sono obbligatori']);
            return;
        }
        
        // Ottieni gym_id dell'utente corrente
        $gym_id = getGymIdForUser($conn, $user);
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Palestra non trovata']);
            return;
        }
        
        // Verifica che l'utente esista e non sia già in una palestra
        $checkUserStmt = $conn->prepare("SELECT id, gym_id FROM users WHERE id = ?");
        $checkUserStmt->bind_param("i", $data['user_id']);
        $checkUserStmt->execute();
        $userResult = $checkUserStmt->get_result();
        
        if ($userResult->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Utente non trovato']);
            return;
        }
        
        $targetUser = $userResult->fetch_assoc();
        if ($targetUser['gym_id']) {
            http_response_code(400);
            echo json_encode(['error' => 'L\'utente è già membro di una palestra']);
            return;
        }
        
        // Verifica limiti
        if (!checkGymLimits($conn, $gym_id, $data['role_in_gym'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Raggiunto il limite massimo per questo tipo di utente']);
            return;
        }
        
        // Inizia transazione
        $conn->begin_transaction();
        
        // Aggiorna utente
        $updateUserStmt = $conn->prepare("UPDATE users SET gym_id = ? WHERE id = ?");
        $updateUserStmt->bind_param("ii", $gym_id, $data['user_id']);
        $updateUserStmt->execute();
        
        // Crea membership
        $membershipStmt = $conn->prepare("
            INSERT INTO gym_memberships (gym_id, user_id, role_in_gym, status)
            VALUES (?, ?, ?, 'active')
        ");
        
        $membershipStmt->bind_param("iis", $gym_id, $data['user_id'], $data['role_in_gym']);
        
        if (!$membershipStmt->execute()) {
            $conn->rollback();
            throw new Exception($membershipStmt->error);
        }
        
        $conn->commit();
        
        // Aggiorna statistiche palestra
        updateGymStatsManually($conn, $gym_id);
        
        echo json_encode(['message' => 'Utente aggiunto alla palestra con successo']);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiunta dell\'utente: ' . $e->getMessage()]);
    }
}

/**
 * Aggiorna membro della palestra
 */
function updateGymMember($conn, $user_id, $user) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Ottieni gym_id dell'utente corrente
        $gym_id = getGymIdForUser($conn, $user);
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Palestra non trovata']);
            return;
        }
        
        // Verifica che l'utente appartenga alla palestra
        $checkStmt = $conn->prepare("
            SELECT gm.id, gm.role_in_gym 
            FROM gym_memberships gm 
            WHERE gm.gym_id = ? AND gm.user_id = ?
        ");
        $checkStmt->bind_param("ii", $gym_id, $user_id);
        $checkStmt->execute();
        $membershipResult = $checkStmt->get_result();
        
        if ($membershipResult->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Utente non trovato in questa palestra']);
            return;
        }
        
        $membership = $membershipResult->fetch_assoc();
        
        // Costruisci query di aggiornamento
        $updateFields = [];
        $paramTypes = '';
        $paramValues = [];
        
        // Aggiorna membership
        if (isset($data['role_in_gym']) && $data['role_in_gym'] !== $membership['role_in_gym']) {
            // Verifica limiti se cambia ruolo
            if (!checkGymLimits($conn, $gym_id, $data['role_in_gym'], $user_id)) {
                http_response_code(400);
                echo json_encode(['error' => 'Raggiunto il limite massimo per questo tipo di utente']);
                return;
            }
            
            $updateFields[] = "role_in_gym = ?";
            $paramTypes .= "s";
            $paramValues[] = $data['role_in_gym'];
        }
        
        if (isset($data['status'])) {
            $updateFields[] = "status = ?";
            $paramTypes .= "s";
            $paramValues[] = $data['status'];
        }
        
        if (!empty($updateFields)) {
            $paramTypes .= "ii";
            $paramValues[] = $gym_id;
            $paramValues[] = $user_id;
            
            $query = "UPDATE gym_memberships SET " . implode(", ", $updateFields) . 
                    " WHERE gym_id = ? AND user_id = ?";
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param($paramTypes, ...$paramValues);
            $stmt->execute();
        }
        
        echo json_encode(['message' => 'Membro aggiornato con successo']);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento del membro: ' . $e->getMessage()]);
    }
}

/**
 * Rimuovi membro dalla palestra
 */
function removeMemberFromGym($conn, $user_id, $user) {
    try {
        // Ottieni gym_id dell'utente corrente
        $gym_id = getGymIdForUser($conn, $user);
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Palestra non trovata']);
            return;
        }
        
        // Verifica che l'utente appartenga alla palestra
        $checkStmt = $conn->prepare("
            SELECT gm.id 
            FROM gym_memberships gm 
            WHERE gm.gym_id = ? AND gm.user_id = ?
        ");
        $checkStmt->bind_param("ii", $gym_id, $user_id);
        $checkStmt->execute();
        
        if ($checkStmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Utente non trovato in questa palestra']);
            return;
        }
        
        // Non permettere di rimuovere il proprietario
        $ownerStmt = $conn->prepare("SELECT owner_user_id FROM gyms WHERE id = ?");
        $ownerStmt->bind_param("i", $gym_id);
        $ownerStmt->execute();
        $ownerResult = $ownerStmt->get_result();
        if ($ownerResult->num_rows > 0) {
            $owner = $ownerResult->fetch_assoc();
            if ($owner['owner_user_id'] == $user_id) {
                http_response_code(400);
                echo json_encode(['error' => 'Non è possibile rimuovere il proprietario della palestra']);
                return;
            }
        }
        
        // Inizia transazione
        $conn->begin_transaction();
        
        // Rimuovi membership
        $deleteMembershipStmt = $conn->prepare("DELETE FROM gym_memberships WHERE gym_id = ? AND user_id = ?");
        $deleteMembershipStmt->bind_param("ii", $gym_id, $user_id);
        $deleteMembershipStmt->execute();
        
        // Rimuovi associazione gym_id dall'utente
        $updateUserStmt = $conn->prepare("UPDATE users SET gym_id = NULL WHERE id = ?");
        $updateUserStmt->bind_param("i", $user_id);
        $updateUserStmt->execute();
        
        $conn->commit();
        
        // Aggiorna statistiche palestra
        updateGymStatsManually($conn, $gym_id);
        
        echo json_encode(['message' => 'Utente rimosso dalla palestra con successo']);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella rimozione dell\'utente: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni gym_id per l'utente corrente
 */
function getGymIdForUser($conn, $user) {
    if (hasRole($user, 'admin')) {
        // Admin può specificare gym_id via GET
        return isset($_GET['gym_id']) ? (int)$_GET['gym_id'] : null;
    }
    
    if (hasRole($user, 'gym')) {
        $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
        $stmt->bind_param("i", $user['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            return $result->fetch_assoc()['gym_id'];
        }
    }
    
    return null;
}

/**
 * Verifica limiti della palestra
 */
function checkGymLimits($conn, $gym_id, $role_in_gym, $exclude_user_id = null) {
    $stmt = $conn->prepare("SELECT max_users, max_trainers FROM gyms WHERE id = ?");
    $stmt->bind_param("i", $gym_id);
    $stmt->execute();
    $limits = $stmt->get_result()->fetch_assoc();
    
    if (!$limits) return false;
    
    if ($role_in_gym === 'trainer') {
        $countStmt = $conn->prepare("
            SELECT COUNT(*) as count 
            FROM gym_memberships 
            WHERE gym_id = ? AND role_in_gym = 'trainer' AND status = 'active'" . 
            ($exclude_user_id ? " AND user_id != ?" : "")
        );
        
        if ($exclude_user_id) {
            $countStmt->bind_param("ii", $gym_id, $exclude_user_id);
        } else {
            $countStmt->bind_param("i", $gym_id);
        }
        
        $countStmt->execute();
        $count = $countStmt->get_result()->fetch_assoc()['count'];
        
        return $count < $limits['max_trainers'];
    } else {
        $countStmt = $conn->prepare("
            SELECT COUNT(*) as count 
            FROM gym_memberships 
            WHERE gym_id = ? AND status = 'active'" . 
            ($exclude_user_id ? " AND user_id != ?" : "")
        );
        
        if ($exclude_user_id) {
            $countStmt->bind_param("ii", $gym_id, $exclude_user_id);
        } else {
            $countStmt->bind_param("i", $gym_id);
        }
        
        $countStmt->execute();
        $count = $countStmt->get_result()->fetch_assoc()['count'];
        
        return $count < $limits['max_users'];
    }
}

/**
 * Ottieni role_id dal ruolo nella palestra
 */
function getRoleIdFromGymRole($conn, $role_in_gym) {
    $role_name = ($role_in_gym === 'trainer') ? 'trainer' : 'user';
    
    $stmt = $conn->prepare("SELECT id FROM user_role WHERE name = ?");
    $stmt->bind_param("s", $role_name);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc()['id'];
    }
    
    return null;
}

/**
 * Ottieni informazioni complete dell'utente
 */
function getCompleteUserInfo($conn, $user_id) {
    $stmt = $conn->prepare("
        SELECT 
            u.id, u.username, u.name, u.email, u.active, u.last_login, u.created_at,
            gm.role_in_gym, gm.status as membership_status, gm.joined_at,
            r.name as role_name
        FROM users u
        LEFT JOIN gym_memberships gm ON u.id = gm.user_id
        LEFT JOIN user_role r ON u.role_id = r.id
        WHERE u.id = ?
    ");
    
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    return $stmt->get_result()->fetch_assoc();
}

/**
 * Aggiorna statistiche palestra manualmente (senza trigger)
 */
function updateGymStatsManually($conn, $gym_id) {
    try {
        // Chiama la stored procedure per aggiornare le statistiche
        $stmt = $conn->prepare("CALL UpdateGymStats(?)");
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        $stmt->close();
        
        return true;
    } catch (Exception $e) {
        error_log("Errore aggiornamento statistiche palestra $gym_id: " . $e->getMessage());
        return false;
    }
}

$conn->close();
?>
