<?php
// test_template_rating_simple.php - Test semplificato per template rating
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'config.php';

// Controlla se auth_functions.php esiste e lo include
if (file_exists('auth_functions.php')) {
    require_once 'auth_functions.php';
    debug_log("auth_functions.php caricato correttamente");
} else {
    debug_log("auth_functions.php NON TROVATO");
}

// Funzione di debug semplice
function debug_log($message) {
    error_log("SIMPLE_TEMPLATE_TEST[" . date('Y-m-d H:i:s') . "]: $message");
}

try {
    debug_log("Inizio test semplificato template rating");
    
    // Test 1: Verifica header Authorization
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
    
    debug_log("Header Authorization presente: " . ($auth_header ? 'SÌ' : 'NO'));
    
    if ($auth_header) {
        debug_log("Header Authorization: " . $auth_header);
        
        // Verifica formato Bearer
        if (strpos($auth_header, 'Bearer ') === 0) {
            debug_log("Formato Bearer corretto");
            $token = substr($auth_header, 7);
            debug_log("Token estratto (primi 20 caratteri): " . substr($token, 0, 20) . "...");
            
            // Test verifica token con auth_functions
            debug_log("Controllando se funzione verifyToken esiste...");
            if (function_exists('verifyToken')) {
                debug_log("Funzione verifyToken trovata, verificando token...");
                $auth_result = verifyToken($auth_header);
                debug_log("Risultato verifica token: " . ($auth_result['success'] ? 'SUCCESSO' : 'FALLIMENTO'));
                
                if ($auth_result['success']) {
                    debug_log("User ID: " . $auth_result['user_id']);
                    debug_log("Username: " . ($auth_result['username'] ?? 'N/A'));
                    
                    // Test inserimento rating (simulato)
                    debug_log("Testando inserimento rating...");
                    
                    // Verifica se le tabelle esistono
                    $tables_check = $conn->query("SHOW TABLES LIKE 'user_template_ratings'");
                    $table_exists = $tables_check->num_rows > 0;
                    debug_log("Tabella user_template_ratings esiste: " . ($table_exists ? 'SÌ' : 'NO'));
                    
                    if ($table_exists) {
                        // Test inserimento (senza salvare)
                        $template_id = 1; // Template di test
                        $rating = 5;
                        $review = "Test review";
                        $user_id = $auth_result['user_id'];
                        
                        debug_log("Simulando inserimento rating per template $template_id, user $user_id, rating $rating");
                        
                        // Verifica se esiste già un rating
                        $check_stmt = $conn->prepare("SELECT id FROM user_template_ratings WHERE template_id = ? AND user_id = ?");
                        $check_stmt->bind_param('ii', $template_id, $user_id);
                        $check_stmt->execute();
                        $existing = $check_stmt->get_result();
                        
                        if ($existing->num_rows > 0) {
                            debug_log("Rating esistente trovato, simulando UPDATE");
                        } else {
                            debug_log("Nessun rating esistente, simulando INSERT");
                        }
                        
                        echo json_encode([
                            'success' => true,
                            'message' => 'Test template rating completato',
                            'results' => [
                                'is_authenticated' => true,
                                'auth_header_present' => true,
                                'auth_header_format' => 'CORRETTO',
                                'token_verification' => 'SUCCESSO',
                                'user_id' => $auth_result['user_id'],
                                'username' => $auth_result['username'],
                                'table_exists' => $table_exists,
                                'rating_test' => 'SIMULAZIONE_OK'
                            ],
                            'recommendations' => [
                                'Autenticazione funzionante',
                                'Tabelle database OK',
                                'Sistema rating pronto'
                            ]
                        ]);
                    } else {
                        echo json_encode([
                            'success' => false,
                            'message' => 'Tabella user_template_ratings non esiste',
                            'results' => [
                                'is_authenticated' => true,
                                'auth_header_present' => true,
                                'auth_header_format' => 'CORRETTO',
                                'token_verification' => 'SUCCESSO',
                                'user_id' => $auth_result['user_id'],
                                'username' => $auth_result['username'],
                                'table_exists' => false,
                                'rating_test' => 'FALLITO'
                            ],
                            'recommendations' => [
                                'Autenticazione funzionante',
                                'Eseguire fix_template_ratings.php per creare le tabelle'
                            ]
                        ]);
                    }
                } else {
                    debug_log("Errore: " . $auth_result['message']);
                    echo json_encode([
                        'success' => false,
                        'message' => 'Token non valido: ' . $auth_result['message'],
                        'results' => [
                            'is_authenticated' => false,
                            'auth_header_present' => true,
                            'auth_header_format' => 'CORRETTO',
                            'token_verification' => 'FALLIMENTO',
                            'error' => $auth_result['message']
                        ]
                    ]);
                }
            } else {
                debug_log("Funzione verifyToken non disponibile");
                echo json_encode([
                    'success' => false,
                    'message' => 'Funzione verifyToken non disponibile',
                    'results' => [
                        'is_authenticated' => false,
                        'auth_header_present' => true,
                        'auth_header_format' => 'CORRETTO',
                        'token_verification' => 'FUNZIONE_MANCANTE'
                    ]
                ]);
            }
        } else {
            debug_log("Formato Bearer NON corretto");
            echo json_encode([
                'success' => false,
                'message' => 'Formato token non corretto',
                'results' => [
                    'is_authenticated' => false,
                    'auth_header_present' => true,
                    'auth_header_format' => 'NON_CORRETTO'
                ]
            ]);
        }
    } else {
        debug_log("Nessun header Authorization trovato");
        echo json_encode([
            'success' => false,
            'message' => 'Header Authorization mancante',
            'results' => [
                'is_authenticated' => false,
                'auth_header_present' => false,
                'auth_header_format' => 'N/A'
            ]
        ]);
    }
    
} catch (Exception $e) {
    debug_log("Errore nel test: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Errore nel test: ' . $e->getMessage(),
        'error_details' => [
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]
    ]);
}
?>
