<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Impostazioni iniziali - nessun header Content-Type qui
include 'config.php';

// CORS headers - accetta richieste dalle origini consentite
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

    exit(0); // Return early with a 200 status code
}

// Imposta percorso per allegati
$upload_dir = '/var/www/html/uploads/feedback/';

// ===== IMPORTANTE: VERIFICA VIEW/DOWNLOAD PRIMA DELL'AUTENTICAZIONE =====
// Gestione delle richieste per view/download (senza autenticazione)
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['action'])) {
    if (($_GET['action'] === 'download' || $_GET['action'] === 'view') && isset($_GET['file'])) {
        // Per queste azioni non richiediamo autenticazione
        serveFile($_GET['file'], $_GET['action'] === 'download');
        exit;
    }
}

// Per tutte le altre richieste, richiedi l'autenticazione
header('Content-Type: application/json');
require_once 'auth_functions.php';

// Verifica la sessione/autenticazione (usando il sistema esistente)
$auth_result = authMiddleware($conn);
if (!$auth_result) {
    exit; // authMiddleware ha già restituito l'errore
}
$user_id = $auth_result['user_id'];

if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

// Funzione per sanitizzare l'input
function sanitizeInput($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

// Gestione delle richieste
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'POST':
        handlePostRequest();
        break;
    case 'GET':
        // Qui gestiamo solo la richiesta per ottenere i feedback (la view/download è già gestita sopra)
        handleGetRequest();
        break;
    default:
        echo json_encode([
            'success' => false,
            'message' => 'Metodo non supportato'
        ]);
        break;
}

function serveFile($filename, $isDownload = true) {
    global $upload_dir;
    
    // Prevent directory traversal attacks
    $filename = basename($filename);
    $filepath = $upload_dir . $filename;
    
    error_log("Serving file: " . $filename . " from path: " . $filepath);
    
    if (!file_exists($filepath)) {
        header("HTTP/1.1 404 Not Found");
        echo "File non trovato: " . $filename;
        exit;
    }
    
    // Determine MIME type based on file extension
    $ext = strtolower(pathinfo($filepath, PATHINFO_EXTENSION));
    $mime_types = [
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];
    
    $content_type = isset($mime_types[$ext]) ? $mime_types[$ext] : 'application/octet-stream';
    
    // IMPORTANTE: Aggiungi questi header CORS per consentire la visualizzazione
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: GET, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type");
    
    // Imposta gli header appropriati
    header("Content-Type: $content_type");
    
    // Imposta Content-Disposition in base a se stiamo scaricando o visualizzando
    if ($isDownload) {
        header("Content-Disposition: attachment; filename=\"$filename\"");
    } else {
        header("Content-Disposition: inline; filename=\"$filename\"");
    }
    
    header("Content-Length: " . filesize($filepath));
    header("Cache-Control: public, max-age=86400");
    readfile($filepath);
    exit; // Assicurati che lo script termini dopo aver inviato il file
}

function handleStatusUpdate($data) {
    global $conn;
    
    // Validate required parameters
    if (!isset($data['feedback_id']) || !isset($data['status'])) {
        echo json_encode([
            'success' => false,
            'message' => 'Parametri mancanti'
        ]);
        exit;
    }
    
    $feedback_id = intval($data['feedback_id']);
    $status = sanitizeInput($data['status']);
    
    // Validate status
    $valid_statuses = ['new', 'in_progress', 'closed', 'rejected'];
    if (!in_array($status, $valid_statuses)) {
        echo json_encode([
            'success' => false,
            'message' => 'Stato non valido'
        ]);
        exit;
    }
    
    try {
        $stmt = $conn->prepare("UPDATE feedback SET status = ?, updated_at = NOW() WHERE id = ?");
        $stmt->bind_param("si", $status, $feedback_id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Stato aggiornato con successo'
            ]);
        } else {
            throw new Exception("Errore nell'aggiornamento dello stato: " . $stmt->error);
        }
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    }
}

