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

$method = $_SERVER['REQUEST_METHOD'];

// Verifica autenticazione e ruolo
$user = authMiddleware($conn, ['admin', 'trainer']);
if (!$user) {
    exit();
}

switch($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            getUserById($conn, $_GET['id'], $user);
        } else if (isset($_GET['role']) && $_GET['role'] === 'trainer') {
            getTrainers($conn);
        } else {
            getAllUsers($conn, $user);
        }
        break;
        
    case 'POST':
        createUser($conn, $user);
        break;
        
    case 'PUT':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID utente mancante']);
            break;
        }
        updateUser($conn, $_GET['id'], $user);
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'ID utente mancante']);
            break;
        }
        deleteUser($conn, $_GET['id'], $user);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non consentito']);
}

function getAllUsers($conn, $user) {
    try {
        // Log per debug
        error_log("Richiesta utenti per utente: " . json_encode($user));
        
        // Base query
        $baseQuery = "
            SELECT u.id, u.username, u.email, u.name, u.role_id, 
                u.active, u.last_login, u.created_at, r.name as role_name,
                u.trainer_id, t.username as trainer_username, t.name as trainer_name,
                u.current_plan_id, p.name as plan_name, u.is_tester
            FROM users u
            JOIN user_role r ON u.role_id = r.id
            LEFT JOIN users t ON u.trainer_id = t.id
            LEFT JOIN subscription_plans p ON u.current_plan_id = p.id
        ";
        
        // Filtro per ruolo se specificato
        $roleFilter = isset($_GET['role_name']) ? $_GET['role_name'] : null;
        
        // Per i trainer, mostra solo gli utenti assegnati
        if (hasRole($user, 'trainer')) {
            $whereClause = " WHERE (u.trainer_id = ? OR u.id = ?)";
            if ($roleFilter) {
                $whereClause .= " AND r.name = ?";
                $stmt = $conn->prepare($baseQuery . $whereClause . " ORDER BY u.created_at DESC");
                $stmt->bind_param("iis", $user['user_id'], $user['user_id'], $roleFilter);
            } else {
                $stmt = $conn->prepare($baseQuery . $whereClause . " ORDER BY u.created_at DESC");
                $stmt->bind_param("ii", $user['user_id'], $user['user_id']);
            }
        } else {
            // Per admin, mostra tutti gli utenti o filtra per ruolo
            if ($roleFilter) {
                $whereClause = " WHERE r.name = ?";
                $stmt = $conn->prepare($baseQuery . $whereClause . " ORDER BY u.created_at DESC");
                $stmt->bind_param("s", $roleFilter);
            } else {
                $stmt = $conn->prepare($baseQuery . " ORDER BY u.created_at DESC");
            }
        }

        $stmt->execute();
        
        // Log per debug
        error_log("Query eseguita correttamente");
        
        $result = $stmt->get_result();

        $users = [];
        while ($row = $result->fetch_assoc()) {
            // Formatta le informazioni del trainer
            if ($row['trainer_id']) {
                $row['trainer'] = [
                    'id' => $row['trainer_id'],
                    'username' => $row['trainer_username'],
                    'name' => $row['trainer_name']
                ];
            }
            
            // Aggiungi le informazioni del piano
            $row['plan'] = [
                'id' => $row['current_plan_id'],
                'name' => $row['plan_name']
            ];
            
            // Rimuovi campi ridondanti
            unset($row['trainer_id']);
            unset($row['trainer_username']);
            unset($row['trainer_name']);
            unset($row['current_plan_id']);
            unset($row['plan_name']);
            
            $users[] = $row;
        }
        
        // Log per debug
        error_log("Numero utenti trovati: " . count($users));
        
        echo json_encode($users);
    } catch (Exception $e) {
        // Log dell'errore
        error_log("Errore nel recupero degli utenti: " . $e->getMessage());
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero degli utenti: ' . $e->getMessage()]);
    }
}

