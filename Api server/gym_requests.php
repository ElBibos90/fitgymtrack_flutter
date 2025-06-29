<?php
// /api/admin/gym_requests.php
// Restituisce tutte le richieste delle palestre

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

// Recupera tutte le richieste
$stmt = $conn->prepare("SELECT * FROM gym_requests ORDER BY created_at DESC");
$stmt->execute();
$result = $stmt->get_result();

$requests = [];
while ($row = $result->fetch_assoc()) {
    $requests[] = $row;
}

echo json_encode([
    'success' => true,
    'requests' => $requests
]);

$stmt->close();
$conn->close();
?>