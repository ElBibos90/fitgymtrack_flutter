<?php
// fitgymtrack_flutter/Api server/firebase/send_push_notification_v1.php

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
            AND r.name IN ('user', 'trainer', 'gym')
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
    
    // Invia notifica push usando V1 API
    $push_results = [];
    foreach ($fcm_tokens as $token) {
        $push_result = sendFCMNotificationV1($token, $title, $message, $type, $priority);
        $push_results[] = $push_result;
    }
    
    // Salva notifica nel database
    $notification_id = saveNotification($conn, $user, $title, $message, $type, $priority, $recipient_id, $is_broadcast);
    
    echo json_encode([
        'success' => true,
        'message' => 'Notifica push inviata con successo (V1 API)',
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
 * Invia notifica FCM usando V1 API
 */
function sendFCMNotificationV1($token, $title, $message, $type, $priority) {
    // Configurazione Service Account
    $service_account = [
        'type' => 'service_account',
        'project_id' => 'fitgymtrack-1c62f',
        'private_key_id' => '546104d0ff9466ccc09e3abc40fceb19328a4dc1',
        'private_key' => "-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDT0kTvPTpvw8sI
xdK4K8Bzw95UggsWnIsCBxHziV6y85ISYKoirpn4Ew6kNNFJierObkJoSHCUe3Tu
+ATUWdlQxFro1IJsquqkUMexuOdU5bOzYDQI5mTeK0PmaE00hC1D8wEzRCVmHmGJ
tM0Qc83uJTpIYQZbi+TvR9RcLbPc8Qjp4ffsBkuJm4SxlANZ7ZGfPs6ijQPmVFFS
fegDmdiqDycTQG8RuMnXM3NPMwgNHTKQL6MTlk+ws4VrDtkzRc3Emyod46wR25DE
QrN9VtbtkG56bd7AZMVc3nqiGKdcFAYsUnQI6/McHJN8dk0VuzObc1G6YVWU7Kyt
QxzBaUjhAgMBAAECggEARDQaOiYu4LnccDCyTtbXmu7gcbmFtHwnTjnUj+QVd+1x
hTVW0uABd507Q6g2E0WzM1DRVR6uEUFHP4Lgmzdq/9SZqQp0DGVkNBBGnHT7F5z2
pbU+S/dTVy37KP9AjL5ajNx78HPqztzNbzemJ7wB/MJD5/ZFw8hhqKIqQJv+pA7q
ZdeXBFj7znzJ9JfuSSXYYifAGnP9JKCOXWjIo7ux/mYqaE9wSbDA+hL7ON5ifpiK
RB3pcftr/l8SUqS1jgMiUAX3nocKsRAB0s/LXva40ESEe8COaivmd/2uKiQQC3fh
DvVB83zSSraYA3eTjgihNP11sjn0T/poYkLFY3rVmQKBgQDrOc13v5N3X2dvJ0Jc
jzF2DiB/A08CdKvvGTKN0pc3VmdUlp6t2rnbQZg7Txz+TjTjtMR4GxJJbhKzu3GC
LhFrE4LtZr5gKLOL8LiXUZa91pXavFxL7Zpye4V4tXDGlI2FcvdcG6mrZdmH+Jle
nP2LXkpDJFThDUnqr99pMk0X4wKBgQDmh1F2o5STrhDyH6jkF3o2+/J9HOZS3QzF
uip/3aNgZcc1eXrBte2AwnHude/OoQC0zX1MNmZ/HgbJ2jt8A0eMpyS2di9yrpOj
pIWxIxyRQL5lQEau9bN8Ae5kwA6z7DAYdJDsGT0Q9K4b9vjexzSap/uUYG5yhE2Q
zOXUJC4PawKBgQDT+ZQKrM7EjWoVxehMpxHolFR+gUnLKb7jSe6/1Z5F1QxrMwyu
GWTRjGwWTnYPSgTpirZeke7J03LxGyLwMHmr57peG+/FkggzPOvsGS9hxiXnJ0V5
exZqwpuGKuQFYEukjfURwTAGcFM28DWuCIWH+aGsneoLoUESSAlpsFW/BwKBgQCK
zGC1IOqdPEnBrmQ+6Q/RuUKYJ+VZcPR2vI9IK4dpy/30aW8K4OHeC7UTUXkQnQnS
0oKld3+g+9A0iqwUD9lti1lkbqZE023bMny4WZ6iqiu4xMmKIC9v8624hZaUqBmR
L+Xt8Yg+BEQsXDgd0i0PDSNBhAob8yLMk0GxyBLffwKBgQDlvk+qn8GIDzKAOn6w
sN9hKLB7bsycvWbB4bxrbP1MgoA1rkbSIkYhs6a2icVPub1W/pit4+IPJ+BJj1lQ
3NEWt38jfVGW7kHVuY0RHLU0ISfrZUkZkQTx9d+VRAAQhHlsDWsa4iReMYE1szLi
+0NpA+4y/TDEe/Nc/NKYH5KSDA==
-----END PRIVATE KEY-----",
        'client_email' => 'firebase-adminsdk-fbsvc@fitgymtrack-1c62f.iam.gserviceaccount.com',
        'client_id' => '117563980715722095403',
        'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
        'token_uri' => 'https://oauth2.googleapis.com/token'
    ];
    
    // Ottieni access token
    $access_token_result = getAccessToken($service_account);
    
    // Se è un array, significa che c'è stato un errore
    if (is_array($access_token_result)) {
        return [
            'token' => substr($token, 0, 20) . '...',
            'success' => false,
            'error' => 'Failed to get access token',
            'debug' => $access_token_result
        ];
    }
    
    if (!$access_token_result) {
        return [
            'token' => substr($token, 0, 20) . '...',
            'success' => false,
            'error' => 'Failed to get access token',
            'debug' => 'JWT creation failed or OAuth response error'
        ];
    }
    
    $access_token = $access_token_result;
    
    // Prepara payload per V1 API
    $data = [
        'message' => [
            'token' => $token,
            'notification' => [
                'title' => $title,
                'body' => $message
            ],
            'data' => [
                'type' => $type,
                'priority' => $priority,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ],
            'android' => [
                'priority' => $priority === 'high' ? 'high' : 'normal'
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1
                    ]
                ]
            ]
        ]
    ];
    
    $headers = [
        'Authorization: Bearer ' . $access_token,
        'Content-Type: application/json'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/v1/projects/fitgymtrack-1c62f/messages:send');
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
 * Ottieni access token per V1 API
 */
function getAccessToken($service_account) {
    $jwt = createJWT($service_account);
    
    // Debug: Log JWT creation
    error_log("Firebase JWT created: " . substr($jwt, 0, 50) . "...");
    
    $data = [
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    // Debug: Log response
    error_log("Firebase Auth Response - HTTP Code: $http_code, Response: $response");
    
    if ($http_code === 200) {
        $result = json_decode($response, true);
        return $result['access_token'] ?? null;
    }
    
    // Debug: Log dell'errore
    error_log("Firebase Auth Error - HTTP Code: $http_code, Response: $response");
    
    // Restituisci l'errore per debug
    return [
        'error' => true,
        'http_code' => $http_code,
        'response' => $response
    ];
}

/**
 * Crea JWT per autenticazione
 */
function createJWT($service_account) {
    $header = [
        'alg' => 'RS256',
        'typ' => 'JWT'
    ];
    
    $now = time();
    $payload = [
        'iss' => $service_account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ];
    
    $header_encoded = base64url_encode(json_encode($header));
    $payload_encoded = base64url_encode(json_encode($payload));
    
    $signature = '';
    openssl_sign(
        $header_encoded . '.' . $payload_encoded,
        $signature,
        $service_account['private_key'],
        OPENSSL_ALGO_SHA256
    );
    
    $signature_encoded = base64url_encode($signature);
    
    return $header_encoded . '.' . $payload_encoded . '.' . $signature_encoded;
}

/**
 * Base64 URL encode
 */
function base64url_encode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
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
