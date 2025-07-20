<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';

// ============================================================================
// STRIPE SUBSCRIPTION PAYMENT INTENT - DEBUG VERSION WITH FILE LOGGING
// ============================================================================

// 🔧 CUSTOM LOGGING FUNCTION - Scrive nella cartella api/stripe/
function debug_log($message) {
    $log_file = __DIR__ . '/debug_subscription.log';
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND | LOCK_EX);
}

// 🔧 Cancella log precedente ad ogni test
$log_file = __DIR__ . '/debug_subscription.log';
if (file_exists($log_file)) {
    unlink($log_file);
}

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 🔍 DEBUG: Log della richiesta iniziale
debug_log("=== STRIPE SUBSCRIPTION PAYMENT INTENT DEBUG START ===");
debug_log("Request Method: " . $_SERVER['REQUEST_METHOD']);
debug_log("Request URI: " . $_SERVER['REQUEST_URI']);
debug_log("Headers: " . json_encode(getallheaders()));

// Solo POST supportato
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    debug_log("ERROR: Method not allowed - " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    stripe_json_response(false, null, 'Solo POST supportato');
}

// 🔍 DEBUG: Verifica configurazione Stripe
debug_log("Checking Stripe configuration...");
if (!stripe_is_configured()) {
    debug_log("ERROR: Stripe not configured");
    stripe_json_response(false, null, 'Stripe non configurato correttamente');
} else {
    debug_log("SUCCESS: Stripe is configured");
}

// 🔍 DEBUG: Verifica autenticazione
debug_log("Getting user from token...");
$user = get_user_from_token();
if (!$user) {
    debug_log("ERROR: Invalid token");
    http_response_code(401);
    stripe_json_response(false, null, 'Token non valido');
} else {
    debug_log("SUCCESS: User authenticated - ID: " . $user['id'] . ", Email: " . ($user['email'] ?? 'no-email'));
}

$user_id = $user['id'];

try {
    debug_log("Calling handle_create_subscription_payment_intent for user: " . $user_id);
    handle_create_subscription_payment_intent($user_id, $user);
} catch (Exception $e) {
    debug_log("FATAL ERROR in subscription payment intent: " . $e->getMessage());
    debug_log("Stack trace: " . $e->getTraceAsString());
    stripe_log_error('Subscription payment intent error', [
        'user_id' => $user_id,
        'error' => $e->getMessage()
    ]);
    handle_stripe_error($e);
}

// ============================================================================
// MAIN FUNCTION WITH EXTENSIVE DEBUG LOGGING
// ============================================================================

/**
 * 🚀 DEBUG: Crea un Payment Intent per subscription con logging esteso
 */
