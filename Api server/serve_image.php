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
        header("Access-Control-Allow-Methods: GET, OPTIONS");
    }
    
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }

    exit(0);
}

include 'config.php';
require_once 'auth_functions.php';

// RIMOSSO: autenticazione per accesso pubblico alle immagini
// $userData = authMiddleware($conn);
// if (!$userData) {
//     exit; // authMiddleware ha già restituito l'errore
// }

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch($method) {
        case 'GET':
            if (!isset($_GET['filename'])) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Nome file mancante']);
                exit;
            }
            
            $filename = $_GET['filename'];
            
            // Validazione del nome file per sicurezza
            if (!preg_match('/^[a-zA-Z0-9_-]+\.gif$/', $filename)) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Nome file non valido']);
                exit;
            }
            
            // Percorso completo del file
            $filePath = '/var/www/html/uploads/images/' . $filename;
            
            // Verifica che il file esista
            if (!file_exists($filePath)) {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'File non trovato']);
                exit;
            }
            
            // Verifica che sia un file GIF
            $fileInfo = pathinfo($filePath);
            if (strtolower($fileInfo['extension']) !== 'gif') {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Tipo di file non supportato']);
                exit;
            }
            
            // Imposta gli header per il download/visualizzazione
            header('Content-Type: image/gif');
            header('Content-Length: ' . filesize($filePath));
            header('Cache-Control: public, max-age=86400'); // Cache per 1 giorno
            
            // Leggi e invia il file
            readfile($filePath);
            exit;
            break;

        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Errore del server: ' . $e->getMessage()]);
}
?> 