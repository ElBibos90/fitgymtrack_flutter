<?php
// gym_request.php - Gestisce le richieste delle palestre

// Abilita il reporting degli errori
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
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
    }
    
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }

    exit(0);
}

header('Content-Type: application/json');

// Verifica che la richiesta sia POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Metodo non consentito'
    ]);
    exit;
}

// Leggi il corpo della richiesta JSON
$input = json_decode(file_get_contents('php://input'), true);

// Verifica che tutti i campi richiesti siano presenti
if (!isset($input['name']) || !isset($input['email']) || !isset($input['additionalInfo'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Dati mancanti. Assicurati di compilare tutti i campi obbligatori.'
    ]);
    exit;
}

// Valida l'email
if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'L\'indirizzo email fornito non è valido.'
    ]);
    exit;
}

// Connessione al database
include 'config.php';

if (!$conn) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Errore di connessione al database'
    ]);
    exit;
}

try {
    // Prima verifica se il database ha la tabella gym_requests
    $checkTable = $conn->query("SHOW TABLES LIKE 'gym_requests'");
    
    // Se la tabella non esiste, creala
    if ($checkTable->num_rows === 0) {
        $conn->query("CREATE TABLE gym_requests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            gym_name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL,
            additional_info TEXT,
            status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");
    }
    
    // Sanitizza gli input
    $name = $conn->real_escape_string($input['name']);
    $email = $conn->real_escape_string($input['email']);
    $additionalInfo = $conn->real_escape_string($input['additionalInfo']);
    
    // Inserisci la richiesta nel database
    $stmt = $conn->prepare("INSERT INTO gym_requests (gym_name, email, additional_info) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $name, $email, $additionalInfo);
    
    if ($stmt->execute()) {
        // Opzionalmente, invia un'email di notifica all'amministratore
        $adminEmail = "admin@fitgymtrack.com"; // Cambia con l'email dell'amministratore
        $subject = "Nuova richiesta palestra: " . $name;
        $message = "È stata ricevuta una nuova richiesta di accesso:\n\n";
        $message .= "Nome Palestra: " . $name . "\n";
        $message .= "Email: " . $email . "\n";
        $message .= "Informazioni Aggiuntive: " . $additionalInfo . "\n\n";
        $message .= "Accedi al pannello di amministrazione per gestire questa richiesta.";
        $headers = "From: noreply@fitgymtrack.com";
        
        // Commenta la riga seguente se non vuoi inviare email (richiede configurazione mail server)
        // mail($adminEmail, $subject, $message, $headers);
        
        // Invia una risposta di successo
        echo json_encode([
            'success' => true,
            'message' => 'La tua richiesta è stata inviata con successo. Ti contatteremo presto all\'indirizzo email fornito.'
        ]);
    } else {
        throw new Exception("Errore nell'inserimento dati: " . $stmt->error);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Errore durante l\'elaborazione della richiesta: ' . $e->getMessage()
    ]);
}

$conn->close();
?>