<?php
// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - accetta richieste da localhost:3000
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

    exit(0);
}

header('Content-Type: application/json');

include 'config.php';
require_once 'auth_functions.php';

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'POST':
        $input = file_get_contents("php://input");
        $data = json_decode($input, true);
        
        // Determina l'azione in base all'endpoint
        $action = isset($_GET['action']) ? $_GET['action'] : '';
        
        switch($action) {
            case 'login':
                handleLogin($conn, $data);
                break;
                
            case 'logout':
                handleLogout($conn, $data);
                break;
                
            case 'verify':
            case 'verify_token':
                verifyToken($conn);
                break;
                
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata']);
        }
        break;
        
    // 🔧 FIX: Aggiungi supporto per GET requests
    case 'GET':
        $action = isset($_GET['action']) ? $_GET['action'] : '';
        
        switch($action) {
            case 'verify':
            case 'verify_token':
                verifyToken($conn);
                break;
                
            default:
                http_response_code(400);
                echo json_encode(['error' => 'Azione non specificata per GET']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

function handleLogin($conn, $data) {
    error_log("Login attempt for username: " . $data['username']);
    if (!isset($data['username']) || !isset($data['password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Username e password sono obbligatori']);
        return;
    }
    
    $username = $data['username'];
    $password = $data['password'];
    
    error_log("Looking up user in database: " . $username);

    // Recupera l'utente dal database
    $stmt = $conn->prepare("
        SELECT u.id, u.username, u.password, u.email, u.name, u.role_id, 
               r.name as role_name, u.trainer_id,
               t.username as trainer_username, t.name as trainer_name
        FROM users u
        JOIN user_role r ON u.role_id = r.id
        LEFT JOIN users t ON u.trainer_id = t.id
        WHERE u.username = ? AND u.active = 1
    ");
    
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    
    if (!$user || !password_verify($password, $user['password'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Credenziali non valide']);
        return;
    }
    
    // 🔒 CONTROLLO ACCESSO WEBAPP: Blocca utenti "user" dalla webapp
    $platform = detectPlatform();
    if ($platform === 'webapp' && $user['role_name'] === 'user') {
        http_response_code(403);
        echo json_encode([
            'error' => 'ACCESS_DENIED_WEBAPP',
            'message' => 'Accesso negato: questa piattaforma è riservata a trainer, gestori palestra, amministratori e utenti standalone. Per accedere alle funzionalità della palestra, utilizza l\'app mobile FitGymTrack.'
        ]);
        return;
    }
    
    error_log("User found, verifying password for: " . $username);
    error_log("Stored password hash: " . $user['password']);

    // Password corretta, genera token
    $token = generateAuthToken($conn, $user['id']);
    
    if (!$token) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella generazione del token']);
        return;
    }
    
    // Aggiorna ultimo accesso
    $updateStmt = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
    $updateStmt->bind_param("i", $user['id']);
    $updateStmt->execute();
    
    // Ritorna i dati utente e il token (escludendo la password)
    unset($user['password']);
    
    // Aggiungi informazioni sul trainer
    if ($user['trainer_id']) {
        $user['trainer'] = [
            'id' => $user['trainer_id'],
            'username' => $user['trainer_username'],
            'name' => $user['trainer_name']
        ];
    }
    
    // Rimuovi campi ridondanti
    unset($user['trainer_id']);
    unset($user['trainer_username']);
    unset($user['trainer_name']);
    
    echo json_encode([
        'user' => $user,
        'token' => $token,
        'message' => 'Login effettuato con successo'
    ]);
}

function handleLogout($conn, $data) {
    if (!isset($data['token'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Token mancante']);
        return;
    }
    
    $token = $data['token'];
    $success = invalidateToken($conn, $token);
    
    if ($success) {
        echo json_encode(['message' => 'Logout effettuato con successo']);
    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Token non valido o già scaduto']);
    }
}

function verifyToken($conn) {
    $authHeader = getAuthorizationHeader();
    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(['error' => 'Token mancante']);
        return;
    }
    
    // Estrai il token dall'header
    $token = str_replace('Bearer ', '', $authHeader);
    
    $userData = validateAuthToken($conn, $token);
    if (!$userData) {
        http_response_code(401);
        echo json_encode(['error' => 'Token non valido o scaduto']);
        return;
    }
    
    // Se l'utente ha un trainer, recupera le sue informazioni
    if ($userData['trainer_id']) {
        $stmt = $conn->prepare("
            SELECT id, username, name, email
            FROM users
            WHERE id = ?
        ");
        $stmt->bind_param("i", $userData['trainer_id']);
        $stmt->execute();
        $trainer = $stmt->get_result()->fetch_assoc();
        
        $userData['trainer'] = $trainer;
    }
    
    echo json_encode([
        'valid' => true,
        'user' => $userData,
        'message' => 'Token valido'
    ]);
}

$conn->close();
?>