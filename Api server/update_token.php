<?php
header('Content-Type: application/json');
include 'config.php';  // Include database connection

// Il codice di verifica che hai ricevuto
$newToken = "273aa8673c58d622d0ca6c7da62d0e43";

// Aggiorna il token nel database per tutti i token non utilizzati e non scaduti
$stmt = $conn->prepare("UPDATE password_resets SET token = ? WHERE used = 0 AND expires_at > NOW()");
$stmt->bind_param("s", $newToken);

if ($stmt->execute() && $stmt->affected_rows > 0) {
    echo json_encode(['success' => true, 'message' => 'Token aggiornato con successo']);
} else {
    echo json_encode(['success' => false, 'message' => 'Nessun token aggiornato: ' . $conn->error]);
}

$conn->close();
?>
