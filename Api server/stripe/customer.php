<?php
include '../config.php';
require_once '../auth_functions.php';
require_once '../stripe_auth_bridge.php';
require_once '../stripe_config.php';

// ============================================================================
// STRIPE CUSTOMER MANAGEMENT - STRIPE ONLY VERSION (No local DB)
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
        case 'POST':
            handle_get_or_create_customer_stripe_only($user_id, $user);
            break;
            
        case 'GET':
            handle_get_customer_stripe_only($user_id, $user);
            break;
            
        default:
            http_response_code(405);
            stripe_json_response(false, null, 'Metodo non supportato');
    }
    
} catch (Exception $e) {
    stripe_log_error('Customer endpoint error', [
        'user_id' => $user_id,
        'method' => $method,
        'error' => $e->getMessage()
    ]);
    handle_stripe_error($e);
}

// ============================================================================
// CUSTOMER FUNCTIONS - STRIPE ONLY VERSION
// ============================================================================

/**
 * 🚀 NEW: Cerca customer per email su Stripe, se non esiste lo crea
 */
function handle_get_or_create_customer_stripe_only($user_id, $user_data) {
    // Parse request data
    $input = json_decode(file_get_contents('php://input'), true);
    $email = $input['email'] ?? $user_data['email'] ?? "user{$user_id}@fitgymtrack.com";
    $name = $input['name'] ?? $user_data['username'] ?? "User {$user_id}";
    
    stripe_log_info("Getting or creating customer for email: {$email}");
    
    try {
        // 🔍 STEP 1: Cerca customer esistente per email su Stripe
        $existing_customer = find_stripe_customer_by_email($email);
        
        if ($existing_customer) {
            stripe_log_info("Found existing Stripe customer: {$existing_customer->id}");
            
            // 🔧 Aggiorna i metadata con user_id corrente se necessario
            $metadata = $existing_customer->metadata->toArray();
            if (!isset($metadata['user_id']) || $metadata['user_id'] != $user_id) {
                stripe_log_info("Updating customer metadata with user_id: {$user_id}");
                
                \Stripe\Customer::update($existing_customer->id, [
                    'metadata' => array_merge($metadata, [
                        'user_id' => (string)$user_id,
                        'platform' => 'fitgymtrack_flutter',
                        'updated_at' => date('Y-m-d H:i:s')
                    ])
                ]);
                
                // Recupera customer aggiornato
                $existing_customer = \Stripe\Customer::retrieve($existing_customer->id);
            }
            
            stripe_json_response(true, [
                'customer' => [
                    'id' => $existing_customer->id,
                    'email' => $existing_customer->email,
                    'name' => $existing_customer->name,
                    'metadata' => $existing_customer->metadata->toArray()
                ]
            ], 'Cliente esistente recuperato con successo');
            
            return;
        }
        
        // 🆕 STEP 2: Nessun customer trovato, creane uno nuovo
        stripe_log_info("No existing customer found, creating new one for email: {$email}");
        
        $new_customer = \Stripe\Customer::create([
            'email' => $email,
            'name' => $name,
            'metadata' => [
                'user_id' => (string)$user_id,
                'platform' => 'fitgymtrack_flutter',
                'created_at' => date('Y-m-d H:i:s')
            ]
        ]);
        
        stripe_log_info("New Stripe customer created: {$new_customer->id}");
        
        stripe_json_response(true, [
            'customer' => [
                'id' => $new_customer->id,
                'email' => $new_customer->email,
                'name' => $new_customer->name,
                'metadata' => $new_customer->metadata->toArray()
            ]
        ], 'Nuovo cliente creato con successo');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to get or create Stripe customer', [
            'user_id' => $user_id,
            'email' => $email,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * 🔍 Trova customer per email su Stripe
 */
function find_stripe_customer_by_email($email) {
    try {
        stripe_log_info("Searching for customer with email: {$email}");
        
        // Cerca customer per email
        $customers = \Stripe\Customer::all([
            'email' => $email,
            'limit' => 1
        ]);
        
        if ($customers->data && count($customers->data) > 0) {
            $customer = $customers->data[0];
            stripe_log_info("Found customer: {$customer->id}");
            return $customer;
        }
        
        stripe_log_info("No customer found with email: {$email}");
        return null;
        
    } catch (Exception $e) {
        stripe_log_error("Error searching for customer by email", [
            'email' => $email,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * 📋 Ottiene customer per user (cerca per email associata all'user)
 */
function handle_get_customer_stripe_only($user_id, $user_data) {
    $email = $user_data['email'] ?? "user{$user_id}@fitgymtrack.com";
    
    try {
        $customer = find_stripe_customer_by_email($email);
        
        if (!$customer) {
            stripe_json_response(false, null, 'Cliente non trovato');
            return;
        }
        
        stripe_json_response(true, [
            'customer' => [
                'id' => $customer->id,
                'email' => $customer->email,
                'name' => $customer->name,
                'metadata' => $customer->metadata->toArray()
            ]
        ], 'Cliente trovato');
        
    } catch (Exception $e) {
        stripe_log_error('Failed to get Stripe customer', [
            'user_id' => $user_id,
            'email' => $email,
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

// ============================================================================
// 🧹 CLEANUP FUNCTIONS - ELIMINA DUPLICATI SU STRIPE
// ============================================================================

/**
 * 🧹 Trova e elimina customer duplicati per email (funzione di manutenzione)
 */
function cleanup_duplicate_stripe_customers($email) {
    try {
        stripe_log_info("Cleaning up duplicate customers for email: {$email}");
        
        // Trova tutti i customer con questa email
        $customers = \Stripe\Customer::all([
            'email' => $email,
            'limit' => 100
        ]);
        
        if (count($customers->data) <= 1) {
            stripe_log_info("No duplicates found for email: {$email}");
            return ['cleaned' => 0, 'kept' => count($customers->data)];
        }
        
        stripe_log_info("Found " . count($customers->data) . " customers with email: {$email}");
        
        // Ordina per data di creazione (mantieni il più vecchio)
        $sorted_customers = $customers->data;
        usort($sorted_customers, function($a, $b) {
            return $a->created <=> $b->created;
        });
        
        // Mantieni il primo, elimina gli altri
        $keep_customer = array_shift($sorted_customers);
        $deleted_count = 0;
        
        foreach ($sorted_customers as $duplicate_customer) {
            try {
                $duplicate_customer->delete();
                $deleted_count++;
                stripe_log_info("Deleted duplicate customer: {$duplicate_customer->id}");
            } catch (Exception $e) {
                stripe_log_error("Failed to delete duplicate customer: {$duplicate_customer->id}", [
                    'error' => $e->getMessage()
                ]);
            }
        }
        
        stripe_log_info("Cleanup completed for email {$email}: kept {$keep_customer->id}, deleted {$deleted_count}");
        
        return [
            'cleaned' => $deleted_count,
            'kept' => 1,
            'kept_customer_id' => $keep_customer->id
        ];
        
    } catch (Exception $e) {
        stripe_log_error('Cleanup failed for email: ' . $email, [
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}

/**
 * 🔧 Debug: Lista tutti i customer per una email
 */
function debug_list_customers_by_email($email) {
    try {
        $customers = \Stripe\Customer::all([
            'email' => $email,
            'limit' => 100
        ]);
        
        $customer_list = [];
        foreach ($customers->data as $customer) {
            $customer_list[] = [
                'id' => $customer->id,
                'email' => $customer->email,
                'name' => $customer->name,
                'created' => date('Y-m-d H:i:s', $customer->created),
                'metadata' => $customer->metadata->toArray()
            ];
        }
        
        stripe_log_info("Found " . count($customer_list) . " customers for email: {$email}", $customer_list);
        
        return $customer_list;
        
    } catch (Exception $e) {
        stripe_log_error('Failed to list customers for email: ' . $email, [
            'error' => $e->getMessage()
        ]);
        throw $e;
    }
}
?>