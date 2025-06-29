<?php
// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - accetta richieste da ambienti multipli
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

// Verifica autenticazione
$userData = authMiddleware($conn);
if (!$userData) {
    exit();
}

// Ottieni l'ID dell'utente autenticato
$userId = $userData['user_id'];
$isTrainer = hasRole($userData, 'trainer');
$isAdmin = hasRole($userData, 'admin');

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        try {
            if(isset($_GET['id'])) {
                $id = intval($_GET['id']);
                
                // Query base per ottenere l'allenamento
                $baseQuery = "
                    SELECT a.*, s.nome as scheda_nome
                    FROM allenamenti a
                    JOIN schede s ON a.scheda_id = s.id
                    JOIN user_workout_assignments uwa ON a.scheda_id = uwa.scheda_id
                ";
                
                if ($isAdmin) {
                    // Admin vede tutti gli allenamenti
                    $stmt = $conn->prepare($baseQuery . " WHERE a.id = ?");
                    $stmt->bind_param("i", $id);
                } else if ($isTrainer) {
                    // Trainer vede gli allenamenti dei suoi utenti
                    $stmt = $conn->prepare($baseQuery . "
                        JOIN users u ON uwa.user_id = u.id
                        WHERE a.id = ? AND (u.trainer_id = ? OR a.user_id = ?)
                    ");
                    $stmt->bind_param("iii", $id, $userId, $userId);
                } else {
                    // Utente normale vede solo i propri allenamenti
                    $stmt = $conn->prepare($baseQuery . " WHERE a.id = ? AND uwa.user_id = ?");
                    $stmt->bind_param("ii", $id, $userId);
                }
                
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows === 0) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Accesso non autorizzato a questo allenamento']);
                    exit;
                }
                
                echo json_encode($result->fetch_assoc());
            } else {
                // Filtra gli allenamenti in base al ruolo
                $baseQuery = "
                    SELECT a.*, s.nome as scheda_nome
                    FROM allenamenti a
                    JOIN schede s ON a.scheda_id = s.id
                    JOIN user_workout_assignments uwa ON a.scheda_id = uwa.scheda_id
                ";
                
                if ($isAdmin) {
                    // Admin vede tutti gli allenamenti
                    $stmt = $conn->prepare($baseQuery . " ORDER BY a.data_allenamento DESC");
                } else if ($isTrainer) {
                    // Trainer vede gli allenamenti dei suoi utenti
                    $stmt = $conn->prepare($baseQuery . "
                        JOIN users u ON uwa.user_id = u.id 
                        WHERE u.trainer_id = ? OR a.user_id = ?
                        ORDER BY a.data_allenamento DESC
                    ");
                    $stmt->bind_param("ii", $userId, $userId);
                } else {
                    // Utente normale vede solo i propri allenamenti
                    $stmt = $conn->prepare($baseQuery . " WHERE uwa.user_id = ? ORDER BY a.data_allenamento DESC");
                    $stmt->bind_param("i", $userId);
                }
                
                $stmt->execute();
                $result = $stmt->get_result();
                
                $allenamenti = array();
                while($row = $result->fetch_assoc()) {
                    $allenamenti[] = $row;
                }
                echo json_encode($allenamenti);
            }
        } catch (Exception $e) {
            error_log("Errore in GET allenamenti: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'POST':
        try {
            $input = file_get_contents("php://input");
            error_log("Dati ricevuti: " . $input);  // Log dei dati ricevuti
            
            $data = json_decode($input, true);
            if(!$data) {
                throw new Exception("Dati non validi: " . json_last_error_msg());
            }
            
            if (!isset($data['scheda_id'])) {
                throw new Exception("scheda_id mancante");
            }
            
            $scheda_id = intval($data['scheda_id']);
            
            // Verifica che l'utente abbia accesso a questa scheda
            if ($isAdmin) {
                // L'admin ha accesso a tutte le schede
                $stmt = $conn->prepare("SELECT id FROM schede WHERE id = ?");
                $stmt->bind_param("i", $scheda_id);
            } else if ($isTrainer) {
                // Verifica che la scheda sia assegnata a un utente di questo trainer
                $stmt = $conn->prepare("
                    SELECT s.id 
                    FROM schede s
                    JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
                    JOIN users u ON uwa.user_id = u.id
                    WHERE s.id = ? AND (u.trainer_id = ? OR uwa.user_id = ?)
                ");
                $stmt->bind_param("iii", $scheda_id, $userId, $userId);
            } else {
                // Verifica che la scheda sia assegnata all'utente
                $stmt = $conn->prepare("
                    SELECT id FROM user_workout_assignments 
                    WHERE user_id = ? AND scheda_id = ? AND active = 1
                ");
                $stmt->bind_param("ii", $userId, $scheda_id);
            }
            
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                throw new Exception("Non sei autorizzato ad utilizzare questa scheda");
            }
            
            // Imposta l'utente corretto per l'allenamento
            $allenamentoUserId = $userId;
            
            // Se l'admin o il trainer sta creando l'allenamento per un altro utente
            if (($isAdmin || $isTrainer) && isset($data['user_id']) && $data['user_id'] != $userId) {
                // Verifica che l'utente esista e il trainer abbia accesso
                if ($isTrainer) {
                    $checkUserStmt = $conn->prepare("
                        SELECT id FROM users WHERE id = ? AND trainer_id = ?
                    ");
                    $checkUserStmt->bind_param("ii", $data['user_id'], $userId);
                } else {
                    // Admin può creare per qualsiasi utente
                    $checkUserStmt = $conn->prepare("SELECT id FROM users WHERE id = ?");
                    $checkUserStmt->bind_param("i", $data['user_id']);
                }
                
                $checkUserStmt->execute();
                $userResult = $checkUserStmt->get_result();
                
                if ($userResult->num_rows === 0) {
                    throw new Exception("Utente non valido o non hai permessi");
                }
                
                $allenamentoUserId = $data['user_id'];
            }
            
            $stmt = $conn->prepare("
                INSERT INTO allenamenti (scheda_id, data_allenamento, user_id) 
                VALUES (?, NOW(), ?)
            ");
            
            $stmt->bind_param("ii", $scheda_id, $allenamentoUserId);
            
            if(!$stmt->execute()) {
                throw new Exception("Errore nell'esecuzione della query: " . $stmt->error);
            }
            
            $id = $stmt->insert_id;
            
            // Recupera l'allenamento appena creato
            $result = $conn->query("
                SELECT a.*, s.nome as scheda_nome
                FROM allenamenti a
                JOIN schede s ON a.scheda_id = s.id
                WHERE a.id = $id
            ");
            
            if (!$result) {
                throw new Exception("Errore nel recupero dell'allenamento: " . $conn->error);
            }
            
            $allenamento = $result->fetch_assoc();
            if (!$allenamento) {
                throw new Exception("Allenamento non trovato dopo l'inserimento");
            }
            
            echo json_encode($allenamento);
            
        } catch (Exception $e) {
            error_log("Errore in POST allenamenti: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'PUT':
        try {
            if(!isset($_GET['id'])) {
                throw new Exception("ID mancante");
            }
            
            $id = intval($_GET['id']);
            
            // Verifica che l'allenamento appartenga all'utente o a un utente gestito dal trainer
            if ($isAdmin) {
                // Admin può modificare qualsiasi allenamento
                $checkStmt = $conn->prepare("SELECT id FROM allenamenti WHERE id = ?");
                $checkStmt->bind_param("i", $id);
            } else if ($isTrainer) {
                // Trainer può modificare allenamenti dei suoi utenti o propri
                $checkStmt = $conn->prepare("
                    SELECT a.id 
                    FROM allenamenti a
                    JOIN users u ON a.user_id = u.id
                    WHERE a.id = ? AND (u.trainer_id = ? OR a.user_id = ?)
                ");
                $checkStmt->bind_param("iii", $id, $userId, $userId);
            } else {
                // Utente normale può modificare solo i propri allenamenti
                $checkStmt = $conn->prepare("SELECT id FROM allenamenti WHERE id = ? AND user_id = ?");
                $checkStmt->bind_param("ii", $id, $userId);
            }
            
            $checkStmt->execute();
            $checkResult = $checkStmt->get_result();
            
            if ($checkResult->num_rows === 0) {
                http_response_code(403);
                echo json_encode(['error' => 'Non autorizzato a modificare questo allenamento']);
                exit;
            }
            
            $data = json_decode(file_get_contents("php://input"), true);
            
            $stmt = $conn->prepare("
                UPDATE allenamenti 
                SET durata_totale = ?, note = ?
                WHERE id = ?
            ");
            
            $note = isset($data['note']) ? $data['note'] : '';
            $durata = isset($data['durata_totale']) ? intval($data['durata_totale']) : 0;
            
            $stmt->bind_param("isi", $durata, $note, $id);
            
            if(!$stmt->execute()) {
                throw new Exception("Errore nell'aggiornamento: " . $stmt->error);
            }
            
            echo json_encode(['message' => 'Allenamento aggiornato']);
            
        } catch (Exception $e) {
            error_log("Errore in PUT allenamenti: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'DELETE':
        try {
            if(!isset($_GET['id'])) {
                throw new Exception("ID mancante");
            }
            
            $id = intval($_GET['id']);
            
            // Verifica che l'allenamento appartenga all'utente o a un utente gestito dal trainer
            if ($isAdmin) {
                // Admin può eliminare qualsiasi allenamento
                $checkStmt = $conn->prepare("SELECT id FROM allenamenti WHERE id = ?");
                $checkStmt->bind_param("i", $id);
            } else if ($isTrainer) {
                // Trainer può eliminare allenamenti dei suoi utenti o propri
                $checkStmt = $conn->prepare("
                    SELECT a.id 
                    FROM allenamenti a
                    JOIN users u ON a.user_id = u.id
                    WHERE a.id = ? AND (u.trainer_id = ? OR a.user_id = ?)
                ");
                $checkStmt->bind_param("iii", $id, $userId, $userId);
            } else {
                // Utente normale può eliminare solo i propri allenamenti
                $checkStmt = $conn->prepare("SELECT id FROM allenamenti WHERE id = ? AND user_id = ?");
                $checkStmt->bind_param("ii", $id, $userId);
            }
            
            $checkStmt->execute();
            $checkResult = $checkStmt->get_result();
            
            if ($checkResult->num_rows === 0) {
                http_response_code(403);
                echo json_encode(['error' => 'Non autorizzato a eliminare questo allenamento']);
                exit;
            }
            
            // Prima eliminiamo tutte le serie completate associate
            $stmt = $conn->prepare("DELETE FROM serie_completate WHERE allenamento_id = ?");
            $stmt->bind_param("i", $id);
            $stmt->execute();
            
            // Poi eliminiamo l'allenamento
            $stmt = $conn->prepare("DELETE FROM allenamenti WHERE id = ?");
            $stmt->bind_param("i", $id);
            
            if(!$stmt->execute()) {
                throw new Exception("Errore nell'eliminazione dell'allenamento");
            }
            
            echo json_encode(['message' => 'Allenamento eliminato']);
            
        } catch (Exception $e) {
            error_log("Errore in DELETE allenamenti: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;
    default:
        http_response_code(405);
        echo json_encode(["message" => "Metodo non consentito"]);
}

$conn->close();
?>