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

// Verifica autenticazione e ruolo (solo admin e trainer possono gestire le attrezzature)
$userData = authMiddleware($conn, ['admin', 'trainer']);
if (!$userData) {
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            getEquipmentById($conn, $_GET['id']);
        } else {
            getAllEquipment($conn);
        }
        break;
        
    case 'POST':
        createEquipment($conn);
        break;
        
    case 'PUT':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID attrezzatura mancante']);
            break;
        }
        updateEquipment($conn, $_GET['id']);
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID attrezzatura mancante']);
            break;
        }
        deleteEquipment($conn, $_GET['id']);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

function getAllEquipment($conn) {
    try {
        $result = $conn->query("
            SELECT * FROM equipment_types
            ORDER BY name ASC
        ");

        $equipment = [];
        while ($row = $result->fetch_assoc()) {
            $equipment[] = $row;
        }
        
        echo json_encode($equipment);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero delle attrezzature: ' . $e->getMessage()]);
    }
}

function getEquipmentById($conn, $id) {
    try {
        $stmt = $conn->prepare("SELECT * FROM equipment_types WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $equipment = $result->fetch_assoc();
        
        if (!$equipment) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        // Recupera i pesi disponibili se l'attrezzatura ha pesi fissi
        if ($equipment['has_fixed_weights']) {
            $weightsStmt = $conn->prepare("SELECT id, weight FROM equipment_weights WHERE equipment_id = ? ORDER BY weight ASC");
            $weightsStmt->bind_param("i", $id);
            $weightsStmt->execute();
            $weightsResult = $weightsStmt->get_result();
            
            $weights = [];
            while ($weight = $weightsResult->fetch_assoc()) {
                $weights[] = $weight;
            }
            
            $equipment['weights'] = $weights;
        }
        
        // Recupera i dischi disponibili se l'attrezzatura è componibile
        if ($equipment['is_composable']) {
            $discsStmt = $conn->prepare("SELECT id, weight, quantity FROM equipment_discs WHERE equipment_id = ? ORDER BY weight ASC");
            $discsStmt->bind_param("i", $id);
            $discsStmt->execute();
            $discsResult = $discsStmt->get_result();
            
            $discs = [];
            while ($disc = $discsResult->fetch_assoc()) {
                $discs[] = $disc;
            }
            
            $equipment['discs'] = $discs;
        }
        
        echo json_encode($equipment);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dell\'attrezzatura: ' . $e->getMessage()]);
    }
}

function createEquipment($conn) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Validazione dati
        if (!isset($data['name']) || empty($data['name'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Nome attrezzatura obbligatorio']);
            return;
        }
        
        // Verifica se il nome esiste già
        $checkStmt = $conn->prepare("SELECT id FROM equipment_types WHERE name = ?");
        $checkStmt->bind_param("s", $data['name']);
        $checkStmt->execute();
        if ($checkStmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Nome attrezzatura già in uso']);
            return;
        }
        
        // Preparazione valori predefiniti
        $description = isset($data['description']) ? $data['description'] : '';
        $baseWeight = isset($data['base_weight']) ? floatval($data['base_weight']) : 0.00;
        $isComposable = isset($data['is_composable']) ? (bool)$data['is_composable'] : false;
        $increment = isset($data['increment']) ? floatval($data['increment']) : 1.00;
        $hasFixedWeights = isset($data['has_fixed_weights']) ? (bool)$data['has_fixed_weights'] : true;
        
        // Inserimento attrezzatura
        $conn->begin_transaction();
        
        $stmt = $conn->prepare("
            INSERT INTO equipment_types 
            (name, description, base_weight, is_composable, increment, has_fixed_weights) 
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        
        $isComposableInt = $isComposable ? 1 : 0;
        $hasFixedWeightsInt = $hasFixedWeights ? 1 : 0;
        
        $stmt->bind_param("ssddii", 
            $data['name'], 
            $description, 
            $baseWeight, 
            $isComposableInt, 
            $increment,
            $hasFixedWeightsInt
        );
        
        if (!$stmt->execute()) {
            throw new Exception($stmt->error);
        }
        
        $equipmentId = $stmt->insert_id;
        
        // Inserimento pesi disponibili se specificati
        if ($hasFixedWeights && isset($data['weights']) && is_array($data['weights'])) {
            $weightStmt = $conn->prepare("INSERT INTO equipment_weights (equipment_id, weight) VALUES (?, ?)");
            
            foreach ($data['weights'] as $weight) {
                $weightValue = floatval($weight);
                $weightStmt->bind_param("id", $equipmentId, $weightValue);
                
                if (!$weightStmt->execute()) {
                    $conn->rollback();
                    throw new Exception("Errore nell'inserimento del peso: " . $weightStmt->error);
                }
            }
        }
        
        // Inserimento dischi disponibili se specificati
        if ($isComposable && isset($data['discs']) && is_array($data['discs'])) {
            $discStmt = $conn->prepare("INSERT INTO equipment_discs (equipment_id, weight, quantity) VALUES (?, ?, ?)");
            
            foreach ($data['discs'] as $disc) {
                if (!isset($disc['weight']) || !isset($disc['quantity'])) continue;
                
                $discWeight = floatval($disc['weight']);
                $discQuantity = intval($disc['quantity']);
                
                $discStmt->bind_param("idi", $equipmentId, $discWeight, $discQuantity);
                
                if (!$discStmt->execute()) {
                    $conn->rollback();
                    throw new Exception("Errore nell'inserimento del disco: " . $discStmt->error);
                }
            }
        }
        
        $conn->commit();
        
        // Recupera l'attrezzatura appena creata
        $stmt = $conn->prepare("SELECT * FROM equipment_types WHERE id = ?");
        $stmt->bind_param("i", $equipmentId);
        $stmt->execute();
        $newEquipment = $stmt->get_result()->fetch_assoc();
        
        http_response_code(201); // Created
        echo json_encode([
            'message' => 'Attrezzatura creata con successo',
            'equipment' => $newEquipment
        ]);
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione dell\'attrezzatura: ' . $e->getMessage()]);
    }
}

