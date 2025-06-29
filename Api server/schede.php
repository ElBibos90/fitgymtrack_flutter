<?php
// Abilita il reporting degli errori
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

// Funzione di logging personalizzata
// function debugLog($message, $data = null) {
//     $log_file = __DIR__ . '/debug.log';
//     $timestamp = date('Y-m-d H:i:s');
//     $log_message = "[$timestamp] $message";
    
//     if ($data !== null) {
//         $log_message .= "\nData: " . print_r($data, true);
//     }
    
//     $log_message .= "\n" . str_repeat('-', 80) . "\n";
    
//     file_put_contents($log_file, $log_message, FILE_APPEND);
// }

// Funzione di logging per errori
function debug_error($message, $exception = null) {
    $log_file = __DIR__ . '/error.log';
    $timestamp = date('Y-m-d H:i:s');
    $error_message = "[$timestamp] ERROR: $message";
    
    if ($exception !== null) {
        $error_message .= "\nException: " . $exception->getMessage();
        $error_message .= "\nFile: " . $exception->getFile() . " (Line: " . $exception->getLine() . ")";
        $error_message .= "\nStack Trace: " . $exception->getTraceAsString();
    }
    
    $error_message .= "\n" . str_repeat('-', 80) . "\n";
    
    file_put_contents($log_file, $error_message, FILE_APPEND);
}