function handleNotesUpdate($data) {
    global $conn;
    
    // Validate required parameters
    if (!isset($data['feedback_id']) || !isset($data['admin_notes'])) {
        echo json_encode([
            'success' => false,
            'message' => 'Parametri mancanti'
        ]);
        exit;
    }
    
    $feedback_id = intval($data['feedback_id']);
    $notes = sanitizeInput($data['admin_notes']);
    
    try {
        $stmt = $conn->prepare("UPDATE feedback SET admin_notes = ?, updated_at = NOW() WHERE id = ?");
        $stmt->bind_param("si", $notes, $feedback_id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Note aggiornate con successo'
            ]);
        } else {
            throw new Exception("Errore nell'aggiornamento delle note: " . $stmt->error);
        }
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    }
}
/**
 * Gestisce le richieste POST (invia feedback)
 */
function handlePostRequest() {
    global $conn, $user_id, $upload_dir;
        // Get JSON data for non-multipart requests
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
    
    // Check if this is an action request
    if (isset($data['action'])) {
        switch($data['action']) {
            case 'update_status':
                handleStatusUpdate($data);
                return;
            case 'update_notes':
                handleNotesUpdate($data);
                return;
        }
    }
    
    // Debug: Verifica permessi della directory di upload
    $testfile = $upload_dir . "test.txt";
    $test_result = file_put_contents($testfile, "Test write");
    error_log("Test file write nella directory upload: " . ($test_result !== false ? "Successo" : "Fallito"));
    if (file_exists($testfile)) {
        unlink($testfile);
    }
    
    // Controlla se è una richiesta multipart/form-data (con allegati)
    $contentType = isset($_SERVER["CONTENT_TYPE"]) ? trim($_SERVER["CONTENT_TYPE"]) : '';
    
    // Debug: Registra content type
    error_log("Content-Type ricevuto: " . $contentType);
    
    // Gestiamo il device info prima di elaborare il resto dei dati
    $device_info_raw = isset($_POST['device_info']) ? $_POST['device_info'] : '{}';
    error_log("Device info raw: " . $device_info_raw);
    
    // Gestione più robusta del JSON device_info
    try {
        $device_info_array = json_decode($device_info_raw, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            // Non terminiamo, solo log dell'errore e usiamo array vuoto
            error_log("Errore nel parsing JSON del device_info: " . json_last_error_msg());
            $device_info_array = [];
        }
    } catch (Exception $e) {
        error_log("Eccezione nel parsing device_info: " . $e->getMessage());
        $device_info_array = [];
    }
    
    $device_info = json_encode($device_info_array);

    if (strpos($contentType, 'multipart/form-data') !== false) {
        // Debug: Registra dettagli dei file ricevuti
        error_log("FILES ricevuti: " . print_r($_FILES, true));
        
        // Gestione del form con allegati
        $feedbackData = [
            'type' => sanitizeInput($_POST['type'] ?? 'bug'),
            'title' => sanitizeInput($_POST['title'] ?? ''),
            'description' => sanitizeInput($_POST['description'] ?? ''),
            'email' => sanitizeInput($_POST['email'] ?? ''),
            'severity' => sanitizeInput($_POST['severity'] ?? 'medium'),
            'device_info' => $device_info,
        ];
        
        // Validazione
        $validation = validateFeedbackData($feedbackData);
        if (!$validation['valid']) {
            echo json_encode([
                'success' => false,
                'message' => $validation['message'],
                'error_code' => 'validation_error'
            ]);
            exit;
        }
        
        // Gestione allegati
        $attachments = [];
        if (isset($_FILES['attachments'])) {
            $files = reArrayFiles($_FILES['attachments']);
            
            foreach ($files as $file) {
                // Verifica che non ci siano errori nel caricamento
                if ($file['error'] === UPLOAD_ERR_OK) {
                    // Controlla dimensione massima (5MB)
                    if ($file['size'] > 5 * 1024 * 1024) {
                        error_log("File troppo grande: " . $file['name'] . " - size: " . $file['size']);
                        continue; // Salta file troppo grandi
                    }
                    
                    // Debug: Verifica esistenza file temporaneo
                    error_log("File temporaneo esiste: " . (file_exists($file['tmp_name']) ? "Sì" : "No"));
                    error_log("Dimensione file temporaneo: " . (file_exists($file['tmp_name']) ? filesize($file['tmp_name']) : "N/A"));
                    
                    // Genera nome file unico
                    $fileName = uniqid() . '_' . basename($file['name']);
                    $targetFilePath = $upload_dir . $fileName;
                    
                    // Sposta il file nella cartella uploads
                    if (move_uploaded_file($file['tmp_name'], $targetFilePath)) {
                        error_log("File caricato con successo: " . $targetFilePath . " - size: " . filesize($targetFilePath));
                        $attachments[] = [
                            'filename' => $fileName,
                            'original_name' => basename($file['name']),
                            'size' => $file['size'],
                            'path' => $targetFilePath
                        ];
                        chmod($targetFilePath, 0644);
                        error_log("File permissions set to: " . substr(sprintf('%o', fileperms($targetFilePath)), -4));
                    } else {
                        error_log("Errore nel caricamento del file: " . error_get_last()['message']);
                    }
                } else {
                    error_log("Errore nel file upload: codice " . $file['error']);
                }
            }
        }
    } else {
        // Gestione JSON (senza allegati)
        $json = file_get_contents('php://input');
        $data = json_decode($json, true);
        
        if (!$data) {
            echo json_encode([
                'success' => false,
                'message' => 'Dati non validi'
            ]);
            exit;
        }
        
        $feedbackData = [
            'type' => sanitizeInput($data['type'] ?? 'bug'),
            'title' => sanitizeInput($data['title'] ?? ''),
            'description' => sanitizeInput($data['description'] ?? ''),
            'email' => sanitizeInput($data['email'] ?? ''),
            'severity' => sanitizeInput($data['severity'] ?? 'medium'),
            'device_info' => $device_info,
        ];
        
        // Validazione
        $validation = validateFeedbackData($feedbackData);
        if (!$validation['valid']) {
            echo json_encode([
                'success' => false,
                'message' => $validation['message'],
                'error_code' => 'validation_error'
            ]);
            exit;
        }
        
        $attachments = []; // Nessun allegato in richieste JSON
    }
    
    try {
        // Connessione al database
        if ($conn->connect_error) {
            throw new Exception("Connessione fallita: " . $conn->connect_error);
        }
        
        // Inizio transazione
        $conn->begin_transaction();
        
        // Inserisci il feedback nel database
        $stmt = $conn->prepare("INSERT INTO feedback (user_id, type, title, description, email, severity, device_info, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 'new', NOW())");
        
        $status = 'new';
        $stmt->bind_param("issssss", 
            $user_id, 
            $feedbackData['type'], 
            $feedbackData['title'], 
            $feedbackData['description'],
            $feedbackData['email'],
            $feedbackData['severity'],
            $feedbackData['device_info']
        );
        
        if (!$stmt->execute()) {
            throw new Exception("Errore nell'inserimento del feedback: " . $stmt->error);
        }
        
        $feedback_id = $conn->insert_id;
        
        // Inserisci gli allegati nel database
        if (!empty($attachments)) {
            $stmt = $conn->prepare("INSERT INTO feedback_attachments (feedback_id, filename, original_name, file_size, file_path) VALUES (?, ?, ?, ?, ?)");
            
            foreach ($attachments as $attachment) {
                $stmt->bind_param("issis", 
                    $feedback_id,
                    $attachment['filename'],
                    $attachment['original_name'],
                    $attachment['size'],
                    $attachment['path']
                );
                
                if (!$stmt->execute()) {
                    throw new Exception("Errore nell'inserimento dell'allegato: " . $stmt->error);
                }
            }
        }
        
        // Commit della transazione
        $conn->commit();
        
        // Invia email di notifica (opzionale)
        sendNotificationEmail($feedbackData, $feedback_id);
        
        echo json_encode([
            'success' => true,
            'message' => 'Feedback inviato con successo',
            'feedback_id' => $feedback_id,
            'attachments_count' => count($attachments)
        ]);
        
    } catch (Exception $e) {
        // Rollback in caso di errore
        if ($conn && $conn->ping()) {
            $conn->rollback();
        }
        
        error_log("Errore nell'API di feedback: " . $e->getMessage());
        
        echo json_encode([
            'success' => false,
            'message' => 'Si è verificato un errore durante il salvataggio del feedback',
            'debug' => $e->getMessage()
        ]);
    } finally {
        if ($conn && $conn->ping()) {
            $conn->close();
        }
    }
}

