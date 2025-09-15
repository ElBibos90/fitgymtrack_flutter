<?php
// template_ratings.php - API per gestire i rating dei template
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'config.php';
require_once 'auth_functions.php';
require_once 'auth_helper.php';

// Funzione di debug
function debug_log($message, $data = null) {
    error_log("TEMPLATE_RATINGS_DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("TEMPLATE_RATINGS_DATA: " . print_r($data, true));
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
        $authResult = requireAuthentication();
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
            $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
            $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
            
            // Query per ottenere i rating
            $stmt = $conn->prepare("
                SELECT 
                    utr.id,
                    utr.rating,
                    utr.review,
                    utr.created_at,
                    utr.updated_at,
                    u.name as user_name,
                    u.username
                FROM user_template_ratings utr
                JOIN users u ON utr.user_id = u.id
                WHERE utr.template_id = ?
                ORDER BY utr.created_at DESC
                LIMIT ? OFFSET ?
            ");
            
            $stmt->bind_param('iii', $templateId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $ratings = [];
            while ($row = $result->fetch_assoc()) {
                // Nascondi username per privacy, mostra solo nome
                unset($row['username']);
                $ratings[] = $row;
            }
            
            // Verifica se l'utente ha già valutato questo template
            $userRatingStmt = $conn->prepare("
                SELECT rating, review, created_at, updated_at
                FROM user_template_ratings
                WHERE user_id = ? AND template_id = ?
            ");
            
            $userRatingStmt->bind_param('ii', $userId, $templateId);
            $userRatingStmt->execute();
            $userRatingResult = $userRatingStmt->get_result();
            
            $userRating = null;
            if ($userRatingResult->num_rows > 0) {
                $userRating = $userRatingResult->fetch_assoc();
            }
            
            // Ottieni statistiche del template
            $statsStmt = $conn->prepare("
                SELECT 
                    rating_average,
                    rating_count
                FROM workout_templates
                WHERE id = ?
            ");
            
            $statsStmt->bind_param('i', $templateId);
            $statsStmt->execute();
            $statsResult = $statsStmt->get_result();
            $stats = $statsResult->fetch_assoc();
            
            echo json_encode([
                'success' => true,
                'ratings' => $ratings,
                'user_rating' => $userRating,
                'stats' => $stats,
                'pagination' => [
                    'limit' => $limit,
                    'offset' => $offset
                ]
            ]);
            break;
            
        case 'POST':
            // Aggiungi o aggiorna rating
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['template_id']) || !isset($input['rating'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Template ID e rating richiesti']);
                exit();
            }
            
            $templateId = intval($input['template_id']);
            $rating = intval($input['rating']);
            $review = isset($input['review']) ? trim($input['review']) : null;
            
            // Validazione rating
            if ($rating < 1 || $rating > 5) {
                http_response_code(400);
                echo json_encode(['error' => 'Rating deve essere tra 1 e 5']);
                exit();
            }
            
            // Verifica che il template esista
            $templateStmt = $conn->prepare("
                SELECT id FROM workout_templates WHERE id = ? AND is_active = 1
            ");
            $templateStmt->bind_param('i', $templateId);
            $templateStmt->execute();
            $templateResult = $templateStmt->get_result();
            
            if ($templateResult->num_rows === 0) {
                http_response_code(404);
                echo json_encode(['error' => 'Template non trovato']);
                exit();
            }
            
            // Verifica se l'utente ha già valutato questo template
            $existingStmt = $conn->prepare("
                SELECT id FROM user_template_ratings 
                WHERE user_id = ? AND template_id = ?
            ");
            $existingStmt->bind_param('ii', $userId, $templateId);
            $existingStmt->execute();
            $existingResult = $existingStmt->get_result();
            
            if ($existingResult->num_rows > 0) {
                // Aggiorna rating esistente
                $updateStmt = $conn->prepare("
                    UPDATE user_template_ratings 
                    SET rating = ?, review = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE user_id = ? AND template_id = ?
                ");
                $updateStmt->bind_param('isii', $rating, $review, $userId, $templateId);
                $updateStmt->execute();
                
                $message = 'Rating aggiornato con successo';
            } else {
                // Inserisci nuovo rating
                $insertStmt = $conn->prepare("
                    INSERT INTO user_template_ratings (user_id, template_id, rating, review) 
                    VALUES (?, ?, ?, ?)
                ");
                $insertStmt->bind_param('iiis', $userId, $templateId, $rating, $review);
                $insertStmt->execute();
                
                $message = 'Rating aggiunto con successo';
            }
            
            // Registra l'utilizzo del template
            $logStmt = $conn->prepare("
                INSERT INTO template_usage_log (user_id, template_id, action) 
                VALUES (?, ?, 'rated')
            ");
            $logStmt->bind_param('ii', $userId, $templateId);
            $logStmt->execute();
            
            echo json_encode([
                'success' => true,
                'message' => $message,
                'rating' => $rating,
                'review' => $review
            ]);
            break;
            
        case 'DELETE':
            // Rimuovi rating
            if (!isset($_GET['template_id'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Template ID richiesto']);
                exit();
            }
            
            $templateId = intval($_GET['template_id']);
            
            $deleteStmt = $conn->prepare("
                DELETE FROM user_template_ratings 
                WHERE user_id = ? AND template_id = ?
            ");
            $deleteStmt->bind_param('ii', $userId, $templateId);
            $deleteStmt->execute();
            
            if ($deleteStmt->affected_rows > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Rating rimosso con successo'
                ]);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Rating non trovato']);
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
