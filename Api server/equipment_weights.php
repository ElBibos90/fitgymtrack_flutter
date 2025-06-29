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

// Verifica autenticazione e ruolo (solo admin e trainer possono gestire i pesi)
$userData = authMiddleware($conn, ['admin', 'trainer']);
if (!$userData) {
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        if (isset($_GET['equipment_id'])) {
            getWeightsByEquipmentId($conn, $_GET['equipment_id']);
        } else if (isset($_GET['id'])) {
            getWeightById($conn, $_GET['id']);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'ID attrezzatura mancante']);
        }
        break;
        
    case 'POST':
        createWeight($conn);
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID peso mancante']);
            break;
        }
        deleteWeight($conn, $_GET['id']);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

function getWeightsByEquipmentId($conn, $equipmentId) {
    try {
        // Verifica che l'attrezzatura esista
        $checkStmt = $conn->prepare("SELECT id, name, has_fixed_weights FROM equipment_types WHERE id = ?");
        $checkStmt->bind_param("i", $equipmentId);
        $checkStmt->execute();
        $equipment = $checkStmt->get_result()->fetch_assoc();
        
        if (!$equipment) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        // Verifica che l'attrezzatura abbia pesi fissi
        if (!$equipment['has_fixed_weights']) {
            http_response_code(400);
            echo json_encode([
                'error' => 'Questa attrezzatura non utilizza pesi fissi',
                'equipment' => $equipment
            ]);
            return;
        }
        
        // Recupera i pesi disponibili
        $stmt = $conn->prepare("
            SELECT * FROM equipment_weights 
            WHERE equipment_id = ? 
            ORDER BY weight ASC
        ");
        $stmt->bind_param("i", $equipmentId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $weights = [];
        while ($row = $result->fetch_assoc()) {
            $weights[] = $row;
        }
        
        echo json_encode([
            'equipment' => $equipment,
            'weights' => $weights
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dei pesi: ' . $e->getMessage()]);
    }
}

function getWeightById($conn, $id) {
    try {
        $stmt = $conn->prepare("
            SELECT w.*, e.name as equipment_name 
            FROM equipment_weights w
            JOIN equipment_types e ON w.equipment_id = e.id
            WHERE w.id = ?
        ");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $weight = $result->fetch_assoc();
        
        if (!$weight) {
            http_response_code(404);
            echo json_encode(['error' => 'Peso non trovato']);
            return;
        }
        
        echo json_encode($weight);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero del peso: ' . $e->getMessage()]);
    }
}

function createWeight($conn) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Validazione dati
        if (!isset($data['equipment_id']) || !isset($data['weight'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Equipment ID e peso sono obbligatori']);
            return;
        }
        
        $equipmentId = intval($data['equipment_id']);
        $weight = floatval($data['weight']);
        
        // Verifica che l'attrezzatura esista e utilizzi pesi fissi
        $checkStmt = $conn->prepare("SELECT id, has_fixed_weights FROM equipment_types WHERE id = ?");
        $checkStmt->bind_param("i", $equipmentId);
        $checkStmt->execute();
        $equipment = $checkStmt->get_result()->fetch_assoc();
        
        if (!$equipment) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        if (!$equipment['has_fixed_weights']) {
            http_response_code(400);
            echo json_encode(['error' => 'Questa attrezzatura non utilizza pesi fissi']);
            return;
        }
        
        // Verifica che il peso non esista già per questa attrezzatura
        $checkWeightStmt = $conn->prepare("SELECT id FROM equipment_weights WHERE equipment_id = ? AND weight = ?");
        $checkWeightStmt->bind_param("id", $equipmentId, $weight);
        $checkWeightStmt->execute();
        
        if ($checkWeightStmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Questo peso è già disponibile per questa attrezzatura']);
            return;
        }
        
        // Inserisci il nuovo peso
        $stmt = $conn->prepare("INSERT INTO equipment_weights (equipment_id, weight) VALUES (?, ?)");
        $stmt->bind_param("id", $equipmentId, $weight);
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        $newWeightId = $stmt->insert_id;
        
        // Recupera il peso appena creato
        $getStmt = $conn->prepare("
            SELECT w.*, e.name as equipment_name 
            FROM equipment_weights w
            JOIN equipment_types e ON w.equipment_id = e.id
            WHERE w.id = ?
        ");
        $getStmt->bind_param("i", $newWeightId);
        $getStmt->execute();
        $newWeight = $getStmt->get_result()->fetch_assoc();
        
        http_response_code(201); // Created
        echo json_encode([
            'message' => 'Peso aggiunto con successo',
            'weight' => $newWeight
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiunta del peso: ' . $e->getMessage()]);
    }
}

function deleteWeight($conn, $id) {
    try {
        // Verifica che il peso esista
        $stmt = $conn->prepare("SELECT id FROM equipment_weights WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Peso non trovato']);
            return;
        }
        
        // Elimina il peso
        $deleteStmt = $conn->prepare("DELETE FROM equipment_weights WHERE id = ?");
        $deleteStmt->bind_param("i", $id);
        
        if (!$deleteStmt->execute()) {
            throw new Exception($deleteStmt->error);
        }
        
        echo json_encode(['message' => 'Peso eliminato con successo']);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione del peso: ' . $e->getMessage()]);
    }
}

$conn->close();
?>