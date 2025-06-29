<?php
// Abilita errori per debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS
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
        header("Access-Control-Allow-Methods: GET, OPTIONS");
    }
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }
    exit(0);
}

header('Content-Type: application/json');

include 'config.php';

// Aggiungiamo un log di debug per tracciare le richieste
// function logDebug($message, $data = null) {
//     $logFile = __DIR__ . '/equipment_debug.log';
//     $timestamp = date('Y-m-d H:i:s');
//     $logMessage = "[$timestamp] $message";
    
//     if ($data !== null) {
//         $logMessage .= " - " . json_encode($data);
//     }
    
//     file_put_contents($logFile, $logMessage . PHP_EOL, FILE_APPEND);
// }

// API entrypoint
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Metodo non consentito']);
    exit();
}

if (isset($_GET['exercise_id'])) {
    //logDebug("Richiesta con exercise_id", $_GET['exercise_id']);
    getEquipmentByExerciseId($conn, $_GET['exercise_id']);
} elseif (isset($_GET['scheda_esercizi_id'])) {
    //logDebug("Richiesta con scheda_esercizi_id", $_GET['scheda_esercizi_id']);
    getEquipmentBySchedaEserciziId($conn, $_GET['scheda_esercizi_id']);
} else {
    http_response_code(400);
    //logDebug("Richiesta senza parametri validi", $_GET);
    echo json_encode(['error' => 'Parametro mancante']);
}

