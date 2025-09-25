<?php
// fitgymtrack_flutter/Api server/firebase/register_token.php

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
    $platform = $input['platform'] ?? 'unknown';
    
    if (!$fcm_token) {
        throw new Exception('FCM token richiesto');
    }
    
    // Verifica se il token esiste già
    $checkStmt = $conn->prepare("
        SELECT id FROM user_fcm_tokens 
        WHERE user_id = ? AND fcm_token = ?
    ");
    $checkStmt->bind_param("is", $user['user_id'], $fcm_token);
    $checkStmt->execute();
    $result = $checkStmt->get_result();
    
    if ($result->num_rows > 0) {
        // Token già esistente, aggiorna timestamp
        $updateStmt = $conn->prepare("
            UPDATE user_fcm_tokens 
            SET platform = ?, updated_at = NOW() 
            WHERE user_id = ? AND fcm_token = ?
        ");
        $updateStmt->bind_param("sis", $platform, $user['user_id'], $fcm_token);
        $updateStmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Token aggiornato con successo',
            'action' => 'updated'
        ]);
    } else {
        // Nuovo token, inserisci
        $insertStmt = $conn->prepare("
            INSERT INTO user_fcm_tokens (user_id, fcm_token, platform, created_at, updated_at) 
            VALUES (?, ?, ?, NOW(), NOW())
        ");
        $insertStmt->bind_param("iss", $user['user_id'], $fcm_token, $platform);
        $insertStmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Token registrato con successo',
            'action' => 'created'
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
