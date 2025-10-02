<?php
/**
 * test_renewal_check.php
 * Script di test per il cronjob di controllo rinnovi
 * 
 * Usage: php test_renewal_check.php
 *        oppure: http://yourdomain.com/api/stripe/test_renewal_check.php
 */

// Include il cronjob
require_once __DIR__ . '/cron_renewal_check.php';

echo "<h2>🔄 Test Cronjob Rinnovi Automatici</h2>";
echo "<p>Timestamp: " . date('Y-m-d H:i:s') . "</p>";

// Simula esecuzione manuale
$_GET['manual_run'] = true;

echo "<h3>📊 Risultati:</h3>";
echo "<pre>";

// Il cronjob si eseguirà automaticamente e mostrerà i risultati

echo "</pre>";

echo "<h3>📝 Log File:</h3>";
$logFile = __DIR__ . '/logs/renewal_cron_' . date('Y-m') . '.log';
if (file_exists($logFile)) {
    echo "<pre>";
    echo htmlspecialchars(file_get_contents($logFile));
    echo "</pre>";
} else {
    echo "<p>Log file non trovato: $logFile</p>";
}

?>
