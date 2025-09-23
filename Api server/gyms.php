<?php
// ============================================================================
// API GESTIONE PALESTRE
// Permette agli admin di creare e gestire palestre
// Permette ai gestori palestre di gestire i propri utenti
// ============================================================================

// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - accetta richieste da localhost:3000
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

$method = $_SERVER['REQUEST_METHOD'];

// Verifica autenticazione - Admin, Gym e Trainer possono accedere
$user = authMiddleware($conn, ['admin', 'gym', 'trainer']);
if (!$user) {
    exit();
}

switch($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            getGymById($conn, $_GET['id'], $user);
        } elseif (isset($_GET['action']) && $_GET['action'] === 'stats') {
            getGymStats($conn, $_GET['gym_id'] ?? null, $user);
        } elseif (isset($_GET['action']) && $_GET['action'] === 'members') {
            getGymMembers($conn, $_GET['gym_id'] ?? null, $user);
        } else {
            getAllGyms($conn, $user);
        }
        break;
        
    case 'POST':
        createGym($conn, $user);
        break;
        
    case 'PUT':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID palestra mancante']);
            break;
        }
        updateGym($conn, $_GET['id'], $user);
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID palestra mancante']);
            break;
        }
        deleteGym($conn, $_GET['id'], $user);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

/**
 * Ottieni tutte le palestre (solo admin) o la propria palestra (gym/trainer)
 */