function validate_set_type($value) {
    // Gestione valori nulli o vuoti
    if ($value === null || $value === '') {
        return 'normal';
    }
    
    // Gestione valori numerici
    if (is_numeric($value)) {
        $numValue = intval($value);
        switch ($numValue) {
            case 0: return 'normal';
            case 1: return 'superset';
            case 2: return 'dropset';
            case 3: return 'circuit';
            case 4: return 'piramidale';
            default: return 'normal';
        }
    }
    
    // Valori stringa
    $strValue = trim(strtolower((string)$value));
    
    // Corrispondenze esatte per i valori ENUM consentiti
    if ($strValue === 'normal' || $strValue === 'superset' || 
        $strValue === 'dropset' || $strValue === 'circuit' || 
        $strValue === 'piramidale') {
        return $strValue;
    }
    
    // Corrispondenze parziali
    if (strpos($strValue, 'normal') === 0) return 'normal';
    if (strpos($strValue, 'super') === 0) return 'superset';
    if (strpos($strValue, 'drop') === 0) return 'dropset';
    if (strpos($strValue, 'circ') === 0) return 'circuit';
    if (strpos($strValue, 'pira') === 0) return 'piramidale';
    
    // Abbreviazioni
    if ($strValue === 'n') return 'normal';
    if ($strValue === 's') return 'superset';
    if ($strValue === 'd') return 'dropset';
    if ($strValue === 'c') return 'circuit';
    if ($strValue === 'p') return 'piramidale';
    
    // Valore predefinito
    return 'normal';
}

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        try {
            // Ottieni l'utente autenticato
            $authHeader = getAuthorizationHeader();
            $token = str_replace('Bearer ', '', $authHeader);
            $user = validateAuthToken($conn, $token);
            
            if (!$user) {
                http_response_code(401);
                echo json_encode(['error' => 'Autenticazione richiesta']);
                exit;
            }
            
            $isAdmin = hasRole($user, 'admin');
            $isTrainer = hasRole($user, 'trainer');
            $userId = $user['user_id'];
            
            if(isset($_GET['id'])) {
                $id = $_GET['id'];
                
                // Se l'utente è un trainer, verifica che abbia accesso a questa scheda
                if ($isTrainer) {
                    $checkAccess = $conn->prepare("
                        SELECT s.id 
                        FROM schede s
                        JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
                        JOIN users u ON uwa.user_id = u.id
                        WHERE s.id = ? AND u.trainer_id = ?
                    ");
                    $checkAccess->bind_param("ii", $id, $userId);
                    $checkAccess->execute();
                    
                    if ($checkAccess->get_result()->num_rows === 0) {
                        http_response_code(403);
                        echo json_encode(['error' => 'Non hai permessi per accedere a questa scheda']);
                        exit;
                    }
                } else if (!$isAdmin) {
                    // Se è un utente normale, verifica che la scheda sia assegnata a lui
                    $checkAccess = $conn->prepare("
                        SELECT s.id 
                        FROM schede s
                        JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
                        WHERE s.id = ? AND uwa.user_id = ?
                    ");
                    $checkAccess->bind_param("ii", $id, $userId);
                    $checkAccess->execute();
                    
                    if ($checkAccess->get_result()->num_rows === 0) {
                        http_response_code(403);
                        echo json_encode(['error' => 'Non hai permessi per accedere a questa scheda']);
                        exit;
                    }
                }
                
                // Usa prepared statement per sicurezza
                $stmt = $conn->prepare("SELECT * FROM schede WHERE id = ?");
                $stmt->bind_param("i", $id);
                $stmt->execute();
                $result = $stmt->get_result();
                $scheda = $result->fetch_assoc();
                
                if($scheda) {
                    // Usa prepared statement anche per gli esercizi
                    $stmt = $conn->prepare("
                        SELECT se.*, e.nome, e.descrizione, e.gruppo_muscolare, e.attrezzatura, e.immagine_url,
                            se.serie, se.ripetizioni, se.peso, se.note, se.tempo_recupero, 
                            se.set_type, se.linked_to_previous, e.is_isometric
                        FROM scheda_esercizi se
                        JOIN esercizi e ON se.esercizio_id = e.id
                        WHERE se.scheda_id = ?
                        ORDER BY se.ordine
                    ");
                    $stmt->bind_param("i", $id);
                    $stmt->execute();
                    $esercizi_result = $stmt->get_result();
                    
                    $esercizi = array();
                    while($row = $esercizi_result->fetch_assoc()) {
                        $esercizi[] = $row;
                    }
                    
                    $scheda['esercizi'] = $esercizi;
                }
                
                echo json_encode($scheda);
            } else {
                // Query di base
                $baseQuery = "
                    SELECT DISTINCT s.* 
                    FROM schede s
                ";
                
                // Filtro per schede attive/inattive
                if (isset($_GET['show_inactive']) && $_GET['show_inactive'] === '0') {
                    // Se show_inactive è 0, mostra solo schede attive
                    $whereClause = " WHERE s.active = 1 ";
                } else if (isset($_GET['show_inactive']) && $_GET['show_inactive'] === '1') {
                    // Se show_inactive è 1, mostra tutte le schede
                    $whereClause = " ";
                } else {
                    // Comportamento predefinito: mostra solo schede attive
                    $whereClause = " WHERE s.active = 1 ";
                }
                
                if ($isAdmin) {
                    // Admin vede tutte le schede
                    $query = $baseQuery . $whereClause . " ORDER BY s.data_creazione DESC";
                    $stmt = $conn->prepare($query);
                } else if ($isTrainer) {
                    // Trainer vede solo le schede dei suoi utenti
                    $query = $baseQuery . $whereClause . (empty($whereClause) ? " WHERE " : " AND ") . "
                        JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
                        JOIN users u ON uwa.user_id = u.id
                        WHERE u.trainer_id = ?
                        ORDER BY s.data_creazione DESC
                    ";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("i", $userId);
                } else {
                    // Utente normale vede solo le schede assegnate a lui
                    $query = $baseQuery . $whereClause . (empty($whereClause) ? " WHERE " : " AND ") . "
                        JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
                        WHERE uwa.user_id = ?
                        ORDER BY s.data_creazione DESC
                    ";
                    $stmt = $conn->prepare($query);
                    $stmt->bind_param("i", $userId);
                }
                
                $stmt->execute();
                $result = $stmt->get_result();
                
                if (!$result) {
                    throw new Exception("Errore nella query: " . $conn->error);
                }
                
                $schede = array();
                while($scheda = $result->fetch_assoc()) {
                    $scheda_id = $scheda['id'];
                    
                    // Ottiene gli esercizi per ogni scheda
                    $esercizi_result = $conn->prepare("
                        SELECT se.*, e.nome, e.descrizione, e.gruppo_muscolare, e.attrezzatura,
                               se.serie, se.ripetizioni, se.peso, se.note, se.tempo_recupero,
                               se.set_type, se.linked_to_previous, e.is_isometric
                        FROM scheda_esercizi se
                        JOIN esercizi e ON se.esercizio_id = e.id
                        WHERE se.scheda_id = ?
                        ORDER BY se.ordine
                    ");
                    
                    $esercizi_result->bind_param("i", $scheda_id);
                    $esercizi_result->execute();
                    $esercizi_data = $esercizi_result->get_result();
                    
                    if (!$esercizi_data) {
                        throw new Exception("Errore nella query esercizi: " . $conn->error);
                    }
                    
                    $esercizi = array();
                    while($esercizio = $esercizi_data->fetch_assoc()) {
                        $esercizi[] = $esercizio;
                    }
                    
                    $scheda['esercizi'] = $esercizi;
                    $schede[] = $scheda;
                }
                
                echo json_encode($schede);
            }
        } catch (Exception $e) {
            //debugLog("Errore in GET", ["message" => $e->getMessage()]);
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

        case 'POST':
            try {
                $input = file_get_contents("php://input");
                //debugLog("Dati ricevuti in POST schede", ["input" => $input]);
        
                $data = json_decode($input, true);
        
                if(!$data) {
                    throw new Exception("Dati non validi: " . json_last_error_msg());
                }
        
                $conn->begin_transaction();
                $active = isset($data['active']) ? intval($data['active']) : 1;
        
                $stmt = $conn->prepare("INSERT INTO schede (nome, descrizione, data_creazione, active) VALUES (?, ?, NOW(), ?)");
                $stmt->bind_param("ssi", $data['nome'], $data['descrizione'], $active);
        
                if(!$stmt->execute()) {
                    throw new Exception("Errore nell'inserimento della scheda: " . $stmt->error);
                }
        
                $scheda_id = $stmt->insert_id;
                //debugLog("Creata nuova scheda", ["id" => $scheda_id, "nome" => $data['nome'], "active" => $active]);
        
                if(isset($data['esercizi']) && is_array($data['esercizi'])) {
                    foreach($data['esercizi'] as $index => $esercizio) {
                        if(empty($esercizio['esercizio_id'])) {
                            throw new Exception("ID esercizio mancante per l'elemento in posizione " . $index);
                        }
        
                        /*debugLog("Elaborazione esercizio", [
                            "index" => $index,
                            "esercizio_raw" => $esercizio
                        ]);*/
        
                        $set_type_raw = isset($esercizio['set_type']) ? $esercizio['set_type'] : 'normal';
                        $set_type = validate_set_type($set_type_raw);
                        //debugLog("Validazione set_type", ["input" => $set_type_raw, "output" => $set_type]);
        
                        $tempo_recupero = isset($esercizio['tempo_recupero']) ? $esercizio['tempo_recupero'] : 90;
                        $note = isset($esercizio['note']) ? $esercizio['note'] : '';
                        $serie = isset($esercizio['serie']) ? intval($esercizio['serie']) : 3;
                        $ripetizioni = isset($esercizio['ripetizioni']) ? intval($esercizio['ripetizioni']) : 10;
                        $peso = isset($esercizio['peso']) ? floatval($esercizio['peso']) : 0;
                        $linked_to_previous = isset($esercizio['linked_to_previous']) 
                            ? (int)filter_var($esercizio['linked_to_previous'], FILTER_VALIDATE_BOOLEAN) 
                            : 0;
                        $ordine = $index;
        
                        $stmt = $conn->prepare("INSERT INTO scheda_esercizi 
                            (scheda_id, esercizio_id, serie, ripetizioni, peso, note, tempo_recupero, set_type, linked_to_previous, ordine) 
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                            
                        if (!in_array($set_type, ['normal', 'superset', 'dropset', 'circuit', 'piramidale'])) {
                            $set_type = 'normal';
                        }
        
                        $esercizio_id_int = intval($esercizio['esercizio_id']);
        
                        $stmt->bind_param(
                            "iiidssssii",
                            $scheda_id,
                            $esercizio_id_int,
                            $serie,
                            $ripetizioni,
                            $peso,
                            $note,
                            $tempo_recupero,
                            $set_type,
                            $linked_to_previous,
                            $ordine
                        );
                        
                        if(!$stmt->execute()) {
                            throw new Exception("Errore nell'inserimento dell'esercizio: " . $stmt->error);
                        }
                        
                        //debugLog("Esercizio inserito con successo", ["index" => $index]);
                    }
                }
                
                $conn->commit();
                
                // Recupera la scheda creata per restituirla
                $stmt = $conn->prepare("SELECT * FROM schede WHERE id = ?");
                $stmt->bind_param("i", $scheda_id);
                $stmt->execute();
                $scheda = $stmt->get_result()->fetch_assoc();
                
                // Recupera gli esercizi
                $stmt = $conn->prepare("
                    SELECT se.*, e.nome, e.descrizione, e.gruppo_muscolare, e.attrezzatura,
                           se.serie, se.ripetizioni, se.peso, se.note, se.tempo_recupero, 
                           se.set_type, se.linked_to_previous
                    FROM scheda_esercizi se
                    JOIN esercizi e ON se.esercizio_id = e.id
                    WHERE se.scheda_id = ?
                    ORDER BY se.ordine
                ");
                $stmt->bind_param("i", $scheda_id);
                $stmt->execute();
                $result = $stmt->get_result();
                
                $esercizi = array();
                while($row = $result->fetch_assoc()) {
                    $esercizi[] = $row;
                }
                
                $scheda['esercizi'] = $esercizi;
                
                /*debugLog("Risposta POST schede completata", [
                    "scheda_id" => $scheda['id'], 
                    "num_esercizi" => count($esercizi)
                ]);*/
                
                echo json_encode($scheda);
                
            } catch(Exception $e) {
                $conn->rollback();
                /*debugLog("Errore completo in POST schede", [
                    "message" => $e->getMessage(),
                    "trace" => $e->getTraceAsString()
                ]);*/
                
                http_response_code(500);
                echo json_encode(["error" => $e->getMessage()]);
            }
            break;


            
    
        
    case 'PUT':
        try {
            $input = file_get_contents("php://input");
            //debugLog("Dati ricevuti in PUT", ["input" => $input]);
            
            $data = json_decode($input, true);
            if(!$data) {
                throw new Exception("Dati non validi: " . json_last_error_msg());
            }
            
            if (!isset($_GET['id'])) {
                throw new Exception("ID mancante");
            }
            
            $scheda_id = (int)$_GET['id'];
            //debugLog("Aggiornamento scheda", ["id" => $scheda_id, "nome" => $data['nome']]);
            
            // Inizia la transazione
            $conn->begin_transaction();
            
            try {
                // IMPORTANTE: Verifica che la scheda esista
                $stmt = $conn->prepare("SELECT id FROM schede WHERE id = ?");
                $stmt->bind_param("i", $scheda_id);
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows === 0) {
                    throw new Exception("Scheda con ID $scheda_id non trovata");
                }
                
                //debugLog("Scheda trovata, procedo con l'aggiornamento", ["id" => $scheda_id]);
                
                // Aggiorna i dati base della scheda, incluso lo stato active
                $active = isset($data['active']) ? intval($data['active']) : 1;
                $stmt = $conn->prepare("UPDATE schede SET nome = ?, descrizione = ?, active = ? WHERE id = ?");
                $stmt->bind_param("ssii", $data['nome'], $data['descrizione'], $active, $scheda_id);
                
                if (!$stmt->execute()) {
                    throw new Exception("Errore nell'aggiornamento della scheda: " . $stmt->error);
                }
                
                //debugLog("Aggiornamento dati base completato", ["affected_rows" => $stmt->affected_rows, "active" => $active]);
                
                // Dopo aver aggiornato i dati base della scheda
                if ($stmt->affected_rows === 0) {
                    //debugLog("Attenzione: nessuna riga aggiornata", ["scheda_id" => $scheda_id]);
                    // Verifica se l'ID esiste ancora
                    $verify = $conn->prepare("SELECT id FROM schede WHERE id = ?");
                    $verify->bind_param("i", $scheda_id);
                    $verify->execute();
                    $exists = $verify->get_result()->num_rows > 0;
                    
                    if (!$exists) {
                        throw new Exception("La scheda con ID $scheda_id non esiste più dopo l'aggiornamento");
                    }
                }
                
                // Ottieni gli esercizi correnti per confronto
                $currentExercisesQuery = $conn->prepare("SELECT id, esercizio_id FROM scheda_esercizi WHERE scheda_id = ?");
                $currentExercisesQuery->bind_param("i", $scheda_id);
                $currentExercisesQuery->execute();
                $currentResult = $currentExercisesQuery->get_result();
        
                $currentExercises = [];
                while($row = $currentResult->fetch_assoc()) {
                    $currentExercises[$row['id']] = $row;
                }
        
                //debugLog("Esercizi attuali nella scheda", ["count" => count($currentExercises)]);
        
                // Array per tenere traccia degli ID esercizi che arrivano nella richiesta
                $requestedExerciseIds = [];
        
                // Elabora gli esercizi inviati
                if (isset($data['esercizi']) && is_array($data['esercizi'])) {
                    //debugLog("Elaborazione esercizi ricevuti", ["count" => count($data['esercizi'])]);
                    
                    foreach($data['esercizi'] as $index => $esercizio) {
                        // Aggiungi log dettagliati
                        /*debugLog("Elaborazione esercizio", [
                            "index" => $index, 
                            "esercizio_raw" => $esercizio
                        ]);*/
        
                        // Validazione più rigorosa
                        if (!isset($esercizio['esercizio_id']) || empty($esercizio['esercizio_id'])) {
                            //debugLog("Errore: ID esercizio mancante", ["esercizio" => $esercizio]);
                            throw new Exception("ID esercizio mancante per l'elemento in posizione " . $index);
                        }
                        
                        // Valori predefiniti con conversione esplicita
                        $tempo_recupero = isset($esercizio['tempo_recupero']) ? $esercizio['tempo_recupero'] : 90;
                        $note = isset($esercizio['note']) ? $esercizio['note'] : '';
                        $serie = isset($esercizio['serie']) ? intval($esercizio['serie']) : 3;
                        $ripetizioni = isset($esercizio['ripetizioni']) ? intval($esercizio['ripetizioni']) : 10;
                        $peso = isset($esercizio['peso']) ? floatval($esercizio['peso']) : 0.0;
                        
                        // Gestione del set_type
                        $set_type_raw = $esercizio['set_type'] ?? 'normal';
                        $set_type = validate_set_type($set_type_raw);
                        //debugLog("Validazione set_type", ["input" => $set_type_raw, "output" => $set_type]);
                        
                        $linked_to_previous = isset($esercizio['linked_to_previous']) ? (int)!!$esercizio['linked_to_previous'] : 0;
                        
                        // Debug dei valori processati
                        /*debugLog("Valori processati per esercizio", [
                            "tempo_recupero" => $tempo_recupero,
                            "note" => $note,
                            "serie" => $serie,
                            "ripetizioni" => $ripetizioni,
                            "peso" => $peso,
                            "set_type" => $set_type,
                            "linked_to_previous" => $linked_to_previous
                        ]);*/
                        
                        // Verifica se l'esercizio ha un ID esistente (modifica) o è nuovo (inserimento)
                        $isExistingExercise = isset($esercizio['id']) && !empty($esercizio['id']);
                        
                        if ($isExistingExercise) {
                            // Verificare che l'ID appartenga effettivamente a questa scheda
                            $verifyQuery = $conn->prepare("SELECT id FROM scheda_esercizi WHERE id = ? AND scheda_id = ?");
                            $verifyQuery->bind_param("ii", $esercizio['id'], $scheda_id);
                            $verifyQuery->execute();
                            $verifyResult = $verifyQuery->get_result();
                            
                            if ($verifyResult->num_rows > 0) {
                                // Aggiungi l'ID alla lista degli esercizi elaborati
                                $requestedExerciseIds[] = $esercizio['id'];
        
                                // Prepara la query di aggiornamento con controllo rigoroso dei tipi
                                $updateQuery = $conn->prepare("
                                    UPDATE scheda_esercizi 
                                    SET esercizio_id = ?, serie = ?, ripetizioni = ?, peso = ?, 
                                        note = ?, tempo_recupero = ?, set_type = ?, linked_to_previous = ?, ordine = ?
                                    WHERE id = ?
                                ");
                                
                                // Debug della preparazione della query
                                if (!$updateQuery) {
                                    /*debugLog("Errore nella preparazione della query di update", [
                                        "error" => $conn->error,
                                        "esercizio" => $esercizio
                                    ]);*/
                                    throw new Exception("Errore nella preparazione della query di aggiornamento: " . $conn->error);
                                }
                                
                                // Conversione esplicita dei tipi
                                $esercizio_id_int = (int)$esercizio['esercizio_id'];
                                $serie_int = (int)$serie;
                                $ripetizioni_int = (int)$ripetizioni;
                                $peso_double = (float)$peso;
                                $linked_to_previous_int = (int)$linked_to_previous;
                                $index_int = (int)$index;
                                $esercizio_id_to_update = (int)$esercizio['id'];
                                
                                // Debug prima del binding
                                /*debugLog("Binding parametri per aggiornamento esercizio", [
                                    "esercizio_id" => $esercizio_id_int,
                                    "serie" => $serie_int,
                                    "ripetizioni" => $ripetizioni_int,
                                    "peso" => $peso_double,
                                    "note" => $note,
                                    "tempo_recupero" => $tempo_recupero,
                                    "set_type" => $set_type,
                                    "linked_to_previous" => $linked_to_previous_int,
                                    "index" => $index_int,
                                    "id" => $esercizio_id_to_update
                                ]);*/
                                
                                $set_type_raw = isset($esercizio['set_type']) ? $esercizio['set_type'] : 'normal';
                                    $set_type = validate_set_type($set_type_raw);

                                    // Log di debug
                                    /*debugLog("Set type per binding", [
                                        "set_type_originale" => $set_type_raw,
                                        "set_type_validato" => $set_type,
                                        "tipo" => gettype($set_type),
                                        "lunghezza" => strlen($set_type)
                                    ]);*/

                                    // Verifica che il valore sia uno dei valori ENUM consentiti
                                    $allowed_values = ['normal', 'superset', 'dropset', 'circuit', 'piramidale'];
                                    if (!in_array($set_type, $allowed_values)) {
                                        $set_type = 'normal'; // Fallback sicuro
                                    }

                                $updateQuery->bind_param(
                                    "iiidsssiii", 
                                    $esercizio_id_int, 
                                    $serie_int, 
                                    $ripetizioni_int, 
                                    $peso_double, 
                                    $note, 
                                    $tempo_recupero, 
                                    $set_type, // Usa il valore ENUM completo
                                    $linked_to_previous_int, 
                                    $index_int, 
                                    $esercizio_id_to_update
                                );
                                
                                // Esegui e controlla l'esito dell'aggiornamento
                                if (!$updateQuery->execute()) {
                                    /*debugLog("Errore nell'aggiornamento dell'esercizio", [
                                        "error" => $updateQuery->error,
                                        "esercizio" => $esercizio
                                    ]);*/
                                    throw new Exception("Errore nell'aggiornamento dell'esercizio: " . $updateQuery->error);
                                }
                                
                                /*debugLog("Esercizio aggiornato con successo", [
                                    "id" => $esercizio['id'], 
                                    "affected_rows" => $updateQuery->affected_rows
                                ]);*/
                            }
                        } else {
                            // Inserimento nuovo esercizio
                           /* //debugLog("Tentativo inserimento nuovo esercizio", [
                                "esercizio_id" => $esercizio['esercizio_id'],
                                "serie" => $serie,
                                "ripetizioni" => $ripetizioni,
                                "peso" => $peso,
                                "set_type" => $set_type
                            ]);*/
                                                        
                            $insertQuery = $conn->prepare("
                                INSERT INTO scheda_esercizi 
                                (scheda_id, esercizio_id, serie, ripetizioni, peso, note, tempo_recupero, set_type, linked_to_previous, ordine) 
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            ");
                            
                            if (!$insertQuery) {
                                throw new Exception("Errore nella preparazione della query di inserimento: " . $conn->error);
                            }
                            
                            // Conversione esplicita dei tipi
                            $scheda_id_int = (int)$scheda_id;
                            $esercizio_id_int = (int)$esercizio['esercizio_id'];
                            $serie_int = (int)$serie;
                            $ripetizioni_int = (int)$ripetizioni;
                            $peso_double = (float)$peso;
                            $linked_to_previous_int = (int)$linked_to_previous;
                            $index_int = (int)$index;
                            
                            // Forziamo le stringhe
                            $note_str = (string)$note;
                            $tempo_recupero_str = (string)$tempo_recupero;
                            
                            // Debug prima del binding
                            /*debugLog("Binding parametri per nuovo esercizio", [
                                "scheda_id" => $scheda_id_int,
                                "esercizio_id" => $esercizio_id_int,
                                "serie" => $serie_int,
                                "ripetizioni" => $ripetizioni_int,
                                "peso" => $peso_double,
                                "note" => $note_str,
                                "tempo_recupero" => $tempo_recupero_str,
                                "set_type" => $set_type,
                                "linked_to_previous" => $linked_to_previous_int,
                                "index" => $index_int
                            ]);*/
                            
                            $set_type_str = (string)$set_type;

                            $set_type_raw = isset($esercizio['set_type']) ? $esercizio['set_type'] : 'normal';
                            $set_type = validate_set_type($set_type_raw);
                            
                            // Log di debug
                            /*debugLog("Set type per binding", [
                                "set_type_originale" => $set_type_raw,
                                "set_type_validato" => $set_type,
                                "tipo" => gettype($set_type),
                                "lunghezza" => strlen($set_type)
                            ]);*/
                            
                            // Verifica che il valore sia uno dei valori ENUM consentiti
                            $allowed_values = ['normal', 'superset', 'dropset', 'circuit', 'piramidale'];
                            if (!in_array($set_type, $allowed_values)) {
                                $set_type = 'normal'; // Fallback sicuro
                            }
                            
                            $insertQuery->bind_param(
                                "iiidssssii",
                                $scheda_id_int,
                                $esercizio_id_int,
                                $serie_int,
                                $ripetizioni_int,
                                $peso_double,
                                $note_str,
                                $tempo_recupero_str,
                                $set_type, // Usa il valore ENUM completo
                                $linked_to_previous_int,
                                $index_int
                            );
                                                            
                            try {
                                if (!$insertQuery->execute()) {
                                    throw new Exception("Errore nell'inserimento dell'esercizio: " . $insertQuery->error);
                                }
                                
                                // Aggiungi l'ID del nuovo esercizio alla lista di quelli elaborati
                                $requestedExerciseIds[] = $insertQuery->insert_id;
                                //debugLog("Nuovo esercizio inserito", ["id" => $insertQuery->insert_id]);
                            } catch (Exception $insertError) {
                                debug_error("Errore durante l'inserimento dell'esercizio", $insertError);
                                throw $insertError;
                            }
                        }
                    }
                }
        
                // Elimina gli esercizi che non sono stati inclusi nella richiesta (quelli rimossi)
                if (!empty($currentExercises) && !empty($requestedExerciseIds)) {
                    $exercisesToDelete = array_diff(array_keys($currentExercises), $requestedExerciseIds);
                    
                    if (!empty($exercisesToDelete)) {
                        //debugLog("Esercizi da eliminare", ["count" => count($exercisesToDelete), "ids" => $exercisesToDelete]);
                        
                        // Elimina eventuali serie completate associate
                        $inClause = implode(',', array_map('intval', $exercisesToDelete));
                        $conn->query("DELETE FROM serie_completate WHERE scheda_esercizio_id IN ($inClause)");
                        
                        // Ora elimina gli esercizi
                        $conn->query("DELETE FROM scheda_esercizi WHERE id IN ($inClause)");
                        
                        //debugLog("Esercizi eliminati", ["count" => count($exercisesToDelete)]);
                    }
                }
                
            } catch (Exception $innerException) {
                debug_error("Errore durante l'elaborazione", $innerException);
                throw $innerException;
            }
            
            // Commit della transazione
            $conn->commit();
            //debugLog("Transazione completata con successo", ["scheda_id" => $scheda_id]);
            
            // Recupera la scheda aggiornata per restituirla
            $stmt = $conn->prepare("SELECT * FROM schede WHERE id = ?");
            $stmt->bind_param("i", $scheda_id);
            $stmt->execute();
            $scheda = $stmt->get_result()->fetch_assoc();
            
            // Recupera gli esercizi aggiornati
            $stmt = $conn->prepare("
                SELECT se.*, e.nome, e.descrizione, e.gruppo_muscolare, e.attrezzatura,
                       se.set_type, se.linked_to_previous
                FROM scheda_esercizi se
                JOIN esercizi e ON se.esercizio_id = e.id
                WHERE se.scheda_id = ?
                ORDER BY se.ordine
            ");
            $stmt->bind_param("i", $scheda_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $esercizi = array();
            while($row = $result->fetch_assoc()) {
                $esercizi[] = $row;
            }
            
            $scheda['esercizi'] = $esercizi;
            
            //debugLog("Risposta PUT", ["scheda_id" => $scheda['id'], "num_esercizi" => count($esercizi)]);
            echo json_encode($scheda);
            
        } catch (Exception $e) {
            $conn->rollback();
            debug_error("Errore completo in PUT", $e);
            http_response_code(500);
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;
    
    case 'DELETE':
        try {
            // Ottieni l'utente autenticato
            $authHeader = getAuthorizationHeader();
            $token = str_replace('Bearer ', '', $authHeader);
            $user = validateAuthToken($conn, $token);
            
            if (!$user) {
                http_response_code(401);
                echo json_encode(['error' => 'Autenticazione richiesta']);
                exit;
            }
            
            $isAdmin = hasRole($user, 'admin');
            $isTrainer = hasRole($user, 'trainer');
            $userId = $user['user_id'];
            
            if(!isset($_GET['id'])) {
                throw new Exception("ID mancante");
            }
            
            $id = $_GET['id'];
            //debugLog("Richiesta eliminazione scheda", ["id" => $id]);
            
            // Verifica dei permessi
            if ($isTrainer) {
                // Verifica che il trainer abbia accesso a questa scheda
                $checkAccess = $conn->prepare("
                    SELECT s.id 
                    FROM schede s
                    JOIN user_workout_assignments uwa ON s.id = uwa.scheda_id
                    JOIN users u ON uwa.user_id = u.id
                    WHERE s.id = ? AND u.trainer_id = ?
                ");
                $checkAccess->bind_param("ii", $id, $userId);
                $checkAccess->execute();
                
                if ($checkAccess->get_result()->num_rows === 0) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Non hai permessi per eliminare questa scheda']);
                    exit;
                }
            } else if (!$isAdmin) {
                // Gli utenti normali non possono eliminare schede
                http_response_code(403);
                echo json_encode(['error' => 'Non hai permessi per eliminare schede']);
                exit;
            }
            
            // Inizia la transazione
            $conn->begin_transaction();
            
            // Verifica se ci sono serie completate legate a questa scheda
            $stmt = $conn->prepare("
                SELECT COUNT(*) as count 
                FROM serie_completate sc
                JOIN scheda_esercizi se ON sc.scheda_esercizio_id = se.id
                WHERE se.scheda_id = ?
            ");
            
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $result = $stmt->get_result();
            $completedSeries = $result->fetch_assoc()['count'];
            
            if ($completedSeries > 0) {
                // Se ci sono serie completate, non possiamo eliminare la scheda
                //debugLog("Scheda con serie completate, non può essere eliminata", ["id" => $id, "series" => $completedSeries]);
                
                // Informiamo l'utente dell'impossibilità di eliminare la scheda
                http_response_code(400);
                echo json_encode([
                    'error' => 'Impossibile eliminare la scheda: contiene esercizi con serie completate',
                    'series_count' => $completedSeries
                ]);
                $conn->rollback();
                return;
            }
            
            // Controlla se ci sono riferimenti alle assegnazioni utente
            $stmt = $conn->prepare("SELECT COUNT(*) as count FROM user_workout_assignments WHERE scheda_id = ?");
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $result = $stmt->get_result()->fetch_assoc();
            
            if ($result['count'] > 0) {
                //debugLog("Eliminazione assegnazioni utente", ["count" => $result['count']]);
                // Elimina prima le assegnazioni utente
                $stmt = $conn->prepare("DELETE FROM user_workout_assignments WHERE scheda_id = ?");
                $stmt->bind_param("i", $id);
                
                if(!$stmt->execute()) {
                    throw new Exception("Errore nell'eliminazione delle assegnazioni utente");
                }
            }
            
            // Controlla se ci sono allenamenti collegati a questa scheda
            $stmt = $conn->prepare("SELECT COUNT(*) as count FROM allenamenti WHERE scheda_id = ?");
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $result = $stmt->get_result()->fetch_assoc();
            
            if ($result['count'] > 0) {
                //debugLog("Eliminazione allenamenti collegati", ["count" => $result['count']]);
                // Elimina prima gli allenamenti collegati
                $stmt = $conn->prepare("
                    DELETE FROM serie_completate 
                    WHERE allenamento_id IN (SELECT id FROM allenamenti WHERE scheda_id = ?)
                ");
                $stmt->bind_param("i", $id);
                
                if(!$stmt->execute()) {
                    throw new Exception("Errore nell'eliminazione delle serie completate");
                }
                
                $stmt = $conn->prepare("DELETE FROM allenamenti WHERE scheda_id = ?");
                $stmt->bind_param("i", $id);
                
                if(!$stmt->execute()) {
                    throw new Exception("Errore nell'eliminazione degli allenamenti");
                }
            }
            
            // Elimina gli esercizi della scheda
            $stmt = $conn->prepare("DELETE FROM scheda_esercizi WHERE scheda_id = ?");
            $stmt->bind_param("i", $id);
            
            if(!$stmt->execute()) {
                throw new Exception("Errore nell'eliminazione degli esercizi");
            }
            
            //debugLog("Esercizi eliminati", ["scheda_id" => $id]);
            
            // Infine elimina la scheda
            $stmt = $conn->prepare("DELETE FROM schede WHERE id = ?");
            $stmt->bind_param("i", $id);
            
            if(!$stmt->execute()) {
                throw new Exception("Errore nell'eliminazione della scheda");
            }
            
            //debugLog("Scheda eliminata", ["id" => $id]);
            
            // Commit della transazione
            $conn->commit();
            echo json_encode(["message" => "Scheda eliminata"]);
            
        } catch(Exception $e) {
            $conn->rollback();
            debug_error("Errore in DELETE", $e);
            http_response_code(500);
            echo json_encode(["error" => $e->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["message" => "Metodo non consentito"]);
}

$conn->close();
?>