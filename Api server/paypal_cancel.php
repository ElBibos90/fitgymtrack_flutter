<?php
// paypal_cancel.php - Gestisce l'annullamento di un pagamento PayPal

// Includi le configurazioni
include 'config.php';
include 'paypal_config.php';

// Funzione per il logging di debug
function debugLog($message, $data = null) {
    $log_file = __DIR__ . '/paypal_cancel_debug.log';
    $timestamp = date('Y-m-d H:i:s');
    $log_message = "[{$timestamp}] {$message}";
    
    if ($data !== null) {
        if (is_array($data) || is_object($data)) {
            $log_message .= " - Data: " . print_r($data, true);
        } else {
            $log_message .= " - Data: {$data}";
        }
    }
    
    file_put_contents($log_file, $log_message . PHP_EOL, FILE_APPEND);
}

// Log dei parametri ricevuti
/*debugLog("Annullamento pagamento", [
    'GET' => $_GET,
]);*/

// Ottieni l'ID ordine dall'URL
$orderId = isset($_GET['order_id']) ? $_GET['order_id'] : null;

if ($orderId) {
    // Aggiorna lo stato dell'ordine a "cancelled"
    $stmt = $conn->prepare("UPDATE paypal_orders SET status = 'cancelled' WHERE order_id = ? AND status = 'pending'");
    if ($stmt) {
        $stmt->bind_param('s', $orderId);
        $stmt->execute();
        $stmt->close();
        
        /*debugLog("Ordine annullato", [
            'orderId' => $orderId,
            'affected_rows' => $stmt->affected_rows
        ]);*/
    } else {
        /*debugLog("Errore nella preparazione della query", [
            'error' => $conn->error
        ]);*/
    }
}

// Reindirizza l'utente alla pagina di abbonamento con un messaggio
header("Location: " . FRONTEND_URL . "/standalone/subscription?cancelled=true");
exit;