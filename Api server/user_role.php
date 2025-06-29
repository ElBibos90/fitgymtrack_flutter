<?php
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

// Per GET non richiediamo autenticazione per semplificare
if ($method !== 'GET') {
    // Verifica autenticazione e ruolo amministratore
    $user = authMiddleware($conn, ['admin']);
    if (!$user) {
        exit();
    }
}

switch($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            getRoleById($conn, $_GET['id']);
        } else {
            getAllRoles($conn);
        }
        break;
        
    case 'POST':
        createRole($conn);
        break;
        
    case 'PUT':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID ruolo mancante']);
            break;
        }
        updateRole($conn, $_GET['id']);
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID ruolo mancante']);
            break;
        }
        deleteRole($conn, $_GET['id']);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

function getAllRoles($conn) {
    try {
        $result = $conn->query("
            SELECT * FROM user_role
            ORDER BY name ASC
        ");

        $roles = [];
        while ($row = $result->fetch_assoc()) {
            $roles[] = $row;
        }
        
        echo json_encode($roles);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dei ruoli: ' . $e->getMessage()]);
    }
}

function getRoleById($conn, $id) {
    try {
        $stmt = $conn->prepare("SELECT * FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $role = $result->fetch_assoc();
        
        if (!$role) {
            http_response_code(404);
            echo json_encode(['error' => 'Ruolo non trovato']);
            return;
        }
        
        echo json_encode($role);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero del ruolo: ' . $e->getMessage()]);
    }
}

function createRole($conn) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Validazione dati
        if (!isset($data['name']) || empty($data['name'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Nome ruolo obbligatorio']);
            return;
        }
        
        // Verifica se il nome ruolo esiste già
        $stmt = $conn->prepare("SELECT id FROM user_role WHERE name = ?");
        $stmt->bind_param("s", $data['name']);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Nome ruolo già in uso']);
            return;
        }
        
        // Inserimento ruolo
        $stmt = $conn->prepare("
            INSERT INTO user_role (name, description)
            VALUES (?, ?)
        ");
        
        $description = isset($data['description']) ? $data['description'] : '';
        
        $stmt->bind_param("ss", $data['name'], $description);
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        $newRoleId = $stmt->insert_id;
        
        // Recupera il ruolo appena creato
        $stmt = $conn->prepare("SELECT * FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $newRoleId);
        $stmt->execute();
        $newRole = $stmt->get_result()->fetch_assoc();
        
        http_response_code(201); // Created
        echo json_encode([
            'message' => 'Ruolo creato con successo',
            'role' => $newRole
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione del ruolo: ' . $e->getMessage()]);
    }
}

function updateRole($conn, $id) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Verifica che il ruolo esista
        $stmt = $conn->prepare("SELECT id FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Ruolo non trovato']);
            return;
        }
        
        // Previeni la modifica dei ruoli di sistema (admin, user e trainer)
        if ($id <= 3) {
            http_response_code(403);
            echo json_encode(['error' => 'I ruoli di sistema non possono essere modificati']);
            return;
        }
        
        // Se si sta modificando il nome, verifica che non esista già
        if (isset($data['name']) && !empty($data['name'])) {
            $stmt = $conn->prepare("SELECT id FROM user_role WHERE name = ? AND id != ?");
            $stmt->bind_param("si", $data['name'], $id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows > 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Nome ruolo già in uso']);
                return;
            }
        } else {
            // Nome obbligatorio
            http_response_code(400);
            echo json_encode(['error' => 'Nome ruolo obbligatorio']);
            return;
        }
        
        // Aggiorna il ruolo
        $description = isset($data['description']) ? $data['description'] : '';
        
        $stmt = $conn->prepare("
            UPDATE user_role 
            SET name = ?, description = ?
            WHERE id = ?
        ");
        
        $stmt->bind_param("ssi", $data['name'], $description, $id);
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        // Recupera il ruolo aggiornato
        $stmt = $conn->prepare("SELECT * FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $updatedRole = $stmt->get_result()->fetch_assoc();
        
        echo json_encode([
            'message' => 'Ruolo aggiornato con successo',
            'role' => $updatedRole
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento del ruolo: ' . $e->getMessage()]);
    }
}

function deleteRole($conn, $id) {
    try {
        // Verifica che il ruolo esista
        $stmt = $conn->prepare("SELECT id FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Ruolo non trovato']);
            return;
        }
        
        // Previeni l'eliminazione dei ruoli di sistema (admin, user e trainer)
        if ($id <= 3) {
            http_response_code(403);
            echo json_encode(['error' => 'I ruoli di sistema non possono essere eliminati']);
            return;
        }
        
        // Verifica se ci sono utenti con questo ruolo
        $stmt = $conn->prepare("SELECT id FROM users WHERE role_id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Impossibile eliminare il ruolo: esistono utenti con questo ruolo']);
            return;
        }
        
        // Elimina il ruolo
        $stmt = $conn->prepare("DELETE FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        echo json_encode(['message' => 'Ruolo eliminato con successo']);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione del ruolo: ' . $e->getMessage()]);
    }
}

$conn->close();
?>