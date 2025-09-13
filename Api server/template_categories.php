<?php
// template_categories.php - API per gestire le categorie dei template
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'config.php';
require_once 'auth_functions.php';

// Funzione di debug
function debug_log($message, $data = null) {
    error_log("TEMPLATE_CATEGORIES_DEBUG[" . date('Y-m-d H:i:s') . "]: $message");
    if ($data !== null) {
        error_log("TEMPLATE_CATEGORIES_DATA: " . print_r($data, true));
    }
}

$method = $_SERVER['REQUEST_METHOD'];
debug_log("Richiesta ricevuta: $method");

try {
    if ($method === 'GET') {
        // Le categorie sono pubbliche, non richiedono autenticazione
        
        // Query per ottenere le categorie con conteggio template
        $query = "
            SELECT 
                tc.id,
                tc.name,
                tc.description,
                tc.icon,
                tc.color,
                tc.sort_order,
                COUNT(wt.id) as template_count,
                COUNT(CASE WHEN wt.is_premium = 0 THEN 1 END) as free_template_count,
                COUNT(CASE WHEN wt.is_premium = 1 THEN 1 END) as premium_template_count
            FROM template_categories tc
            LEFT JOIN workout_templates wt ON tc.id = wt.category_id AND wt.is_active = 1
            WHERE tc.is_active = 1
            GROUP BY tc.id, tc.name, tc.description, tc.icon, tc.color, tc.sort_order
            ORDER BY tc.sort_order ASC, tc.name ASC
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $categories = [];
        while ($row = $result->fetch_assoc()) {
            $categories[] = $row;
        }
        
        // Aggiungi categoria "Tutti" se richiesta
        if (isset($_GET['include_all']) && filter_var($_GET['include_all'], FILTER_VALIDATE_BOOLEAN)) {
            // Conta tutti i template
            $totalStmt = $conn->prepare("
                SELECT 
                    COUNT(*) as total_count,
                    COUNT(CASE WHEN is_premium = 0 THEN 1 END) as total_free,
                    COUNT(CASE WHEN is_premium = 1 THEN 1 END) as total_premium
                FROM workout_templates 
                WHERE is_active = 1
            ");
            $totalStmt->execute();
            $totalResult = $totalStmt->get_result();
            $totalData = $totalResult->fetch_assoc();
            
            array_unshift($categories, [
                'id' => 0,
                'name' => 'Tutti i Template',
                'description' => 'Visualizza tutti i template disponibili',
                'icon' => 'apps',
                'color' => '#667EEA',
                'sort_order' => 0,
                'template_count' => $totalData['total_count'],
                'free_template_count' => $totalData['total_free'],
                'premium_template_count' => $totalData['total_premium']
            ]);
        }
        
        echo json_encode([
            'success' => true,
            'categories' => $categories
        ]);
        
    } else {
        http_response_code(405);
        echo json_encode(['error' => 'Metodo non supportato']);
    }
    
} catch (Exception $e) {
    debug_log("Errore: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Errore interno del server']);
}
?>