// CORREZIONE: Modifica alla query per ottenere l'equipment_type_id dall'esercizio collegato
function getEquipmentBySchedaEserciziId($conn, $schedaEserciziId) {
    try {
        //logDebug("Inizio recupero dati per scheda_esercizi_id", $schedaEserciziId);
        
        // Query modificata: JOIN con esercizi per ottenere l'equipment_type_id
        $stmt = $conn->prepare("
            SELECT e.equipment_type_id 
            FROM scheda_esercizi se 
            JOIN esercizi e ON se.esercizio_id = e.id 
            WHERE se.id = ?
        ");
        
        $stmt->bind_param("i", $schedaEserciziId);
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();

        if (!$row) {
            //logDebug("Scheda esercizio non trovata", $schedaEserciziId);
            http_response_code(404);
            echo json_encode(['error' => 'Scheda esercizio non trovata']);
            return;
        }

        //logDebug("Dati recuperati dalla query", $row);

        if (!$row['equipment_type_id']) {
            //logDebug("Scheda esercizio senza equipment_type_id", ['schedaEserciziId' => $schedaEserciziId, 'result' => $row]);
            http_response_code(404);
            echo json_encode(['error' => 'Scheda esercizio senza equipment_type_id']);
            return;
        }

        // Recupera direttamente i dati dell'attrezzatura
        getEquipmentById($conn, $row['equipment_type_id']);
    } catch (Exception $e) {
        /*logDebug("Errore nella risoluzione scheda esercizio", [
            "schedaEserciziId" => $schedaEserciziId,
            "error" => $e->getMessage()
        ]);*/
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella risoluzione scheda esercizio: ' . $e->getMessage()]);
    }
}

// Function per recuperare i dati dell'attrezzatura dato l'ID dell'esercizio
function getEquipmentByExerciseId($conn, $exerciseId) {
    try {
        //logDebug("Inizio recupero dati per exercise_id", $exerciseId);
        
        $stmt = $conn->prepare("SELECT equipment_type_id FROM esercizi WHERE id = ?");
        $stmt->bind_param("i", $exerciseId);
        $stmt->execute();
        $result = $stmt->get_result();
        $exercise = $result->fetch_assoc();

        if (!$exercise) {
            //logDebug("Esercizio non trovato", $exerciseId);
            http_response_code(404);
            echo json_encode(['error' => 'Esercizio non trovato']);
            return;
        }

        //logDebug("Dati esercizio recuperati", $exercise);

        if (!$exercise['equipment_type_id']) {
            /*logDebug("Esercizio senza equipment_type_id", [
                "exerciseId" => $exerciseId,
                "exercise" => $exercise
            ]);*/
            http_response_code(404);
            echo json_encode(['error' => 'Esercizio senza equipment_type_id']);
            return;
        }

        getEquipmentById($conn, $exercise['equipment_type_id']);
    } catch (Exception $e) {
        /*logDebug("Errore nel recupero dati esercizio", [
            "exerciseId" => $exerciseId,
            "error" => $e->getMessage()
        ]);*/
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dati: ' . $e->getMessage()]);
    }
}

// Recupera e formatta i dati dell'attrezzatura dato il suo ID
function getEquipmentById($conn, $id) {
    try {
        //logDebug("Recupero attrezzatura con ID", $id);
        
        $stmt = $conn->prepare("SELECT * FROM equipment_types WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $equipment = $result->fetch_assoc();

        if (!$equipment) {
            //logDebug("Attrezzatura non trovata con ID", $id);
            http_response_code(404);
            echo json_encode(['error' => 'Attrezzatura non trovata']);
            return;
        }

        /*logDebug("Attrezzatura trovata", [
            "id" => $id,
            "name" => $equipment['name'],
            "has_fixed_weights" => $equipment['has_fixed_weights'],
            "is_composable" => $equipment['is_composable']
        ]);*/

        // CORREZIONE: Assicurati che i campi booleani siano convertiti in interi
        // Questo evita problemi di interpretazione nel frontend
        $equipment['has_fixed_weights'] = (int)$equipment['has_fixed_weights'];
        $equipment['is_composable'] = (int)$equipment['is_composable'];

        // Recupera i pesi fissi disponibili se l'attrezzatura li supporta
        if ($equipment['has_fixed_weights']) {
            $weightsStmt = $conn->prepare("SELECT id, weight FROM equipment_weights WHERE equipment_id = ? ORDER BY weight ASC");
            $weightsStmt->bind_param("i", $id);
            $weightsStmt->execute();
            $weightsResult = $weightsStmt->get_result();

            $weights = [];
            while ($weight = $weightsResult->fetch_assoc()) {
                // Assicurati che il peso sia un numero
                $weight['weight'] = (float)$weight['weight'];
                $weights[] = $weight;
            }
            
            //logDebug("Pesi fissi recuperati", count($weights));
            $equipment['weights'] = $weights;
        }

        // Recupera i dischi componibili se l'attrezzatura è componibile
        if ($equipment['is_composable']) {
            $discsStmt = $conn->prepare("SELECT id, weight, quantity FROM equipment_discs WHERE equipment_id = ? ORDER BY weight ASC");
            $discsStmt->bind_param("i", $id);
            $discsStmt->execute();
            $discsResult = $discsStmt->get_result();

            $discs = [];
            while ($disc = $discsResult->fetch_assoc()) {
                // Assicurati che i valori siano numerici
                $disc['weight'] = (float)$disc['weight'];
                $disc['quantity'] = (int)$disc['quantity'];
                $discs[] = $disc;
            }
            
            //logDebug("Dischi componibili recuperati", count($discs));
            $equipment['discs'] = $discs;
        }

        /*logDebug("Dati attrezzatura completi pronti per la risposta", [
            "id" => $equipment['id'],
            "name" => $equipment['name'],
            "weightsCount" => isset($equipment['weights']) ? count($equipment['weights']) : 0,
            "discsCount" => isset($equipment['discs']) ? count($equipment['discs']) : 0
        ]);*/

        echo json_encode($equipment);
    } catch (Exception $e) {
        /*logDebug("Errore nel recupero attrezzatura", [
            "id" => $id,
            "error" => $e->getMessage()
        ]);*/
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero attrezzatura: ' . $e->getMessage()]);
    }
}

$conn->close();
?>