function getTrainers($conn) {
    try {
        $stmt = $conn->prepare("
            SELECT u.id, u.username, u.name, u.email, u.active
            FROM users u
            JOIN user_role r ON u.role_id = r.id
            WHERE r.name = 'trainer' AND u.active = 1
            ORDER BY u.name, u.username
        ");
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $trainers = [];
        while ($row = $result->fetch_assoc()) {
            $trainers[] = $row;
        }
        
        echo json_encode($trainers);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dei trainer: ' . $e->getMessage()]);
    }
}

function getUserById($conn, $id, $user) {
    try {
        // Verifica se l'utente ha accesso a questo user
        if (!hasAccessToUser($user, $id, $conn)) {
            http_response_code(403);
            echo json_encode(['error' => 'Non hai permessi per visualizzare questo utente']);
            return;
        }
        
        $stmt = $conn->prepare("
            SELECT u.id, u.username, u.email, u.name, u.role_id, 
                   u.active, u.last_login, u.created_at, r.name as role_name,
                   u.trainer_id, t.username as trainer_username, t.name as trainer_name,
                   u.current_plan_id, p.name as plan_name, u.is_tester
            FROM users u
            JOIN user_role r ON u.role_id = r.id
            LEFT JOIN users t ON u.trainer_id = t.id
            LEFT JOIN subscription_plans p ON u.current_plan_id = p.id
            WHERE u.id = ?
        ");
        
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $user = $result->fetch_assoc();
        
        if (!$user) {
            http_response_code(404);
            echo json_encode(['error' => 'Utente non trovato']);
            return;
        }
        
        // Format the trainer info
        if ($user['trainer_id']) {
            $user['trainer'] = [
                'id' => $user['trainer_id'],
                'username' => $user['trainer_username'],
                'name' => $user['trainer_name']
            ];
        }
        
        // Format the plan info
        $user['plan'] = [
            'id' => $user['current_plan_id'],
            'name' => $user['plan_name']
        ];
        
        // Remove redundant fields
        unset($user['trainer_id']);
        unset($user['trainer_username']);
        unset($user['trainer_name']);
        unset($user['current_plan_id']);
        unset($user['plan_name']);
        
        echo json_encode($user);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Errore nel recupero dell\'utente: ' . $e->getMessage()]);
    }
}

