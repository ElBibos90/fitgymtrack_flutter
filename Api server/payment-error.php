<?php
// payment-error.php - Gestisce la visualizzazione degli errori di pagamento PayPal

// Includi le configurazioni base se necessario (opzionale)
// include 'config.php';

// Recupera il messaggio di errore dall'URL
$errorMessage = isset($_GET['message']) ? htmlspecialchars($_GET['message']) : 'Si è verificato un errore durante il pagamento.';

// Definisci l'URL per tornare alla pagina degli abbonamenti
$subscriptionUrl = "/standalone/subscription";

// Determina lo stile dell'interfaccia (chiaro/scuro) in base alla sessione o cookie se disponibile
$isDarkMode = false;
if (isset($_COOKIE['theme']) && $_COOKIE['theme'] === 'dark') {
    $isDarkMode = true;
}
?>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Errore Pagamento - FitGymTrack</title>
    <!-- Includiamo Tailwind per la compatibilità con lo stile dell'app React -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="<?php echo $isDarkMode ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-900'; ?>">
    <div class="min-h-screen flex items-center justify-center p-4">
        <div class="max-w-lg w-full rounded-lg shadow-lg <?php echo $isDarkMode ? 'bg-gray-800' : 'bg-white'; ?> p-6">
            <div class="flex items-center mb-6">
                <div class="w-12 h-12 rounded-full flex items-center justify-center <?php echo $isDarkMode ? 'bg-red-900/30 text-red-400' : 'bg-red-100 text-red-500'; ?>">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-8 h-8">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                </div>
                <h1 class="text-xl font-bold ml-4">Errore durante il pagamento</h1>
            </div>
            
            <div class="mb-6">
                <p class="<?php echo $isDarkMode ? 'text-red-300' : 'text-red-600'; ?> mb-4">
                    <?php echo $errorMessage; ?>
                </p>
                <p class="<?php echo $isDarkMode ? 'text-gray-400' : 'text-gray-600'; ?> text-sm">
                    Se il problema persiste, contatta l'assistenza o prova a utilizzare un altro metodo di pagamento.
                </p>
            </div>
            
            <div class="flex justify-center">
                <a href="<?php echo $subscriptionUrl; ?>" class="inline-flex items-center px-6 py-3 <?php echo $isDarkMode ? 'bg-indigo-600 hover:bg-indigo-700' : 'bg-indigo-600 hover:bg-indigo-700'; ?> text-white font-semibold rounded-lg transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-5 h-5 mr-2">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                    </svg>
                    Torna agli abbonamenti
                </a>
            </div>
        </div>
    </div>
</body>
</html>