/**
 * Gestisce le richieste GET (recupera feedback - solo per admin)
 */
function handleGetRequest() {
    global $conn, $user_id;
    
    // Verifica se l'utente è admin
    if (!isUserAdmin($user_id)) {
        echo json_encode([
            'success' => false,
            'message' => 'Permesso negato'
        ]);
        exit;
    }
    
    try {
        // Connessione al database
        if ($conn->connect_error) {
            throw new Exception("Connessione fallita: " . $conn->connect_error);
        }
        
        // Recupera i feedback
        $stmt = $conn->prepare("
            SELECT f.id, f.user_id, f.type, f.title, f.description, f.email, 
                   f.severity, f.device_info, f.status, f.created_at,
                   u.username, u.name
            FROM feedback f
            LEFT JOIN users u ON f.user_id = u.id
            ORDER BY f.created_at DESC
        ");
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $feedbacks = [];
        while ($row = $result->fetch_assoc()) {
            // Recupera gli allegati per questo feedback
            $attach_stmt = $conn->prepare("
                SELECT id, filename, original_name, file_size 
                FROM feedback_attachments 
                WHERE feedback_id = ?
            ");
            
            $attach_stmt->bind_param("i", $row['id']);
            $attach_stmt->execute();
            $attach_result = $attach_stmt->get_result();
            
            $attachments = [];
            while ($attach = $attach_result->fetch_assoc()) {
                $attachments[] = $attach;
            }
            
            $row['attachments'] = $attachments;
            $feedbacks[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'feedbacks' => $feedbacks
        ]);
        
    } catch (Exception $e) {
        error_log("Errore nel recupero dei feedback: " . $e->getMessage());
        
        echo json_encode([
            'success' => false,
            'message' => 'Si è verificato un errore durante il recupero dei feedback',
            'debug' => $e->getMessage()
        ]);
    } finally {
        if ($conn && $conn->ping()) {
            $conn->close();
        }
    }
}

/**
 * Funzione di validazione dati
 */
function validateFeedbackData($data) {
    // Verifica i campi obbligatori
    if (empty($data['title'])) {
        return ['valid' => false, 'message' => 'Il titolo è obbligatorio'];
    }
    
    if (empty($data['description'])) {
        return ['valid' => false, 'message' => 'La descrizione è obbligatoria'];
    }
    
    if (strlen($data['description']) < 10) {
        return ['valid' => false, 'message' => 'La descrizione è troppo breve'];
    }
    
    if (empty($data['email'])) {
        return ['valid' => false, 'message' => 'L\'email è obbligatoria'];
    }
    
    // Verifica formato email
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        return ['valid' => false, 'message' => 'Formato email non valido'];
    }
    
    return ['valid' => true];
}

/**
 * Funzione per inviare email di notifica
 */
function sendNotificationEmail($feedbackData, $feedback_id) {
    // Questa è una implementazione di esempio, da personalizzare
    $admin_email = 'fitgymtrack@gmail.com';
    $subject = "Nuovo feedback: " . $feedbackData['title'];
    
    $message = "È stato ricevuto un nuovo feedback:\n\n";
    $message .= "ID: " . $feedback_id . "\n";
    $message .= "Tipo: " . $feedbackData['type'] . "\n";
    $message .= "Titolo: " . $feedbackData['title'] . "\n";
    $message .= "Gravità: " . $feedbackData['severity'] . "\n";
    $message .= "Email: " . $feedbackData['email'] . "\n\n";
    $message .= "Descrizione:\n" . $feedbackData['description'] . "\n\n";
    $message .= "Accedi al pannello di amministrazione per maggiori dettagli.";
    
    $headers = "From: noreply@fitgymtrack.com";
    
    // Invia l'email (disattivabile)
    if (defined('ENABLE_EMAIL_NOTIFICATIONS') && ENABLE_EMAIL_NOTIFICATIONS) {
        mail($admin_email, $subject, $message, $headers);
    }
}

/**
 * Funzione per riorganizzare l'array dei file
 */
function reArrayFiles($file_post) {
    $file_ary = array();
    $file_count = count($file_post['name']);
    $file_keys = array_keys($file_post);
    
    for ($i = 0; $i < $file_count; $i++) {
        foreach ($file_keys as $key) {
            $file_ary[$i][$key] = $file_post[$key][$i];
        }
    }
    
    return $file_ary;
}

/**
 * Verifica se l'utente è admin
 */
function isUserAdmin($user_id) {
    global $conn;
    
    $stmt = $conn->prepare("SELECT user_role.name FROM users INNER JOIN user_role on users.role_id = user_role.id WHERE users.id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        return $row['name'] === 'admin';
    }
    
    return false;
}