<?php
// delete_completed_series.php
ob_start(); // Buffer l'output per evitare caratteri indesiderati
error_reporting(0);
ini_set('display_errors', 0);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'DELETE' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Metodo non consentito');
    }

    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['serie_id'])) {
        throw new Exception('ID serie mancante');
    }

    $serie_id = intval($input['serie_id']);

    $deleteStmt = $conn->prepare("DELETE FROM serie_completate WHERE id = ?");
    $deleteStmt->bind_param('i', $serie_id);
    
    if (!$deleteStmt->execute()) {
        throw new Exception('Errore durante l\'eliminazione della serie');
    }
    
    $deleteStmt->close();
    
    ob_clean();
    echo json_encode(['success' => true, 'message' => 'Serie eliminata con successo']);
} catch (Exception $e) {
    ob_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
exit();
?>