function createUser($conn, $user) {
    try {
        $data = json_decode(file_get_contents("php://input"), true);
        
        // Validazione dati
        $required = ['username', 'password', 'email', 'role_id'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                http_response_code(400);
                echo json_encode(['error' => "Campo '$field' obbligatorio"]);
                return;
            }
        }
        
        // Verifica se lo username esiste già
        $stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
        $stmt->bind_param("s", $data['username']);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Username già in uso']);
            return;
        }
        
        // Verifica se l'email esiste già
        $stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->bind_param("s", $data['email']);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Email già in uso']);
            return;
        }
        
        // Verifica che il ruolo sia valido
        $stmt = $conn->prepare("SELECT id FROM user_role WHERE id = ?");
        $stmt->bind_param("i", $data['role_id']);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Ruolo non valido']);
            return;
        }
        
        // Verifica che il trainer sia valido
        $trainer_id = null;
        if (hasRole($user, 'trainer')) {
            // Se l'utente è un trainer, imposta automaticamente il trainer_id
            $trainer_id = $user['user_id'];
            
            // I trainer possono creare solo utenti con ruolo 'user'
            $getRoleStmt = $conn->prepare("SELECT id FROM user_role WHERE name = 'user'");
            $getRoleStmt->execute();
            $userRoleResult = $getRoleStmt->get_result();
            if ($userRoleResult->num_rows === 0) {
                http_response_code(500);
                echo json_encode(['error' => 'Ruolo user non trovato']);
                return;
            }
            $userRole = $userRoleResult->fetch_assoc();
            $data['role_id'] = $userRole['id']; // Override del role_id per i trainer
        } else if (isset($data['trainer_id']) && !empty($data['trainer_id'])) {
            // Se l'admin specifica un trainer_id, verifica che sia valido
            $stmt = $conn->prepare("
                SELECT u.id FROM users u
                JOIN user_role r ON u.role_id = r.id
                WHERE u.id = ? AND r.name = 'trainer'
            ");
            $stmt->bind_param("i", $data['trainer_id']);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Trainer non valido']);
                return;
            }
            $trainer_id = $data['trainer_id'];
        }
        
        // Hash della password
        $hashedPassword = password_hash($data['password'], PASSWORD_BCRYPT);
        
        // Inizia una transazione per garantire che entrambe le operazioni vengano eseguite correttamente
        $conn->begin_transaction();
        
        // Inserimento utente con current_plan_id = 4
        $stmt = $conn->prepare("
            INSERT INTO users (username, password, email, name, role_id, active, trainer_id, current_plan_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, 4)
        ");
        
        $name = isset($data['name']) ? $data['name'] : '';
        $active = isset($data['active']) ? (int)$data['active'] : 1;
        
        $stmt->bind_param("ssssiis", 
            $data['username'], 
            $hashedPassword, 
            $data['email'], 
            $name, 
            $data['role_id'], 
            $active,
            $trainer_id
        );
        
        if (!$stmt->execute()) {
            $conn->rollback();
            throw new Exception($stmt->error);
        }
        
        $newUserId = $stmt->insert_id;
        
        // Crea la subscription per il nuovo utente con plan_id = 4
        $endDate = date('Y-m-d H:i:s', strtotime('+1 month')); // Imposta la data di fine a 1 mese da oggi
        
        $subStmt = $conn->prepare("
            INSERT INTO user_subscriptions (user_id, plan_id, status, start_date, end_date, auto_renew)
            VALUES (?, 4, 'active', NOW(), ?, 1)
        ");
        
        $subStmt->bind_param("is", $newUserId, $endDate);
        
        if (!$subStmt->execute()) {
            $conn->rollback();
            throw new Exception($subStmt->error);
        }
        
        // Committa la transazione
        $conn->commit();
        
        // Recupera l'utente appena creato
        $stmt = $conn->prepare("
            SELECT u.id, u.username, u.email, u.name, u.role_id, 
                   u.active, u.created_at, r.name as role_name,
                   u.trainer_id, t.username as trainer_username, t.name as trainer_name,
                   u.current_plan_id, p.name as plan_name
            FROM users u
            JOIN user_role r ON u.role_id = r.id
            LEFT JOIN users t ON u.trainer_id = t.id
            LEFT JOIN subscription_plans p ON u.current_plan_id = p.id
            WHERE u.id = ?
        ");
        
        $stmt->bind_param("i", $newUserId);
        $stmt->execute();
        $newUser = $stmt->get_result()->fetch_assoc();
        
        // Format the trainer info
        if ($newUser['trainer_id']) {
            $newUser['trainer'] = [
                'id' => $newUser['trainer_id'],
                'username' => $newUser['trainer_username'],
                'name' => $newUser['trainer_name']
            ];
        }
        
        // Format the plan info
        $newUser['plan'] = [
            'id' => $newUser['current_plan_id'],
            'name' => $newUser['plan_name']
        ];
        
        // Remove redundant fields
        unset($newUser['trainer_id']);
        unset($newUser['trainer_username']);
        unset($newUser['trainer_name']);
        unset($newUser['current_plan_id']);
        unset($newUser['plan_name']);
        
        http_response_code(201); // Created
        echo json_encode([
            'message' => 'Utente creato con successo',
            'user' => $newUser
        ]);
    } catch (Exception $e) {
        // Se siamo in una transazione, rollback
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore nella creazione dell\'utente: ' . $e->getMessage()]);
    }
}

