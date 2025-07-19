<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';

// ============================================================================
// STRIPE SUBSCRIPTION MANAGEMENT - FIXED VERSION FOR POST-PAYMENT
// ============================================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Verifica che Stripe sia configurato
if (!stripe_is_configured()) {
    stripe_json_response(false, null, 'Stripe non configurato correttamente');
}

// Get user from token
$user = get_user_from_token();
if (!$user) {
    http_response_code(401);
    stripe_json_response(false, null, 'Token non valido');
}

$user_id = $user['id'];
$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            handle_get_subscription($user_id);
            break;
            
        case 'POST':
            handle_create_subscription($user_id);
            break;
            
        case 'PUT':
            handle_update_subscription($user_id);
            break;
            
        case 'DELETE':
            handle_cancel_subscription($user_id);
            break;
            
        default:
            http_response_code(405);
            stripe_json_response(false, null, 'Metodo non supportato');
    }
    
} catch (Exception $e) {
    stripe_log_error('Subscription endpoint error', [
        'user_id' => $user_id,
        'method' => $method,
        'error' => $e->getMessage()
    ]);
    handle_stripe_error($e);
}

// ============================================================================
// SUBSCRIPTION FUNCTIONS
// ============================================================================

/**
 * 🚀 FIXED: Ottiene la subscription corrente dell'utente - INCLUDE INCOMPLETE STATUS
 */
