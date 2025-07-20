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

header('Content-Type: application/json');

// Funzione di debug per tracciare errori
function debug_log($message, $data = null) {
    error_log("DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("DATA: " . print_r($data, true));
    }
}

// NUOVA FUNZIONE: Garantisce che set_type sia sempre una stringa valida
function sanitize_set_type($value) {
    // Prima convertiamo esplicitamente a stringa
    $str_value = (string)$value;
    
    // Lista di valori validi
    $valid_types = ['normal', 'superset', 'dropset', 'rest_pause', 'giant_set', 'circuit'];
    
    // Se il valore è numerico, vuoto o non nella lista valida, usiamo 'normal'
    if (is_numeric($str_value) || empty($str_value) || !in_array($str_value, $valid_types)) {
        debug_log("⚠️ Valore set_type non valido ($str_value), impostato a 'normal'");
        return 'normal';
    }
    
    debug_log("✅ Valore set_type valido: $str_value");
    return $str_value;
}

$method = $_SERVER['REQUEST_METHOD'];

debug_log("Richiesta ricevuta: $method");

switch ($method) {
    case 'GET':
        if (isset($_GET['scheda_id'])) {
            // Recupera esercizi di una scheda (AGGIORNATO con campi REST-PAUSE)
            $scheda_id = intval($_GET['scheda_id']);
            debug_log("GET: Recupero esercizi per scheda_id=$scheda_id");
            
            $query = "
                SELECT se.id as scheda_esercizio_id, se.esercizio_id as id, e.nome, e.gruppo_muscolare, e.attrezzatura, e.descrizione, 
                    e.is_isometric, e.immagine_nome, se.serie, se.ripetizioni, se.peso, se.ordine, se.tempo_recupero, 
                    se.note, se.set_type, se.linked_to_previous, se.is_rest_pause, se.rest_pause_reps, se.rest_pause_rest_seconds
                FROM scheda_esercizi se
                INNER JOIN esercizi e ON e.id = se.esercizio_id
                WHERE se.scheda_id = ?
                ORDER BY se.ordine ASC
            ";
            $stmt = $conn->prepare($query);
            $stmt->bind_param('i', $scheda_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $esercizi = [];

            while ($row = $result->fetch_assoc()) {
                // CORREZIONE: Applica sanitize_set_type per garantire una stringa valida
                $row['set_type'] = sanitize_set_type($row['set_type']);
                
                // Assicuriamoci che linked_to_previous sia un valore booleano o intero
                $row['linked_to_previous'] = intval($row['linked_to_previous']);
                
                // CONVERSIONI REST-PAUSE per compatibilità
                $row['is_rest_pause'] = intval($row['is_rest_pause']);
                $row['rest_pause_rest_seconds'] = intval($row['rest_pause_rest_seconds']);
                
                $esercizi[] = $row;
            }

            debug_log("Esercizi recuperati:", count($esercizi));
            echo json_encode(['success' => true, 'esercizi' => $esercizi]);
            exit;
        }

        if (!isset($_GET['user_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing user_id']);
            exit;
        }

        $user_id = intval($_GET['user_id']);
        debug_log("GET: Recupero schede per user_id=$user_id");
        
        $query = "
            SELECT s.id, s.nome, s.descrizione, s.data_creazione
            FROM schede s
            INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
            WHERE uwa.user_id = ? AND uwa.active = 1
        ";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('i', $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $schede = [];

        while ($row = $result->fetch_assoc()) {
            $schede[] = $row;
        }

        debug_log("Schede recuperate:", count($schede));
        echo json_encode(['success' => true, 'schede' => $schede]);
        break;

    case 'POST':
        // Gestione eliminazione scheda
        if (isset($_POST['action']) && $_POST['action'] === 'delete' && isset($_POST['scheda_id'])) {
            $scheda_id = intval($_POST['scheda_id']);
            debug_log("POST: Eliminazione scheda_id=$scheda_id");
            debug_log("POST data ricevuta:", $_POST);

            // Verifica connessione database
            if (!$conn) {
                debug_log("❌ ERRORE: Connessione database non disponibile");
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Errore connessione database']);
                exit;
            }

            // Inizia transazione per garantire integrità
            $conn->begin_transaction();
            
            try {
                // Verifica che la scheda esista
                debug_log("Verifica esistenza scheda");
                $check_stmt = $conn->prepare("SELECT id FROM schede WHERE id = ?");
                if (!$check_stmt) {
                    debug_log("❌ ERRORE PREPARE check: " . $conn->error);
                    throw new Exception("Errore nella verifica scheda: " . $conn->error);
                }
                $check_stmt->bind_param('i', $scheda_id);
                $check_stmt->execute();
                $check_result = $check_stmt->get_result();
                
                if ($check_result->num_rows === 0) {
                    debug_log("❌ ERRORE: Scheda $scheda_id non trovata");
                    throw new Exception("Scheda non trovata");
                }
                debug_log("✅ Scheda $scheda_id trovata, procedo con l'eliminazione");
                $check_stmt->close();
                // 1. Elimina tutti gli esercizi della scheda
                debug_log("Eliminazione esercizi della scheda");
                $stmt = $conn->prepare("DELETE FROM scheda_esercizi WHERE scheda_id = ?");
                if (!$stmt) {
                    debug_log("❌ ERRORE PREPARE: " . $conn->error);
                    throw new Exception("Errore nella preparazione query esercizi: " . $conn->error);
                }
                $stmt->bind_param('i', $scheda_id);
                $result = $stmt->execute();
                if (!$result) {
                    debug_log("❌ ERRORE EXECUTE esercizi: " . $stmt->error);
                    throw new Exception("Errore nell'eliminazione esercizi: " . $stmt->error);
                }
                $affected_rows = $stmt->affected_rows;
                debug_log("✅ Eliminati $affected_rows esercizi dalla scheda");
                $stmt->close();
                
                // 2. Elimina tutti gli assignment della scheda
                debug_log("Eliminazione assignment della scheda");
                $stmt = $conn->prepare("DELETE FROM user_workout_assignments WHERE scheda_id = ?");
                if (!$stmt) {
                    debug_log("❌ ERRORE PREPARE assignment: " . $conn->error);
                    throw new Exception("Errore nella preparazione query assignment: " . $conn->error);
                }
                $stmt->bind_param('i', $scheda_id);
                $result = $stmt->execute();
                if (!$result) {
                    debug_log("❌ ERRORE EXECUTE assignment: " . $stmt->error);
                    throw new Exception("Errore nell'eliminazione assignment: " . $stmt->error);
                }
                $affected_rows = $stmt->affected_rows;
                debug_log("✅ Eliminati $affected_rows assignment dalla scheda");
                $stmt->close();
                
                // 3. Elimina la scheda
                debug_log("Eliminazione scheda principale");
                $stmt = $conn->prepare("DELETE FROM schede WHERE id = ?");
                if (!$stmt) {
                    debug_log("❌ ERRORE PREPARE scheda: " . $conn->error);
                    throw new Exception("Errore nella preparazione query scheda: " . $conn->error);
                }
                $stmt->bind_param('i', $scheda_id);
                $result = $stmt->execute();
                if (!$result) {
                    debug_log("❌ ERRORE EXECUTE scheda: " . $stmt->error);
                    throw new Exception("Errore nell'eliminazione scheda: " . $stmt->error);
                }
                $affected_rows = $stmt->affected_rows;
                debug_log("✅ Eliminata scheda (affected rows: $affected_rows)");
                $stmt->close();
                
                // Commit della transazione
                $conn->commit();
                debug_log("✅ Scheda eliminata con successo");
                
                echo json_encode(['success' => true, 'message' => 'Scheda eliminata con successo.']);
                
            } catch (Exception $e) {
                // Rollback in caso di errore
                $conn->rollback();
                debug_log("❌ ERRORE eliminazione: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['success' => false, 'message' => 'Errore durante l\'eliminazione: ' . $e->getMessage()]);
            }
            
            exit;
        }
        // (Gestione creazione scheda nuova, già implementata in create_scheda_standalone.php)
        break;

    case 'PUT':
        debug_log("PUT: Aggiornamento scheda");
        
        $input_data = file_get_contents("php://input");
        debug_log("PUT data raw ricevuta:", $input_data);
        
        // Decodifichiamo JSON 
        $input = json_decode($input_data, true);
        
        // In caso di errore JSON
        if (json_last_error() !== JSON_ERROR_NONE) {
            debug_log("❌ ERRORE JSON: " . json_last_error_msg());
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'JSON non valido: ' . json_last_error_msg()]);
            exit;
        }
        
        debug_log("PUT data decodificata:", $input);

        if (!isset($input['scheda_id'], $input['nome'], $input['descrizione'], $input['esercizi'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Dati mancanti per aggiornamento.']);
            exit;
        }

        $scheda_id = intval($input['scheda_id']);
        $nome = trim($input['nome']);
        $descrizione = trim($input['descrizione']);
        $esercizi = $input['esercizi']; 

        debug_log("Esercizi ricevuti:", $esercizi);

        $conn->begin_transaction();
        try {
            // Aggiorna scheda
            $stmt = $conn->prepare("UPDATE schede SET nome = ?, descrizione = ? WHERE id = ?");
            $stmt->bind_param('ssi', $nome, $descrizione, $scheda_id);
            $stmt->execute();
            $stmt->close();
            debug_log("Scheda base aggiornata");

            // Aggiorna esercizi
            foreach ($esercizi as $ex) {
                debug_log("Elaborazione esercizio:", $ex);
                
                $serie = intval($ex['serie']);
                $ripetizioni = intval($ex['ripetizioni']);
                $peso = floatval($ex['peso']);
                $esercizio_id = intval($ex['id']);
                $ordine = intval($ex['ordine']);
                
                // Campi esistenti con valori predefiniti se non presenti
                $tempo_recupero = isset($ex['tempo_recupero']) ? intval($ex['tempo_recupero']) : 90;
                $note = isset($ex['note']) ? $ex['note'] : '';
                
                // Usiamo la funzione di sanitizzazione per set_type
                $set_type = sanitize_set_type(isset($ex['set_type']) ? $ex['set_type'] : 'normal');
                
                $linked_to_previous = isset($ex['linked_to_previous']) ? intval($ex['linked_to_previous']) : 0;

                // NUOVI CAMPI REST-PAUSE con valori predefiniti
                $is_rest_pause = isset($ex['is_rest_pause']) ? intval($ex['is_rest_pause']) : 0;
                $rest_pause_reps = isset($ex['rest_pause_reps']) && !empty($ex['rest_pause_reps']) ? $ex['rest_pause_reps'] : null;
                $rest_pause_rest_seconds = isset($ex['rest_pause_rest_seconds']) ? intval($ex['rest_pause_rest_seconds']) : 15;

                debug_log("⭐ VALORI FINALI:", [
                    'serie' => $serie, 
                    'ripetizioni' => $ripetizioni,
                    'peso' => $peso,
                    'ordine' => $ordine,
                    'tempo_recupero' => $tempo_recupero,
                    'note' => $note,
                    'set_type' => $set_type . ' (' . gettype($set_type) . ')',
                    'linked_to_previous' => $linked_to_previous,
                    'is_rest_pause' => $is_rest_pause,
                    'rest_pause_reps' => $rest_pause_reps,
                    'rest_pause_rest_seconds' => $rest_pause_rest_seconds
                ]);

                $check = $conn->prepare("
                    SELECT id FROM scheda_esercizi
                    WHERE scheda_id = ? AND esercizio_id = ?
                ");
                $check->bind_param('ii', $scheda_id, $esercizio_id);
                $check->execute();
                $check_result = $check->get_result();

                if ($check_result->num_rows > 0) {
                    // Update esistente - AGGIORNATO per includere campi REST-PAUSE
                    debug_log("Aggiornamento esercizio esistente");
                    $update = $conn->prepare("
                        UPDATE scheda_esercizi 
                        SET serie = ?, ripetizioni = ?, peso = ?, ordine = ?, 
                            tempo_recupero = ?, note = ?, set_type = ?, linked_to_previous = ?,
                            is_rest_pause = ?, rest_pause_reps = ?, rest_pause_rest_seconds = ?
                        WHERE scheda_id = ? AND esercizio_id = ?
                    ");
$update->bind_param('iidiissiisiii', 
    $serie, $ripetizioni, $peso, $ordine, 
    $tempo_recupero, $note, $set_type, $linked_to_previous,
    $is_rest_pause, $rest_pause_reps, $rest_pause_rest_seconds,
    $scheda_id, $esercizio_id
);
                    
                    if (!$update->execute()) {
                        debug_log("❌ ERRORE UPDATE: " . $update->error);
                        throw new Exception("Errore nell'aggiornamento: " . $update->error);
                    }
                    
                    $update->close();
                    debug_log("Esercizio aggiornato con successo");
                } else {
                    // Insert nuovo - AGGIORNATO per includere campi REST-PAUSE
                    debug_log("Inserimento nuovo esercizio");
                    $insert = $conn->prepare("
                        INSERT INTO scheda_esercizi 
                        (scheda_id, esercizio_id, serie, ripetizioni, peso, ordine, tempo_recupero, note, set_type, linked_to_previous, is_rest_pause, rest_pause_reps, rest_pause_rest_seconds) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ");
                    $insert->bind_param('iiiidiissiisi', 
                        $scheda_id, $esercizio_id, $serie, $ripetizioni, $peso, $ordine,
                        $tempo_recupero, $note, $set_type, $linked_to_previous,
                        $is_rest_pause, $rest_pause_reps, $rest_pause_rest_seconds
                    );
                    
                    if (!$insert->execute()) {
                        debug_log("❌ ERRORE INSERT: " . $insert->error);
                        throw new Exception("Errore nell'inserimento: " . $insert->error);
                    }
                    
                    // Verifica se il valore è stato inserito correttamente
                    $new_id = $conn->insert_id;
                    $check_insert = $conn->prepare("SELECT set_type FROM scheda_esercizi WHERE id = ?");
                    $check_insert->bind_param('i', $new_id);
                    $check_insert->execute();
                    $check_result = $check_insert->get_result();
                    $check_row = $check_result->fetch_assoc();
                    debug_log("✅ VERIFICA INSERT: set_type salvato come '" . $check_row['set_type'] . "'");
                    $check_insert->close();
                    
                    $insert->close();
                    debug_log("Nuovo esercizio inserito con successo");
                }
            }

            // Rimuovi esercizi eliminati
            if (isset($input['rimuovi'])) {
                $rimuovi = $input['rimuovi']; 
                debug_log("Esercizi da rimuovere:", $rimuovi);
                
                if ($rimuovi && is_array($rimuovi)) {
                    foreach ($rimuovi as $exRimosso) {
                        $esercizio_id = intval($exRimosso['id']);
                        debug_log("Rimozione esercizio ID: $esercizio_id");
                        
                        $delete = $conn->prepare("
                            DELETE FROM scheda_esercizi
                            WHERE scheda_id = ? AND esercizio_id = ?
                        ");
                        $delete->bind_param('ii', $scheda_id, $esercizio_id);
                        $delete->execute();
                        $delete->close();
                        debug_log("Esercizio rimosso con successo");
                    }
                }
            }

            $conn->commit();
            debug_log("Transazione completata con successo");
            echo json_encode(['success' => true, 'message' => 'Scheda aggiornata con successo.']);
        } catch (Exception $e) {
            $conn->rollback();
            debug_log("ERRORE durante l'aggiornamento: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Errore aggiornamento: ' . $e->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Metodo non supportato']);
        break;
}

$conn->close();
?>