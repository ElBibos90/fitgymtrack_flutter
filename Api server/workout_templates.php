<?php
// workout_templates.php - API per i template di allenamento
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestione preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Includi configurazione database
    include 'config.php';
    
    if (!$conn) {
        throw new Exception("Connessione database fallita");
    }
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            // Parametri di query
            $categoryId = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
            $difficulty = isset($_GET['difficulty']) ? $_GET['difficulty'] : null;
            $goal = isset($_GET['goal']) ? $_GET['goal'] : null;
            $search = isset($_GET['search']) ? trim($_GET['search']) : null;
            $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
            $limit = isset($_GET['limit']) ? min(50, max(1, intval($_GET['limit']))) : 20;
            $offset = ($page - 1) * $limit;
            
            // Costruisci query base
            $query = "
                SELECT 
                    wt.id,
                    wt.name,
                    wt.description,
                    wt.category_id,
                    tc.name as category_name,
                    tc.icon as category_icon,
                    tc.color as category_color,
                    wt.difficulty_level,
                    wt.goal,
                    wt.is_premium,
                    wt.is_featured,
                    wt.rating_average,
                    wt.rating_count,
                    wt.usage_count,
                    wt.created_at,
                    wt.updated_at
                FROM workout_templates wt
                JOIN template_categories tc ON wt.category_id = tc.id
                WHERE wt.is_active = 1
            ";
            
            $params = [];
            $paramTypes = '';
            
            // Filtri
            if ($categoryId) {
                $query .= " AND wt.category_id = ?";
                $params[] = $categoryId;
                $paramTypes .= 'i';
            }
            
            if ($difficulty) {
                $query .= " AND wt.difficulty_level = ?";
                $params[] = $difficulty;
                $paramTypes .= 's';
            }
            
            if ($goal) {
                $query .= " AND wt.goal = ?";
                $params[] = $goal;
                $paramTypes .= 's';
            }
            
            if ($search) {
                $query .= " AND (wt.name LIKE ? OR wt.description LIKE ?)";
                $searchTerm = "%$search%";
                $params[] = $searchTerm;
                $params[] = $searchTerm;
                $paramTypes .= 'ss';
            }
            
            // Per ora mostriamo tutti i template per test
            // TODO: Implementare controllo premium quando necessario
            // $query .= " AND wt.is_premium = 0";
            
            // Ordinamento e paginazione
            $query .= " ORDER BY wt.is_featured DESC, wt.rating_average DESC, wt.usage_count DESC";
            $query .= " LIMIT ? OFFSET ?";
            $params[] = $limit;
            $params[] = $offset;
            $paramTypes .= 'ii';
            
            // Esegui query
            $stmt = $conn->prepare($query);
            if (!empty($params) && !empty($paramTypes)) {
                $stmt->bind_param($paramTypes, ...$params);
            }
            $stmt->execute();
            $result = $stmt->get_result();
            
            $templates = [];
            while ($row = $result->fetch_assoc()) {
                $templates[] = $row;
            }
            
            // Conta totale per paginazione
            $countQuery = "
                SELECT COUNT(*) as total
                FROM workout_templates wt
                JOIN template_categories tc ON wt.category_id = tc.id
                WHERE wt.is_active = 1
            ";
            
            if ($categoryId) {
                $countQuery .= " AND wt.category_id = $categoryId";
            }
            if ($difficulty) {
                $countQuery .= " AND wt.difficulty_level = '$difficulty'";
            }
            if ($goal) {
                $countQuery .= " AND wt.goal = '$goal'";
            }
            if ($search) {
                $countQuery .= " AND (wt.name LIKE '%$search%' OR wt.description LIKE '%$search%')";
            }
            // $countQuery .= " AND wt.is_premium = 0";
            
            $countResult = $conn->query($countQuery);
            $totalCount = $countResult ? $countResult->fetch_assoc()['total'] : 0;
            
            echo json_encode([
                'success' => true,
                'templates' => $templates,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $totalCount,
                    'pages' => ceil($totalCount / $limit)
                ]
            ]);
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['error' => 'Metodo non supportato']);
            break;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Errore interno del server',
        'message' => $e->getMessage()
    ]);
}
?>