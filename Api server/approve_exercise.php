<?php
// API per approvare o rifiutare gli esercizi (admin)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

// Recupera il token di autenticazione
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);

// Verifica l'autenticazione e il ruolo dell'utente
$user = validateAuthToken($conn, $token);

// Controllo accesso: solo gli admin possono approvare/rifiutare esercizi
if (!$user || !hasRole($user, 'admin')) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Accesso non autorizzato. Questa operazione richiede privilegi di amministratore.']);
    exit;
}

// Verifica il metodo della richiesta
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
    exit;
}

// Decodifica il JSON ricevuto
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['exercise_id'], $input['action'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Dati mancanti']);
    exit;
}

$exercise_id = intval($input['exercise_id']);
$action = $input['action'];

if (!in_array($action, ['approve', 'reject'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Azione non valida']);
    exit;
}

try {
    // Aggiorna lo stato dell'esercizio in base all'azione
    $status = $action === 'approve' ? 'approved' : 'user_only';
    
    $stmt = $conn->prepare("UPDATE esercizi SET status = ? WHERE id = ?");
    $stmt->bind_param('si', $status, $exercise_id);
    
    if (!$stmt->execute()) {
        throw new Exception("Errore nell'aggiornamento: " . $stmt->error);
    }
    
    if ($stmt->affected_rows === 0) {
        throw new Exception("Nessun esercizio trovato con ID: $exercise_id");
    }
    
    $stmt->close();
    
    // Prova a registrare l'azione per audit SOLO se la tabella esiste
    // Verifica se la tabella admin_actions_log esiste
    $tableExistsQuery = "SHOW TABLES LIKE 'admin_actions_log'";
    $tableExists = $conn->query($tableExistsQuery)->num_rows > 0;
    
    if ($tableExists) {
        // Registra l'azione solo se la tabella esiste
        $admin_id = $user['user_id'];
        $logStmt = $conn->prepare("
            INSERT INTO admin_actions_log 
            (user_id, action_type, target_table, target_id, status_change, action_date) 
            VALUES (?, ?, 'esercizi', ?, ?, NOW())
        ");
        
        $action_type = $action === 'approve' ? 'exercise_approval' : 'exercise_rejection';
        
        if ($logStmt) {
            $logStmt->bind_param('isis', $admin_id, $action_type, $exercise_id, $status);
            $logStmt->execute();
            $logStmt->close();
        }
    }
    
    // Restituisci il risultato
    echo json_encode([
        'success' => true,
        'message' => $action === 'approve' ? 'Esercizio approvato con successo' : 'Esercizio rifiutato con successo',
        'exercise_id' => $exercise_id,
        'status' => $status
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Errore: ' . $e->getMessage()
    ]);
}

$conn->close();
?>