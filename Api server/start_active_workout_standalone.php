<?php
// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Aggiungi logging per debug
// function debugLog($message, $data = null) {
//     $log_file = __DIR__ . '/workout_debug.log';
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

    if (!isset($input['user_id'], $input['scheda_id'])) {
        handleError('Campi obbligatori mancanti (user_id, scheda_id)', 400);
    }

    $user_id = intval($input['user_id']);
    $scheda_id = intval($input['scheda_id']);

    // Utilizziamo un session_id per prevenire duplicati, se fornito
    $session_id = isset($input['session_id']) ? $input['session_id'] : null;

    //debugLog("Elaborazione richiesta per user_id: {$user_id}, scheda_id: {$scheda_id}, session_id: {$session_id}");

    if (!$conn) {
        handleError('Errore di connessione al database', 500);
    }

    // Usiamo un blocco transazionale per garantire atomicità
    $conn->begin_transaction();

    try {
        // Verifica se esiste già un allenamento iniziato con questo session_id
        if ($session_id) {
            // Aggiungiamo una colonna 'session_id' alla tabella allenamenti, se non esiste
            $conn->query("
                CREATE TABLE IF NOT EXISTS workout_sessions (
                    session_id VARCHAR(255) NOT NULL PRIMARY KEY,
                    allenamento_id INT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ");

            // Verifica se esiste già un allenamento con questo session_id
            $checkSessionStmt = $conn->prepare("SELECT allenamento_id FROM workout_sessions WHERE session_id = ?");
            if (!$checkSessionStmt) {
                throw new Exception('Errore di preparazione query: ' . $conn->error);
            }

            $checkSessionStmt->bind_param('s', $session_id);
            if (!$checkSessionStmt->execute()) {
                throw new Exception('Errore di esecuzione query: ' . $checkSessionStmt->error);
            }

            $sessionResult = $checkSessionStmt->get_result();

            if ($sessionResult->num_rows > 0) {
                // Questo session_id è già stato usato, restituisci l'allenamento associato
                $sessionRow = $sessionResult->fetch_assoc();
                $allenamento_id = $sessionRow['allenamento_id'];

                //debugLog("Session ID già usato, restituisco allenamento esistente, ID: {$allenamento_id}");

                $checkSessionStmt->close();
                $conn->commit();

                echo json_encode([
                    'success' => true,
                    'allenamento_id' => $allenamento_id,
                    'message' => 'Allenamento esistente recuperato tramite session_id',
                    'session_id' => $session_id
                ]);
                exit;
            }

            $checkSessionStmt->close();
        }

        // Verifica se esiste già un allenamento non completato per questa scheda e questo utente
        // Consideriamo un allenamento incompleto quando durata_totale è NULL
        $checkStmt = $conn->prepare("SELECT id FROM allenamenti WHERE user_id = ? AND scheda_id = ? AND durata_totale IS NULL LIMIT 1");
        if (!$checkStmt) {
            throw new Exception('Errore di preparazione query: ' . $conn->error);
        }

        $checkStmt->bind_param('ii', $user_id, $scheda_id);
        if (!$checkStmt->execute()) {
            throw new Exception('Errore di esecuzione query: ' . $checkStmt->error);
        }

        $result = $checkStmt->get_result();

        if ($result->num_rows > 0) {
            // Se esiste già un allenamento in corso, restituisci quello
            $allenamento = $result->fetch_assoc();
            $allenamento_id = $allenamento['id'];
            $checkStmt->close();

            //debugLog("Trovato allenamento esistente, ID: {$allenamento_id}");

            // Associa il session_id a questo allenamento se fornito
            if ($session_id) {
                $storeSessionStmt = $conn->prepare("INSERT INTO workout_sessions (session_id, allenamento_id) VALUES (?, ?)");
                if (!$storeSessionStmt) {
                    throw new Exception('Errore di preparazione query: ' . $conn->error);
                }

                $storeSessionStmt->bind_param('si', $session_id, $allenamento_id);
                if (!$storeSessionStmt->execute()) {
                    // Se fallisce, probabilmente c'è già un'associazione, ma continuiamo comunque
                    //debugLog("Non è stato possibile associare session_id: " . $storeSessionStmt->error);
                }

                $storeSessionStmt->close();
            }

            // Completiamo la transazione
            $conn->commit();

            echo json_encode([
                'success' => true,
                'allenamento_id' => $allenamento_id,
                'message' => 'Allenamento esistente recuperato'
            ]);
            exit;
        }

        $checkStmt->close();

        // Se non esiste, crea un nuovo allenamento
        $stmt = $conn->prepare("INSERT INTO allenamenti (user_id, scheda_id, data_allenamento) VALUES (?, ?, NOW())");
        if (!$stmt) {
            throw new Exception('Errore di preparazione query di inserimento: ' . $conn->error);
        }

        $stmt->bind_param('ii', $user_id, $scheda_id);

        if (!$stmt->execute()) {
            throw new Exception('Errore di inserimento: ' . $stmt->error);
        }

        $allenamento_id = $stmt->insert_id;
        $stmt->close();

        //debugLog("Nuovo allenamento creato con successo, ID: {$allenamento_id}");

        // Associa il session_id a questo allenamento se fornito
        if ($session_id) {
            $storeSessionStmt = $conn->prepare("INSERT INTO workout_sessions (session_id, allenamento_id) VALUES (?, ?)");
            if (!$storeSessionStmt) {
                throw new Exception('Errore di preparazione query: ' . $conn->error);
            }

            $storeSessionStmt->bind_param('si', $session_id, $allenamento_id);
            if (!$storeSessionStmt->execute()) {
                //debugLog("Non è stato possibile salvare session_id: " . $storeSessionStmt->error);
            }

            $storeSessionStmt->close();
        }

        // Completiamo la transazione
        $conn->commit();

        echo json_encode([
            'success' => true,
            'allenamento_id' => $allenamento_id,
            'message' => 'Nuovo allenamento creato',
            'session_id' => $session_id
        ]);
    } catch (Exception $e) {
        $conn->rollback();
        handleError('Errore durante l\'operazione: ' . $e->getMessage());
    }

    $conn->close();

} catch (Exception $e) {
    handleError('Eccezione: ' . $e->getMessage(), 500);
}
?>