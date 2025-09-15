<?php
// template_ratings.php - API per gestire i rating dei template (versione corretta)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Funzione di debug
function debug_log($message, $data = null) {
    error_log("TEMPLATE_RATINGS_DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("TEMPLATE_RATINGS_DEBUG_DATA: " . print_r($data, true));
    }
}

// Funzione per ottenere l'header Authorization
function getAuthorizationHeader() {
    $auth_header = '';
    
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth_header = $_SERVER['HTTP_AUTHORIZATION'];
        debug_log("Header Authorization trovato in HTTP_AUTHORIZATION");
    } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $auth_header = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        debug_log("Header Authorization trovato in REDIRECT_HTTP_AUTHORIZATION");
    } elseif (function_exists('getallheaders')) {
        $headers = getallheaders();
        if (isset($headers['Authorization'])) {
            $auth_header = $headers['Authorization'];
            debug_log("Header Authorization trovato con getallheaders()");
        } elseif (isset($headers['authorization'])) {
            $auth_header = $headers['authorization'];
            debug_log("Header Authorization trovato con getallheaders() (lowercase)");
        }
    }
    
    return $auth_header;
}

// Funzione per verificare l'autenticazione
function verifyAuthentication() {
    $auth_header = getAuthorizationHeader();
    
    if (empty($auth_header)) {
        debug_log("Nessun header Authorization trovato");
        return [
            'success' => false,
            'message' => 'Header Authorization mancante',
            'user_id' => null
        ];
    }
    
    debug_log("Header Authorization trovato: " . $auth_header);
    
    // Verifica formato Bearer
    if (strpos($auth_header, 'Bearer ') !== 0) {
        debug_log("Formato Bearer non corretto");
        return [
            'success' => false,
            'message' => 'Formato token non corretto',
            'user_id' => null
        ];
    }
    
    $token = substr($auth_header, 7); // Rimuovi "Bearer "
    debug_log("Token estratto (primi 20 caratteri): " . substr($token, 0, 20) . "...");
    
    // Connessione database
    try {
        // Prova a includere config.php
        if (file_exists('config.php')) {
            include 'config.php';
            debug_log("config.php incluso con successo");
        } else {
            debug_log("config.php non trovato, usando connessione diretta");
            // Connessione diretta
            $conn = new mysqli('localhost', 'fitgymtrack_user', 'fitgymtrack_pass', 'fitgymtrack_db');
            if ($conn->connect_error) {
                throw new Exception("Errore connessione database: " . $conn->connect_error);
            }
        }
        
        // Verifica token
        $stmt = $conn->prepare("SELECT user_id, expires_at FROM auth_tokens WHERE token = ?");
        $stmt->bind_param('s', $token);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $token_data = $result->fetch_assoc();
            $user_id = $token_data['user_id'];
            $expires_at = $token_data['expires_at'];
            
            debug_log("Token trovato per user_id: $user_id");
            
            // Verifica scadenza
            $now = date('Y-m-d H:i:s');
            if ($expires_at > $now) {
                debug_log("Token valido (non scaduto)");
                
                // Verifica utente
                $user_stmt = $conn->prepare("SELECT id, username, email FROM users WHERE id = ?");
                $user_stmt->bind_param('i', $user_id);
                $user_stmt->execute();
                $user_result = $user_stmt->get_result();
                
                if ($user_result->num_rows > 0) {
                    $user_data = $user_result->fetch_assoc();
                    debug_log("Utente trovato: " . $user_data['username']);
                    
                    return [
                        'success' => true,
                        'message' => 'Autenticazione riuscita',
                        'user_id' => $user_id,
                        'username' => $user_data['username']
                    ];
                } else {
                    debug_log("Utente non trovato nel database");
                    return [
                        'success' => false,
                        'message' => 'Utente non trovato',
                        'user_id' => null
                    ];
                }
            } else {
                debug_log("Token scaduto");
                return [
                    'success' => false,
                    'message' => 'Token scaduto',
                    'user_id' => null
                ];
            }
        } else {
            debug_log("Token non trovato nel database");
            return [
                'success' => false,
                'message' => 'Token non valido',
                'user_id' => null
            ];
        }
        
    } catch (Exception $e) {
        debug_log("Errore nella verifica: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Errore nella verifica: ' . $e->getMessage(),
            'user_id' => null
        ];
    }
}

