<?php
// fitgymtrack_flutter/Api server/firebase/send_push_notification.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Gestisci preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';
require_once '../../auth/auth_middleware.php';

// Verifica che sia una richiesta POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
    exit();
}

try {
    // Autentica l'utente (solo gym e trainer possono inviare notifiche)
    $user = authMiddleware($conn, ['admin', 'trainer', 'gym']);
    
    // Leggi i dati JSON
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Dati JSON non validi');
    }
    
    $title = $input['title'] ?? null;
    $message = $input['message'] ?? null;
    $recipient_id = $input['recipient_id'] ?? null;
    $is_broadcast = $input['is_broadcast'] ?? false;
    $type = $input['type'] ?? 'message';
    $priority = $input['priority'] ?? 'normal';
    
    if (!$title || !$message) {
        throw new Exception('Titolo e messaggio richiesti');
    }
    
    // Ottieni FCM tokens dei destinatari
    $fcm_tokens = [];
    
    if ($is_broadcast) {
        // Broadcast a tutti i membri della palestra
        $tokensStmt = $conn->prepare("
            SELECT DISTINCT fcm_token 
            FROM user_fcm_tokens uft
            JOIN users u ON uft.user_id = u.id
            JOIN user_role r ON u.role_id = r.id
            WHERE u.gym_id = (SELECT gym_id FROM users WHERE id = ?) 
            AND r.name = 'user'
            AND uft.fcm_token IS NOT NULL
        ");
        $tokensStmt->bind_param("i", $user['user_id']);
    } else {
        // Notifica singola
        if (!$recipient_id) {
            throw new Exception('ID destinatario richiesto per notifica singola');
        }
        
        $tokensStmt = $conn->prepare("
            SELECT fcm_token 
            FROM user_fcm_tokens 
            WHERE user_id = ? AND fcm_token IS NOT NULL
        ");
        $tokensStmt->bind_param("i", $recipient_id);
    }
    
    $tokensStmt->execute();
    $result = $tokensStmt->get_result();
    
    while ($row = $result->fetch_assoc()) {
        $fcm_tokens[] = $row['fcm_token'];
    }
    
    if (empty($fcm_tokens)) {
        throw new Exception('Nessun token FCM trovato per i destinatari');
    }
    
    // Invia notifica push
    $push_results = [];
    foreach ($fcm_tokens as $token) {
        $push_result = sendFCMNotification($token, $title, $message, $type, $priority);
        $push_results[] = $push_result;
    }
    
    // Salva notifica nel database
    $notification_id = saveNotification($conn, $user, $title, $message, $type, $priority, $recipient_id, $is_broadcast);
    
    echo json_encode([
        'success' => true,
        'message' => 'Notifica push inviata con successo',
        'notification_id' => $notification_id,
        'recipients_count' => count($fcm_tokens),
        'push_results' => $push_results
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

/**
 * Invia notifica FCM
 */
function sendFCMNotification($token, $title, $message, $type, $priority) {
    $server_key = 'AIzaSyD-PyYLjsz7VXr2_4ehoOrX0heQPzNtAM8'; // Firebase Server Key
    
    $data = [
        'to' => $token,
        'notification' => [
            'title' => $title,
            'body' => $message,
            'sound' => 'default',
            'badge' => 1
        ],
        'data' => [
            'type' => $type,
            'priority' => $priority,
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
        ],
        'priority' => $priority === 'high' ? 'high' : 'normal'
    ];
    
    $headers = [
        'Authorization: key=' . $server_key,
        'Content-Type: application/json'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'token' => substr($token, 0, 20) . '...',
        'success' => $http_code === 200,
        'response' => $response
    ];
}

/**
 * Salva notifica nel database
 */
function saveNotification($conn, $user, $title, $message, $type, $priority, $recipient_id, $is_broadcast) {
    $sender_type = hasRole($user, 'gym') ? 'gym' : 'trainer';
    
    $stmt = $conn->prepare("
        INSERT INTO notifications (sender_id, sender_type, recipient_id, title, message, type, priority, status, is_broadcast, created_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, 'sent', ?, NOW())
    ");
    
    $stmt->bind_param("isissssi", 
        $user['user_id'], 
        $sender_type, 
        $recipient_id, 
        $title, 
        $message, 
        $type, 
        $priority, 
        $is_broadcast
    );
    
    $stmt->execute();
    return $conn->insert_id;
}
?>
