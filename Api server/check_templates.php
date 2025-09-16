<?php
// check_templates.php - Controllo template nel database
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    // Controlla tutti i template
    $query = "SELECT COUNT(*) as total FROM workout_templates WHERE is_active = 1";
    $result = $conn->query($query);
    $total = $result->fetch_assoc()['total'];
    
    // Controlla template gratuiti
    $query = "SELECT COUNT(*) as free FROM workout_templates WHERE is_active = 1 AND is_premium = 0";
    $result = $conn->query($query);
    $free = $result->fetch_assoc()['free'];
    
    // Controlla template premium
    $query = "SELECT COUNT(*) as premium FROM workout_templates WHERE is_active = 1 AND is_premium = 1";
    $result = $conn->query($query);
    $premium = $result->fetch_assoc()['premium'];
    
    // Mostra alcuni template di esempio
    $query = "SELECT id, name, is_premium, is_featured FROM workout_templates WHERE is_active = 1 LIMIT 5";
    $result = $conn->query($query);
    $examples = [];
    while ($row = $result->fetch_assoc()) {
        $examples[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'total_templates' => $total,
        'free_templates' => $free,
        'premium_templates' => $premium,
        'examples' => $examples
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>




