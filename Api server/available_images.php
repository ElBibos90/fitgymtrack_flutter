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

header('Content-Type: application/json');

include 'config.php';
require_once 'auth_functions.php';

// Verifica autenticazione e permessi (solo admin e trainer)
$userData = authMiddleware($conn, ['admin', 'trainer']);
if (!$userData) {
    exit; // authMiddleware ha già restituito l'errore
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch($method) {
        case 'GET':
            // Percorso della cartella delle immagini
            $imagesPath = '/var/www/html/uploads/images/';
            
            // Verifica che la cartella esista
            if (!is_dir($imagesPath)) {
                // Crea la cartella se non esiste
                if (!mkdir($imagesPath, 0755, true)) {
                    throw new Exception("Impossibile creare la cartella delle immagini");
                }
            }
            
            // Ottieni tutti i file GIF dalla cartella
            $images = [];
            $files = scandir($imagesPath);
            
            if ($files !== false) {
                foreach ($files as $file) {
                    // Filtra solo i file GIF
                    if (pathinfo($file, PATHINFO_EXTENSION) === 'gif') {
                        $images[] = $file;
                    }
                }
                
                // Ordina alfabeticamente
                sort($images);
            }
            
            echo json_encode([
                'success' => true,
                'images' => $images,
                'count' => count($images)
            ]);
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