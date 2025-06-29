<?php
// delete_allenamento_standalone.php
ob_start(); // Buffer l'output per evitare caratteri indesiderati
error_reporting(0); // Disabilita tutti gli errori
ini_set('display_errors', 0);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'DELETE' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Metodo non consentito');
    }

    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['allenamento_id'])) {
        throw new Exception('ID allenamento mancante');
    }

    $allenamento_id = intval($input['allenamento_id']);

    $conn->begin_transaction();

    try {
        // Prima elimina tutte le serie associate
        $deleteSerieStmt = $conn->prepare("DELETE FROM serie_completate WHERE allenamento_id = ?");
        $deleteSerieStmt->bind_param('i', $allenamento_id);
        $deleteSerieStmt->execute();
        $deleteSerieStmt->close();

        // Poi elimina l'allenamento
        $deleteAllenamentoStmt = $conn->prepare("DELETE FROM allenamenti WHERE id = ?");
        $deleteAllenamentoStmt->bind_param('i', $allenamento_id);
        $deleteAllenamentoStmt->execute();
        $deleteAllenamentoStmt->close();

        $conn->commit();
        
        // Pulisci il buffer e invia solo il JSON
        ob_clean();
        echo json_encode(['success' => true, 'message' => 'Allenamento eliminato con successo']);
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }
} catch (Exception $e) {
    ob_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
exit(); // Assicurati che non venga aggiunto nulla dopo il JSON
?>