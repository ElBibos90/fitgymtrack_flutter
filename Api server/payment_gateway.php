<?php
// payment_gateway.php - Gateway di pagamento simulato

header('Content-Type: application/json');

// Abilita CORS per le richieste dal frontend
if (isset($_SERVER['HTTP_ORIGIN'])) {
    $allowed_origins = ['http://localhost:3000', 'https://fitgymtrack.com', 'http://fitgymtrack.com'];
    if (in_array($_SERVER['HTTP_ORIGIN'], $allowed_origins)) {
        header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 86400');
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    header("Access-Control-Allow-Methods: POST, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization");
    exit(0);
}

// In produzione, useremo Stripe o un altro gateway di pagamento
// Questo è solo un simulatore per testing

// Funzione per generare un ID transazione casuale
function generateTransactionId() {
    return 'tran_' . bin2hex(random_bytes(10));
}

// Simula un ritardo di elaborazione
sleep(1);

// Verifica se abbiamo tutti i dati necessari
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

if (!$input) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Dati JSON non validi'
    ]);
    exit;
}

// Verifica i campi richiesti per il pagamento
if (!isset($input['card_number'], $input['expiry'], $input['cvc'], $input['amount'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Dati di pagamento incompleti'
    ]);
    exit;
}

// Simuliamo una verifica base della carta (ovviamente in produzione questo non sarebbe sufficiente)
$card_number = preg_replace('/\s+/', '', $input['card_number']);
$expiry = preg_replace('/\s+/', '', $input['expiry']);
$cvc = preg_replace('/\s+/', '', $input['cvc']);
$amount = floatval($input['amount']);

// Per il test, accettiamo solo la carta che inizia con "4242" (come Stripe)
if (substr($card_number, 0, 4) !== '4242') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Carta di credito non valida',
        'error_code' => 'invalid_card'
    ]);
    exit;
}

// Verifica che l'importo sia positivo
if ($amount <= 0) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'L\'importo deve essere maggiore di zero',
        'error_code' => 'invalid_amount'
    ]);
    exit;
}

// Simuliamo un errore di pagamento casuale nel 10% dei casi
if (rand(1, 10) === 1) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Pagamento rifiutato dalla banca emittente',
        'error_code' => 'card_declined'
    ]);
    exit;
}

// Se arriviamo qui, il pagamento è stato accettato
$transaction_id = generateTransactionId();
$payment_date = date('Y-m-d H:i:s');

// In produzione, qui salveremmo i dati della transazione in un database
// Ma per questo simulatore, restituiamo solo una risposta di successo

echo json_encode([
    'success' => true,
    'message' => 'Pagamento elaborato con successo',
    'transaction_id' => $transaction_id,
    'amount' => $amount,
    'currency' => 'EUR',
    'payment_date' => $payment_date,
    'card_last4' => substr($card_number, -4),
    // Altri dati rilevanti...
]);
?>