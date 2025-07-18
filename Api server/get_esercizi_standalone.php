<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';

header('Content-Type: application/json');

try {
    // Recupera l'ID utente se presente
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    
    // Costruisci la query per ottenere:
    // 1. Tutti gli esercizi approvati (status = 'approved' o NULL)
    // 2. PLUS tutti gli esercizi creati dall'utente (indipendentemente dallo stato)
    $query = "
        SELECT * FROM esercizi 
        WHERE (status = 'approved' OR status IS NULL) ";
    
    // Aggiungi gli esercizi personali dell'utente se è specificato un user_id
    if ($user_id > 0) {
        $query .= " OR (created_by_user_id = $user_id) ";
    }
    
    $query .= " ORDER BY nome ASC";
    
    // Log per debug
    error_log("Query esercizi standalone: " . $query);
    
    $result = $conn->query($query);

    if ($result) {
        $esercizi = array();
        while ($row = $result->fetch_assoc()) {
            if (isset($row['is_isometric'])) {
                $row['is_isometric'] = (int)$row['is_isometric'];
            }
            // RIMOSSA la normalizzazione di immagine_url: lasciamo immagine_nome e immagine_url come sono
            $esercizi[] = $row;
        }
        
        echo json_encode([
            "success" => true,
            "esercizi" => $esercizi
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Errore nella query degli esercizi: " . $conn->error
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Errore server: " . $e->getMessage()
    ]);
}

$conn->close();
?>