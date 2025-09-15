<?php
// check_tables.php - Controllo esistenza tabelle
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    $tables = [
        'template_categories',
        'workout_templates', 
        'template_exercises',
        'user_template_ratings',
        'template_usage_log'
    ];
    
    $results = [];
    
    foreach ($tables as $table) {
        $query = "SHOW TABLES LIKE '$table'";
        $result = $conn->query($query);
        
        if ($result && $result->num_rows > 0) {
            // Conta i record
            $countQuery = "SELECT COUNT(*) as count FROM $table";
            $countResult = $conn->query($countQuery);
            $count = $countResult ? $countResult->fetch_assoc()['count'] : 0;
            
            $results[$table] = [
                'exists' => true,
                'count' => $count
            ];
        } else {
            $results[$table] = [
                'exists' => false,
                'count' => 0
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'tables' => $results
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage()
    ]);
}
?>



