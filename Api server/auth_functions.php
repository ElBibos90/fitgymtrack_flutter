<?php
/**
 * Funzioni di supporto per l'autenticazione
 */

/**
 * Genera un token di autenticazione per un utente
 * 
 * @param mysqli $conn La connessione al database
 * @param int $userId ID dell'utente
 * @param int $expiresInHours Durata validità token in ore (default 24)
 * @return string|false Il token generato o false in caso di errore
 */
function generateAuthToken($conn, $userId, $expiresInHours = 24) {
    // Genera un token sicuro
    $token = bin2hex(random_bytes(32));
    
    // Calcola la data di scadenza
    $expiresAt = date('Y-m-d H:i:s', strtotime("+{$expiresInHours} hours"));
    
    // Salva il token nel database
    $stmt = $conn->prepare("
        INSERT INTO auth_tokens (user_id, token, expires_at)
        VALUES (?, ?, ?)
    ");
    
    $stmt->bind_param("iss", $userId, $token, $expiresAt);
    $result = $stmt->execute();
    
    if (!$result) {
        return false;
    }
    
    return $token;
}

/**
 * Valida un token di autenticazione
 * 
 * @param mysqli $conn La connessione al database
 * @param string $token Il token da validare
 * @return array|false I dati dell'utente o false se il token non è valido
 */
function validateAuthToken($conn, $token) {
    // Pulisci i token scaduti
    clearExpiredTokens($conn);
    
    // Verifica se il token esiste ed è valido
    $stmt = $conn->prepare("
        SELECT t.user_id, t.expires_at, u.username, u.email, u.name, u.role_id, 
               r.name as role_name, u.trainer_id, u.is_tester
        FROM auth_tokens t
        JOIN users u ON t.user_id = u.id
        JOIN user_role r ON u.role_id = r.id
        WHERE t.token = ? AND t.expires_at > NOW() AND u.active = 1
    ");
    
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        return false;
    }
    
    return $result->fetch_assoc();
}

/**
 * Invalida un token di autenticazione (logout)
 * 
 * @param mysqli $conn La connessione al database
 * @param string $token Il token da invalidare
 * @return bool True se l'operazione è riuscita, altrimenti false
 */
function invalidateToken($conn, $token) {
    $stmt = $conn->prepare("DELETE FROM auth_tokens WHERE token = ?");
    $stmt->bind_param("s", $token);
    return $stmt->execute() && $stmt->affected_rows > 0;
}

/**
 * Pulisce i token scaduti dal database
 * 
 * @param mysqli $conn La connessione al database
 */
function clearExpiredTokens($conn) {
    $conn->query("DELETE FROM auth_tokens WHERE expires_at < NOW()");
}

/**
 * Verifica se un utente ha un ruolo specifico
 * 
 * @param array $userData I dati dell'utente ottenuti da validateAuthToken()
 * @param string $roleName Il nome del ruolo da verificare
 * @return bool True se l'utente ha il ruolo, altrimenti false
 */
function hasRole($userData, $roleName) {
    return isset($userData['role_name']) && $userData['role_name'] === $roleName;
}

/**
 * Verifica se l'utente ha accesso all'utente specificato
 * 
 * @param array $userData I dati dell'utente autenticato
 * @param int $targetUserId ID dell'utente target
 * @param mysqli $conn La connessione al database
 * @return bool True se l'utente ha accesso, altrimenti false
 */
function hasAccessToUser($userData, $targetUserId, $conn) {
    // L'admin ha accesso a tutti gli utenti
    if (hasRole($userData, 'admin')) {
        return true;
    }
    
    // Il trainer ha accesso ai clienti della sua palestra
    if (hasRole($userData, 'trainer')) {
        // Verifica se l'utente target appartiene alla stessa palestra del trainer
        $stmt = $conn->prepare("
            SELECT u1.id 
            FROM users u1 
            JOIN users u2 ON u1.gym_id = u2.gym_id
            WHERE u1.id = ? AND u2.id = ? AND u1.gym_id IS NOT NULL
        ");
        $stmt->bind_param("ii", $targetUserId, $userData['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->num_rows > 0;
    }
    
    // Il gestore palestra ha accesso ai membri della sua palestra
    if (hasRole($userData, 'gym')) {
        // Verifica se l'utente target appartiene alla palestra del gestore
        $stmt = $conn->prepare("
            SELECT u1.id 
            FROM users u1 
            JOIN users u2 ON u1.gym_id = u2.gym_id
            WHERE u1.id = ? AND u2.id = ? AND u1.gym_id IS NOT NULL
        ");
        $stmt->bind_param("ii", $targetUserId, $userData['user_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        return $result->num_rows > 0;
    }
    
    // L'utente normale ha accesso solo a se stesso
    return $userData['user_id'] == $targetUserId;
}

/**
 * Rileva se la richiesta proviene dalla webapp o dall'app mobile
 * 
 * @return string 'webapp' o 'mobile'
 */
function detectPlatform() {
    // Controlla User-Agent per rilevare l'app mobile
    $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
    
    // L'app Flutter ha un User-Agent specifico
    if (strpos($userAgent, 'FitGymTrack') !== false || 
        strpos($userAgent, 'Flutter') !== false ||
        strpos($userAgent, 'Dart') !== false) {
        return 'mobile';
    }
    
    // Controlla header personalizzati dell'app
    if (isset($_SERVER['HTTP_X_PLATFORM']) && $_SERVER['HTTP_X_PLATFORM'] === 'mobile') {
        return 'mobile';
    }
    
    // Controlla Origin per webapp
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    if (strpos($origin, 'fitgymtrack.com') !== false || 
        strpos($origin, 'localhost:3000') !== false) {
        return 'webapp';
    }
    
    // Default: webapp
    return 'webapp';
}

/**
 * Middleware per proteggere le API che richiedono autenticazione
 * 
 * @param mysqli $conn La connessione al database
 * @param array $allowedRoles Array di ruoli consentiti (vuoto = tutti i ruoli autenticati)
 * @return array|false I dati dell'utente autenticato o false se non autorizzato
 */
function authMiddleware($conn, $allowedRoles = []) {
    $authHeader = getAuthorizationHeader();
    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(['error' => 'Autenticazione richiesta']);
        return false;
    }
    
    // Estrai il token dall'header
    $token = str_replace('Bearer ', '', $authHeader);
    
    $userData = validateAuthToken($conn, $token);
    if (!$userData) {
        http_response_code(401);
        echo json_encode(['error' => 'Token non valido o scaduto']);
        return false;
    }
    
    // 🔒 CONTROLLO ACCESSO DIFFERENZIATO PER PIATTAFORMA
    $platform = detectPlatform();
    $userRole = $userData['role_name'];
    
    if ($platform === 'webapp') {
        // WebApp: Admin, Trainer, Gym, Standalone (NO User)
        if ($userRole === 'user') {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato: questa piattaforma è riservata a trainer, gestori palestra, amministratori e utenti standalone']);
            return false;
        }
    } elseif ($platform === 'mobile') {
        // App Mobile: Solo User, Standalone (NO Admin, NO Trainer, NO Gym)
        if ($userRole === 'admin' || $userRole === 'trainer' || $userRole === 'gym') {
            http_response_code(403);
            echo json_encode(['error' => 'Accesso negato: questa app è riservata agli utenti e ai membri delle palestre']);
            return false;
        }
    }
    
    // Se sono specificati ruoli consentiti, verifica che l'utente ne abbia uno
    if (!empty($allowedRoles) && !in_array($userData['role_name'], $allowedRoles)) {
        http_response_code(403);
        echo json_encode(['error' => 'Permessi insufficienti']);
        return false;
    }
    
    return $userData;
}

/**
 * Ottiene l'header di autorizzazione
 * 
 * @return string|null L'header Authorization o null se non presente
 */
function getAuthorizationHeader() {
    $headers = null;
    
    if (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER['Authorization']);
    } else if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
    } else if (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        $requestHeaders = array_combine(
            array_map('ucwords', array_keys($requestHeaders)),
            array_values($requestHeaders)
        );
        
        if (isset($requestHeaders['Authorization'])) {
            $headers = trim($requestHeaders['Authorization']);
        }
    }
    
    return $headers;
}
?>