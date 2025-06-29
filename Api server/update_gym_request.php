<?php
// /api/admin/update_gym_request.php
// Aggiorna lo stato di una richiesta palestra

// Include i file necessari
include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

// Verifica l'autenticazione dell'admin
$authHeader = getAuthorizationHeader();
$token = str_replace('Bearer ', '', $authHeader);
$user = validateAuthToken($conn, $token);

if (!$user || !hasRole($user, 'admin')) {
    http_response_code(403);
    echo json_encode(['error' => 'Accesso non autorizzato']);
    exit;
}

// Leggi il corpo della richiesta
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['requestId']) || !isset($input['status'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Dati mancanti']);
    exit;
}

$requestId = intval($input['requestId']);
$status = $input['status'];

// Verifica che lo stato sia valido
if (!in_array($status, ['pending', 'approved', 'rejected'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Stato non valido']);
    exit;
}

// Aggiorna lo stato della richiesta
$stmt = $conn->prepare("UPDATE gym_requests SET status = ? WHERE id = ?");
$stmt->bind_param("si", $status, $requestId);

if ($stmt->execute()) {
    // Se la richiesta è stata approvata, qui potresti voler creare un account per la palestra
    if ($status === 'approved') {
        // Recupera le informazioni della richiesta
        $getRequest = $conn->prepare("SELECT * FROM gym_requests WHERE id = ?");
        $getRequest->bind_param("i", $requestId);
        $getRequest->execute();
        $request = $getRequest->get_result()->fetch_assoc();
        $getRequest->close();
        
        if ($request) {
            // Qui potresti implementare la logica per creare un account per la palestra
            // e inviare una email con le credenziali
            
            // Esempio (da implementare secondo le tue necessità):
            /*
            $username = generateUsername($request['gym_name']);
            $password = generateRandomPassword();
            $email = $request['email'];
            
            // Crea l'account
            createGymAccount($username, $password, $email, $request['gym_name']);
            
            // Invia email con le credenziali
            sendCredentialsEmail($email, $username, $password);
            */
        }
    }
    
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Errore durante l\'aggiornamento']);
}

$stmt->close();
$conn->close();
?>