function updateEquipment($conn, $id) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Verifica che l'attrezzatura esista
        $stmt = $conn->prepare("SELECT id FROM equipment_types WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        // Validazione nome se fornito
        if (isset($data['name']) && !empty($data['name'])) {
            $checkStmt = $conn->prepare("SELECT id FROM equipment_types WHERE name = ? AND id != ?");
            $checkStmt->bind_param("si", $data['name'], $id);
            $checkStmt->execute();
            if ($checkStmt->get_result()->num_rows > 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Nome attrezzatura già in uso']);
                return;
            }
        } else if (isset($data['name'])) {
            // Nome fornito ma vuoto
            http_response_code(400);
            echo json_encode(['error' => 'Nome attrezzatura obbligatorio']);
            return;
        }
        
        $conn->begin_transaction();
        
        // Costruisci la query di aggiornamento
        $updateFields = [];
        $updateParams = [];
        $paramTypes = "";
        
        if (isset($data['name'])) {
            $updateFields[] = "name = ?";
            $updateParams[] = $data['name'];
            $paramTypes .= "s";
        }
        
        if (isset($data['description'])) {
            $updateFields[] = "description = ?";
            $updateParams[] = $data['description'];
            $paramTypes .= "s";
        }
        
        if (isset($data['base_weight'])) {
            $updateFields[] = "base_weight = ?";
            $updateParams[] = floatval($data['base_weight']);
            $paramTypes .= "d";
        }
        
        if (isset($data['is_composable'])) {
            $updateFields[] = "is_composable = ?";
            $updateParams[] = (bool)$data['is_composable'] ? 1 : 0;
            $paramTypes .= "i";
        }
        
        if (isset($data['increment'])) {
            $updateFields[] = "increment = ?";
            $updateParams[] = floatval($data['increment']);
            $paramTypes .= "d";
        }
        
        if (isset($data['has_fixed_weights'])) {
            $updateFields[] = "has_fixed_weights = ?";
            $updateParams[] = (bool)$data['has_fixed_weights'] ? 1 : 0;
            $paramTypes .= "i";
        }
        
        // Se non ci sono campi da aggiornare
        if (empty($updateFields)) {
            $conn->rollback();
            http_response_code(400);
            echo json_encode(['error' => 'Nessun campo da aggiornare']);
            return;
        }
        
        // Prepara la query di aggiornamento
        $updateQuery = "UPDATE equipment_types SET " . implode(", ", $updateFields) . " WHERE id = ?";
        $paramTypes .= "i";
        $updateParams[] = $id;
        
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->bind_param($paramTypes, ...$updateParams);
        
        if (!$updateStmt->execute()) {
            $conn->rollback();
            throw new Exception($updateStmt->error);
        }
        
        // Gestione pesi disponibili
        if (isset($data['weights']) && is_array($data['weights'])) {
            // Rimuovi tutti i pesi esistenti
            $deleteWeightsStmt = $conn->prepare("DELETE FROM equipment_weights WHERE equipment_id = ?");
            $deleteWeightsStmt->bind_param("i", $id);
            $deleteWeightsStmt->execute();
            
            // Inserisci i nuovi pesi
            $weightStmt = $conn->prepare("INSERT INTO equipment_weights (equipment_id, weight) VALUES (?, ?)");
            
            foreach ($data['weights'] as $weight) {
                $weightValue = floatval($weight);
                $weightStmt->bind_param("id", $id, $weightValue);
                
                if (!$weightStmt->execute()) {
                    $conn->rollback();
                    throw new Exception("Errore nell'aggiornamento del peso: " . $weightStmt->error);
                }
            }
        }
        
        // Gestione dischi disponibili
        if (isset($data['discs']) && is_array($data['discs'])) {
            // Rimuovi tutti i dischi esistenti
            $deleteDiscsStmt = $conn->prepare("DELETE FROM equipment_discs WHERE equipment_id = ?");
            $deleteDiscsStmt->bind_param("i", $id);
            $deleteDiscsStmt->execute();
            
            // Inserisci i nuovi dischi
            $discStmt = $conn->prepare("INSERT INTO equipment_discs (equipment_id, weight, quantity) VALUES (?, ?, ?)");
            
            foreach ($data['discs'] as $disc) {
                if (!isset($disc['weight']) || !isset($disc['quantity'])) continue;
                
                $discWeight = floatval($disc['weight']);
                $discQuantity = intval($disc['quantity']);
                
                $discStmt->bind_param("idi", $id, $discWeight, $discQuantity);
                
                if (!$discStmt->execute()) {
                    $conn->rollback();
                    throw new Exception("Errore nell'aggiornamento del disco: " . $discStmt->error);
                }
            }
        }
        
        $conn->commit();
        
        // Recupera l'attrezzatura aggiornata
        $stmt = $conn->prepare("SELECT * FROM equipment_types WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $updatedEquipment = $stmt->get_result()->fetch_assoc();
        
        echo json_encode([
            'message' => 'Attrezzatura aggiornata con successo',
            'equipment' => $updatedEquipment
        ]);
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento dell\'attrezzatura: ' . $e->getMessage()]);
    }
}

