<?php
/**
 * course_reminder_cron.php
 * CRON JOB - Promemoria Corsi Automatici
 * 
 * Location: /var/www/html/api/course_reminder_cron.php
 * Schedule: ogni 15 minuti
 * 
 * LOGICA:
 * 1. Trova tutti i corsi che iniziano tra 60-75 minuti
 * 2. Per ogni corso, trova gli utenti iscritti
 * 3. Invia notifica push a ogni utente
 * 4. Logga tutto per debug
 * 
 * VANTAGGI:
 * - Promemoria 1 ora prima del corso
 * - Controllo ogni 15 minuti (precisione)
 * - Evita notifiche duplicate
 * - Logging completo
 */

// =============================================================================
// CONFIGURAZIONE E INCLUDE
// =============================================================================

$baseDir = '/var/www/html/api';
$logDir = '/var/www/html/api/logs';

// Crea directory log se non esiste
if (!is_dir($logDir)) {
    mkdir($logDir, 0755, true);
}

// Include database
require_once $baseDir . '/config.php';

// =============================================================================
// LOGGING
// =============================================================================

$logFile = $logDir . '/course_reminders_' . date('Y-m') . '.log';

function reminderLog($message, $level = 'INFO') {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] [$level] $message" . PHP_EOL;
    
    // Assicurati che il file di log sia definito
    if (empty($logFile)) {
        $logFile = '/var/www/html/api/logs/course_reminders_' . date('Y-m') . '.log';
    }
    
    // Crea directory se non esiste
    $logDir = dirname($logFile);
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    // Prova a scrivere il log, se fallisce usa echo
    if (!file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX)) {
        // Se non riesce a scrivere, almeno stampa
        echo "WARNING: Cannot write to log file $logFile" . PHP_EOL;
    }
    echo $logEntry;
}

function reminderErrorLog($message, $error = null) {
    $fullMessage = $message;
    if ($error) {
        $fullMessage .= " - Error: $error";
    }
    reminderLog($fullMessage, 'ERROR');
}

// =============================================================================
// FUNZIONI HELPER
// =============================================================================

/**
 * Ottieni corsi che iniziano tra 60-75 minuti
 */
