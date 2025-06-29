<?php
// Abilita il reporting degli errori per il debug
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// CORS headers - accetta richieste da ambienti multipli
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

// Verifica autenticazione
$userData = authMiddleware($conn);
if (!$userData) {
    exit();
}

// Funzioni di mappatura per experienceLevel
function mapExperienceLevelToInt($level) {
    switch($level) {
        case 'beginner': return 1;
        case 'intermediate': return 2;
        case 'advanced': return 3;
        default: return 1; // Default a beginner
    }
}

function mapIntToExperienceLevel($value) {
    switch($value) {
        case 1: return 'beginner';
        case 2: return 'intermediate';
        case 3: return 'advanced';
        default: return 'beginner';
    }
}

// Ottieni l'ID dell'utente autenticato
$userId = $userData['user_id'];

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        try {
            // Verifica se l'ID è specificato e l'utente ha i permessi per accedervi
            $targetUserId = isset($_GET['user_id']) ? intval($_GET['user_id']) : $userId;
            
            // Se l'utente sta cercando di accedere a un profilo diverso dal proprio, verifica i permessi
            if ($targetUserId !== $userId) {
                // Verifica dei permessi (solo admin e trainer possono vedere altri profili)
                $isAdmin = hasRole($userData, 'admin');
                $isTrainer = hasRole($userData, 'trainer');
                
                if (!$isAdmin && (!$isTrainer || !isUserAssignedToTrainer($conn, $targetUserId, $userId))) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Non autorizzato ad accedere a questo profilo']);
                    exit();
                }
            }
            
            // Recupera i dati del profilo utente dalla tabella user_profiles
            $stmt = $conn->prepare("
                SELECT * FROM user_profiles 
                WHERE user_id = ?
            ");
            
            $stmt->bind_param("i", $targetUserId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            // Se il profilo esiste, restituiscilo
            if ($result->num_rows > 0) {
                $profile = $result->fetch_assoc();
                
                // Converti experienceLevel da intero a stringa
                if (isset($profile['experienceLevel'])) {
                    $profile['experienceLevel'] = mapIntToExperienceLevel($profile['experienceLevel']);
                }
                
                echo json_encode($profile);
            } else {
                // Se il profilo non esiste, crea un profilo predefinito
                $defaultProfile = createDefaultProfile($conn, $targetUserId);
                echo json_encode($defaultProfile);
            }
        } catch (Exception $e) {
            error_log("Errore nel recupero del profilo utente: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;
        
    case 'PUT':
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            
            if (!$data) {
                throw new Exception("Dati non validi o formato JSON non corretto");
            }
            
            // Verifica se l'ID è specificato e l'utente ha i permessi per modificarlo
            $targetUserId = isset($_GET['user_id']) ? intval($_GET['user_id']) : $userId;
            
            // Se l'utente sta cercando di modificare un profilo diverso dal proprio, verifica i permessi
            if ($targetUserId !== $userId) {
                // Verifica dei permessi (solo admin e trainer possono modificare altri profili)
                $isAdmin = hasRole($userData, 'admin');
                $isTrainer = hasRole($userData, 'trainer');
                
                if (!$isAdmin && (!$isTrainer || !isUserAssignedToTrainer($conn, $targetUserId, $userId))) {
                    http_response_code(403);
                    echo json_encode(['error' => 'Non autorizzato a modificare questo profilo']);
                    exit();
                }
            }
            
            // Verifica se il profilo esiste
            $stmt = $conn->prepare("SELECT user_id FROM user_profiles WHERE user_id = ?");
            $stmt->bind_param("i", $targetUserId);
            $stmt->execute();
            
            if ($stmt->get_result()->num_rows === 0) {
                // Se il profilo non esiste, lo creiamo
                createDefaultProfile($conn, $targetUserId);
            }
            
            // Validazione dei dati
            if (isset($data['gender']) && !in_array($data['gender'], ['male', 'female', 'other'])) {
                $data['gender'] = 'male'; // Valore predefinito se non valido
            }
            
            // Validazione e conversione di experienceLevel
            if (isset($data['experienceLevel'])) {
                if (!in_array($data['experienceLevel'], ['beginner', 'intermediate', 'advanced'])) {
                    $data['experienceLevel'] = 'beginner';
                }
                $data['experienceLevel'] = mapExperienceLevelToInt($data['experienceLevel']);
            }
            
            // Validazione dei dati numerici
            if (isset($data['height'])) {
                $data['height'] = min(max(intval($data['height']), 100), 250); // Limita tra 100 e 250 cm
            }
            
            if (isset($data['weight'])) {
                $data['weight'] = min(max(floatval($data['weight']), 30), 250); // Limita tra 30 e 250 kg
            }
            
            if (isset($data['age'])) {
                $data['age'] = min(max(intval($data['age']), 16), 100); // Limita tra 16 e 100 anni
            }
            
            // Aggiorna i campi del profilo
            $fields = [];
            $types = "";
            $values = [];
            
            // Campi che possono essere aggiornati
            $allowedFields = [
                'height' => 'i',
                'weight' => 'd',
                'age' => 'i',
                'gender' => 's',
                'experienceLevel' => 'i',  // Modificato da 's' a 'i'
                'fitnessGoals' => 's',
                'injuries' => 's',
                'preferences' => 's',
                'notes' => 's'
            ];
            
            foreach ($allowedFields as $field => $type) {
                if (isset($data[$field])) {
                    $fields[] = "$field = ?";
                    $types .= $type;
                    $values[] = $data[$field];
                }
            }
            
            if (empty($fields)) {
                throw new Exception("Nessun campo valido da aggiornare");
            }
            
            // Aggiungi updated_at al campo da aggiornare
            $fields[] = "updated_at = NOW()";
            
            $query = "UPDATE user_profiles SET " . implode(", ", $fields) . " WHERE user_id = ?";
            $types .= "i";
            $values[] = $targetUserId;
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param($types, ...$values);
            
            if (!$stmt->execute()) {
                throw new Exception("Errore nell'aggiornamento del profilo: " . $stmt->error);
            }
            
            // Recupera il profilo aggiornato
            $stmt = $conn->prepare("SELECT * FROM user_profiles WHERE user_id = ?");
            $stmt->bind_param("i", $targetUserId);
            $stmt->execute();
            $profile = $stmt->get_result()->fetch_assoc();
            
            // Converti experienceLevel da intero a stringa per il frontend
            if (isset($profile['experienceLevel'])) {
                $profile['experienceLevel'] = mapIntToExperienceLevel($profile['experienceLevel']);
            }
            
            echo json_encode([
                'message' => 'Profilo aggiornato con successo',
                'profile' => $profile
            ]);
            
        } catch (Exception $e) {
            error_log("Errore nell'aggiornamento del profilo: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

/**
 * Verifica se un utente è assegnato a un trainer
 */
function isUserAssignedToTrainer($conn, $userId, $trainerId) {
    $stmt = $conn->prepare("SELECT id FROM users WHERE id = ? AND trainer_id = ?");
    $stmt->bind_param("ii", $userId, $trainerId);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

/**
 * Crea un profilo utente predefinito
 */
function createDefaultProfile($conn, $userId) {
    // Ottieni alcuni dati base dell'utente
    $stmt = $conn->prepare("SELECT role_id FROM users WHERE id = ?");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $user = $stmt->get_result()->fetch_assoc();
    
    // Determina il livello di esperienza in base al ruolo (usando valori interi)
    $experienceLevel = 1; // Default per utenti normali (beginner)
    
    if ($user && $user['role_id'] == 1) { // Admin
        $experienceLevel = 3; // advanced
    } else if ($user && $user['role_id'] == 2) { // Trainer
        $experienceLevel = 2; // intermediate
    }
    
    // Inserisci il profilo predefinito
    $stmt = $conn->prepare("
        INSERT INTO user_profiles 
        (user_id, height, weight, age, gender, experienceLevel, fitnessGoals, injuries, preferences, notes, created_at, updated_at) 
        VALUES (?, 175, 70, 30, 'male', ?, 'general_fitness', NULL, NULL, NULL, NOW(), NOW())
    ");
    
    $stmt->bind_param("ii", $userId, $experienceLevel);
    
    if (!$stmt->execute()) {
        error_log("Errore nella creazione del profilo predefinito: " . $stmt->error);
        throw new Exception("Errore nella creazione del profilo predefinito");
    }
    
    // Ritorna il profilo appena creato (convertendo experienceLevel in stringa)
    return [
        'user_id' => $userId,
        'height' => 175,
        'weight' => 70,
        'age' => 30,
        'gender' => 'male',
        'experienceLevel' => mapIntToExperienceLevel($experienceLevel),
        'fitnessGoals' => 'general_fitness',
        'injuries' => null,
        'preferences' => null,
        'notes' => null,
        'created_at' => date('Y-m-d H:i:s'),
        'updated_at' => date('Y-m-d H:i:s')
    ];
}

$conn->close();
?>