function handle_create_subscription_payment_intent($user_id, $user_data) {
    global $pdo;
    
    debug_log("=== HANDLE CREATE SUBSCRIPTION PAYMENT INTENT START ===");
    debug_log("User ID: " . $user_id);
    debug_log("User data: " . json_encode($user_data));
    
    // 🔍 DEBUG: Parse request data
    $raw_input = file_get_contents('php://input');
    debug_log("Raw input: " . $raw_input);
    
    $input = json_decode($raw_input, true);
    debug_log("Parsed input: " . json_encode($input));
    
    if ($input === null) {
        debug_log("ERROR: JSON decode failed - " . json_last_error_msg());
        stripe_json_response(false, null, 'Errore nel parsing JSON: ' . json_last_error_msg());
        return;
    }
    
    $price_id = $input['price_id'] ?? '';
    $metadata = $input['metadata'] ?? [];
    
    debug_log("Extracted price_id: " . $price_id);
    debug_log("Extracted metadata: " . json_encode($metadata));
    
    // 🆕 NUOVO: Estrai payment_type dai metadata
    $payment_type = $metadata['payment_type'] ?? 'recurring'; // Default: recurring
    
    debug_log("Payment type: " . $payment_type);
    
    stripe_log_info("Creating subscription payment intent", [
        'user_id' => $user_id,
        'price_id' => $price_id,
        'payment_type' => $payment_type
    ]);
    
    // 🔍 DEBUG: Validazione price_id
    debug_log("=== VALIDATION PHASE START ===");
    
    if (empty($price_id)) {
        debug_log("ERROR: price_id is empty");
        stripe_json_response(false, null, 'price_id è obbligatorio');
        return;
    } else {
        debug_log("SUCCESS: price_id is not empty: " . $price_id);
    }
    
    // 🆕 NUOVO: Valida payment_type
    if (!in_array($payment_type, ['recurring', 'onetime'])) {
        debug_log("ERROR: Invalid payment_type: " . $payment_type);
        stripe_json_response(false, null, 'payment_type deve essere "recurring" o "onetime"');
        return;
    } else {
        debug_log("SUCCESS: payment_type is valid: " . $payment_type);
    }
    
    // 🔍 DEBUG: Verifica che il price_id sia valido per entrambi i tipi
    $valid_prices = [
        'price_1RXVOfHHtQGHyul9qMGFmpmO',  // Ricorrente
        'price_1RbmRkHHtQGHyul92oUMSkUY',  // OneTime
    ];
    
    debug_log("Valid prices: " . json_encode($valid_prices));
    debug_log("Checking if price_id '" . $price_id . "' is in valid prices...");
    
    if (!in_array($price_id, $valid_prices)) {
        debug_log("ERROR: price_id not in valid prices");
        debug_log("Provided: " . $price_id);
        debug_log("Valid: " . implode(', ', $valid_prices));
        stripe_json_response(false, null, 'price_id non valido: ' . $price_id . '. Validi: ' . implode(', ', $valid_prices));
        return;
    } else {
        debug_log("SUCCESS: price_id is valid");
    }
    
    debug_log("=== VALIDATION PHASE COMPLETED ===");
    
    try {
        debug_log("=== STRIPE OPERATIONS START ===");
        
        // 🚀 NEW: Ottieni o crea Stripe customer - STRIPE-ONLY VERSION
        debug_log("Getting or creating Stripe customer...");
        $stripe_customer_id = get_or_create_stripe_customer_stripe_only($user_id, $user_data);
        debug_log("Got customer ID: " . $stripe_customer_id);
        
        // Cancella subscription esistenti
        debug_log("Cancelling existing subscriptions...");
        cancel_existing_subscriptions_stripe_only($user_id, $stripe_customer_id);
        debug_log("Existing subscriptions cancelled");
        
        // 🆕 UPDATED: Crea subscription con metadata che include payment_type
        $subscription_data = [
            'customer' => $stripe_customer_id,
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
                'payment_type' => $payment_type, // 🆕 NUOVO: Include payment_type
                'platform' => 'fitgymtrack_flutter',
                'created_timestamp' => time()
            ])
        ];
        
        // 🆕 NUOVO: Se è onetime, configura per cancellarsi automaticamente
        if ($payment_type === 'onetime') {
            $subscription_data['cancel_at_period_end'] = true;
            debug_log("Onetime subscription: setting cancel_at_period_end = true");
            stripe_log_info("Onetime subscription: setting cancel_at_period_end = true");
        }
        
        debug_log("Subscription data: " . json_encode($subscription_data));
        debug_log("Creating Stripe subscription...");
        
        $subscription = \Stripe\Subscription::create($subscription_data);
        debug_log("Stripe subscription created: " . $subscription->id);
        debug_log("Subscription status: " . $subscription->status);
        debug_log("Cancel at period end: " . ($subscription->cancel_at_period_end ? 'true' : 'false'));
        
        // 🆕 UPDATED: Salva subscription nel database con payment_type
        debug_log("Saving subscription to database...");
        save_subscription_to_db($user_id, $subscription, $stripe_customer_id, $price_id, $payment_type);
        debug_log("Subscription saved to database");
        
        // Ottieni payment intent
        debug_log("Getting payment intent from subscription...");
        $payment_intent = $subscription->latest_invoice->payment_intent;
        debug_log("Payment intent ID: " . $payment_intent->id);
        debug_log("Payment intent status: " . $payment_intent->status);
        
        // 🆕 UPDATED: Salva payment intent con payment_type nei metadata
        debug_log("Saving payment intent to database...");
        save_payment_intent_to_db($user_id, $payment_intent, 'subscription', $payment_type, $subscription->id);
        debug_log("Payment intent saved to database");
        
        stripe_log_info("Subscription payment intent created successfully", [
            'payment_intent_id' => $payment_intent->id,
            'subscription_id' => $subscription->id,
            'user_id' => $user_id,
            'price_id' => $price_id,
            'payment_type' => $payment_type
        ]);
        
        $response_data = [
            'payment_intent' => [
                'client_secret' => $payment_intent->client_secret,
                'payment_intent_id' => $payment_intent->id,
                'status' => $payment_intent->status,
                'amount' => $payment_intent->amount,
                'currency' => $payment_intent->currency,
                'customer_id' => $payment_intent->customer
            ],
            'subscription' => [
                'id' => $subscription->id,
                'status' => $subscription->status,
                'customer_id' => $subscription->customer,
                'payment_type' => $payment_type,  // 🆕 NUOVO: Include nel response
                'cancel_at_period_end' => $subscription->cancel_at_period_end
            ]
        ];
        
        debug_log("Response data: " . json_encode($response_data));
        debug_log("=== SUCCESS: Sending response ===");
        
        stripe_json_response(true, $response_data, 'Payment Intent per subscription creato');
        
    } catch (Exception $e) {
        debug_log("EXCEPTION in Stripe operations: " . $e->getMessage());
        debug_log("Exception trace: " . $e->getTraceAsString());
        
        stripe_log_error('Failed to create subscription payment intent', [
            'user_id' => $user_id,
            'price_id' => $price_id,
            'payment_type' => $payment_type,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

// ============================================================================
// STRIPE-ONLY HELPER FUNCTIONS WITH DEBUG LOGGING
// ============================================================================

/**
 * 🚀 NEW: Ottiene o crea un Stripe customer - STRIPE-ONLY VERSION
 * (Consistent with customer.php logic)
 */
function get_or_create_stripe_customer_stripe_only($user_id, $user_data) {
    debug_log("=== GET OR CREATE CUSTOMER START ===");
    
    $email = $user_data['email'] ?? "user{$user_id}@fitgymtrack.com";
    $name = $user_data['username'] ?? "User {$user_id}";
    
    debug_log("Customer email: " . $email);
    debug_log("Customer name: " . $name);
    
    stripe_log_info("Getting or creating customer for subscription (stripe-only): {$email}");
    
    try {
        // 🔍 STEP 1: Cerca customer esistente per email su Stripe
        debug_log("Searching for existing customer...");
        $existing_customer = find_stripe_customer_by_email($email);
        
        if ($existing_customer) {
            debug_log("Found existing customer: " . $existing_customer->id);
            stripe_log_info("Found existing Stripe customer for subscription: {$existing_customer->id}");
            
            // 🔧 Aggiorna i metadata con user_id corrente se necessario
            $metadata = $existing_customer->metadata->toArray();
            debug_log("Existing customer metadata: " . json_encode($metadata));
            
            if (!isset($metadata['user_id']) || $metadata['user_id'] != $user_id) {
                debug_log("Updating customer metadata with user_id: " . $user_id);
                stripe_log_info("Updating customer metadata for subscription with user_id: {$user_id}");
                
                \Stripe\Customer::update($existing_customer->id, [
                    'metadata' => array_merge($metadata, [
                        'user_id' => (string)$user_id,
                        'platform' => 'fitgymtrack_flutter',
                        'updated_at' => date('Y-m-d H:i:s')
                    ])
                ]);
                debug_log("Customer metadata updated");
            }
            
            debug_log("Returning existing customer ID: " . $existing_customer->id);
            return $existing_customer->id;
        }
        
        // 🆕 STEP 2: Nessun customer trovato, creane uno nuovo
        debug_log("No existing customer found, creating new one");
        stripe_log_info("No existing customer found, creating new one for subscription: {$email}");
        
        $new_customer_data = [
            'email' => $email,
            'name' => $name,
            'metadata' => [
                'user_id' => (string)$user_id,
                'platform' => 'fitgymtrack_flutter',
                'created_at' => date('Y-m-d H:i:s')
            ]
        ];
        
        debug_log("New customer data: " . json_encode($new_customer_data));
        
        $new_customer = \Stripe\Customer::create($new_customer_data);
        
        debug_log("New customer created: " . $new_customer->id);
        stripe_log_info("New Stripe customer created for subscription: {$new_customer->id}");
        
        return $new_customer->id;
        
    } catch (Exception $e) {
        debug_log("ERROR in get_or_create_stripe_customer_stripe_only: " . $e->getMessage());
        stripe_log_error('Failed to get or create Stripe customer for subscription', [
            'user_id' => $user_id,
            'email' => $email,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * 🔍 Trova customer per email su Stripe (same logic as customer.php)
 */
function find_stripe_customer_by_email($email) {
    try {
        debug_log("Searching Stripe for customer with email: " . $email);
        stripe_log_info("Searching for customer with email: {$email}");
        
        // Cerca customer per email
        $customers = \Stripe\Customer::all([
            'email' => $email,
            'limit' => 1
        ]);
        
        debug_log("Stripe customer search returned " . count($customers->data) . " results");
        
        if ($customers->data && count($customers->data) > 0) {
            $customer = $customers->data[0];
            debug_log("Found customer: " . $customer->id);
            stripe_log_info("Found customer: {$customer->id}");
            return $customer;
        }
        
        debug_log("No customer found with email: " . $email);
        stripe_log_info("No customer found with email: {$email}");
        return null;
        
    } catch (Exception $e) {
        debug_log("ERROR searching for customer by email: " . $e->getMessage());
        stripe_log_error("Error searching for customer by email", [
            'email' => $email,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * 🚀 UPDATED: Cancella subscription esistenti per l'utente - STRIPE-ONLY VERSION
 */
function cancel_existing_subscriptions_stripe_only($user_id, $stripe_customer_id) {
    global $pdo;
    
    debug_log("=== CANCEL EXISTING SUBSCRIPTIONS START ===");
    debug_log("User ID: " . $user_id);
    debug_log("Customer ID: " . $stripe_customer_id);
    
    try {
        // 🚀 NEW: Cerca subscription su Stripe per questo customer
        $subscriptions = \Stripe\Subscription::all([
            'customer' => $stripe_customer_id,
            'status' => 'active',
            'limit' => 100
        ]);
        
        debug_log("Found " . count($subscriptions->data) . " active subscriptions");
        
        foreach ($subscriptions->data as $subscription) {
            try {
                debug_log("Processing subscription: " . $subscription->id . " (status: " . $subscription->status . ")");
                
                // Se è incomplete, cancella immediatamente
                if ($subscription->status === 'incomplete') {
                    $subscription->cancel();
                    debug_log("Cancelled incomplete subscription: " . $subscription->id);
                } else {
                    // Altrimenti cancella a fine periodo
                    \Stripe\Subscription::update($subscription->id, [
                        'cancel_at_period_end' => true
                    ]);
                    debug_log("Set cancel_at_period_end for subscription: " . $subscription->id);
                }
                
                stripe_log_info("Cancelled existing subscription: {$subscription->id}");
            } catch (Exception $e) {
                debug_log("Failed to cancel subscription " . $subscription->id . ": " . $e->getMessage());
                stripe_log_error("Failed to cancel existing subscription: {$subscription->id}", ['error' => $e->getMessage()]);
            }
        }
        
        // 🚀 NEW: Aggiorna anche le subscription nel database locale (se esistono)
        if ($pdo) {
            $stmt = $pdo->prepare("
                UPDATE stripe_subscriptions 
                SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
                WHERE user_id = ? AND status IN ('active', 'past_due', 'unpaid', 'incomplete')
            ");
            $result = $stmt->execute([$user_id]);
            debug_log("Updated " . $stmt->rowCount() . " local subscription records");
            
            stripe_log_info("Updated local subscription records for user: {$user_id}");
        } else {
            debug_log("WARNING: PDO not available for updating local subscriptions");
        }
        
    } catch (Exception $e) {
        debug_log("ERROR cancelling existing subscriptions: " . $e->getMessage());
        stripe_log_error('Failed to cancel existing subscriptions', [
            'user_id' => $user_id,
            'customer_id' => $stripe_customer_id,
            'error' => $e->getMessage()
        ]);
        // Non fare throw - non è critico se fallisce
    }
    
    debug_log("=== CANCEL EXISTING SUBSCRIPTIONS END ===");
}

/**
 * 🆕 UPDATED: Salva subscription nel database con payment_type
 */
function save_subscription_to_db($user_id, $subscription, $customer_id, $price_id, $payment_type = 'recurring') {
    global $pdo;
    
    debug_log("=== SAVE SUBSCRIPTION TO DB START ===");
    
    if (!$pdo) {
        debug_log("WARNING: PDO not available, skipping database save");
        return;
    }
    
    // Determina plan_id locale con logging
    $plan_id = null;
    if ($price_id === 'price_1RXVOfHHtQGHyul9qMGFmpmO' || $price_id === 'price_1RbmRkHHtQGHyul92oUMSkUY') {
        $plan_id = 2; // Premium monthly (sia recurring che onetime)
        debug_log("Set plan_id to 2 (Premium monthly) for price_id: " . $price_id);
    } else {
        debug_log("Unknown price_id, plan_id remains null: " . $price_id);
    }
    
    $save_data = [
        'subscription_id' => $subscription->id,
        'user_id' => $user_id,
        'payment_type' => $payment_type,
        'plan_id' => $plan_id,
        'cancel_at_period_end' => $subscription->cancel_at_period_end,
        'status' => $subscription->status,
        'current_period_start' => $subscription->current_period_start,
        'current_period_end' => $subscription->current_period_end
    ];
    
    debug_log("Subscription save data: " . json_encode($save_data));
    
    stripe_log_info("Saving subscription to database", $save_data);
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO stripe_subscriptions (
                user_id, stripe_subscription_id, stripe_customer_id, status,
                current_period_start, current_period_end, cancel_at_period_end,
                plan_id, price_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            status = VALUES(status),
            current_period_start = VALUES(current_period_start),
            current_period_end = VALUES(current_period_end),
            cancel_at_period_end = VALUES(cancel_at_period_end),
            updated_at = CURRENT_TIMESTAMP
        ");
        
        $execute_params = [
            $user_id,
            $subscription->id,
            $customer_id,
            $subscription->status,
            $subscription->current_period_start,
            $subscription->current_period_end,
            $subscription->cancel_at_period_end ? 1 : 0,
            $plan_id,
            $price_id
        ];
        
        debug_log("Execute params: " . json_encode($execute_params));
        
        $result = $stmt->execute($execute_params);
        
        if ($result) {
            debug_log("Subscription saved successfully, affected rows: " . $stmt->rowCount());
        } else {
            debug_log("Failed to save subscription to database");
        }
        
    } catch (Exception $e) {
        debug_log("ERROR saving subscription to database: " . $e->getMessage());
        throw $e;
    }
    
    debug_log("=== SAVE SUBSCRIPTION TO DB END ===");
}

/**
 * 🆕 UPDATED: Salva Payment Intent nel database con payment_type e stripe_subscription_id
 */
function save_payment_intent_to_db($user_id, $payment_intent, $payment_type, $subscription_payment_type = 'recurring', $stripe_subscription_id = null) {
    global $pdo;
    
    debug_log("=== SAVE PAYMENT INTENT TO DB START ===");
    
    if (!$pdo) {
        debug_log("WARNING: PDO not available, skipping payment intent save");
        return;
    }
    
    // 🆕 NUOVO: Include payment_type e stripe_subscription_id nei metadata
    $metadata = $payment_intent->metadata->toArray();
    $metadata['subscription_payment_type'] = $subscription_payment_type;
    
    // 🆕 CRITICO: Aggiungi stripe_subscription_id ai metadata
    if ($stripe_subscription_id) {
        $metadata['stripe_subscription_id'] = $stripe_subscription_id;
        debug_log("Added stripe_subscription_id to metadata: " . $stripe_subscription_id);
    }
    
    $save_data = [
        'payment_intent_id' => $payment_intent->id,
        'user_id' => $user_id,
        'amount' => $payment_intent->amount,
        'currency' => $payment_intent->currency,
        'status' => $payment_intent->status,
        'payment_type' => $payment_type,
        'subscription_payment_type' => $subscription_payment_type,
        'stripe_subscription_id' => $stripe_subscription_id,
        'metadata' => $metadata
    ];
    
    debug_log("Payment intent save data: " . json_encode($save_data));
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO stripe_payment_intents (
                user_id, stripe_payment_intent_id, amount, currency, status, payment_type, metadata
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            status = VALUES(status),
            metadata = VALUES(metadata),
            updated_at = CURRENT_TIMESTAMP
        ");
        
        $execute_params = [
            $user_id,
            $payment_intent->id,
            $payment_intent->amount,
            $payment_intent->currency,
            $payment_intent->status,
            $payment_type, // 'subscription'
            json_encode($metadata)
        ];
        
        debug_log("Payment intent execute params: " . json_encode($execute_params));
        
        $result = $stmt->execute($execute_params);
        
        if ($result) {
            debug_log("Payment intent saved successfully, affected rows: " . $stmt->rowCount());
        } else {
            debug_log("Failed to save payment intent to database");
        }
        
        stripe_log_info("Payment intent saved with subscription metadata", [
            'payment_intent_id' => $payment_intent->id,
            'subscription_payment_type' => $subscription_payment_type,
            'stripe_subscription_id' => $stripe_subscription_id
        ]);
        
    } catch (Exception $e) {
        debug_log("ERROR saving payment intent to database: " . $e->getMessage());
        throw $e;
    }
    
    debug_log("=== SAVE PAYMENT INTENT TO DB END ===");
}

debug_log("=== STRIPE SUBSCRIPTION PAYMENT INTENT DEBUG END ===");
?>