function deleteEquipment($conn, $id) {
    try {
        // Verifica che l'attrezzatura esista
        $stmt = $conn->prepare("SELECT id FROM equipment_types WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }
        
        // Verifica se ci sono esercizi che utilizzano questa attrezzatura
        $checkStmt = $conn->prepare("SELECT COUNT(*) as count FROM esercizi WHERE equipment_type_id = ?");
        $checkStmt->bind_param("i", $id);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result()->fetch_assoc();
        
        if ($checkResult['count'] > 0) {
            // Imposta a NULL il riferimento negli esercizi
            $updateStmt = $conn->prepare("UPDATE esercizi SET equipment_type_id = NULL WHERE equipment_type_id = ?");
            $updateStmt->bind_param("i", $id);
            $updateStmt->execute();
        }
        
        $conn->begin_transaction();
        
        // Elimina i pesi associati
        $deleteWeightsStmt = $conn->prepare("DELETE FROM equipment_weights WHERE equipment_id = ?");
        $deleteWeightsStmt->bind_param("i", $id);
        $deleteWeightsStmt->execute();
        
        // Elimina i dischi associati
        $deleteDiscsStmt = $conn->prepare("DELETE FROM equipment_discs WHERE equipment_id = ?");
        $deleteDiscsStmt->bind_param("i", $id);
        $deleteDiscsStmt->execute();
        
        // Elimina l'attrezzatura
        $deleteStmt = $conn->prepare("DELETE FROM equipment_types WHERE id = ?");
        $deleteStmt->bind_param("i", $id);
        
        if (!$deleteStmt->execute()) {
            $conn->rollback();
            throw new Exception($deleteStmt->error);
        }
        
        $conn->commit();
        
        echo json_encode(['message' => 'Attrezzatura eliminata con successo']);
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione dell\'attrezzatura: ' . $e->getMessage()]);
    }
}

$conn->close();
?>