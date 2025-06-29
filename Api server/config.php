<?php
// ============================================================================
// DATABASE CONFIGURATION ORIGINALE (MANTIENE TUTTO IDENTICO)
// ============================================================================
$servername = "localhost";
$username = "ElBibo";
$password = "Groot00";
$dbname = "Workout";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$conn->set_charset("utf8mb4");

// ============================================================================
// AGGIUNTA PDO PER STRIPE (NON INTERFERISCE CON NULLA)
// ============================================================================
try {
    $pdo = new PDO("mysql:host=$servername;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
} catch(PDOException $e) {
    error_log("❌ PDO Connection failed: " . $e->getMessage());
    // Non fermare l'esecuzione per compatibilità totale
    $pdo = null;
}
?>