function handle_get_subscription($user_id) {
    global $pdo;
    
    // 🔧 FIX: Include query parameters per post-payment handling
    $include_cancelled = isset($_GET['include_cancelled']) && $_GET['include_cancelled'] === 'true';
    $include_incomplete = isset($_GET['include_incomplete']) && $_GET['include_incomplete'] === 'true';
    $include_recent = isset($_GET['include_recent']) && $_GET['include_recent'] === 'true';
    
    // 🚀 NUOVA: Lista status comprehensiva per gestire tutti i casi
    $allowed_statuses = ['active', 'past_due', 'unpaid'];
    
    // 🔧 FIX PRINCIPALE: Include incomplete status per subscription appena create
    if ($include_incomplete || $include_recent) {
        $allowed_statuses[] = 'incomplete';
        $allowed_statuses[] = 'incomplete_expired';
    }
    
    // Include subscription cancellate se richiesto
    if ($include_cancelled) {
        $allowed_statuses[] = 'cancelled';
        $allowed_statuses[] = 'cancel_at_period_end';
    }
    
    // 🚀 NUOVO: Logging per debug post-payment
    stripe_log_info("GET Subscription - User: $user_id, Statuses: " . json_encode($allowed_statuses), [
        'include_incomplete' => $include_incomplete,
        'include_recent' => $include_recent,
        'include_cancelled' => $include_cancelled
    ]);

error_log("=== STRIPE DEBUG START ===");
error_log("DEBUG User ID: " . $user_id);
error_log("DEBUG GET params: " . json_encode($_GET));
error_log("DEBUG include_recent: " . ($include_recent ? 'true' : 'false'));
error_log("DEBUG include_incomplete: " . ($include_incomplete ? 'true' : 'false'));
error_log("DEBUG allowed_statuses: " . json_encode($allowed_statuses));

// 🔧 TEST QUERY DIRETTA per vedere se la subscription esiste
$debug_stmt = $pdo->prepare("SELECT COUNT(*) as count FROM stripe_subscriptions WHERE user_id = ?");
$debug_stmt->execute([$user_id]);
$debug_count = $debug_stmt->fetch(PDO::FETCH_ASSOC);
error_log("DEBUG Total subscriptions for user $user_id: " . $debug_count['count']);

// 🔧 TEST QUERY SPECIFICA per la subscription che dovrebbe esistere
$debug_stmt2 = $pdo->prepare("SELECT stripe_subscription_id, status, created_at FROM stripe_subscriptions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1");
$debug_stmt2->execute([$user_id]);
$debug_sub = $debug_stmt2->fetch(PDO::FETCH_ASSOC);
error_log("DEBUG Latest subscription: " . json_encode($debug_sub));

// 🔧 TEST QUERY CON STATUS ACTIVE
$debug_stmt3 = $pdo->prepare("SELECT stripe_subscription_id, status FROM stripe_subscriptions WHERE user_id = ? AND status = 'active'");
$debug_stmt3->execute([$user_id]);
$debug_active = $debug_stmt3->fetch(PDO::FETCH_ASSOC);
error_log("DEBUG Active subscription: " . json_encode($debug_active));

error_log("=== STRIPE DEBUG END ===");

    
    // Crea placeholders per la query
    $status_placeholders = str_repeat('?,', count($allowed_statuses) - 1) . '?';
    
    // 🔧 FIX: Query che include tutti gli status necessari
    $stmt = $pdo->prepare("
        SELECT 
            stripe_subscription_id,
            stripe_customer_id,
            status,
            current_period_start,
            current_period_end,
            cancel_at_period_end,
            plan_id,
            price_id,
            created_at,
            updated_at
        FROM stripe_subscriptions 
        WHERE user_id = ? 
        AND status IN ($status_placeholders)
        ORDER BY created_at DESC 
        LIMIT 1
    ");
    
    // Execute con parametri dinamici
    $params = array_merge([$user_id], $allowed_statuses);
    $stmt->execute($params);
    $local_subscription = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // 🚀 NUOVO: Enhanced logging per troubleshooting
    if ($local_subscription) {
        stripe_log_info("Local subscription found: {$local_subscription['stripe_subscription_id']} (status: {$local_subscription['status']})");
    } else {
        stripe_log_info("No local subscription found for user $user_id with statuses: " . json_encode($allowed_statuses));
        
        // 🔧 FIX: Se non trova nulla ma era una ricerca post-payment, cerca tutte le subscription
        if ($include_recent) {
            stripe_log_info("Post-payment search failed, checking all subscription statuses...");
            
            $stmt = $pdo->prepare("
                SELECT stripe_subscription_id, status, created_at 
                FROM stripe_subscriptions 
                WHERE user_id = ? 
                ORDER BY created_at DESC 
                LIMIT 5
            ");
            $stmt->execute([$user_id]);
            $all_subscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            stripe_log_info("All subscriptions for user $user_id: " . json_encode($all_subscriptions));
        }
    }
    
    if (!$local_subscription) {
        stripe_json_response(true, [
            'subscription' => null,
            'subscriptions' => [] // 🚀 NUOVO: Array vuoto per compatibilità frontend
        ], 'Nessuna subscription trovata');
        return;
    }
    
    try {
        // Verifica su Stripe
        $stripe_subscription = \Stripe\Subscription::retrieve($local_subscription['stripe_subscription_id']);
        
        // 🔧 FIX: Aggiorna dati locali se necessario (soprattutto status)
        update_local_subscription($user_id, $stripe_subscription);
        
        // 🚀 NUOVO: Logging successful retrieval
        stripe_log_info("Stripe subscription retrieved successfully: {$stripe_subscription->id} (status: {$stripe_subscription->status})");
        
        $formatted_subscription = format_subscription_response($stripe_subscription);
        
        // 🚀 NUOVO: Supporta sia formato singolo che array per frontend flexibility
        stripe_json_response(true, [
            'subscription' => $formatted_subscription,
            'subscriptions' => [$formatted_subscription] // 🚀 NUOVO: Per frontend che cerca array
        ], 'Subscription recuperata');
        
    } catch (\Stripe\Exception\InvalidRequestException $e) {
        // Subscription non esiste più su Stripe
        stripe_log_info("Stripe subscription not found, marking as cancelled: {$local_subscription['stripe_subscription_id']}");
        
        // Aggiorna stato locale
        $stmt = $pdo->prepare("UPDATE stripe_subscriptions SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP WHERE user_id = ?");
        $stmt->execute([$user_id]);
        
        stripe_json_response(true, [
            'subscription' => null,
            'subscriptions' => []
        ], 'Subscription non più attiva');
    } catch (Exception $e) {
        stripe_log_error("Error retrieving Stripe subscription: {$local_subscription['stripe_subscription_id']}", [
            'error' => $e->getMessage()
        ]);
        
        // 🔧 FIX: In caso di errore, restituisci comunque i dati locali se disponibili
        if ($local_subscription['status'] === 'incomplete' && $include_recent) {
            stripe_log_info("Returning local incomplete subscription data due to Stripe API error");
            
            $local_formatted = [
                'id' => $local_subscription['stripe_subscription_id'],
                'status' => $local_subscription['status'],
                'customer_id' => $local_subscription['stripe_customer_id'],
                'current_period_start' => $local_subscription['current_period_start'],
                'current_period_end' => $local_subscription['current_period_end'],
                'cancel_at_period_end' => (bool)$local_subscription['cancel_at_period_end'],
                'items' => [
                    [
                        'price' => [
                            'id' => $local_subscription['price_id'],
                            'amount' => 499, // Default per compatibilità
                            'currency' => 'eur'
                        ]
                    ]
                ]
            ];
            
            stripe_json_response(true, [
                'subscription' => $local_formatted,
                'subscriptions' => [$local_formatted]
            ], 'Subscription (dati locali)');
        } else {
            throw $e;
        }
    }
}

/**
 * 🔧 ENHANCED: Crea una nuova subscription con better status tracking
 */
function handle_create_subscription($user_id) {
    global $pdo;
    
    $input = json_decode(file_get_contents('php://input'), true);
    $customer_id = $input['customer_id'] ?? '';
    $price_id = $input['price_id'] ?? '';
    $metadata = $input['metadata'] ?? [];
    
    if (empty($customer_id) || empty($price_id)) {
        stripe_json_response(false, null, 'customer_id e price_id sono obbligatori');
    }
    
    try {
        // Verifica che il customer appartenga all'utente
        $stmt = $pdo->prepare("SELECT id FROM stripe_customers WHERE user_id = ? AND stripe_customer_id = ?");
        $stmt->execute([$user_id, $customer_id]);
        if (!$stmt->fetch()) {
            stripe_json_response(false, null, 'Cliente non valido');
        }
        
        // Cancella subscription esistenti
        cancel_existing_subscriptions($user_id);
        
        // 🚀 NUOVO: Enhanced logging pre-creation
        stripe_log_info("Creating new Stripe subscription", [
            'user_id' => $user_id,
            'customer_id' => $customer_id,
            'price_id' => $price_id,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
        // Crea subscription su Stripe
        $stripe_subscription = \Stripe\Subscription::create([
            'customer' => $customer_id,
            'items' => [
                ['price' => $price_id]
            ],
            'payment_behavior' => 'default_incomplete',
            'payment_settings' => [
                'save_default_payment_method' => 'on_subscription'
            ],
            'expand' => ['latest_invoice.payment_intent'],
            'metadata' => array_merge($metadata, [
                'user_id' => $user_id,
                'platform' => 'fitgymtrack_flutter',
                'created_timestamp' => time()
            ])
        ]);
        
        // 🚀 NUOVO: Enhanced logging post-creation
        stripe_log_info("Stripe subscription created successfully", [
            'subscription_id' => $stripe_subscription->id,
            'status' => $stripe_subscription->status,
            'user_id' => $user_id,
            'customer_id' => $customer_id
        ]);
        
        // Salva nel database
        save_subscription_to_db($user_id, $stripe_subscription, $customer_id);
        
        stripe_log_info("Subscription saved to database: {$stripe_subscription->id}");
        
        stripe_json_response(true, [
            'subscription' => format_subscription_response($stripe_subscription),
            'client_secret' => $stripe_subscription->latest_invoice->payment_intent->client_secret
        ], 'Subscription creata');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to create subscription', [
            'user_id' => $user_id,
            'customer_id' => $customer_id,
            'price_id' => $price_id,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        throw $e;
    }
}

/**
 * Aggiorna una subscription
 */
function handle_update_subscription($user_id) {
    global $pdo;
    
    $input = json_decode(file_get_contents('php://input'), true);
    $subscription_id = $input['subscription_id'] ?? '';
    $new_price_id = $input['price_id'] ?? '';
    
    if (empty($subscription_id)) {
        stripe_json_response(false, null, 'subscription_id è obbligatorio');
    }
    
    // Verifica ownership
    $stmt = $pdo->prepare("SELECT id FROM stripe_subscriptions WHERE user_id = ? AND stripe_subscription_id = ?");
    $stmt->execute([$user_id, $subscription_id]);
    if (!$stmt->fetch()) {
        stripe_json_response(false, null, 'Subscription non trovata');
    }
    
    try {
        $stripe_subscription = \Stripe\Subscription::retrieve($subscription_id);
        
        $update_data = [];
        
        // Cambia prezzo se specificato
        if (!empty($new_price_id)) {
            $update_data['items'] = [
                [
                    'id' => $stripe_subscription->items->data[0]->id,
                    'price' => $new_price_id
                ]
            ];
        }
        
        // Aggiorna su Stripe
        $updated_subscription = \Stripe\Subscription::update($subscription_id, $update_data);
        
        // Aggiorna nel database
        update_local_subscription($user_id, $updated_subscription);
        
        stripe_log_info("Stripe subscription updated: {$subscription_id}");
        
        stripe_json_response(true, [
            'subscription' => format_subscription_response($updated_subscription)
        ], 'Subscription aggiornata');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to update subscription', [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * Cancella una subscription
 */
function handle_cancel_subscription($user_id) {
    global $pdo;
    
    $input = json_decode(file_get_contents('php://input'), true);
    $subscription_id = $input['subscription_id'] ?? '';
    $immediately = $input['immediately'] ?? false;
    
    if (empty($subscription_id)) {
        stripe_json_response(false, null, 'subscription_id è obbligatorio');
    }
    
    // Verifica ownership
    $stmt = $pdo->prepare("SELECT id FROM stripe_subscriptions WHERE user_id = ? AND stripe_subscription_id = ?");
    $stmt->execute([$user_id, $subscription_id]);
    if (!$stmt->fetch()) {
        stripe_json_response(false, null, 'Subscription non trovata');
    }
    
    try {
        if ($immediately) {
            // Cancella immediatamente
            $stripe_subscription = \Stripe\Subscription::retrieve($subscription_id);
            $stripe_subscription->cancel();
        } else {
            // Cancella a fine periodo
            \Stripe\Subscription::update($subscription_id, [
                'cancel_at_period_end' => true
            ]);
        }
        
        // Aggiorna database
        $status = $immediately ? 'cancelled' : 'cancel_at_period_end';
        $stmt = $pdo->prepare("
            UPDATE stripe_subscriptions 
            SET status = ?, cancel_at_period_end = ?, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND stripe_subscription_id = ?
        ");
        $stmt->execute([$status, !$immediately, $user_id, $subscription_id]);
        
        stripe_log_info("Stripe subscription cancelled: {$subscription_id} (immediately: " . ($immediately ? 'yes' : 'no') . ")");
        
        stripe_json_response(true, null, $immediately ? 'Subscription cancellata' : 'Subscription verrà cancellata a fine periodo');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to cancel subscription', [
            'user_id' => $user_id,
            'subscription_id' => $subscription_id,
            'immediately' => $immediately,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Cancella subscription esistenti per l'utente
 */
function cancel_existing_subscriptions($user_id) {
    global $pdo;
    
    $stmt = $pdo->prepare("
        SELECT stripe_subscription_id 
        FROM stripe_subscriptions 
        WHERE user_id = ? AND status IN ('active', 'past_due', 'unpaid', 'incomplete')
    ");
    $stmt->execute([$user_id]);
    $subscriptions = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    foreach ($subscriptions as $subscription_id) {
        try {
            $stripe_subscription = \Stripe\Subscription::retrieve($subscription_id);
            $stripe_subscription->cancel();
            
            stripe_log_info("Cancelled existing subscription: {$subscription_id}");
        } catch (Exception $e) {
            stripe_log_error("Failed to cancel existing subscription: {$subscription_id}", ['error' => $e->getMessage()]);
        }
    }
    
    // Aggiorna database
    $stmt = $pdo->prepare("
        UPDATE stripe_subscriptions 
        SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
        WHERE user_id = ? AND status IN ('active', 'past_due', 'unpaid', 'incomplete')
    ");
    $stmt->execute([$user_id]);
}

/**
 * 🔧 ENHANCED: Salva subscription nel database con better error handling
 */
function save_subscription_to_db($user_id, $stripe_subscription, $customer_id) {
    global $pdo;
    
    try {
        $price_id = $stripe_subscription->items->data[0]->price->id;
        
        // Trova plan_id locale se esiste
        $plan_id = null;
        if ($price_id === STRIPE_PREMIUM_MONTHLY_PRICE_ID) {
            $plan_id = 2; // Premium monthly
        } elseif ($price_id === STRIPE_PREMIUM_YEARLY_PRICE_ID) {
            $plan_id = 3; // Premium yearly
        }
        
        // 🚀 NUOVO: Logging pre-save
        stripe_log_info("Saving subscription to database", [
            'user_id' => $user_id,
            'subscription_id' => $stripe_subscription->id,
            'status' => $stripe_subscription->status,
            'price_id' => $price_id,
            'plan_id' => $plan_id
        ]);
        
        $stmt = $pdo->prepare("
            INSERT INTO stripe_subscriptions (
                user_id, stripe_subscription_id, stripe_customer_id, status,
                current_period_start, current_period_end, cancel_at_period_end,
                plan_id, price_id, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON DUPLICATE KEY UPDATE
            status = VALUES(status),
            current_period_start = VALUES(current_period_start),
            current_period_end = VALUES(current_period_end),
            cancel_at_period_end = VALUES(cancel_at_period_end),
            updated_at = CURRENT_TIMESTAMP
        ");
        
        $stmt->execute([
            $user_id,
            $stripe_subscription->id,
            $customer_id,
            $stripe_subscription->status,
            $stripe_subscription->current_period_start,
            $stripe_subscription->current_period_end,
            $stripe_subscription->cancel_at_period_end ? 1 : 0,
            $plan_id,
            $price_id
        ]);
        
        stripe_log_info("Subscription saved successfully to database: {$stripe_subscription->id}");
        
    } catch (Exception $e) {
        stripe_log_error("Failed to save subscription to database", [
            'subscription_id' => $stripe_subscription->id,
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * 🔧 ENHANCED: Aggiorna subscription locale con dati Stripe
 */
function update_local_subscription($user_id, $stripe_subscription) {
    global $pdo;
    
    try {
        // 🚀 NUOVO: Logging pre-update
        stripe_log_info("Updating local subscription", [
            'subscription_id' => $stripe_subscription->id,
            'new_status' => $stripe_subscription->status,
            'user_id' => $user_id
        ]);
        
        $stmt = $pdo->prepare("
            UPDATE stripe_subscriptions 
            SET 
                status = ?,
                current_period_start = ?,
                current_period_end = ?,
                cancel_at_period_end = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = ? AND stripe_subscription_id = ?
        ");
        
        $result = $stmt->execute([
            $stripe_subscription->status,
            $stripe_subscription->current_period_start,
            $stripe_subscription->current_period_end,
            $stripe_subscription->cancel_at_period_end ? 1 : 0,
            $user_id,
            $stripe_subscription->id
        ]);
        
        if ($result) {
            stripe_log_info("Local subscription updated successfully: {$stripe_subscription->id}");
        } else {
            stripe_log_error("Failed to update local subscription: {$stripe_subscription->id}");
        }
        
    } catch (Exception $e) {
        stripe_log_error("Error updating local subscription", [
            'subscription_id' => $stripe_subscription->id,
            'user_id' => $user_id,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * Formatta response subscription
 */
function format_subscription_response($stripe_subscription) {
    $price = $stripe_subscription->items->data[0]->price;
    
    return [
        'id' => $stripe_subscription->id,
        'customer_id' => $stripe_subscription->customer,
        'status' => $stripe_subscription->status,
        // 🔧 FIX: NULL SAFETY per timestamp
        'current_period_start' => $stripe_subscription->current_period_start ?? 0,
        'current_period_end' => $stripe_subscription->current_period_end ?? 0,
        'cancel_at_period_end' => $stripe_subscription->cancel_at_period_end ?? false,
        'items' => [
            [
                'id' => $stripe_subscription->items->data[0]->id,
                'price' => [
                    'id' => $price->id,
                    // 🔧 FIX: NULL SAFETY per amount
                    'amount' => $price->unit_amount ?? 0,
                    'currency' => $price->currency ?? 'eur',
                    'interval' => $price->recurring->interval ?? 'month',
                    'interval_count' => $price->recurring->interval_count ?? 1,
                    'product' => [
                        'id' => $price->product->id ?? $price->product,
                        'name' => is_object($price->product) ? $price->product->name : 'Premium Plan'
                    ]
                ]
            ]
        ],
        'latest_invoice' => $stripe_subscription->latest_invoice ?? null,
        'metadata' => $stripe_subscription->metadata->toArray() ?? []
    ];
}
?>