$method = $_SERVER['REQUEST_METHOD'];
debug_log("Richiesta ricevuta: $method");

try {
    // Per GET, non richiediamo autenticazione (pubblico)
    // Per POST/PUT/DELETE, richiediamo autenticazione
    $userId = null;
    
    if ($method !== 'GET') {
        debug_log("Richiesta richiede autenticazione, verificando...");
        $authResult = verifyAuthentication();
        if (!$authResult['success']) {
            debug_log("Autenticazione fallita: " . $authResult['message']);
            http_response_code(401);
            echo json_encode(['error' => 'Autenticazione richiesta', 'message' => $authResult['message']]);
            exit();
        }
        $userId = $authResult['user_id'];
        debug_log("Utente autenticato: $userId");
    }
    
    switch ($method) {
        case 'GET':
            // Ottieni rating per un template specifico
            if (!isset($_GET['template_id'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Template ID richiesto']);
                exit();
            }
            
            $templateId = intval($_GET['template_id']);
            debug_log("Richiesta GET per template_id: $templateId");
            
            // Connessione database
            if (file_exists('config.php')) {
                include 'config.php';
            } else {
                $conn = new mysqli('localhost', 'fitgymtrack_user', 'fitgymtrack_pass', 'fitgymtrack_db');
                if ($conn->connect_error) {
                    throw new Exception("Errore connessione database: " . $conn->connect_error);
                }
            }
            
            // Ottieni tutti i rating per il template
            $stmt = $conn->prepare("
                SELECT utr.*, u.username 
                FROM user_template_ratings utr 
                LEFT JOIN users u ON utr.user_id = u.id 
                WHERE utr.template_id = ? 
                ORDER BY utr.created_at DESC
            ");
            $stmt->bind_param('i', $templateId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $ratings = [];
            while ($row = $result->fetch_assoc()) {
                $ratings[] = [
                    'id' => $row['id'],
                    'user_id' => $row['user_id'],
                    'username' => $row['username'],
                    'rating' => floatval($row['rating']),
                    'review' => $row['review'],
                    'created_at' => $row['created_at']
                ];
            }
            
            echo json_encode([
                'success' => true,
                'ratings' => $ratings,
                'count' => count($ratings)
            ]);
            break;
            
        case 'POST':
            // Aggiungi o aggiorna rating
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input || !isset($input['template_id']) || !isset($input['rating'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Dati mancanti']);
                exit();
            }
            
            $templateId = intval($input['template_id']);
            $rating = floatval($input['rating']);
            $review = isset($input['review']) ? trim($input['review']) : '';
            
            debug_log("Richiesta POST per template_id: $templateId, rating: $rating, user_id: $userId");
            
            // Connessione database
            if (file_exists('config.php')) {
                include 'config.php';
            } else {
                $conn = new mysqli('localhost', 'fitgymtrack_user', 'fitgymtrack_pass', 'fitgymtrack_db');
                if ($conn->connect_error) {
                    throw new Exception("Errore connessione database: " . $conn->connect_error);
                }
            }
            
            // Verifica se esiste già un rating per questo utente e template
            $check_stmt = $conn->prepare("SELECT id FROM user_template_ratings WHERE template_id = ? AND user_id = ?");
            $check_stmt->bind_param('ii', $templateId, $userId);
            $check_stmt->execute();
            $existing = $check_stmt->get_result();
            
            if ($existing->num_rows > 0) {
                // Aggiorna rating esistente
                debug_log("Aggiornando rating esistente");
                $update_stmt = $conn->prepare("
                    UPDATE user_template_ratings 
                    SET rating = ?, review = ?, updated_at = NOW() 
                    WHERE template_id = ? AND user_id = ?
                ");
                $update_stmt->bind_param('dsii', $rating, $review, $templateId, $userId);
                $update_stmt->execute();
                
                debug_log("Rating aggiornato con successo");
                
                // 🔧 FIX: Aggiorna manualmente le statistiche
                $update_stats_stmt = $conn->prepare("
                    UPDATE workout_templates 
                    SET rating_average = (
                        SELECT COALESCE(AVG(rating), 0) 
                        FROM user_template_ratings 
                        WHERE template_id = ?
                    ),
                    rating_count = (
                        SELECT COUNT(*) 
                        FROM user_template_ratings 
                        WHERE template_id = ?
                    )
                    WHERE id = ?
                ");
                $update_stats_stmt->bind_param('iii', $templateId, $templateId, $templateId);
                $update_stats_stmt->execute();
                debug_log("Statistiche aggiornate manualmente");
                
                // Verifica le statistiche aggiornate
                $stats_stmt = $conn->prepare("SELECT rating_average, rating_count FROM workout_templates WHERE id = ?");
                $stats_stmt->bind_param('i', $templateId);
                $stats_stmt->execute();
                $stats_result = $stats_stmt->get_result();
                if ($stats_result->num_rows > 0) {
                    $stats = $stats_result->fetch_assoc();
                    debug_log("Statistiche aggiornate - Rating medio: {$stats['rating_average']}, Conteggio: {$stats['rating_count']}");
                }
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Rating aggiornato con successo',
                    'action' => 'updated',
                    'stats' => [
                        'rating_average' => $stats['rating_average'] ?? 0,
                        'rating_count' => $stats['rating_count'] ?? 0
                    ]
                ]);
            } else {
                // Inserisci nuovo rating
                debug_log("Inserendo nuovo rating");
                $insert_stmt = $conn->prepare("
                    INSERT INTO user_template_ratings (template_id, user_id, rating, review, created_at, updated_at) 
                    VALUES (?, ?, ?, ?, NOW(), NOW())
                ");
                $insert_stmt->bind_param('iids', $templateId, $userId, $rating, $review);
                $insert_stmt->execute();
                
                debug_log("Rating inserito con successo");
                
                // 🔧 FIX: Aggiorna manualmente le statistiche
                $update_stats_stmt = $conn->prepare("
                    UPDATE workout_templates 
                    SET rating_average = (
                        SELECT COALESCE(AVG(rating), 0) 
                        FROM user_template_ratings 
                        WHERE template_id = ?
                    ),
                    rating_count = (
                        SELECT COUNT(*) 
                        FROM user_template_ratings 
                        WHERE template_id = ?
                    )
                    WHERE id = ?
                ");
                $update_stats_stmt->bind_param('iii', $templateId, $templateId, $templateId);
                $update_stats_stmt->execute();
                debug_log("Statistiche aggiornate manualmente");
                
                // Verifica le statistiche aggiornate
                $stats_stmt = $conn->prepare("SELECT rating_average, rating_count FROM workout_templates WHERE id = ?");
                $stats_stmt->bind_param('i', $templateId);
                $stats_stmt->execute();
                $stats_result = $stats_stmt->get_result();
                if ($stats_result->num_rows > 0) {
                    $stats = $stats_result->fetch_assoc();
                    debug_log("Statistiche aggiornate - Rating medio: {$stats['rating_average']}, Conteggio: {$stats['rating_count']}");
                }
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Rating aggiunto con successo',
                    'action' => 'created',
                    'stats' => [
                        'rating_average' => $stats['rating_average'] ?? 0,
                        'rating_count' => $stats['rating_count'] ?? 0
                    ]
                ]);
            }
            break;
            
        case 'DELETE':
            // Rimuovi rating
            if (!isset($_GET['template_id'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Template ID richiesto']);
                exit();
            }
            
            $templateId = intval($_GET['template_id']);
            debug_log("Richiesta DELETE per template_id: $templateId, user_id: $userId");
            
            // Connessione database
            if (file_exists('config.php')) {
                include 'config.php';
            } else {
                $conn = new mysqli('localhost', 'fitgymtrack_user', 'fitgymtrack_pass', 'fitgymtrack_db');
                if ($conn->connect_error) {
                    throw new Exception("Errore connessione database: " . $conn->connect_error);
                }
            }
            
            $delete_stmt = $conn->prepare("DELETE FROM user_template_ratings WHERE template_id = ? AND user_id = ?");
            $delete_stmt->bind_param('ii', $templateId, $userId);
            $delete_stmt->execute();
            
            if ($delete_stmt->affected_rows > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Rating rimosso con successo'
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Rating non trovato'
                ]);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['error' => 'Metodo non supportato']);
            break;
    }
    
} catch (Exception $e) {
    debug_log("Errore: " . $e->getMessage());
    debug_log("Stack trace: " . $e->getTraceAsString());
    debug_log("File: " . $e->getFile() . " Line: " . $e->getLine());
    
    http_response_code(500);
    echo json_encode([
        'error' => 'Errore interno del server',
        'message' => 'Errore interno del server. Riprova più tardi.',
        'debug_info' => [
            'error_message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ]);
}
?>