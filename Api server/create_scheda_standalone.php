<?php
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
require_once 'subscription_limits.php';

header('Content-Type: application/json');

// Funzione di debug per tracciare errori
function debug_log($message, $data = null) {
    error_log("DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("DATA: " . print_r($data, true));
    }
}

$input = json_decode(file_get_contents('php://input'), true);
//debug_log("Input ricevuto:", $input);

if (!isset($input['user_id'], $input['nome']) || empty($input['esercizi'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Dati obbligatori mancanti o nessun esercizio selezionato.']);
    exit;
}

foreach ($input['esercizi'] as $es) {
    if (!isset($es['id']) || !isset($es['serie']) || !isset($es['ripetizioni']) || !isset($es['peso']) ||
        trim((string)$es['serie']) === '' || trim((string)$es['ripetizioni']) === '' || trim((string)$es['peso']) === '') {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Compilare tutti i campi: serie, ripetizioni e peso per ogni esercizio selezionato.']);
        exit;
    }
}

$user_id = intval($input['user_id']);
$nome = trim($input['nome']);
$descrizione = isset($input['descrizione']) ? trim($input['descrizione']) : null;
$esercizi = $input['esercizi'];

//debug_log("Preparazione per creazione scheda: user_id=$user_id, nome=$nome");
//debug_log("Esercizi da creare:", $esercizi);

$conn->begin_transaction();

$limitCheck = checkWorkoutLimit($user_id);

if ($limitCheck['limit_reached']) {
    http_response_code(403);
    echo json_encode([
        'success' => false,
        'message' => 'Hai raggiunto il limite di schede per il tuo piano. Passa al piano Premium per avere schede illimitate.',
        'upgrade_required' => true
    ]);
    exit;
}
try {
    $stmt = $conn->prepare("INSERT INTO schede (nome, descrizione, data_creazione, active) VALUES (?, ?, NOW(), 1)");
    $stmt->bind_param('ss', $nome, $descrizione);
    $stmt->execute();
    $scheda_id = $stmt->insert_id;
    $stmt->close();
    //debug_log("Scheda creata con ID: $scheda_id");

    $assign = $conn->prepare("INSERT INTO user_workout_assignments (user_id, scheda_id, active, assigned_date) VALUES (?, ?, 1, NOW())");
    $assign->bind_param('ii', $user_id, $scheda_id);
    $assign->execute();
    $assign->close();
    //debug_log("Scheda assegnata all'utente: $user_id");

    // Query aggiornata per includere i nuovi campi REST-PAUSE
    $insert_exercise = $conn->prepare("
        INSERT INTO scheda_esercizi 
        (scheda_id, esercizio_id, serie, ripetizioni, peso, ordine, tempo_recupero, note, set_type, linked_to_previous, is_rest_pause, rest_pause_reps, rest_pause_rest_seconds) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");

    foreach ($esercizi as $es) {
        $esercizio_id = intval($es['id']);
        $serie = intval($es['serie']);
        $ripetizioni = intval($es['ripetizioni']);
        $peso = floatval($es['peso']);
        $ordine = intval($es['ordine']);
        
        // Campi esistenti con valori predefiniti se non presenti
        $tempo_recupero = isset($es['tempo_recupero']) ? intval($es['tempo_recupero']) : 90;
        $note = isset($es['note']) ? $es['note'] : '';
        
        // Assicuriamoci che set_type sia una stringa valida
        $set_type = isset($es['set_type']) && !empty($es['set_type']) ? $es['set_type'] : 'normal';
        
        $linked_to_previous = isset($es['linked_to_previous']) ? intval($es['linked_to_previous']) : 0;

        // NUOVI CAMPI REST-PAUSE con valori predefiniti
        $is_rest_pause = isset($es['is_rest_pause']) ? intval($es['is_rest_pause']) : 0;
        $rest_pause_reps = isset($es['rest_pause_reps']) && !empty($es['rest_pause_reps']) ? $es['rest_pause_reps'] : null;
        $rest_pause_rest_seconds = isset($es['rest_pause_rest_seconds']) ? intval($es['rest_pause_rest_seconds']) : 15;

        //debug_log("Inserimento esercizio: ID=$esercizio_id, serie=$serie, rip=$ripetizioni, peso=$peso, ordine=$ordine");
        //debug_log("Campi avanzati: tempo_recupero=$tempo_recupero, set_type=$set_type, linked=$linked_to_previous");
        //debug_log("Campi REST-PAUSE: is_rest_pause=$is_rest_pause, rest_pause_reps=$rest_pause_reps, rest_pause_rest_seconds=$rest_pause_rest_seconds");

        $insert_exercise->bind_param('iiiidiissiisi', 
            $scheda_id, 
            $esercizio_id, 
            $serie, 
            $ripetizioni, 
            $peso, 
            $ordine,
            $tempo_recupero,
            $note,
            $set_type,
            $linked_to_previous,
            $is_rest_pause,
            $rest_pause_reps,
            $rest_pause_rest_seconds
        );
        
        $result = $insert_exercise->execute();
        if (!$result) {
            throw new Exception("Errore nell'inserimento dell'esercizio ID $esercizio_id: " . $insert_exercise->error);
        }
        //debug_log("Esercizio inserito con successo");
    }

    $insert_exercise->close();

    $conn->commit();
    //debug_log("Transazione completata con successo");
    echo json_encode(['success' => true, 'message' => 'Scheda e esercizi creati con successo.']);

} catch (Exception $e) {
    $conn->rollback();
    //debug_log("ERRORE: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Errore durante il salvataggio: ' . $e->getMessage()]);
}

$conn->close();
?>