function getAllGyms($conn, $user) {
    try {
        if (hasRole($user, 'admin')) {
            // Admin vede tutte le palestre
            $stmt = $conn->prepare("
                SELECT * FROM gym_overview 
                ORDER BY created_at DESC
            ");
            $stmt->execute();
        } elseif (hasRole($user, 'gym')) {
            // Gym vede solo la propria palestra (dove è owner)
            $stmt = $conn->prepare("
                SELECT * FROM gym_overview 
                WHERE owner_username = ?
            ");
            $stmt->bind_param("s", $user['username']);
            $stmt->execute();
        } else {
            // Trainer vede solo la palestra a cui appartiene
            $stmt = $conn->prepare("
                SELECT go.* FROM gym_overview go
                JOIN users u ON go.id = u.gym_id
                WHERE u.username = ?
            ");
            $stmt->bind_param("s", $user['username']);
            $stmt->execute();
        }
        
        $result = $stmt->get_result();
        $gyms = [];
        while ($row = $result->fetch_assoc()) {
            $gyms[] = $row;
        }
        
        echo json_encode($gyms);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero delle palestre: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni una palestra specifica per ID
 */
function getGymById($conn, $id, $user) {
    try {
        // Verifica permessi
        if (!canAccessGym($conn, $id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Non hai permessi per visualizzare questa palestra']);
            return;
        }
        
        $stmt = $conn->prepare("SELECT * FROM gym_overview WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $gym = $result->fetch_assoc();
        
        if (!$gym) {
            http_response_code(404);
            echo json_encode(['error' => 'Palestra non trovata']);
            return;
        }
        
        echo json_encode($gym);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero della palestra: ' . $e->getMessage()]);
    }
}

/**
 * Crea una nuova palestra (solo admin)
 */
function createGym($conn, $user) {
    try {
        // Solo admin può creare palestre
        if (!hasRole($user, 'admin')) {
            http_response_code(403);
            echo json_encode(['error' => 'Solo gli amministratori possono creare palestre']);
            return;
        }
        
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Validazione dati
        $required = ['name', 'email', 'owner_username'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['error' => "Campo '$field' obbligatorio"]);
                return;
            }
        }
        
        // Verifica che l'email non esista già
        $stmt = $conn->prepare("SELECT id FROM gyms WHERE email = ?");
        $stmt->bind_param("s", $data['email']);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Email già in uso da un\'altra palestra']);
            return;
        }
        
        // Trova o crea l'utente proprietario
        $owner_user_id = null;
        
        if (isset($data['create_owner']) && $data['create_owner']) {
            // Crea nuovo utente gym
            $owner_user_id = createGymOwner($conn, $data);
            if (!$owner_user_id) {
                return; // Errore già gestito in createGymOwner
            }
        } else {
            // Usa utente esistente
            $stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
            $stmt->bind_param("s", $data['owner_username']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Utente proprietario non trovato']);
                return;
            }
            $owner_user_id = $result->fetch_assoc()['id'];
        }
        
        // Inizia transazione
        $conn->begin_transaction();
        
        // Inserimento palestra
        $stmt = $conn->prepare("
            INSERT INTO gyms (name, email, phone, address, owner_user_id, max_users, max_trainers)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        
        $phone = isset($data['phone']) ? $data['phone'] : null;
        $address = isset($data['address']) ? $data['address'] : null;
        $max_users = isset($data['max_users']) ? (int)$data['max_users'] : 100;
        $max_trainers = isset($data['max_trainers']) ? (int)$data['max_trainers'] : 10;
        
        $stmt->bind_param("ssssiii", 
            $data['name'], 
            $data['email'], 
            $phone, 
            $address, 
            $owner_user_id,
            $max_users,
            $max_trainers
        );
        
        if (!$stmt->execute()) {
            $conn->rollback();
            throw new Exception($stmt->error);
        }
        
        $gym_id = $stmt->insert_id;
        
        // Aggiorna l'utente proprietario con il ruolo gym
        $gymRoleStmt = $conn->prepare("SELECT id FROM user_role WHERE name = 'gym'");
        $gymRoleStmt->execute();
        $gymRoleResult = $gymRoleStmt->get_result();
        if ($gymRoleResult->num_rows === 0) {
            $conn->rollback();
            http_response_code(500);
            echo json_encode(['error' => 'Ruolo gym non trovato']);
            return;
        }
        $gymRoleId = $gymRoleResult->fetch_assoc()['id'];
        
        $updateUserStmt = $conn->prepare("UPDATE users SET role_id = ?, gym_id = ? WHERE id = ?");
        $updateUserStmt->bind_param("iii", $gymRoleId, $gym_id, $owner_user_id);
        
        if (!$updateUserStmt->execute()) {
            $conn->rollback();
            throw new Exception($updateUserStmt->error);
        }
        
        // Crea membership del proprietario
        $membershipStmt = $conn->prepare("
            INSERT INTO gym_memberships (gym_id, user_id, role_in_gym, status)
            VALUES (?, ?, 'manager', 'active')
        ");
        $membershipStmt->bind_param("ii", $gym_id, $owner_user_id);
        
        if (!$membershipStmt->execute()) {
            $conn->rollback();
            throw new Exception($membershipStmt->error);
        }
        
        // Inizializza statistiche
        $statsStmt = $conn->prepare("
            INSERT INTO gym_stats (gym_id, total_members, total_trainers)
            VALUES (?, 0, 0)
        ");
        $statsStmt->bind_param("i", $gym_id);
        $statsStmt->execute();
        
        $conn->commit();
        
        // Recupera la palestra creata
        $stmt = $conn->prepare("SELECT * FROM gym_overview WHERE id = ?");
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        $newGym = $stmt->get_result()->fetch_assoc();
        
        http_response_code(201);
        echo json_encode([
            'message' => 'Palestra creata con successo',
            'gym' => $newGym
        ]);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione della palestra: ' . $e->getMessage()]);
    }
}

/**
 * Crea un nuovo utente proprietario della palestra
 */
function createGymOwner($conn, $data) {
    try {
        // Validazione dati owner
        $ownerRequired = ['owner_username', 'owner_password', 'owner_email', 'owner_name'];
        foreach ($ownerRequired as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['error' => "Campo '$field' obbligatorio per creare il proprietario"]);
                return false;
            }
        }
        
        // Verifica che username e email non esistano
        $checkStmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
        $checkStmt->bind_param("ss", $data['owner_username'], $data['owner_email']);
        $checkStmt->execute();
        if ($checkStmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Username o email del proprietario già in uso']);
            return false;
        }
        
        // Hash password
        $hashedPassword = password_hash($data['owner_password'], PASSWORD_BCRYPT);
        
        // Ottieni role_id per 'gym'
        $roleStmt = $conn->prepare("SELECT id FROM user_role WHERE name = 'gym'");
        $roleStmt->execute();
        $roleResult = $roleStmt->get_result();
        if ($roleResult->num_rows === 0) {
            http_response_code(500);
            echo json_encode(['error' => 'Ruolo gym non trovato']);
            return false;
        }
        $gymRoleId = $roleResult->fetch_assoc()['id'];
        
        // Crea utente
        $userStmt = $conn->prepare("
            INSERT INTO users (username, password, email, name, role_id, active, current_plan_id)
            VALUES (?, ?, ?, ?, ?, 1, 4)
        ");
        
        $userStmt->bind_param("ssssi", 
            $data['owner_username'], 
            $hashedPassword, 
            $data['owner_email'], 
            $data['owner_name'],
            $gymRoleId
        );
        
        if (!$userStmt->execute()) {
            throw new Exception($userStmt->error);
        }
        
        return $userStmt->insert_id;
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione del proprietario: ' . $e->getMessage()]);
        return false;
    }
}

/**
 * Aggiorna una palestra
 */
function updateGym($conn, $id, $user) {
    try {
        // Verifica permessi
        if (!canAccessGym($conn, $id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Non hai permessi per modificare questa palestra']);
            return;
        }
        
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Costruisci query dinamica
        $updateFields = [];
        $paramTypes = '';
        $paramValues = [];
        
        $allowedFields = ['name', 'email', 'phone', 'address', 'max_users', 'max_trainers', 'status'];
        
        foreach ($allowedFields as $field) {
            if (isset($data[$field])) {
                $updateFields[] = "$field = ?";
                
                if (in_array($field, ['max_users', 'max_trainers'])) {
                    $paramTypes .= "i";
                    $paramValues[] = (int)$data[$field];
                } else {
                    $paramTypes .= "s";
                    $paramValues[] = $data[$field];
                }
            }
        }
        
        if (empty($updateFields)) {
            http_response_code(400);
            echo json_encode(['error' => 'Nessun campo da aggiornare']);
            return;
        }
        
        // Verifica email unica se modificata
        if (isset($data['email'])) {
            $emailStmt = $conn->prepare("SELECT id FROM gyms WHERE email = ? AND id != ?");
            $emailStmt->bind_param("si", $data['email'], $id);
            $emailStmt->execute();
            if ($emailStmt->get_result()->num_rows > 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Email già in uso da un\'altra palestra']);
                return;
            }
        }
        
        $paramTypes .= "i";
        $paramValues[] = $id;
        
        $query = "UPDATE gyms SET " . implode(", ", $updateFields) . " WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param($paramTypes, ...$paramValues);
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        // Recupera palestra aggiornata
        $stmt = $conn->prepare("SELECT * FROM gym_overview WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $updatedGym = $stmt->get_result()->fetch_assoc();
        
        echo json_encode([
            'message' => 'Palestra aggiornata con successo',
            'gym' => $updatedGym
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento della palestra: ' . $e->getMessage()]);
    }
}

/**
 * Elimina una palestra (solo admin)
 */
function deleteGym($conn, $id, $user) {
    try {
        // Solo admin può eliminare palestre
        if (!hasRole($user, 'admin')) {
            http_response_code(403);
            echo json_encode(['error' => 'Solo gli amministratori possono eliminare palestre']);
            return;
        }
        
        // Verifica che la palestra esista
        $stmt = $conn->prepare("SELECT id, name FROM gyms WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Palestra non trovata']);
            return;
        }
        
        $gym = $result->fetch_assoc();
        
        // Inizia transazione
        $conn->begin_transaction();
        
        // Rimuovi associazione gym_id dagli utenti
        $updateUsersStmt = $conn->prepare("UPDATE users SET gym_id = NULL WHERE gym_id = ?");
        $updateUsersStmt->bind_param("i", $id);
        $updateUsersStmt->execute();
        
        // Elimina palestra (CASCADE eliminerà automaticamente memberships e stats)
        $deleteStmt = $conn->prepare("DELETE FROM gyms WHERE id = ?");
        $deleteStmt->bind_param("i", $id);
        
        if (!$deleteStmt->execute()) {
            $conn->rollback();
            throw new Exception($deleteStmt->error);
        }
        
        $conn->commit();
        
        echo json_encode([
            'message' => 'Palestra "' . $gym['name'] . '" eliminata con successo'
        ]);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione della palestra: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni statistiche di una palestra
 */
function getGymStats($conn, $gym_id, $user) {
    try {
        // Se gym_id non specificato e user è gym, usa la sua palestra
        if (!$gym_id && hasRole($user, 'gym')) {
            $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
            $stmt->bind_param("i", $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $gym_id = $result->fetch_assoc()['gym_id'];
            }
        }
        
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'ID palestra mancante']);
            return;
        }
        
        // Verifica permessi
        if (!canAccessGym($conn, $gym_id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Non hai permessi per visualizzare queste statistiche']);
            return;
        }
        
        $stmt = $conn->prepare("SELECT * FROM gym_stats WHERE gym_id = ?");
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        $stats = $stmt->get_result()->fetch_assoc();
        
        if (!$stats) {
            // Crea statistiche se non esistono
            $insertStmt = $conn->prepare("INSERT INTO gym_stats (gym_id) VALUES (?)");
            $insertStmt->bind_param("i", $gym_id);
            $insertStmt->execute();
            
            $stats = [
                'gym_id' => $gym_id,
                'total_members' => 0,
                'total_trainers' => 0,
                'active_workouts_today' => 0,
                'total_workouts_month' => 0,
                'last_updated' => date('Y-m-d H:i:s')
            ];
        }
        
        echo json_encode($stats);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero delle statistiche: ' . $e->getMessage()]);
    }
}

/**
 * Ottieni membri di una palestra
 */
function getGymMembers($conn, $gym_id, $user) {
    try {
        // Se gym_id non specificato e user è gym, usa la sua palestra
        if (!$gym_id && hasRole($user, 'gym')) {
            $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ?");
            $stmt->bind_param("i", $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $gym_id = $result->fetch_assoc()['gym_id'];
            }
        }
        
        if (!$gym_id) {
            http_response_code(400);
            echo json_encode(['error' => 'ID palestra mancante']);
            return;
        }
        
        // Verifica permessi
        if (!canAccessGym($conn, $gym_id, $user)) {
            http_response_code(403);
            echo json_encode(['error' => 'Non hai permessi per visualizzare questi membri']);
            return;
        }
        
        $stmt = $conn->prepare("
            SELECT 
                u.id, u.username, u.name, u.email, u.active, u.last_login, u.created_at,
                gm.role_in_gym, gm.status as membership_status, gm.joined_at,
                r.name as role_name
            FROM gym_memberships gm
            JOIN users u ON gm.user_id = u.id
            JOIN user_role r ON u.role_id = r.id
            WHERE gm.gym_id = ?
            ORDER BY gm.joined_at DESC
        ");
        
        $stmt->bind_param("i", $gym_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $members = [];
        while ($row = $result->fetch_assoc()) {
            $members[] = $row;
        }
        
        echo json_encode($members);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dei membri: ' . $e->getMessage()]);
    }
}

/**
 * Verifica se l'utente può accedere alla palestra
 */
function canAccessGym($conn, $gym_id, $user) {
    // Admin può accedere a tutto
    if (hasRole($user, 'admin')) {
        return true;
    }
    
    // Gym può accedere solo alla propria palestra (dove è owner)
    if (hasRole($user, 'gym')) {
        $stmt = $conn->prepare("SELECT id FROM gyms WHERE id = ? AND owner_user_id = ?");
        $stmt->bind_param("ii", $gym_id, $user['user_id']);
        $stmt->execute();
        return $stmt->get_result()->num_rows > 0;
    }
    
    // Trainer può accedere solo alla palestra a cui appartiene
    if (hasRole($user, 'trainer')) {
        $stmt = $conn->prepare("SELECT gym_id FROM users WHERE id = ? AND gym_id = ?");
        $stmt->bind_param("ii", $user['user_id'], $gym_id);
        $stmt->execute();
        return $stmt->get_result()->num_rows > 0;
    }
    
    return false;
}

$conn->close();
?>
