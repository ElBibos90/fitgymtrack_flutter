<?php
// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Aggiungi logging per debug
// function debugLog($message, $data = null) {
//     $log_file = __DIR__ . '/series_debug.log';
//     $timestamp = date('Y-m-d H:i:s');
//     $log_message = "[{$timestamp}] {$message}";
    
//     if ($data !== null) {
//         if (is_array($data) || is_object($data)) {
//             $log_message .= " - Data: " . print_r($data, true);
//         } else {
//             $log_message .= " - Data: {$data}";
//         }
//     }
    
//     file_put_contents($log_file, $log_message . PHP_EOL, FILE_APPEND);
    
// }

// Funzione per gestire gli errori e restituire JSON appropriato
function handleError($message, $errorCode = 500) {
    //debugLog("ERRORE: {$message}");
    header('Content-Type: application/json');
    http_response_code($errorCode);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

// Gestione errori personalizzata
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    handleError("Errore PHP: $errstr in $errfile linea $errline");
});

try {
    include 'config.php';
    require_once 'auth_functions.php';

    header('Content-Type: application/json');

    //debugLog("Richiesta ricevuta");

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        handleError('Metodo non consentito', 405);
    }

    $inputJson = file_get_contents('php://input');
    if (!$inputJson) {
        handleError('Nessun dato ricevuto', 400);
    }

    //debugLog("Input ricevuto", $inputJson);

    $input = json_decode($inputJson, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        handleError('JSON non valido: ' . json_last_error_msg(), 400);
    }

    if (!isset($input['allenamento_id'], $input['serie']) || !is_array($input['serie'])) {
        handleError('Campi obbligatori mancanti o non validi', 400);
    }

    $allenamento_id = intval($input['allenamento_id']);
    $serie = $input['serie'];
    // Ottieni l'ID richiesta se disponibile
    $request_id = isset($input['request_id']) ? $input['request_id'] : null;
    
    /*debugLog("Elaborazione serie per allenamento_id: {$allenamento_id}", [
        'serie' => $serie, 
        'request_id' => $request_id
    ]);*/

    if (!$conn) {
        handleError('Errore di connessione al database', 500);
    }
    
    // Se abbiamo un request_id, controlla se è già stato elaborato
    if ($request_id) {
        // Crea tabella di tracking richieste se non esiste
        $conn->query("
            CREATE TABLE IF NOT EXISTS completed_series_requests (
                request_id VARCHAR(255) NOT NULL PRIMARY KEY,
                processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ");
        
        // Verifica se la richiesta è già stata elaborata
        $checkRequestStmt = $conn->prepare("SELECT request_id FROM completed_series_requests WHERE request_id = ?");
        $checkRequestStmt->bind_param('s', $request_id);
        $checkRequestStmt->execute();
        $requestResult = $checkRequestStmt->get_result();
        
        if ($requestResult->num_rows > 0) {
            //debugLog("Richiesta già elaborata, ID: {$request_id}");
            
            echo json_encode([
                'success' => true, 
                'message' => 'Serie già salvata (richiesta duplicata)',
                'request_id' => $request_id
            ]);
            
            $checkRequestStmt->close();
            exit;
        }
        
        $checkRequestStmt->close();
    }

    $conn->begin_transaction();

    try {
        // Per ogni serie, esegui un controllo anti-duplicato
        foreach ($serie as $s) {
            if (!isset($s['scheda_esercizio_id'], $s['peso'], $s['ripetizioni'])) {
                handleError('Dati serie incompleti', 400);
            }
            
            $scheda_esercizio_id = intval($s['scheda_esercizio_id']);
            $serie_number = isset($s['serie_number']) ? intval($s['serie_number']) : null;
            
            /*debugLog("Elaborazione serie", [
                'scheda_esercizio_id' => $scheda_esercizio_id,
                'serie_number' => $serie_number,
                'serie_id' => isset($s['serie_id']) ? $s['serie_id'] : 'non definito'
            ]);*/
            
            // Recuperiamo l'esercizio_id corrispondente a scheda_esercizio_id
            $exerciseQuery = $conn->prepare("
                SELECT esercizio_id, tempo_recupero 
                FROM scheda_esercizi 
                WHERE id = ?
            ");
            $exerciseQuery->bind_param('i', $scheda_esercizio_id);
            $exerciseQuery->execute();
            $exerciseResult = $exerciseQuery->get_result();
            $exerciseData = $exerciseResult->fetch_assoc();
            $exerciseQuery->close();
            
            if (!$exerciseData) {
                handleError("Scheda esercizio non trovata per ID: {$scheda_esercizio_id}", 404);
            }
            
            $peso = floatval($s['peso']);
            $ripetizioni = intval($s['ripetizioni']);
            $completata = isset($s['completata']) ? intval($s['completata']) : 1;
            
            // Tempo di recupero: priorità al valore inviato, poi al default della scheda
            $tempo_recupero = null;
            if (isset($s['tempo_recupero']) && !empty($s['tempo_recupero'])) {
                $tempo_recupero = intval($s['tempo_recupero']);
            } else if ($exerciseData['tempo_recupero']) {
                $tempo_recupero = intval($exerciseData['tempo_recupero']);
            }
            
            $note = isset($s['note']) && !empty($s['note']) ? $s['note'] : null;
            $serie_id = isset($s['serie_id']) ? $s['serie_id'] : null;
            
            // NUOVI CAMPI REST-PAUSE con valori predefiniti
            $is_rest_pause = isset($s['is_rest_pause']) ? intval($s['is_rest_pause']) : 0;
            $rest_pause_reps = isset($s['rest_pause_reps']) && !empty($s['rest_pause_reps']) ? $s['rest_pause_reps'] : null;
            $rest_pause_rest_seconds = isset($s['rest_pause_rest_seconds']) ? intval($s['rest_pause_rest_seconds']) : null;
            
            //debugLog("Tempo recupero finale: " . ($tempo_recupero === null ? 'NULL' : $tempo_recupero));

            // CORREZIONE: Controllo dei duplicati migliorato
            // Se abbiamo un numero di serie, lo usiamo per verificare se questa specifica serie è stata già inserita
            if ($serie_number !== null) {
                // Verifica se esiste già una serie con lo stesso numero per questo esercizio e allenamento
                $checkStmt = $conn->prepare("
                    SELECT id FROM serie_completate 
                    WHERE allenamento_id = ? AND scheda_esercizio_id = ? AND serie_number = ?
                    LIMIT 1
                ");
                
                $checkStmt->bind_param('iii', $allenamento_id, $scheda_esercizio_id, $serie_number);
                $checkStmt->execute();
                $checkResult = $checkStmt->get_result();
                
                if ($checkResult->num_rows > 0) {
                    //debugLog("Serie già presente (numero serie): {$serie_number} - ignoriamo");
                    $checkStmt->close();
                    continue; // Salta questa serie perché esiste già
                }
                
                $checkStmt->close();
            } else {
                // Se non abbiamo un numero di serie, usiamo il vecchio metodo basato su valori e timestamp
                $checkStmt = $conn->prepare("
                    SELECT id FROM serie_completate 
                    WHERE allenamento_id = ? AND scheda_esercizio_id = ? AND peso = ? AND ripetizioni = ? 
                    AND ABS(TIMESTAMPDIFF(SECOND, timestamp, NOW())) < 30
                ");
                
                $checkStmt->bind_param('iidd', $allenamento_id, $scheda_esercizio_id, $peso, $ripetizioni);
                $checkStmt->execute();
                $checkResult = $checkStmt->get_result();
                
                if ($checkResult->num_rows > 0) {
                    //debugLog("Serie duplicata rilevata e ignorata (metodo basato su valori)");
                    $checkStmt->close();
                    continue; // Salta questa serie se è un duplicato recente
                }
                
                $checkStmt->close();
            }

            // Prepara il campo serie_number (se disponibile)
            $hasSerieNumber = $serie_number !== null;
            
            if ($hasSerieNumber) {
                // INSERT con serie_number e campi REST-PAUSE
                $insertStmt = $conn->prepare("
                    INSERT INTO serie_completate (allenamento_id, scheda_esercizio_id, peso, ripetizioni, completata, tempo_recupero, note, serie_number, is_rest_pause, rest_pause_reps, rest_pause_rest_seconds)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ");
                
                if (!$insertStmt) {
                    throw new Exception('Errore di preparazione query: ' . $conn->error);
                }
                
                $insertStmt->bind_param('iidiiisiisi', $allenamento_id, $scheda_esercizio_id, $peso, $ripetizioni, $completata, $tempo_recupero, $note, $serie_number, $is_rest_pause, $rest_pause_reps, $rest_pause_rest_seconds);
            } else {
                // INSERT senza serie_number ma con campi REST-PAUSE
                $insertStmt = $conn->prepare("
                    INSERT INTO serie_completate (allenamento_id, scheda_esercizio_id, peso, ripetizioni, completata, tempo_recupero, note, is_rest_pause, rest_pause_reps, rest_pause_rest_seconds)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ");
                
                if (!$insertStmt) {
                    throw new Exception('Errore di preparazione query: ' . $conn->error);
                }
                
                $insertStmt->bind_param('iidiisiisi', $allenamento_id, $scheda_esercizio_id, $peso, $ripetizioni, $completata, $tempo_recupero, $note, $is_rest_pause, $rest_pause_reps, $rest_pause_rest_seconds);
            }
            
            if (!$insertStmt->execute()) {
                throw new Exception('Errore di esecuzione query: ' . $insertStmt->error);
            }
            
            $insertedId = $insertStmt->insert_id;
            //debugLog("Serie salvata con successo, ID: " . $insertedId);
            $insertStmt->close();
        }

        // Se abbiamo un request_id, registralo come elaborato
        if ($request_id) {
            try {
                // Prima puliamo i record vecchi (più di 7 giorni)
                $cleanupStmt = $conn->prepare("DELETE FROM completed_series_requests WHERE processed_at < DATE_SUB(NOW(), INTERVAL 7 DAY)");
                $cleanupStmt->execute();
                $cleanupStmt->close();
                
                // Ora inseriamo il nuovo record
                $saveRequestStmt = $conn->prepare("INSERT INTO completed_series_requests (request_id) VALUES (?)");
                if (!$saveRequestStmt) {
                    throw new Exception('Errore di preparazione query: ' . $conn->error);
                }
                
                $saveRequestStmt->bind_param('s', $request_id);
                if (!$saveRequestStmt->execute()) {
                    throw new Exception($saveRequestStmt->error);
                }
                
                $saveRequestStmt->close();
            } catch (Exception $e) {
                // Se è un errore di duplicazione, lo ignoriamo silenziosamente
                if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
                    // Log l'errore ma continua senza problemi
                    //debugLog("Ignorato errore di duplicazione per request_id: " . $request_id);
                } else {
                    // Rilancia altri errori
                    throw $e;
                }
            }
        }

        $conn->commit();
        echo json_encode(['success' => true, 'message' => 'Serie salvate con successo']);
    } catch (Exception $e) {
        $conn->rollback();
        handleError('Errore salvataggio serie: ' . $e->getMessage());
    }
} catch (Exception $e) {
    handleError('Eccezione generale: ' . $e->getMessage());
}
?>