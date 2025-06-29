<?php
// reset_simple.php - Versione semplificata del reset password
header('Content-Type: application/json');
include 'config.php';  // Include database connection

// Ricevi i dati in formato JSON
$data = json_decode(file_get_contents("php://input"), true);

// Estrai i dati
$token = isset($data['token']) ? $data['token'] : '';
$code = isset($data['code']) ? $data['code'] : '';
$newPassword = isset($data['newPassword']) ? $data['newPassword'] : '';

// Log per debug
error_log("Token ricevuto: " . $token);
error_log("Codice ricevuto: " . $code);

// CONTROLLO DIRETTO NEL DATABASE
// Cerca una corrispondenza esatta con il token nel database
$query = "SELECT pr.*, u.id as user_id, u.username, u.email 
          FROM password_resets pr
          JOIN users u ON pr.user_id = u.id
          WHERE pr.token = ? AND pr.used = 0 AND pr.expires_at > NOW()";

$stmt = $conn->prepare($query);
$stmt->bind_param("s", $code);  // Usa il code come token per il confronto
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $user_id = $row['user_id'];
    
    // Aggiorna la password
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
    $updateStmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
    $updateStmt->bind_param("si", $hashedPassword, $user_id);
    
    if ($updateStmt->execute()) {
        // Marca il token come usato
        $markUsedStmt = $conn->prepare("UPDATE password_resets SET used = 1 WHERE id = ?");
        $markUsedStmt->bind_param("i", $row['id']);
        $markUsedStmt->execute();
        
        // Log di successo
        error_log("Password aggiornata con successo per l'utente: " . $row['username']);
        
        // Invia email di conferma
        $subject = "FitGymTrack - Password aggiornata";
        $body = "<html><body>
            <h2>Password aggiornata</h2>
            <p>Ciao {$row['username']},</p>
            <p>La tua password è stata aggiornata con successo.</p>
            <p>Se non hai effettuato tu questa modifica, contatta immediatamente il supporto.</p>
            <p>Grazie,<br>Il team di FitGymTrack</p>
        </body></html>";
        
        // Placeholder per invio email (opzionale)
        // mail($row['email'], $subject, $body, "Content-type: text/html; charset=UTF-8");
        
        echo json_encode([
            'success' => true,
            'message' => 'Password aggiornata con successo'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Errore nell\'aggiornamento della password: ' . $conn->error
        ]);
    }
} else {
    // Debug addizionale se il token non viene trovato
    error_log("Token non trovato nel database: " . $code);
    
    // Query per verificare se ci sono token validi
    $checkQuery = "SELECT token FROM password_resets WHERE used = 0 AND expires_at > NOW()";
    $checkResult = $conn->query($checkQuery);
    if ($checkResult->num_rows > 0) {
        while ($row = $checkResult->fetch_assoc()) {
            error_log("Token valido nel DB: " . $row['token']);
        }
    } else {
        error_log("Nessun token valido nel database");
    }
    
    echo json_encode([
        'success' => false,
        'message' => 'Codice di verifica non valido o scaduto'
    ]);
}

$conn->close();
?>