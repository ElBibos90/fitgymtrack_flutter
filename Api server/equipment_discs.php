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

// Verifica autenticazione e ruolo (solo admin e trainer possono gestire i dischi)
$userData = authMiddleware($conn, ['admin', 'trainer']);
if (!$userData) {
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        if (isset($_GET['equipment_id'])) {
            getDiscsByEquipmentId($conn, $_GET['equipment_id']);
        } else if (isset($_GET['id'])) {
            getDiscById($conn, $_GET['id']);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'ID attrezzatura mancante']);
        }
        break;
        
    case 'POST':
        createDisc($conn);
        break;
        
    case 'PUT':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID disco mancante']);
            break;
        }
        updateDisc($conn, $_GET['id']);
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID disco mancante']);
            break;
        }
        deleteDisc($conn, $_GET['id']);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

function getDiscsByEquipmentId($conn, $equipmentId) {
    try {
        // Verifica che l'attrezzatura esista
        $checkStmt = $conn->prepare("SELECT id, name, is_composable FROM equipment_types WHERE id = ?");
        $checkStmt->bind_param("i", $equipmentId);
        $checkStmt->execute();
        $equipment = $checkStmt->get_result()->fetch_assoc();
        
        if (!$equipment) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        // Verifica che l'attrezzatura sia componibile
        if (!$equipment['is_composable']) {
            http_response_code(400);
            echo json_encode([
                'error' => 'Questa attrezzatura non utilizza dischi componibili',
                'equipment' => $equipment
            ]);
            return;
        }
        
        // Recupera i dischi disponibili
        $stmt = $conn->prepare("
            SELECT * FROM equipment_discs 
            WHERE equipment_id = ? 
            ORDER BY weight ASC
        ");
        $stmt->bind_param("i", $equipmentId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $discs = [];
        while ($row = $result->fetch_assoc()) {
            $discs[] = $row;
        }
        
        echo json_encode([
            'equipment' => $equipment,
            'discs' => $discs
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dei dischi: ' . $e->getMessage()]);
    }
}

function getDiscById($conn, $id) {
    try {
        $stmt = $conn->prepare("
            SELECT d.*, e.name as equipment_name 
            FROM equipment_discs d
            JOIN equipment_types e ON d.equipment_id = e.id
            WHERE d.id = ?
        ");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $disc = $result->fetch_assoc();
        
        if (!$disc) {
            http_response_code(404);
            echo json_encode(['error' => 'Disco non trovato']);
            return;
        }
        
        echo json_encode($disc);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero del disco: ' . $e->getMessage()]);
    }
}

function createDisc($conn) {
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
        $quantity = isset($data['quantity']) ? intval($data['quantity']) : 2; // Default 2 dischi
        
        // Verifica che l'attrezzatura esista e sia componibile
        $checkStmt = $conn->prepare("SELECT id, is_composable FROM equipment_types WHERE id = ?");
        $checkStmt->bind_param("i", $equipmentId);
        $checkStmt->execute();
        $equipment = $checkStmt->get_result()->fetch_assoc();
        
        if (!$equipment) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        if (!$equipment['is_composable']) {
            http_response_code(400);
            echo json_encode(['error' => 'Questa attrezzatura non utilizza dischi componibili']);
            return;
        }
        
        // Verifica che il disco non esista già per questa attrezzatura
        $checkDiscStmt = $conn->prepare("SELECT id FROM equipment_discs WHERE equipment_id = ? AND weight = ?");
        $checkDiscStmt->bind_param("id", $equipmentId, $weight);
        $checkDiscStmt->execute();
        
        if ($checkDiscStmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Questo disco è già disponibile per questa attrezzatura']);
            return;
        }
        
        // Inserisci il nuovo disco
        $stmt = $conn->prepare("INSERT INTO equipment_discs (equipment_id, weight, quantity) VALUES (?, ?, ?)");
        $stmt->bind_param("idi", $equipmentId, $weight, $quantity);
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        $newDiscId = $stmt->insert_id;
        
        // Recupera il disco appena creato
        $getStmt = $conn->prepare("
            SELECT d.*, e.name as equipment_name 
            FROM equipment_discs d
            JOIN equipment_types e ON d.equipment_id = e.id
            WHERE d.id = ?
        ");
        $getStmt->bind_param("i", $newDiscId);
        $getStmt->execute();
        $newDisc = $getStmt->get_result()->fetch_assoc();
        
        http_response_code(201); // Created
        echo json_encode([
            'message' => 'Disco aggiunto con successo',
            'disc' => $newDisc
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiunta del disco: ' . $e->getMessage()]);
    }
}

function updateDisc($conn, $id) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Verifica che il disco esista
        $stmt = $conn->prepare("SELECT id FROM equipment_discs WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Disco non trovato']);
            return;
        }
        
        // Validazione input
        if (!isset($data['quantity']) && !isset($data['weight'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Nessun campo da aggiornare']);
            return;
        }
        
        // Costruisci query di aggiornamento
        $updateFields = [];
        $updateParams = [];
        $paramTypes = "";
        
        if (isset($data['quantity'])) {
            $updateFields[] = "quantity = ?";
            $updateParams[] = intval($data['quantity']);
            $paramTypes .= "i";
        }
        
        if (isset($data['weight'])) {
            $updateFields[] = "weight = ?";
            $updateParams[] = floatval($data['weight']);
            $paramTypes .= "d";
        }
        
        $updateQuery = "UPDATE equipment_discs SET " . implode(", ", $updateFields) . " WHERE id = ?";
        $paramTypes .= "i";
        $updateParams[] = $id;
        
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->bind_param($paramTypes, ...$updateParams);
        
        if (!$updateStmt->execute()) {
            throw new Exception($updateStmt->error);
        }
        
        // Recupera il disco aggiornato
        $getStmt = $conn->prepare("
            SELECT d.*, e.name as equipment_name 
            FROM equipment_discs d
            JOIN equipment_types e ON d.equipment_id = e.id
            WHERE d.id = ?
        ");
        $getStmt->bind_param("i", $id);
        $getStmt->execute();
        $updatedDisc = $getStmt->get_result()->fetch_assoc();
        
        echo json_encode([
            'message' => 'Disco aggiornato con successo',
            'disc' => $updatedDisc
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento del disco: ' . $e->getMessage()]);
    }
}

function deleteDisc($conn, $id) {
    try {
        // Verifica che il disco esista
        $stmt = $conn->prepare("SELECT id FROM equipment_discs WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Disco non trovato']);
            return;
        }
        
        // Elimina il disco
        $deleteStmt = $conn->prepare("DELETE FROM equipment_discs WHERE id = ?");
        $deleteStmt->bind_param("i", $id);
        
        if (!$deleteStmt->execute()) {
            throw new Exception($deleteStmt->error);
        }
        
        echo json_encode(['message' => 'Disco eliminato con successo']);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione del disco: ' . $e->getMessage()]);
    }
}

$conn->close();
?>