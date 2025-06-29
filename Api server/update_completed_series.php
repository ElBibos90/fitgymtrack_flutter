<?php
// update_completed_series.php
ob_start(); // Buffer l'output per evitare caratteri indesiderati
error_reporting(0);
ini_set('display_errors', 0);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Metodo non consentito');
    }

    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['serie_id'], $input['peso'], $input['ripetizioni'])) {
        throw new Exception('Dati mancanti');
    }

    $serie_id = intval($input['serie_id']);
    $peso = floatval($input['peso']);
    $ripetizioni = intval($input['ripetizioni']);

    $updateStmt = $conn->prepare("
        UPDATE serie_completate 
        SET peso = ?, ripetizioni = ? 
        WHERE id = ?
    ");
    
    $updateStmt->bind_param('dii', $peso, $ripetizioni, $serie_id);
    
    if (!$updateStmt->execute()) {
        throw new Exception('Errore durante l\'aggiornamento della serie');
    }
    
    $updateStmt->close();
    
    ob_clean();
    echo json_encode(['success' => true, 'message' => 'Serie aggiornata con successo']);
} catch (Exception $e) {
    ob_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
exit();
?>