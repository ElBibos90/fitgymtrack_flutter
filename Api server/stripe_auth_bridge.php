<?php
// ============================================================================
// STRIPE AUTH BRIDGE - Collega MySQLi auth_functions.php con PDO Stripe
// ============================================================================

/**
 * Funzione bridge per ottenere utente da token (per Stripe)
 * Usa le funzioni esistenti di auth_functions.php ma restituisce per PDO
 */
function get_user_from_token() {
    global $conn;
    
    // Usa la funzione esistente per ottenere header
    $authHeader = getAuthorizationHeader();
    if (!$authHeader) {
        return false;
    }
    
    // Estrai il token
    $token = str_replace('Bearer ', '', $authHeader);
    if (empty($token)) {
        return false;
    }
    
    // Usa la funzione esistente per validare il token
    $userData = validateAuthToken($conn, $token);
    if (!$userData) {
        return false;
    }
    
    // Trasforma i dati nel formato che si aspetta Stripe
    return [
        'id' => $userData['user_id'],
        'username' => $userData['username'],
        'email' => $userData['email'],
        'name' => $userData['name'],
        'role_id' => $userData['role_id'],
        'role_name' => $userData['role_name'],
        'trainer_id' => $userData['trainer_id']
    ];
}

/**
 * Verifica se l'utente ha un ruolo specifico
 */
function user_has_role($user, $roleName) {
    return isset($user['role_name']) && $user['role_name'] === $roleName;
}

/**
 * Verifica se l'utente è admin
 */
function is_admin($user) {
    return user_has_role($user, 'admin');
}

/**
 * Verifica se l'utente è trainer
 */
function is_trainer($user) {
    return user_has_role($user, 'trainer');
}

/**
 * Log di debug per Stripe
 */
function stripe_debug_log($message, $context = []) {
    $logMessage = "[STRIPE DEBUG] " . $message;
    if (!empty($context)) {
        $logMessage .= " | " . json_encode($context);
    }
    error_log($logMessage);
}
?>
