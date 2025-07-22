<?php
/**
 * API per il controllo delle versioni dell'app
 * Endpoint: /api/version
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestisci preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configurazione database
require_once 'config.php';
require_once 'auth_functions.php';

// Usa la connessione già stabilita in config.php
if (!isset($conn) || $conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Database connection failed',
        'message' => 'Unable to connect to database'
    ]);
    exit();
}

// Gestisci solo richieste GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

try {
    // Ottieni le informazioni sulla versione dal database
    $stmt = $conn->prepare("
        SELECT 
            version_name,
            version_code,
            build_number,
            update_required,
            update_message,
            min_required_version,
            release_notes,
            release_date
        FROM app_versions 
        WHERE is_active = 1 
        ORDER BY version_code DESC 
        LIMIT 1
    ");
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        // Se non ci sono versioni nel database, usa valori di default
        $versionInfo = [
            'version' => '1.0.1',
            'build_number' => '4',
            'version_code' => 4,
            'update_required' => false,
            'message' => '',
            'min_required_version' => '1.0.0',
            'release_notes' => 'Versione stabile con miglioramenti generali',
            'release_date' => date('Y-m-d H:i:s')
        ];
    } else {
        $row = $result->fetch_assoc();
        $versionInfo = [
            'version' => $row['version_name'],
            'build_number' => $row['build_number'],
            'version_code' => $row['version_code'],
            'update_required' => (bool)$row['update_required'],
            'message' => $row['update_message'] ?? '',
            'min_required_version' => $row['min_required_version'],
            'release_notes' => $row['release_notes'] ?? '',
            'release_date' => $row['release_date']
        ];
    }
    
    // Aggiungi informazioni aggiuntive
    $versionInfo['server_time'] = date('Y-m-d H:i:s');
    $versionInfo['environment'] = 'production';
    
    echo json_encode($versionInfo);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal server error',
        'message' => $e->getMessage()
    ]);
} finally {
    $conn->close();
}
?> 