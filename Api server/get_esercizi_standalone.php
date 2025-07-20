<?php
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