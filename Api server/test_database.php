<?php
// ============================================================================
// TEST DATABASE PALESTRE VIA WEB
// Apri questo file nel browser per testare il sistema
// ============================================================================

header('Content-Type: text/html; charset=utf-8');
include 'config.php';

echo "<h1>🧪 Test Sistema Gestione Palestre</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .test-section { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .success { color: green; }
    .error { color: red; }
    .info { color: blue; }
    table { border-collapse: collapse; width: 100%; margin: 10px 0; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
</style>";

// 1. TEST CONNESSIONE DATABASE
echo "<div class='test-section'>";
echo "<h2>1. 🔌 Test Connessione Database</h2>";
if ($conn->connect_error) {
    echo "<p class='error'>❌ Connessione fallita: " . $conn->connect_error . "</p>";
    exit();
} else {
    echo "<p class='success'>✅ Connessione riuscita al database 'Workout'</p>";
}
echo "</div>";

// 2. VERIFICA TABELLE
echo "<div class='test-section'>";
echo "<h2>2. 📋 Verifica Tabelle Esistenti</h2>";
$tables_query = "SELECT table_name as 'Tabella', table_rows as 'Righe'
FROM information_schema.tables 
WHERE table_schema = 'Workout' 
AND table_name IN ('gyms', 'gym_memberships', 'gym_stats', 'users', 'user_role')
ORDER BY table_name";

$result = $conn->query($tables_query);
if ($result && $result->num_rows > 0) {
    echo "<table>";
    echo "<tr><th>Tabella</th><th>Righe</th></tr>";
    while($row = $result->fetch_assoc()) {
        echo "<tr><td>" . $row['Tabella'] . "</td><td>" . $row['Righe'] . "</td></tr>";
    }
    echo "</table>";
    echo "<p class='success'>✅ Tabelle trovate</p>";
} else {
    echo "<p class='error'>❌ Tabelle non trovate</p>";
}
echo "</div>";

// 3. VERIFICA RUOLO GYM
echo "<div class='test-section'>";
echo "<h2>3. 👤 Verifica Ruolo 'gym'</h2>";
$role_query = "SELECT * FROM user_role WHERE name = 'gym'";
$result = $conn->query($role_query);
if ($result && $result->num_rows > 0) {
    $role = $result->fetch_assoc();
    echo "<p class='success'>✅ Ruolo 'gym' trovato - ID: " . $role['id'] . "</p>";
    echo "<p class='info'>Descrizione: " . $role['description'] . "</p>";
} else {
    echo "<p class='error'>❌ Ruolo 'gym' non trovato</p>";
}
echo "</div>";

// 4. VERIFICA CAMPO GYM_ID
echo "<div class='test-section'>";
echo "<h2>4. 🔗 Verifica Campo gym_id in users</h2>";
$field_query = "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE 
FROM information_schema.columns 
WHERE table_schema = 'Workout' 
AND table_name = 'users' 
AND column_name = 'gym_id'";

$result = $conn->query($field_query);
if ($result && $result->num_rows > 0) {
    $field = $result->fetch_assoc();
    echo "<p class='success'>✅ Campo 'gym_id' trovato</p>";
    echo "<p class='info'>Tipo: " . $field['DATA_TYPE'] . ", Nullable: " . $field['IS_NULLABLE'] . "</p>";
} else {
    echo "<p class='error'>❌ Campo 'gym_id' non trovato nella tabella users</p>";
}
echo "</div>";

// 5. VERIFICA STORED PROCEDURES
echo "<div class='test-section'>";
echo "<h2>5. ⚙️ Verifica Stored Procedures</h2>";
$proc_query = "SELECT ROUTINE_NAME as 'Procedure', ROUTINE_TYPE as 'Tipo'
FROM information_schema.routines 
WHERE routine_schema = 'Workout' 
AND routine_name IN ('UpdateGymStats', 'UpdateAllGymStats')";

$result = $conn->query($proc_query);
if ($result && $result->num_rows > 0) {
    echo "<table>";
    echo "<tr><th>Procedure</th><th>Tipo</th></tr>";
    while($row = $result->fetch_assoc()) {
        echo "<tr><td>" . $row['Procedure'] . "</td><td>" . $row['Tipo'] . "</td></tr>";
    }
    echo "</table>";
    echo "<p class='success'>✅ Stored Procedures trovate</p>";
} else {
    echo "<p class='error'>❌ Stored Procedures non trovate</p>";
}
echo "</div>";

// 6. VERIFICA VISTA
echo "<div class='test-section'>";
echo "<h2>6. 👁️ Verifica Vista gym_overview</h2>";
$view_query = "SELECT TABLE_NAME as 'Vista'
FROM information_schema.views 
WHERE table_schema = 'Workout' 
AND table_name = 'gym_overview'";

$result = $conn->query($view_query);
if ($result && $result->num_rows > 0) {
    echo "<p class='success'>✅ Vista 'gym_overview' trovata</p>";
    
    // Test della vista
    $test_view = "SELECT COUNT(*) as total FROM gym_overview";
    $view_result = $conn->query($test_view);
    if ($view_result) {
        $count = $view_result->fetch_assoc();
        echo "<p class='info'>Palestre nella vista: " . $count['total'] . "</p>";
    }
} else {
    echo "<p class='error'>❌ Vista 'gym_overview' non trovata</p>";
}
echo "</div>";

// 7. TEST CREAZIONE PALESTRA (OPZIONALE)
echo "<div class='test-section'>";
echo "<h2>7. 🏗️ Test Creazione Palestra (Opzionale)</h2>";

// Verifica se esiste già una palestra di test
$check_test_gym = "SELECT * FROM gyms WHERE name = 'Palestra Test Web' LIMIT 1";
$existing = $conn->query($check_test_gym);

if ($existing && $existing->num_rows > 0) {
    echo "<p class='info'>ℹ️ Palestra di test già esistente</p>";
    $test_gym = $existing->fetch_assoc();
    echo "<p>Nome: " . $test_gym['name'] . "</p>";
    echo "<p>Email: " . $test_gym['email'] . "</p>";
    echo "<p>Status: " . $test_gym['status'] . "</p>";
} else {
    // Trova un admin per il test
    $admin_query = "SELECT id FROM users WHERE role_id = 1 LIMIT 1";
    $admin_result = $conn->query($admin_query);
    
    if ($admin_result && $admin_result->num_rows > 0) {
        $admin = $admin_result->fetch_assoc();
        
        echo "<p class='info'>🧪 Creazione palestra di test...</p>";
        
        $create_gym = "INSERT INTO gyms (name, email, phone, address, owner_user_id, status, max_users, max_trainers)
        VALUES ('Palestra Test Web', 'testweb@palestra.com', '+39 123 456 789', 'Via Test 123', " . $admin['id'] . ", 'active', 50, 5)";
        
        if ($conn->query($create_gym)) {
            echo "<p class='success'>✅ Palestra di test creata con successo!</p>";
            $gym_id = $conn->insert_id;
            echo "<p class='info'>ID Palestra: " . $gym_id . "</p>";
            
            // Test stored procedure
            echo "<p class='info'>🔄 Test stored procedure...</p>";
            $test_proc = "CALL UpdateGymStats(" . $gym_id . ")";
            if ($conn->query($test_proc)) {
                echo "<p class='success'>✅ Stored procedure eseguita con successo!</p>";
                
                // Verifica statistiche
                $stats_query = "SELECT * FROM gym_stats WHERE gym_id = " . $gym_id;
                $stats_result = $conn->query($stats_query);
                if ($stats_result && $stats_result->num_rows > 0) {
                    $stats = $stats_result->fetch_assoc();
                    echo "<p class='success'>✅ Statistiche create:</p>";
                    echo "<ul>";
                    echo "<li>Membri: " . $stats['total_members'] . "</li>";
                    echo "<li>Trainer: " . $stats['total_trainers'] . "</li>";
                    echo "<li>Ultimo aggiornamento: " . $stats['last_updated'] . "</li>";
                    echo "</ul>";
                }
            } else {
                echo "<p class='error'>❌ Errore stored procedure: " . $conn->error . "</p>";
            }
        } else {
            echo "<p class='error'>❌ Errore creazione palestra: " . $conn->error . "</p>";
        }
    } else {
        echo "<p class='error'>❌ Nessun admin trovato per il test</p>";
    }
}
echo "</div>";

// 8. RISULTATO FINALE
echo "<div class='test-section'>";
echo "<h2>8. 🎯 Risultato Finale</h2>";
echo "<p class='success'>🎉 Test completati!</p>";
echo "<p class='info'>Se tutti i test sono verdi (✅), il sistema è pronto per essere utilizzato.</p>";
echo "<p class='info'>Puoi ora testare le API e il frontend.</p>";
echo "</div>";

$conn->close();
?>

<script>
// Auto-refresh ogni 30 secondi se necessario
// setTimeout(() => location.reload(), 30000);
</script>
