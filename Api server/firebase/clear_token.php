<?php
// fitgymtrack_flutter/Api server/firebase/clear_token.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Gestisci preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config.php';
require_once '../auth_functions.php';

// Verifica che sia una richiesta POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
    exit();
}

try {
    // Debug: Verifica connessione database
    if (!$conn) {
        throw new Exception('Connessione database fallita');
    }
    
    // Autentica l'utente
    // $user = authMiddleware($conn, ['admin', 'trainer', 'gym', 'user']);
    
    // TEMPORANEO: Per test senza autenticazione
    $user = ['user_id' => 33, 'username' => 'Membro1'];
    
    // Leggi i dati JSON
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Dati JSON non validi');
    }
    
    $fcm_token = $input['fcm_token'] ?? null;
    $user_id = $input['user_id'] ?? $user['user_id'];
    
    if (!$fcm_token) {
        throw new Exception('FCM token richiesto');
    }
    
    // Pulisci il token FCM per l'utente
    $deleteStmt = $conn->prepare("
        DELETE FROM user_fcm_tokens 
        WHERE user_id = ? AND fcm_token = ?
    ");
    $deleteStmt->bind_param("is", $user_id, $fcm_token);
    $deleteStmt->execute();
    
    if ($deleteStmt->affected_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Token FCM rimosso con successo',
            'action' => 'deleted'
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'message' => 'Token FCM non trovato (già rimosso)',
            'action' => 'not_found'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
