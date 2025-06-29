<?php
// Disabilita la visualizzazione degli errori nella risposta HTTP
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Funzione per gestire gli errori e restituire JSON appropriato
function handleError($message, $errorCode = 500) {
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

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        handleError('Metodo non consentito', 405);
    }

    $inputJson = file_get_contents('php://input');
    if (!$inputJson) {
        handleError('Nessun dato ricevuto', 400);
    }

    $input = json_decode($inputJson, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        handleError('JSON non valido: ' . json_last_error_msg(), 400);
    }

    if (!isset($input['allenamento_id'])) {
        handleError('ID allenamento mancante', 400);
    }

    $allenamento_id = intval($input['allenamento_id']);
    $durata_totale = isset($input['durata_totale']) ? intval($input['durata_totale']) : 0;
    $note = isset($input['note']) ? $input['note'] : '';

    if (!$conn) {
        handleError('Errore di connessione al database', 500);
    }

    // Verifica che l'allenamento esista
    $checkStmt = $conn->prepare("SELECT id FROM allenamenti WHERE id = ?");
    if (!$checkStmt) {
        handleError('Errore di preparazione query: ' . $conn->error, 500);
    }

    $checkStmt->bind_param('i', $allenamento_id);
    if (!$checkStmt->execute()) {
        handleError('Errore di esecuzione query: ' . $checkStmt->error, 500);
    }

    $result = $checkStmt->get_result();
    if ($result->num_rows === 0) {
        handleError('Allenamento non trovato con ID: ' . $allenamento_id, 404);
    }

    $checkStmt->close();

    // Aggiorna l'allenamento con la durata totale e le note
    $updateStmt = $conn->prepare("UPDATE allenamenti SET durata_totale = ?, note = ? WHERE id = ?");
    if (!$updateStmt) {
        handleError('Errore di preparazione query di aggiornamento: ' . $conn->error, 500);
    }

    $updateStmt->bind_param('isi', $durata_totale, $note, $allenamento_id);
    if (!$updateStmt->execute()) {
        handleError('Errore di aggiornamento: ' . $updateStmt->error, 500);
    }

    $rowsAffected = $updateStmt->affected_rows;
    $updateStmt->close();

    if ($rowsAffected === 0) {
        handleError('Nessun allenamento aggiornato con ID: ' . $allenamento_id, 400);
    }

    echo json_encode([
        'success' => true, 
        'message' => 'Allenamento completato con successo',
        'allenamento_id' => $allenamento_id,
        'durata_totale' => $durata_totale
    ]);

    $conn->close();
    
} catch (Exception $e) {
    handleError('Eccezione: ' . $e->getMessage(), 500);
}
?>