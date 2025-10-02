<?php
// Abilita errori per debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'config.php';
require_once 'auth_functions.php';
require_once 'subscription_limits.php';

header('Content-Type: application/json');

// Gestione dei metodi HTTP
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // Creazione di un nuovo esercizio personalizzato
    case 'POST':
        $input = json_decode(file_get_contents('php://input'), true);
    
        if (!isset($input['nome'], $input['gruppo_muscolare'], $input['created_by_user_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Dati insufficienti per creare l\'esercizio']);
            exit;
        }
        
        $user_id = intval($input['created_by_user_id']);
        
        // Ora controlliamo il limite con $user_id definito
        $limitCheck = checkCustomExerciseLimit($user_id);
        
        if ($limitCheck['limit_reached']) {
            http_response_code(403);
            echo json_encode([
                'success' => false,
                'message' => 'Hai raggiunto il limite di esercizi personalizzati per il tuo piano. Passa al piano Premium per avere esercizi illimitati.',
                'upgrade_required' => true
            ]);
            exit;
        }

        // Sanitizza i dati
        $nome = $conn->real_escape_string($input['nome']);
        $gruppo_muscolare = $conn->real_escape_string($input['gruppo_muscolare']);
        $descrizione = isset($input['descrizione']) ? $conn->real_escape_string($input['descrizione']) : '';
        $attrezzatura = isset($input['attrezzatura']) ? $conn->real_escape_string($input['attrezzatura']) : '';
        $is_isometric = isset($input['is_isometric']) && $input['is_isometric'] ? 1 : 0;
        $created_by_user_id = intval($input['created_by_user_id']);
        $status = $input['status'] ?? 'pending_review';

        // Verifica che lo status sia valido
        if (!in_array($status, ['approved', 'pending_review', 'user_only'])) {
            $status = 'pending_review';
        }

        try {
            $stmt = $conn->prepare("
                INSERT INTO esercizi 
                (nome, gruppo_muscolare, descrizione, attrezzatura, is_isometric, created_by_user_id, status) 
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");

            $stmt->bind_param(
                'ssssiis', 
                $nome, 
                $gruppo_muscolare, 
                $descrizione, 
                $attrezzatura, 
                $is_isometric,
                $created_by_user_id, 
                $status
            );

            if ($stmt->execute()) {
                $exercise_id = $stmt->insert_id;
                echo json_encode([
                    'success' => true, 
                    'message' => 'Esercizio creato con successo',
                    'exercise_id' => $exercise_id
                ]);
            } else {
                throw new Exception($stmt->error);
            }
            
            $stmt->close();
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Errore durante la creazione dell\'esercizio: ' . $e->getMessage()]);
        }
        break;

    // Aggiornamento di un esercizio esistente
    case 'PUT':
        $input = json_decode(file_get_contents('php://input'), true);

        if (!isset($input['id'], $input['nome'], $input['gruppo_muscolare'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Dati insufficienti per aggiornare l\'esercizio']);
            exit;
        }

        // Sanitizza i dati
        $id = intval($input['id']);
        $nome = $conn->real_escape_string($input['nome']);
        $gruppo_muscolare = $conn->real_escape_string($input['gruppo_muscolare']);
        $descrizione = isset($input['descrizione']) ? $conn->real_escape_string($input['descrizione']) : '';
        $attrezzatura = isset($input['attrezzatura']) ? $conn->real_escape_string($input['attrezzatura']) : '';
        $is_isometric = isset($input['is_isometric']) && $input['is_isometric'] ? 1 : 0;
        
        try {
            // Verifica che l'esercizio appartenga all'utente
            $check = $conn->prepare("
                SELECT id FROM esercizi 
                WHERE id = ? AND created_by_user_id = ?
            ");
            
            $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
            
            $check->bind_param('ii', $id, $user_id);
            $check->execute();
            $result = $check->get_result();
            
            if ($result->num_rows === 0) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Non sei autorizzato a modificare questo esercizio']);
                $check->close();
                exit;
            }
            
            $check->close();

            // Procedi con l'aggiornamento
            $stmt = $conn->prepare("
                UPDATE esercizi SET 
                nome = ?, 
                gruppo_muscolare = ?, 
                descrizione = ?, 
                attrezzatura = ?, 
                is_isometric = ?
                WHERE id = ?
            ");

            $stmt->bind_param(
                'sssiii', 
                $nome, 
                $gruppo_muscolare, 
                $descrizione, 
                $attrezzatura, 
                $is_isometric, 
                $id
            );

            if ($stmt->execute()) {
                echo json_encode([
                    'success' => true, 
                    'message' => 'Esercizio aggiornato con successo'
                ]);
            } else {
                throw new Exception($stmt->error);
            }
            
            $stmt->close();
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Errore durante l\'aggiornamento dell\'esercizio: ' . $e->getMessage()]);
        }
        break;

    // Eliminazione di un esercizio
    case 'DELETE':
        $input = json_decode(file_get_contents('php://input'), true);

        if (!isset($input['exercise_id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'ID esercizio mancante']);
            exit;
        }

        $exercise_id = intval($input['exercise_id']);
        $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;

        try {
            // Verifica che l'esercizio appartenga all'utente
            $check = $conn->prepare("
                SELECT id FROM esercizi 
                WHERE id = ? AND created_by_user_id = ?
            ");
            
            $check->bind_param('ii', $exercise_id, $user_id);
            $check->execute();
            $result = $check->get_result();
            
            if ($result->num_rows === 0) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => 'Non sei autorizzato a eliminare questo esercizio']);
                $check->close();
                exit;
            }
            
            $check->close();

            // Procedi con l'eliminazione
            $stmt = $conn->prepare("DELETE FROM esercizi WHERE id = ?");
            $stmt->bind_param('i', $exercise_id);

            if ($stmt->execute()) {
                echo json_encode([
                    'success' => true, 
                    'message' => 'Esercizio eliminato con successo'
                ]);
            } else {
                throw new Exception($stmt->error);
            }
            
            $stmt->close();
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Errore durante l\'eliminazione dell\'esercizio: ' . $e->getMessage()]);
        }
        break;

    // Metodo non consentito
    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Metodo non consentito']);
        break;
}

$conn->close();
?>