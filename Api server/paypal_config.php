<?php
// paypal_config.php - Configurazione PayPal API

// Modalità dell'ambiente (sandbox o live)
define('PAYPAL_MODE', 'sandbox'); // Cambia in 'live' per produzione

//define('PAYPAL_MODE', 'live'); // Cambia in 'live' per produzione

// Credenziali API Sandbox
 define('PAYPAL_CLIENT_ID', 'AUgpIjB17CO56586ks77IQEL3HmUdxPYWDDRV0KgNYBPspjgQzJKsTtlEc9RylY5PqK-BJc4XIo-GmCT');
 define('PAYPAL_SECRET', 'EFMddJjyOICiQmrRW8Xz4tGNJBKaXldXf6EotYlOT9Gd_UJGv15kuxHoKMktwvdBNyAQIjuU5aG_RAZY');

// Credenziali API Produzione
//define('PAYPAL_CLIENT_ID', 'ASrP-QHCBgT1jGRqSMCLC4RMj2B9bH0QsccM4OHPPiddn61iIbp487S7c9-JEWi7Vvr5NXKn-AxHw-qv');
//define('PAYPAL_SECRET', 'EH5_K1ytSga4-VTmaoQTqHUrmqS-QEf4Qb6JIMrSo9PUWtGBMVqa1bed6R8iEbhZEr-0-GDsCkKIWCQo');

// URLs di base PayPal
if (PAYPAL_MODE === 'sandbox') {
    define('PAYPAL_API_URL', 'https://api-m.sandbox.paypal.com');
} else {
    define('PAYPAL_API_URL', 'https://api-m.paypal.com');
}

// Imposta gli URL di ritorno - SANDBOX
// define('PAYPAL_RETURN_URL', 'http://192.168.1.113/api/paypal_success.php?order_id=');
// define('PAYPAL_CANCEL_URL', 'http://192.168.1.113/api/paypal_cancel.php?order_id=');
// define('FRONTEND_URL', 'http://localhost:3000/gym-2.0/standalone-dashboard');

// Imposta gli URL di ritorno - Produzione
define('PAYPAL_RETURN_URL', 'https://fitgymtrack.com/api/paypal_success.php?order_id=');
define('PAYPAL_CANCEL_URL', 'https://fitgymtrack.com/api/paypal_cancel.php?order_id=');
define('FRONTEND_URL', 'https://fitgymtrack.com/gym-2.0/standalone-dashboard');