<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// standalone_register.php

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

// Leggi input JSON
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['username'], $input['password'], $input['email'], $input['name'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing fields']);
    exit;
}

$username = trim($input['username']);
$password = trim($input['password']);
$email = trim($input['email']);
$name = trim($input['name']);

// Controlla se username o email già esistono
$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
$stmt->bind_param('ss', $username, $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    http_response_code(409);
    echo json_encode(['success' => false, 'message' => 'Username or email already taken']);
    exit;
}

$stmt->close();

// Avvia transazione per garantire coerenza dei dati
$conn->begin_transaction();

try {
    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // Inserisci nuovo utente standalone
    $stmt = $conn->prepare("INSERT INTO users (username, password, email, name, role_id, active, created_at, is_standalone) VALUES (?, ?, ?, ?, ?, 1, NOW(), 1)");
    $role_id = 4; 
    $stmt->bind_param('ssssi', $username, $hashedPassword, $email, $name, $role_id);

    if (!$stmt->execute()) {
        throw new Exception("Errore nella creazione dell'utente: " . $stmt->error);
    }
    
    $userId = $stmt->insert_id;
    $stmt->close();

    // Creazione del profilo utente
    $profileStmt = $conn->prepare("INSERT INTO user_profiles (user_id) VALUES (?)");
    $profileStmt->bind_param('i', $userId);
    
    if (!$profileStmt->execute()) {
        throw new Exception("Errore nella creazione del profilo: " . $profileStmt->error);
    }
    
    $profileStmt->close();

    // Ottieni l'ID del piano Free
    $freePlanStmt = $conn->prepare("SELECT id FROM subscription_plans WHERE name = 'Free' LIMIT 1");
    
    if (!$freePlanStmt->execute()) {
        throw new Exception("Errore nel recupero del piano Free: " . $freePlanStmt->error);
    }
    
    $freePlanResult = $freePlanStmt->get_result();
    
    if ($freePlanResult->num_rows === 0) {
        throw new Exception("Piano Free non trovato nella tabella subscription_plans");
    }
    
    $freePlanId = $freePlanResult->fetch_assoc()['id'];
    $freePlanStmt->close();

    // Imposta il piano corrente dell'utente
    $updateUserStmt = $conn->prepare("UPDATE users SET current_plan_id = ? WHERE id = ?");
    $updateUserStmt->bind_param('ii', $freePlanId, $userId);
    
    if (!$updateUserStmt->execute()) {
        throw new Exception("Errore nell'aggiornamento del piano utente: " . $updateUserStmt->error);
    }
    
    $updateUserStmt->close();

    // Crea l'abbonamento al piano Free
    $subscriptionStmt = $conn->prepare("
        INSERT INTO user_subscriptions 
        (user_id, plan_id, status, start_date, end_date) 
        VALUES (?, ?, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR))
    ");
    $subscriptionStmt->bind_param('ii', $userId, $freePlanId);
    
    if (!$subscriptionStmt->execute()) {
        throw new Exception("Errore nella creazione dell'abbonamento: " . $subscriptionStmt->error);
    }
    
    $subscriptionStmt->close();

    // Commit della transazione
    $conn->commit();
    
    echo json_encode(['success' => true, 'message' => 'User registered successfully', 'userId' => $userId]);

} catch (Exception $e) {
    // Rollback in caso di errore
    $conn->rollback();
    
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}

$conn->close();
?>