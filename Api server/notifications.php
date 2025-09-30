<?php
/**
 * NOTIFICATION SYSTEM - FASE 1
 * API per gestione notifiche in-app
 * 
 * Endpoints:
 * - GET /notifications.php - Recupera notifiche per utente
 * - POST /notifications.php - Invia notifica (singola o broadcast)
 * - PUT /notifications.php?id={id}&action=read - Marca notifica come letta
 * - GET /notifications.php?action=sent - Recupera notifiche inviate (per gym/trainer)
 */

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestisci preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Autenticazione obbligatoria
    $user = authMiddleware($conn, ['gym', 'trainer', 'user', 'standalone']);
    if (!$user) {
        return;
    }

    $method = $_SERVER['REQUEST_METHOD'];
    $action = $_GET['action'] ?? '';

    switch ($method) {
        case 'GET':
            if ($action === 'sent') {
                getSentNotifications($conn, $user);
            } else {
                getUserNotifications($conn, $user);
            }
            break;
            
        case 'POST':
            sendNotification($conn, $user);
            break;
            
        case 'PUT':
            if ($action === 'read') {
                markAsRead($conn, $user);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Azione non valida']);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['error' => 'Metodo non consentito']);
    }

} catch (Exception $e) {
    error_log("Errore notifications.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore interno del server']);
}

/**
 * Recupera le notifiche per l'utente corrente
 */
function getUserNotifications($conn, $user) {
    try {
        $page = max(1, intval($_GET['page'] ?? 1));
        $limit = min(50, max(10, intval($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;
        
        // Query per notifiche dirette e broadcast
        $stmt = $conn->prepare("
            SELECT 
                n.id,
                n.title,
                n.message,
                n.type,
                n.priority,
                CASE 
                    WHEN n.is_broadcast = 1 THEN 
                        CASE WHEN nbl.read_at IS NOT NULL THEN 'read' ELSE 'delivered' END
                    ELSE n.status 
                END as status,
                n.created_at,
                CASE 
                    WHEN n.is_broadcast = 1 THEN nbl.read_at
                    ELSE n.read_at 
                END as read_at,
                n.is_broadcast,
                u.name as sender_name,
                u.username as sender_username
            FROM notifications n
            LEFT JOIN users u ON n.sender_id = u.id
            LEFT JOIN notification_broadcast_log nbl ON n.id = nbl.notification_id AND nbl.recipient_id = ?
            WHERE (
                n.recipient_id = ? OR 
                (n.is_broadcast = 1 AND n.sender_id IN (
                    SELECT id FROM users WHERE gym_id = (
                        SELECT gym_id FROM users WHERE id = ?
                    )
                ))
            )
            ORDER BY n.created_at DESC
            LIMIT ? OFFSET ?
        ");
        
        $stmt->bind_param("iiiii", $user['user_id'], $user['user_id'], $user['user_id'], $limit, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $notifications = [];
        while ($row = $result->fetch_assoc()) {
            $notifications[] = [
                'id' => intval($row['id']),
                'title' => $row['title'],
                'message' => $row['message'],
                'type' => $row['type'],
                'priority' => $row['priority'],
                'status' => $row['status'],
                'created_at' => $row['created_at'],
                'read_at' => $row['read_at'],
                'is_broadcast' => (bool)$row['is_broadcast'],
                'sender_name' => $row['sender_name'],
                'sender_username' => $row['sender_username']
            ];
        }
        
        // Conta totale notifiche
        $countStmt = $conn->prepare("
            SELECT COUNT(*) as total
            FROM notifications n
            WHERE (
                n.recipient_id = ? OR 
                (n.is_broadcast = 1 AND n.sender_id IN (
                    SELECT id FROM users WHERE gym_id = (
                        SELECT gym_id FROM users WHERE id = ?
                    )
                ))
            )
        ");
        $countStmt->bind_param("ii", $user['user_id'], $user['user_id']);
        $countStmt->execute();
        $total = $countStmt->get_result()->fetch_assoc()['total'];
        
        echo json_encode([
            'success' => true,
            'notifications' => $notifications,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => intval($total),
                'pages' => ceil($total / $limit)
            ]
        ]);
        
    } catch (Exception $e) {
        error_log("Errore getUserNotifications: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero delle notifiche']);
    }
}

/**
 * Recupera le notifiche inviate dall'utente corrente (per gym/trainer)
 */
function getSentNotifications($conn, $user) {
    try {
        // Solo gym e trainer possono vedere le notifiche inviate
        if (!hasRole($user, 'gym') && !hasRole($user, 'trainer')) {
            http_response_code(403);
            echo json_encode(['error' => 'Non autorizzato']);
            return;
        }
        
        $page = max(1, intval($_GET['page'] ?? 1));
        $limit = min(50, max(10, intval($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;
        
        $stmt = $conn->prepare("
            SELECT 
                n.id,
                n.title,
                n.message,
                n.type,
                n.priority,
                n.status,
                n.created_at,
                n.is_broadcast,
                u.name as recipient_name,
                u.username as recipient_username,
                COUNT(nbl.id) as delivered_count,
                COUNT(CASE WHEN nbl.read_at IS NOT NULL THEN 1 END) as read_count
            FROM notifications n
            LEFT JOIN users u ON n.recipient_id = u.id
            LEFT JOIN notification_broadcast_log nbl ON n.id = nbl.notification_id
            WHERE n.sender_id = ?
            GROUP BY n.id
            ORDER BY n.created_at DESC
            LIMIT ? OFFSET ?
        ");
        
        $stmt->bind_param("iii", $user['user_id'], $limit, $offset);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $notifications = [];
        while ($row = $result->fetch_assoc()) {
            $notifications[] = [
                'id' => intval($row['id']),
                'title' => $row['title'],
                'message' => $row['message'],
                'type' => $row['type'],
                'priority' => $row['priority'],
                'status' => $row['status'],
                'created_at' => $row['created_at'],
                'is_broadcast' => (bool)$row['is_broadcast'],
                'recipient_name' => $row['recipient_name'],
                'recipient_username' => $row['recipient_username'],
                'delivered_count' => intval($row['delivered_count']),
                'read_count' => intval($row['read_count'])
            ];
        }
        
        echo json_encode([
            'success' => true,
            'notifications' => $notifications,
            'pagination' => [
                'page' => $page,
                'limit' => $limit
            ]
        ]);
        
    } catch (Exception $e) {
        error_log("Errore getSentNotifications: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero delle notifiche inviate']);
    }
}

/**
 * Invia una notifica (singola o broadcast)
 */
function sendNotification($conn, $user) {
    try {
        // Solo gym e trainer possono inviare notifiche
        if (!hasRole($user, 'gym') && !hasRole($user, 'trainer')) {
            http_response_code(403);
            echo json_encode(['error' => 'Non autorizzato a inviare notifiche']);
            return;
        }
        
        $input = json_decode(file_get_contents("php://input"), true);
        
        // Validazione input
        if (!isset($input['title']) || !isset($input['message'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Titolo e messaggio sono obbligatori']);
            return;
        }
        
        $title = trim($input['title']);
        $message = trim($input['message']);
        $type = $input['type'] ?? 'message';
        $priority = $input['priority'] ?? 'normal';
        $recipient_id = $input['recipient_id'] ?? null;
        $is_broadcast = $input['is_broadcast'] ?? false;
        
        // Validazione campi
        if (empty($title) || empty($message)) {
            http_response_code(400);
            echo json_encode(['error' => 'Titolo e messaggio non possono essere vuoti']);
            return;
        }
        
        if (!in_array($type, ['message', 'announcement', 'reminder'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Tipo notifica non valido']);
            return;
        }
        
        if (!in_array($priority, ['low', 'normal', 'high'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Priorità non valida']);
            return;
        }
        
        // Se non è broadcast, verifica che il destinatario appartenga alla stessa palestra
        if (!$is_broadcast && $recipient_id) {
            $accessStmt = $conn->prepare("
                SELECT u1.id 
                FROM users u1 
                JOIN users u2 ON u1.gym_id = u2.gym_id
                WHERE u1.id = ? AND u2.id = ? AND u1.gym_id IS NOT NULL
            ");
            $accessStmt->bind_param("ii", $recipient_id, $user['user_id']);
            $accessStmt->execute();
            $accessResult = $accessStmt->get_result();
            
            if ($accessResult->num_rows === 0) {
                http_response_code(403);
                echo json_encode(['error' => 'Non autorizzato a inviare notifiche a questo utente']);
                return;
            }
        }
        
        $conn->begin_transaction();
        
        try {
            // Determina il tipo di sender
            $sender_type = hasRole($user, 'gym') ? 'gym' : 'trainer';
            
            // Inserisci la notifica
            $stmt = $conn->prepare("
                INSERT INTO notifications (
                    sender_id, sender_type, recipient_id, title, message, 
                    type, priority, is_broadcast, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
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
            
            if (!$stmt->execute()) {
                throw new Exception("Errore nell'inserimento della notifica: " . $stmt->error);
            }
            
            $notification_id = $stmt->insert_id;
            
            // Se è broadcast, crea i log solo per i membri (ruolo 'user') della palestra
            if ($is_broadcast) {
                $broadcastStmt = $conn->prepare("
                    INSERT INTO notification_broadcast_log (notification_id, recipient_id, delivered_at)
                    SELECT ?, u.id, NOW()
                    FROM users u
                    JOIN users sender ON u.gym_id = sender.gym_id
                    JOIN user_role r ON u.role_id = r.id
                    WHERE sender.id = ? AND u.gym_id IS NOT NULL AND u.id != ? AND r.name = 'user'
                ");
                $broadcastStmt->bind_param("iii", $notification_id, $user['user_id'], $user['user_id']);
                $broadcastStmt->execute();
            }
            
            $conn->commit();
            
            // Invia push notification
            try {
                $pushPayload = [
                    'title' => $title,
                    'message' => $message,
                    'type' => $type,
                    'priority' => $priority,
                    'recipient_id' => $recipient_id,
                    'is_broadcast' => $is_broadcast,
                    'user_data' => $user,  // Passa i dati utente direttamente
                    'notification_id' => $notification_id  // Passa l'ID della notifica già creata
                ];
                
                // Chiama l'API push notification con percorso corretto
                $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
                $host = $_SERVER['HTTP_HOST'];
                $pushUrl = $protocol . '://' . $host . '/api/firebase/send_push_notification_v1.php';
                
                $pushResponse = file_get_contents($pushUrl, false, stream_context_create([
                    'http' => [
                        'method' => 'POST',
                        'header' => 'Content-Type: application/json',
                        'content' => json_encode($pushPayload)
                    ]
                ]));
                
                if ($pushResponse === false) {
                    error_log('Push notification failed: ' . error_get_last()['message']);
                } else {
                    error_log('Push notification response: ' . $pushResponse);
                }
            } catch (Exception $pushError) {
                error_log('Push notification error: ' . $pushError->getMessage());
                // Non bloccare il processo se la push fallisce
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Notifica inviata con successo',
                'notification_id' => $notification_id
            ]);
            
        } catch (Exception $e) {
            $conn->rollback();
            throw $e;
        }
        
    } catch (Exception $e) {
        error_log("Errore sendNotification: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'invio della notifica']);
    }
}

/**
 * Marca una notifica come letta
 */
function markAsRead($conn, $user) {
    try {
        $notification_id = $_GET['id'] ?? null;
        
        if (!$notification_id) {
            http_response_code(400);
            echo json_encode(['error' => 'ID notifica richiesto']);
            return;
        }
        
        // Verifica che la notifica appartenga all'utente
        $checkStmt = $conn->prepare("
            SELECT n.id, n.recipient_id, n.is_broadcast, n.sender_id
            FROM notifications n
            WHERE n.id = ? AND (
                n.recipient_id = ? OR 
                (n.is_broadcast = 1 AND n.sender_id IN (
                    SELECT id FROM users WHERE gym_id = (
                        SELECT gym_id FROM users WHERE id = ?
                    )
                ))
            )
        ");
        $checkStmt->bind_param("iii", $notification_id, $user['user_id'], $user['user_id']);
        $checkStmt->execute();
        $notification = $checkStmt->get_result()->fetch_assoc();
        
        if (!$notification) {
            http_response_code(404);
            echo json_encode(['error' => 'Notifica non trovata']);
            return;
        }
        
        $conn->begin_transaction();
        
        try {
            // Se è broadcast, aggiorna solo il log specifico dell'utente
            if ($notification['is_broadcast']) {
                $logStmt = $conn->prepare("
                    UPDATE notification_broadcast_log 
                    SET read_at = NOW() 
                    WHERE notification_id = ? AND recipient_id = ?
                ");
                $logStmt->bind_param("ii", $notification_id, $user['user_id']);
                $logStmt->execute();
            } else {
                // Per notifiche singole, aggiorna la notifica principale
                $updateStmt = $conn->prepare("
                    UPDATE notifications 
                    SET status = 'read', read_at = NOW() 
                    WHERE id = ?
                ");
                $updateStmt->bind_param("i", $notification_id);
                $updateStmt->execute();
            }
            
            $conn->commit();
            
            echo json_encode([
                'success' => true,
                'message' => 'Notifica marcata come letta'
            ]);
            
        } catch (Exception $e) {
            $conn->rollback();
            throw $e;
        }
        
    } catch (Exception $e) {
        error_log("Errore markAsRead: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'aggiornamento della notifica']);
    }
}
?>