function getUpcomingCourses($conn) {
    try {
        // Calcola timestamp per 60-75 minuti nel futuro
        $now = new DateTime();
        $startWindow = clone $now;
        $startWindow->modify('+60 minutes');
        $endWindow = clone $now;
        $endWindow->modify('+75 minutes');
        
        $startTime = $startWindow->format('Y-m-d H:i:s');
        $endTime = $endWindow->format('Y-m-d H:i:s');
        
        reminderLog("🔍 Cercando corsi tra $startTime e $endTime");
        
        $stmt = $conn->prepare("
            SELECT 
                tc.id as session_id,
                tc.course_id,
                tc.gym_id,
                tc.title as course_title,
                tc.start_datetime,
                tc.end_datetime,
                tc.location,
                tc.max_participants,
                tc.current_participants,
                gc.category,
                gc.color
            FROM trainer_calendar tc
            INNER JOIN gym_courses gc ON tc.course_id = gc.id
            WHERE tc.is_course = TRUE 
            AND tc.status = 'scheduled'
            AND CONVERT_TZ(tc.start_datetime, 'Europe/Rome', 'UTC') BETWEEN ? AND ?
            ORDER BY tc.start_datetime ASC
        ");
        
        $stmt->bind_param("ss", $startTime, $endTime);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $courses = [];
        while ($row = $result->fetch_assoc()) {
            $courses[] = $row;
        }
        
        reminderLog("📅 Trovati " . count($courses) . " corsi in programma");
        return $courses;
        
    } catch (Exception $e) {
        reminderErrorLog("Errore nel recupero corsi", $e->getMessage());
        return [];
    }
}

/**
 * Ottieni utenti iscritti a un corso
 */
function getCourseEnrollments($conn, $session_id) {
    try {
        $stmt = $conn->prepare("
            SELECT 
                gce.id as enrollment_id,
                gce.user_id,
                gce.reminder_sent,
                u.name as user_name,
                u.email as user_email,
                uf.fcm_token
            FROM gym_course_enrollments gce
            INNER JOIN users u ON gce.user_id = u.id
            LEFT JOIN user_fcm_tokens uf ON gce.user_id = uf.user_id
            WHERE gce.session_id = ? 
            AND gce.status = 'enrolled'
            AND uf.fcm_token IS NOT NULL
            AND (gce.reminder_sent IS NULL OR gce.reminder_sent = 0)
        ");
        
        $stmt->bind_param("i", $session_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $enrollments = [];
        while ($row = $result->fetch_assoc()) {
            $enrollments[] = $row;
        }
        
        return $enrollments;
        
    } catch (Exception $e) {
        reminderErrorLog("Errore nel recupero iscrizioni per sessione $session_id", $e->getMessage());
        return [];
    }
}

/**
 * Invia notifica push Firebase
 */
function sendReminderPushNotification($fcm_token, $course_title, $start_time, $location = null) {
    try {
        // Configurazione Service Account Firebase (stessa di gym_courses.php)
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
        $access_token = getFCMAccessTokenCron($service_account);
        if (!$access_token) {
            return ['success' => false, 'error' => 'Failed to get access token'];
        }
        
        // Prepara messaggio
        $title = "⏰ Promemoria Corso";
        $body = "Il corso '$course_title' inizia tra 1 ora alle " . date('H:i', strtotime($start_time));
        if ($location) {
            $body .= " - $location";
        }
        
        // Prepara payload per Firebase V1 API
        $data = [
            'message' => [
                'token' => $fcm_token,
                'notification' => [
                    'title' => $title,
                    'body' => $body
                ],
                'data' => [
                    'type' => 'course_reminder',
                    'priority' => 'normal',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                ],
                'android' => [
                    'priority' => 'normal'
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
        
        $success = $http_code === 200;
        
        return [
            'success' => $success,
            'response' => $response,
            'http_code' => $http_code
        ];
        
    } catch (Exception $e) {
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

/**
 * Ottieni Access Token Firebase (versione per cron job)
 */
function getFCMAccessTokenCron($service_account) {
    $jwt = createFCMJWTCron($service_account);
    
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
    
    if ($http_code === 200) {
        $result = json_decode($response, true);
        return $result['access_token'] ?? null;
    }
    
    return null;
}

/**
 * Crea JWT per autenticazione Firebase (versione per cron job)
 */
function createFCMJWTCron($service_account) {
    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    
    $now = time();
    $payload = [
        'iss' => $service_account['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ];
    
    $header_encoded = fcm_base64url_encode_cron(json_encode($header));
    $payload_encoded = fcm_base64url_encode_cron(json_encode($payload));
    
    $signature = '';
    openssl_sign(
        $header_encoded . '.' . $payload_encoded,
        $signature,
        $service_account['private_key'],
        OPENSSL_ALGO_SHA256
    );
    
    $signature_encoded = fcm_base64url_encode_cron($signature);
    
    return $header_encoded . '.' . $payload_encoded . '.' . $signature_encoded;
}

/**
 * Base64 URL encode per Firebase (versione per cron job)
 */
function fcm_base64url_encode_cron($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Marca promemoria come inviato
 */
function markReminderSent($conn, $enrollment_id) {
    try {
        $stmt = $conn->prepare("
            UPDATE gym_course_enrollments 
            SET reminder_sent = 1, reminder_sent_at = NOW()
            WHERE id = ?
        ");
        
        $stmt->bind_param("i", $enrollment_id);
        return $stmt->execute();
        
    } catch (Exception $e) {
        reminderErrorLog("Errore nel marcare promemoria inviato per enrollment $enrollment_id", $e->getMessage());
        return false;
    }
}

// =============================================================================
// FUNZIONE PRINCIPALE
// =============================================================================

/**
 * Esegue il controllo e invio promemoria
 */
function processCourseReminders($conn) {
    try {
        reminderLog("🚀 AVVIO CONTROLLO PROMEMORIA CORSI");
        
        // 1. Ottieni corsi in programma
        $courses = getUpcomingCourses($conn);
        
        if (empty($courses)) {
            reminderLog("✅ Nessun corso in programma nei prossimi 15 minuti");
            return [
                'success' => true,
                'courses_processed' => 0,
                'notifications_sent' => 0
            ];
        }
        
        $totalNotifications = 0;
        $coursesProcessed = 0;
        
        // 2. Per ogni corso, invia promemoria
        foreach ($courses as $course) {
            $coursesProcessed++;
            
            reminderLog("📚 Processando corso: {$course['course_title']} (ID: {$course['session_id']})");
            reminderLog("   ⏰ Inizio: {$course['start_datetime']}");
            reminderLog("   📍 Location: " . ($course['location'] ?? 'Non specificata'));
            
            // Ottieni iscrizioni
            $enrollments = getCourseEnrollments($conn, $course['session_id']);
            
            if (empty($enrollments)) {
                reminderLog("   ⚠️ Nessun utente iscritto con FCM token valido");
                continue;
            }
            
            reminderLog("   👥 Trovati " . count($enrollments) . " utenti da notificare");
            
            // Invia notifica a ogni utente
            foreach ($enrollments as $enrollment) {
                reminderLog("   📱 Invio notifica a: {$enrollment['user_name']} ({$enrollment['user_email']})");
                
                $pushResult = sendReminderPushNotification(
                    $enrollment['fcm_token'],
                    $course['course_title'],
                    $course['start_datetime'],
                    $course['location']
                );
                
                if ($pushResult['success']) {
                    reminderLog("   ✅ Notifica inviata con successo");
                    
                    // Marca come inviato
                    if (markReminderSent($conn, $enrollment['enrollment_id'])) {
                        reminderLog("   ✅ Promemoria marcato come inviato nel DB");
                    } else {
                        reminderLog("   ⚠️ Errore nel marcare promemoria come inviato");
                    }
                    
                    $totalNotifications++;
                } else {
                    reminderErrorLog("   ❌ Errore invio notifica: " . ($pushResult['error'] ?? 'Unknown error'));
                }
            }
        }
        
        reminderLog("🎉 CONTROLLO COMPLETATO");
        reminderLog("📊 Statistiche:");
        reminderLog("   - Corsi processati: $coursesProcessed");
        reminderLog("   - Notifiche inviate: $totalNotifications");
        
        return [
            'success' => true,
            'courses_processed' => $coursesProcessed,
            'notifications_sent' => $totalNotifications
        ];
        
    } catch (Exception $e) {
        reminderErrorLog("ERRORE FATALE nel processamento promemoria", $e->getMessage());
        return [
            'success' => false,
            'error' => $e->getMessage()
        ];
    }
}

// =============================================================================
// ESECUZIONE PRINCIPALE
// =============================================================================

// Controllo accesso - solo se eseguito direttamente
if (basename($_SERVER['PHP_SELF']) === 'course_reminder_cron.php') {
    if (php_sapi_name() !== 'cli' && !isset($_GET['manual_run'])) {
        reminderErrorLog("ACCESSO NEGATO: Solo da CLI o con manual_run");
        http_response_code(403);
        echo json_encode(['error' => 'Access denied']);
        exit;
    }
}

reminderLog("🕕 CRON JOB PROMEMORIA CORSI AVVIATO");
reminderLog("📅 Data/Ora: " . date('Y-m-d H:i:s T'));

// Controllo database
if (!$conn) {
    reminderErrorLog("ERRORE: Connessione database fallita");
    exit(1);
}

reminderLog("✅ Connessione database OK");

// Esecuzione
$startTime = microtime(true);
$result = processCourseReminders($conn);
$endTime = microtime(true);
$executionTime = round(($endTime - $startTime) * 1000, 2);

reminderLog("⏱️  Tempo esecuzione: {$executionTime}ms");

if ($result['success']) {
    reminderLog("🎉 CRON JOB COMPLETATO CON SUCCESSO");
    reminderLog("📊 SUMMARY: {$result['courses_processed']} corsi, {$result['notifications_sent']} notifiche");
    
    echo "SUCCESS: {$result['courses_processed']} courses, {$result['notifications_sent']} notifications";
    exit(0);
} else {
    reminderErrorLog("💥 CRON JOB FALLITO", $result['error'] ?? 'Unknown error');
    exit(1);
}

$conn->close();
?>

