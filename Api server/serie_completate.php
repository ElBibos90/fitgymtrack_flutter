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

// Verifica autenticazione
$userData = authMiddleware($conn);
if (!$userData) {
    exit();
}

// Ottieni l'ID dell'utente autenticato
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : $userData['user_id'];


$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        try {
                    // Nuovo blocco per progressione
        if(isset($_GET['progress']) && $_GET['progress'] === 'true') {
            $stmt = $conn->prepare("
                SELECT 
                    e.id as esercizio_id,
                    e.nome as esercizio_nome,
                    e.gruppo_muscolare,
                    
                    MIN(sc.peso) as peso_min,
                    MAX(sc.peso) as peso_max,
                    AVG(sc.peso) as peso_medio,
                    
                    MIN(sc.ripetizioni) as ripetizioni_min,
                    MAX(sc.ripetizioni) as ripetizioni_max,
                    AVG(sc.ripetizioni) as ripetizioni_medie,
                    
                    COUNT(DISTINCT sc.allenamento_id) as allenamenti_totali,
                    MAX(sc.timestamp) as ultimo_allenamento
                FROM serie_completate sc
                JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
                JOIN esercizi e ON se.esercizio_id = e.id
                JOIN allenamenti a ON sc.allenamento_id = a.id
                WHERE a.user_id = ?
                GROUP BY e.id, e.nome, e.gruppo_muscolare
                HAVING allenamenti_totali > 1
                ORDER BY ultimo_allenamento DESC
                LIMIT 20
            ");

            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();

            $progressData = [];
            while ($row = $result->fetch_assoc()) {
                $progressData[] = $row;
            }

            echo json_encode($progressData);
            exit;
        }
            if(isset($_GET['allenamento_id'])) {
                $allenamento_id = intval($_GET['allenamento_id']);
                
                // Verifica che l'allenamento appartenga all'utente corrente
                $checkStmt = $conn->prepare("
                    SELECT a.id 
                    FROM allenamenti a
                    JOIN user_workout_assignments uwa ON a.scheda_id = uwa.scheda_id
                    WHERE a.id = ? AND uwa.user_id = ?
                ");
                $checkStmt->bind_param("ii", $allenamento_id, $userId);
                $checkStmt->execute();
                $checkResult = $checkStmt->get_result();
                
                if ($checkResult->num_rows === 0) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Accesso non autorizzato a questo allenamento']);
                    exit;
                }
                
                $stmt = $conn->prepare("
                    SELECT 
                        sc.*,
                        e.nome as esercizio_nome,
                        e.gruppo_muscolare,
                        e.id as esercizio_id,
                        se.id as scheda_esercizio_id,
                        se.esercizio_id as esercizio_originale_id
                    FROM serie_completate sc
                    JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
                    JOIN esercizi e ON se.esercizio_id = e.id
                    JOIN allenamenti a ON sc.allenamento_id = a.id
                    JOIN user_workout_assignments uwa ON a.scheda_id = uwa.scheda_id
                    WHERE sc.allenamento_id = ? AND uwa.user_id = ?
                    ORDER BY sc.timestamp ASC
                ");
                
                $stmt->bind_param("ii", $allenamento_id, $userId);
                $stmt->execute();
                $result = $stmt->get_result();
                
                $serie = array();
                while($row = $result->fetch_assoc()) {
                    $serie[] = $row;
                }
                echo json_encode($serie);
            } 
            else if(isset($_GET['esercizio_id'])) {
                $esercizio_id = intval($_GET['esercizio_id']);
                $stmt = $conn->prepare("
                    SELECT 
                        sc.*,
                        e.nome as esercizio_nome,
                        e.gruppo_muscolare,
                        e.id as esercizio_id,
                        se.id as scheda_esercizio_id,
                        se.esercizio_id as esercizio_originale_id
                    FROM serie_completate sc
                    JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
                    JOIN esercizi e ON se.esercizio_id = e.id
                    JOIN allenamenti a ON sc.allenamento_id = a.id
                    JOIN user_workout_assignments uwa ON a.scheda_id = uwa.scheda_id
                    WHERE e.id = ? AND uwa.user_id = ?
                    ORDER BY sc.timestamp DESC
                    LIMIT 20
                ");
                
                $stmt->bind_param("ii", $esercizio_id, $userId);
                if (!$stmt->execute()) {
                    throw new Exception("Errore nell'esecuzione della query: " . $stmt->error);
                }
                
                $result = $stmt->get_result();
                if (!$result) {
                    throw new Exception("Errore nel recupero dei risultati: " . $conn->error);
                }
                
                $storico = array();
                while($row = $result->fetch_assoc()) {
                    $storico[] = $row;
                }
                
                echo json_encode($storico);
            } 
            else {
                throw new Exception("Parametro ID mancante");
            }
        } catch (Exception $e) {
            error_log("Errore in GET serie_completate: " . $e->getMessage());
            http_response_code(400);
            echo json_encode(["message" => $e->getMessage()]);
        }
        break;

    case 'POST':
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            if(!$data) {
                throw new Exception("Dati non validi");
            }
            
            // Verifica che l'allenamento appartenga all'utente corrente
            $checkStmt = $conn->prepare("
                SELECT a.id 
                FROM allenamenti a
                JOIN user_workout_assignments uwa ON a.scheda_id = uwa.scheda_id
                WHERE a.id = ? AND uwa.user_id = ?
            ");
            $checkStmt->bind_param("ii", $data['allenamento_id'], $userId);
            $checkStmt->execute();
            $checkResult = $checkStmt->get_result();
            
            if ($checkResult->num_rows === 0) {
                http_response_code(403);
                echo json_encode(['error' => 'Non autorizzato a registrare serie per questo allenamento']);
                exit;
            }
            
            $stmt = $conn->prepare("
                INSERT INTO serie_completate 
                (allenamento_id, scheda_esercizio_id, peso, ripetizioni, tempo_recupero, note) 
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            
            $tempo_recupero = isset($data['tempo_recupero']) ? $data['tempo_recupero'] : 90;
            $note = isset($data['note']) ? $data['note'] : '';
            
            $stmt->bind_param(
                "iidiis",
                $data['allenamento_id'],
                $data['scheda_esercizio_id'],
                $data['peso'],
                $data['ripetizioni'],
                $tempo_recupero,
                $note
            );
            
            if(!$stmt->execute()) {
                throw new Exception("Errore nel salvataggio: " . $stmt->error);
            }
            
            $newId = $stmt->insert_id;
            
            // Recupera i dati completi della serie appena inserita
            $stmt = $conn->prepare("
                SELECT 
                    sc.*,
                    e.nome as esercizio_nome,
                    e.gruppo_muscolare,
                    e.id as esercizio_id,
                    se.id as scheda_esercizio_id,
                    se.esercizio_id as esercizio_originale_id
                FROM serie_completate sc
                JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
                JOIN esercizi e ON se.esercizio_id = e.id
                WHERE sc.id = ?
            ");
            
            $stmt->bind_param("i", $newId);
            $stmt->execute();
            $result = $stmt->get_result();
            $serieCompleta = $result->fetch_assoc();
            
            echo json_encode([
                "id" => $newId,
                "message" => "Serie registrata con successo",
                "data" => $serieCompleta
            ]);
            
        } catch (Exception $e) {
            error_log("Errore in POST serie_completate: " . $e->getMessage());
            http_response_code(400);
            echo json_encode(["message" => $e->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["message" => "Metodo non consentito"]);
}

$conn->close();
?>