function updateUser($conn, $id, $user) {
    try {
        // Log dettagliati
        error_log("Tentativo di modifica utente. ID target: $id, Utente corrente: " . json_encode($user));
        
        // Dati ricevuti
        $inputData = file_get_contents("php://input");
        $data = json_decode($inputData, true);
        error_log("Dati ricevuti: " . json_encode($data));

        // Verifica ruoli
        $isAdmin = hasRole($user, 'admin');
        $isTrainer = hasRole($user, 'trainer');
        $currentUserId = $user['user_id'];

        // Verifica esistenza utente da modificare
        $checkUserStmt = $conn->prepare("
            SELECT id, trainer_id, role_id, current_plan_id
            FROM users 
            WHERE id = ?
        ");
        $checkUserStmt->bind_param("i", $id);
        $checkUserStmt->execute();
        $userResult = $checkUserStmt->get_result();
        
        if ($userResult->num_rows === 0) {
            error_log("Utente da modificare non trovato: $id");
            http_response_code(404);
            echo json_encode(['error' => 'Utente non trovato']);
            return;
        }

        $targetUser = $userResult->fetch_assoc();
        error_log("Dati utente target: " . json_encode($targetUser));

        // Controlli permessi più dettagliati
        $canModify = $isAdmin || 
                     ($isTrainer && $targetUser['trainer_id'] == $currentUserId) || 
                     ($id == $currentUserId);

        error_log("Può modificare: " . ($canModify ? 'Sì' : 'No'));

        if (!$canModify) {
            error_log("Modifica non autorizzata");
            http_response_code(403);
            echo json_encode(['error' => 'Non hai i permessi per modificare questo utente']);
            return;
        }

        // Preparazione query di update
        $updateFields = [];
        $paramTypes = '';
        $paramValues = [];
        
        // Flag per sapere se è stato modificato il piano
        $planChanged = false;
        $newPlanId = null;

        // Controlli e preparazione campi
        if (isset($data['email'])) {
            // Verifica unicità email
            $emailStmt = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
            $emailStmt->bind_param("si", $data['email'], $id);
            $emailStmt->execute();
            $emailResult = $emailStmt->get_result();
            
            if ($emailResult->num_rows > 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Email già in uso']);
                return;
            }

            $updateFields[] = "email = ?";
            $paramTypes .= "s";
            $paramValues[] = $data['email'];
        }

        if (isset($data['name'])) {
            $updateFields[] = "name = ?";
            $paramTypes .= "s";
            $paramValues[] = $data['name'];
        }

        // Modifica password (solo se fornita)
        if (isset($data['password']) && !empty($data['password'])) {
            $hashedPassword = password_hash($data['password'], PASSWORD_BCRYPT);
            $updateFields[] = "password = ?";
            $paramTypes .= "s";
            $paramValues[] = $hashedPassword;
        }

        // Modifica ruolo (solo per admin)
        if (isset($data['role_id']) && $isAdmin) {
            // Verifica esistenza ruolo
            $roleStmt = $conn->prepare("SELECT id FROM user_role WHERE id = ?");
            $roleStmt->bind_param("i", $data['role_id']);
            $roleStmt->execute();
            $roleResult = $roleStmt->get_result();
            
            if ($roleResult->num_rows === 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Ruolo non valido']);
                return;
            }

            $updateFields[] = "role_id = ?";
            $paramTypes .= "i";
            $paramValues[] = $data['role_id'];
        }

        // Modifica current_plan_id (solo per admin)
        if (isset($data['current_plan_id']) && $isAdmin) {
            // Verifica esistenza piano
            $planStmt = $conn->prepare("SELECT id FROM subscription_plans WHERE id = ?");
            $planStmt->bind_param("i", $data['current_plan_id']);
            $planStmt->execute();
            $planResult = $planStmt->get_result();
            
            if ($planResult->num_rows === 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Piano non valido']);
                return;
            }

            // Se il piano è cambiato, aggiorna anche la subscription
            if ($targetUser['current_plan_id'] != $data['current_plan_id']) {
                $planChanged = true;
                $newPlanId = $data['current_plan_id'];
            }

            $updateFields[] = "current_plan_id = ?";
            $paramTypes .= "i";
            $paramValues[] = $data['current_plan_id'];
        }

        // Modifica trainer (per admin o se è il proprio trainer)
        if (isset($data['trainer_id'])) {
            if ($isAdmin || ($isTrainer && $data['trainer_id'] == $currentUserId)) {
                // Verifica esistenza trainer
                $trainerStmt = $conn->prepare("
                    SELECT id FROM users u
                    JOIN user_role r ON u.role_id = r.id
                    WHERE u.id = ? AND r.name = 'trainer'
                ");
                $trainerStmt->bind_param("i", $data['trainer_id']);
                $trainerStmt->execute();
                $trainerResult = $trainerStmt->get_result();
                
                if ($trainerResult->num_rows === 0) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Trainer non valido']);
                    return;
                }

                $updateFields[] = "trainer_id = ?";
                $paramTypes .= "i";
                $paramValues[] = $data['trainer_id'];
            } else {
                http_response_code(403);
                echo json_encode(['error' => 'Non autorizzato a modificare il trainer']);
                return;
            }
        }

        // Modifica stato utente (solo per admin)
        if (isset($data['active']) && $isAdmin) {
            $updateFields[] = "active = ?";
            $paramTypes .= "i";
            $paramValues[] = $data['active'] ? 1 : 0;
        }

        // Se non ci sono campi da aggiornare
        if (empty($updateFields)) {
            http_response_code(400);
            echo json_encode(['error' => 'Nessun campo da aggiornare']);
            return;
        }

        // Inizia una transazione se il piano è cambiato
        if ($planChanged) {
            $conn->begin_transaction();
        }

        // Aggiungi l'ID come ultimo parametro
        $paramTypes .= "i";
        $paramValues[] = $id;

        // Costruisci la query
        $query = "UPDATE users SET " . implode(", ", $updateFields) . " WHERE id = ?";
        
        // Preparazione e esecuzione statement
        $stmt = $conn->prepare($query);
        $stmt->bind_param($paramTypes, ...$paramValues);

        if (!$stmt->execute()) {
            if ($planChanged) {
                $conn->rollback();
            }
            throw new Exception("Errore durante l'aggiornamento: " . $stmt->error);
        }

        // Se il piano è cambiato, aggiorna la subscription
        if ($planChanged) {
            // Prima disattiva tutte le subscriptions attive
            $disableStmt = $conn->prepare("
                UPDATE user_subscriptions 
                SET status = 'cancelled', updated_at = NOW() 
                WHERE user_id = ? AND status = 'active'
            ");
            $disableStmt->bind_param("i", $id);
            
            if (!$disableStmt->execute()) {
                $conn->rollback();
                throw new Exception("Errore durante l'aggiornamento delle subscriptions: " . $disableStmt->error);
            }
            
            // Crea una nuova subscription con il nuovo piano
            $endDate = date('Y-m-d H:i:s', strtotime('+1 month')); // Imposta la data di fine a 1 mese da oggi
            
            $newSubStmt = $conn->prepare("
                INSERT INTO user_subscriptions (user_id, plan_id, status, start_date, end_date, auto_renew)
                VALUES (?, ?, 'active', NOW(), ?, 1)
            ");
            
            $newSubStmt->bind_param("iis", $id, $newPlanId, $endDate);
            
            if (!$newSubStmt->execute()) {
                $conn->rollback();
                throw new Exception("Errore durante la creazione della nuova subscription: " . $newSubStmt->error);
            }
            
            // Committa la transazione
            $conn->commit();
        }

        // Recupera l'utente aggiornato
        $retrieveStmt = $conn->prepare("
            SELECT u.id, u.username, u.email, u.name, u.role_id, 
                   u.active, u.last_login, u.created_at, r.name as role_name,
                   u.trainer_id, t.username as trainer_username, t.name as trainer_name,
                   u.current_plan_id, p.name as plan_name
            FROM users u
            JOIN user_role r ON u.role_id = r.id
            LEFT JOIN users t ON u.trainer_id = t.id
            LEFT JOIN subscription_plans p ON u.current_plan_id = p.id
            WHERE u.id = ?
        ");
        $retrieveStmt->bind_param("i", $id);
        $retrieveStmt->execute();
        $result = $retrieveStmt->get_result();
        $updatedUser = $result->fetch_assoc();
        
        error_log("Campi da aggiornare: " . json_encode($updateFields));
        error_log("Tipi parametri: $paramTypes");
        error_log("Valori parametri: " . json_encode($paramValues));

        // Prepara la risposta
        $response = [
            'message' => 'Utente aggiornato con successo',
            'user' => [
                'id' => $updatedUser['id'],
                'username' => $updatedUser['username'],
                'email' => $updatedUser['email'],
                'name' => $updatedUser['name'],
                'role_name' => $updatedUser['role_name'],
                'active' => $updatedUser['active'],
                'trainer' => $updatedUser['trainer_id'] ? [
                    'id' => $updatedUser['trainer_id'],
                    'username' => $updatedUser['trainer_username'],
                    'name' => $updatedUser['trainer_name']
                ] : null,
                'plan' => [
                    'id' => $updatedUser['current_plan_id'],
                    'name' => $updatedUser['plan_name']
                ]
            ]
        ];

        echo json_encode($response);

    } catch (Exception $e) {
        // Se siamo in una transazione, rollback
        if ($conn->inTransaction()) {
            $conn->rollback();
        }
        
        error_log("Errore completo nell'aggiornamento utente: " . $e->getMessage());
        error_log("Trace: " . $e->getTraceAsString());
        
        http_response_code(500);
        echo json_encode(['error' => 'Errore interno del server', 'details' => $e->getMessage()]);
    }
}

function deleteUser($conn, $id, $user) {
    try {
        // Verifica se l'utente ha accesso a questo user
        if (!hasAccessToUser($user, $id, $conn)) {
            http_response_code(403);
            echo json_encode(['error' => 'Non hai permessi per eliminare questo utente']);
            return;
        }
        
        // Previeni l'eliminazione di se stessi
        if ((int)$id === (int)$user['user_id']) {
            http_response_code(400);
            echo json_encode(['error' => 'Non puoi eliminare il tuo account']);
            return;
        }
        
        // Verifica che l'utente esista
        $stmt = $conn->prepare("SELECT id FROM users WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['error' => 'Utente non trovato']);
            return;
        }
        
        // Inizia una transazione
        $conn->begin_transaction();
        
        // Elimina prima tutti i token dell'utente
        $stmt = $conn->prepare("DELETE FROM auth_tokens WHERE user_id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        
        // Se l'utente è un trainer, imposta NULL per tutti gli utenti che lo hanno come trainer
        $stmt = $conn->prepare("UPDATE users SET trainer_id = NULL WHERE trainer_id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        
        // Nota: Non è necessario eliminare manualmente le subscriptions poiché
        // la foreign key con ON DELETE CASCADE lo farà automaticamente
        
        // Elimina l'utente
        $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if (!$stmt->execute()) {
            $conn->rollback();
            throw new Exception($stmt->error);
        }
        
        $conn->commit();
        
        echo json_encode(['message' => 'Utente eliminato con successo']);
    } catch (Exception $e) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(['error' => 'Errore nell\'eliminazione dell\'utente: ' . $e->getMessage()]);
    }
}

$conn->close();
?>