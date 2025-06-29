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

// Log di debug
function debug_log($message, $data = null) {
    $log_file = __DIR__ . '/esercizi_debug.log';
    $timestamp = date('Y-m-d H:i:s');
    $log_message = "[$timestamp] $message";
    
    if ($data !== null) {
        if (is_array($data) || is_object($data)) {
            $log_message .= "\nData: " . print_r($data, true);
        } else {
            $log_message .= "\nData: $data";
        }
    }
    
    file_put_contents($log_file, $log_message . "\n", FILE_APPEND);
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch($method) {
        case 'GET':
            if(isset($_GET['id'])) {
                $id = intval($_GET['id']);
                $stmt = $conn->prepare("SELECT * FROM esercizi WHERE id = ? ");
                $stmt->bind_param("i", $id);
                $stmt->execute();
                $result = $stmt->get_result();
                $exercise = $result->fetch_assoc();
                
                if (!$exercise) {
                    http_response_code(404);
                    echo json_encode(['success' => false, 'message' => 'Esercizio non trovato']);
                } else {
                    echo json_encode($exercise);
                }
            } else {
                $result = $conn->query("SELECT * FROM esercizi ORDER BY nome ASC");
                $esercizi = array();
                while($row = $result->fetch_assoc()) {
                    $esercizi[] = $row;
                }
                echo json_encode($esercizi);
            }
            break;

        case 'POST':
            $input = file_get_contents("php://input");
            $data = json_decode($input, true);
            
            if(!$data) {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Dati non validi"]);
                exit;
            }
            
            // Assicurati che is_isometric sia definito
            $is_isometric = isset($data['is_isometric']) ? intval($data['is_isometric']) : 0;
            
            // Assicurati che equipment_type_id sia definito
            $equipment_type_id = isset($data['equipment_type_id']) ? intval($data['equipment_type_id']) : null;
            
            // Inizia transazione per garantire integrità dei dati
            $conn->begin_transaction();
            
            try {
                // Modifica la query per includere equipment_type_id
                $stmt = $conn->prepare("INSERT INTO esercizi (nome, descrizione, immagine_url, gruppo_muscolare, attrezzatura, is_isometric, equipment_type_id, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                
                // Imposta il valore predefinito per status a NULL o a un valore specifico se fornito
                $status = isset($data['status']) ? $data['status'] : null;
                
                $stmt->bind_param("sssssiss", 
                    $data['nome'], 
                    $data['descrizione'], 
                    $data['immagine_url'],
                    $data['gruppo_muscolare'], 
                    $data['attrezzatura'],
                    $is_isometric,
                    $equipment_type_id,
                    $status
                );
                
                if($stmt->execute()) {
                    // Recupera l'esercizio appena creato
                    $id = $stmt->insert_id;
                    $stmt->close();
                    
                    $stmt = $conn->prepare("SELECT * FROM esercizi WHERE id = ?");
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    $newExercise = $result->fetch_assoc();
                    
                    $conn->commit();
                    echo json_encode(['success' => true, 'exercise' => $newExercise]);
                } else {
                    throw new Exception("Errore nell'inserimento dell'esercizio: " . $stmt->error);
                }
            } catch (Exception $e) {
                $conn->rollback();
                http_response_code(500);
                echo json_encode(["success" => false, "message" => "Errore nel salvataggio: " . $e->getMessage()]);
            }
            break;

        case 'PUT':
            if(!isset($_GET['id'])) {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "ID mancante"]);
                exit;
            }
        
            $input = file_get_contents("php://input");
            $data = json_decode($input, true);
            
            //debug_log("PUT request data:", $data);
            
            if(!$data) {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "Dati non validi"]);
                exit;
            }
        
            // Assicurati che is_isometric sia definito
            $is_isometric = isset($data['is_isometric']) ? intval($data['is_isometric']) : 0;
            
            // Assicurati che equipment_type_id sia definito
            $equipment_type_id = isset($data['equipment_type_id']) ? intval($data['equipment_type_id']) : null;
            
            // Gestione dello stato dell'esercizio
            $status = isset($data['status']) ? $data['status'] : null;
            
            $id = intval($_GET['id']);
            
            // Inizia transazione
            $conn->begin_transaction();
            
            try {
                // Verifica se l'esercizio esiste
                $checkStmt = $conn->prepare("SELECT id FROM esercizi WHERE id = ?");
                $checkStmt->bind_param("i", $id);
                $checkStmt->execute();
                
                if ($checkStmt->get_result()->num_rows === 0) {
                    $checkStmt->close();
                    http_response_code(404);
                    echo json_encode(["success" => false, "message" => "Esercizio non trovato"]);
                    exit;
                }
                
                $checkStmt->close();
                
                // Se lo status è incluso, aggiorna anche quello
                if ($status !== null) {
                    $stmt = $conn->prepare("UPDATE esercizi SET nome = ?, descrizione = ?, immagine_url = ?, gruppo_muscolare = ?, attrezzatura = ?, is_isometric = ?, equipment_type_id = ?, status = ? WHERE id = ?");
                    $stmt->bind_param("sssssissi", 
                        $data['nome'], 
                        $data['descrizione'], 
                        $data['immagine_url'],
                        $data['gruppo_muscolare'], 
                        $data['attrezzatura'],
                        $is_isometric,
                        $equipment_type_id,
                        $status,
                        $id
                    );
                } else {
                    // Altrimenti aggiorna tutti i campi tranne status
                    $stmt = $conn->prepare("UPDATE esercizi SET nome = ?, descrizione = ?, immagine_url = ?, gruppo_muscolare = ?, attrezzatura = ?, is_isometric = ?, equipment_type_id = ? WHERE id = ?");
                    $stmt->bind_param("sssssiii", 
                        $data['nome'], 
                        $data['descrizione'], 
                        $data['immagine_url'],
                        $data['gruppo_muscolare'], 
                        $data['attrezzatura'],
                        $is_isometric,
                        $equipment_type_id,
                        $id
                    );
                }
            
                if($stmt->execute()) {
                    // Recupera l'esercizio aggiornato
                    $stmt->close();
                    
                    $stmt = $conn->prepare("SELECT * FROM esercizi WHERE id = ?");
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    $updatedExercise = $result->fetch_assoc();
                    
                    $conn->commit();
                    echo json_encode(['success' => true, 'exercise' => $updatedExercise]);
                } else {
                    throw new Exception("Errore nell'aggiornamento dell'esercizio: " . $stmt->error);
                }
            } catch (Exception $e) {
                $conn->rollback();
                //debug_log("Errore nell'aggiornamento dell'esercizio", $e->getMessage());
                http_response_code(500);
                echo json_encode(["success" => false, "message" => "Errore nell'aggiornamento: " . $e->getMessage()]);
            }
            break;

        case 'DELETE':
            if(!isset($_GET['id'])) {
                http_response_code(400);
                echo json_encode(["success" => false, "message" => "ID mancante"]);
                exit;
            }
            
            $id = intval($_GET['id']);
            
            try {
                // Verifica se l'esercizio esiste
                $checkStmt = $conn->prepare("SELECT id FROM esercizi WHERE id = ?");
                $checkStmt->bind_param("i", $id);
                $checkStmt->execute();
                $result = $checkStmt->get_result();
                
                if ($result->num_rows === 0) {
                    $checkStmt->close();
                    http_response_code(404);
                    echo json_encode(["success" => false, "message" => "Esercizio non trovato"]);
                    exit;
                }
                
                $checkStmt->close();
                
                // Verifica se l'esercizio è utilizzato in qualche scheda
                $usageStmt = $conn->prepare("SELECT COUNT(*) as count FROM scheda_esercizi WHERE esercizio_id = ?");
                $usageStmt->bind_param("i", $id);
                $usageStmt->execute();
                $usageResult = $usageStmt->get_result()->fetch_assoc();
                
                if ($usageResult['count'] > 0) {
                    $usageStmt->close();
                    http_response_code(409); // Conflict
                    echo json_encode([
                        "success" => false, 
                        "message" => "Impossibile eliminare l'esercizio perché è utilizzato in una o più schede"
                    ]);
                    exit;
                }
                
                $usageStmt->close();
                
                // Procedi con l'eliminazione
                $stmt = $conn->prepare("DELETE FROM esercizi WHERE id = ?");
                $stmt->bind_param("i", $id);
                
                if ($stmt->execute()) {
                    if ($stmt->affected_rows > 0) {
                        echo json_encode(["success" => true, "message" => "Esercizio eliminato con successo"]);
                    } else {
                        http_response_code(404);
                        echo json_encode(["success" => false, "message" => "Esercizio non trovato o già eliminato"]);
                    }
                } else {
                    throw new Exception("Errore nell'eliminazione: " . $stmt->error);
                }
                
                $stmt->close();
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode(["success" => false, "message" => "Errore nell'eliminazione: " . $e->getMessage()]);
            }
            break;

        default:
            http_response_code(405);
            echo json_encode(["success" => false, "message" => "Metodo non consentito"]);
    }
} catch (Exception $e) {
    //debug_log("Errore non gestito", $e->getMessage());
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Errore del server: " . $e->getMessage()]);
}

$conn->close();
?>