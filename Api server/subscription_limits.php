<?php
// subscription_limits.php - Helper file for verifying subscription plan limits

/**
 * Check if user has reached the workout schema limit
 * 
 * @param int $userId User ID
 * @return array Result of the check
 */
function checkWorkoutLimit($userId) {
    global $conn;
    
    // First, get the user's current subscription details directly from database
    $subscription = getUserSubscriptionDirect($userId);
    
    if (!$subscription) {
        return [
            'success' => false,
            'message' => 'Nessun abbonamento trovato',
            'limit_reached' => true
        ];
    }

    // If user has a paid plan and the limit is NULL (unlimited)
    if ($subscription['price'] > 0 && $subscription['max_workouts'] === null) {
        return [
            'success' => true,
            'message' => 'Nessun limite per questo piano',
            'limit_reached' => false
        ];
    }
    
    // Get the current count of user's workout schemas
    $stmt = $conn->prepare("
        SELECT COUNT(*) as count 
        FROM schede s
        INNER JOIN user_workout_assignments uwa ON uwa.scheda_id = s.id
        WHERE uwa.user_id = ? AND uwa.active = 1
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $count = $result->fetch_assoc()['count'];
    $stmt->close();
    
    $limit = $subscription['max_workouts'];
    
    return [
        'success' => true,
        'current_count' => $count,
        'max_allowed' => $limit,
        'limit_reached' => $count >= $limit,
        'remaining' => max(0, $limit - $count)
    ];
}

/**
 * Check if user has reached the custom exercise limit
 * 
 * @param int $userId User ID
 * @return array Result of the check
 */
function checkCustomExerciseLimit($userId) {
    global $conn;
    
    // Get subscription data directly
    $subscription = getUserSubscriptionDirect($userId);
    
    if (!$subscription) {
        return [
            'success' => false,
            'message' => 'Nessun abbonamento trovato',
            'limit_reached' => true
        ];
    }

    // If user has a paid plan and the limit is NULL (unlimited)
    if ($subscription['price'] > 0 && $subscription['max_custom_exercises'] === null) {
        return [
            'success' => true,
            'message' => 'Nessun limite per questo piano',
            'limit_reached' => false
        ];
    }
    
    // Get current count of custom exercises
    $stmt = $conn->prepare("
        SELECT COUNT(*) as count 
        FROM esercizi 
        WHERE created_by_user_id = ? AND status != 'approved'
    ");
    
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $count = $result->fetch_assoc()['count'];
    $stmt->close();
    
    $limit = $subscription['max_custom_exercises'];
    
    return [
        'success' => true,
        'current_count' => $count,
        'max_allowed' => $limit,
        'limit_reached' => $count >= $limit,
        'remaining' => max(0, $limit - $count)
    ];
}

/**
 * Get user's current subscription directly from the database
 * This avoids the need for API calls and session data
 * 
 * @param int $userId User ID
 * @return array|null Subscription data or null if not found
 */
function getUserSubscriptionDirect($userId) {
    global $conn;
    
    $stmt = $conn->prepare("
        SELECT us.*, sp.name as plan_name, sp.max_workouts, sp.max_custom_exercises, 
               sp.advanced_stats, sp.cloud_backup, sp.no_ads, sp.price
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ? AND us.status = 'active' 
        ORDER BY us.end_date DESC 
        LIMIT 1
    ");
    
    if (!$stmt) {
        error_log("Query preparation error: " . $conn->error);
        return null;
    }
    
    $stmt->bind_param('i', $userId);
    
    if (!$stmt->execute()) {
        error_log("Query execution error: " . $stmt->error);
        return null;
    }
    
    $result = $stmt->get_result();
    $stmt->close();
    
    if ($result->num_rows > 0) {
        return $result->fetch_assoc();
    }
    
    // If no active subscription found, get the Free plan
    $freePlanStmt = $conn->prepare("
        SELECT * FROM subscription_plans WHERE name = 'Free' LIMIT 1
    ");
    
    if (!$freePlanStmt) {
        error_log("Free plan query preparation error: " . $conn->error);
        return null;
    }
    
    $freePlanStmt->execute();
    $freePlanResult = $freePlanStmt->get_result();
    $freePlanStmt->close();
    
    if ($freePlanResult->num_rows > 0) {
        $freePlan = $freePlanResult->fetch_assoc();
        return [
            'user_id' => $userId,
            'plan_id' => $freePlan['id'],
            'plan_name' => $freePlan['name'],
            'status' => 'active',
            'max_workouts' => $freePlan['max_workouts'],
            'max_custom_exercises' => $freePlan['max_custom_exercises'],
            'advanced_stats' => $freePlan['advanced_stats'],
            'cloud_backup' => $freePlan['cloud_backup'],
            'no_ads' => $freePlan['no_ads'],
            'price' => $freePlan['price']
        ];
    }
    
    return null;
}

/**
 * Check if user has access to advanced stats
 * 
 * @param int $userId User ID
 * @return bool True if user has access, false otherwise
 */
function hasAdvancedStats($userId) {
    $subscription = getUserSubscriptionDirect($userId);
    return $subscription && $subscription['advanced_stats'] == 1;
}

/**
 * Check if user has access to cloud backup
 * 
 * @param int $userId User ID
 * @return bool True if user has access, false otherwise
 */
function hasCloudBackup($userId) {
    $subscription = getUserSubscriptionDirect($userId);
    return $subscription && $subscription['cloud_backup'] == 1;
}

/**
 * Check if user should see ads
 * 
 * @param int $userId User ID
 * @return bool True if user should not see ads, false otherwise
 */
function hasNoAds($userId) {
    $subscription = getUserSubscriptionDirect($userId);
    return $subscription && $subscription['no_ads'] == 1;
}
?>