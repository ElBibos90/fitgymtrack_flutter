-- ============================================================================
-- STORED PROCEDURES PER TEMPLATE (Alternativa ai trigger)
-- ============================================================================
-- Usa questo file se i trigger causano problemi con i privilegi MySQL

-- Procedura per aggiornare le statistiche di rating
DELIMITER //
CREATE PROCEDURE UpdateTemplateRatingStats(IN template_id_param INT)
BEGIN
    UPDATE workout_templates 
    SET rating_average = (
        SELECT COALESCE(AVG(rating), 0) 
        FROM user_template_ratings 
        WHERE template_id = template_id_param
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM user_template_ratings 
        WHERE template_id = template_id_param
    )
    WHERE id = template_id_param;
END//

-- Procedura per aggiornare il contatore di utilizzo
CREATE PROCEDURE UpdateTemplateUsageCount(IN template_id_param INT)
BEGIN
    UPDATE workout_templates 
    SET usage_count = usage_count + 1 
    WHERE id = template_id_param;
END//

DELIMITER ;

-- ============================================================================
-- ISTRUZIONI PER L'USO
-- ============================================================================

-- 1. Esegui questo file SQL per creare le stored procedures
-- 2. Modifica le API PHP per chiamare le procedure invece di fare affidamento sui trigger
-- 3. Esempi di chiamata:
--    CALL UpdateTemplateRatingStats(1);
--    CALL UpdateTemplateUsageCount(1);

-- ============================================================================
-- MODIFICHE NECESSARIE NELLE API PHP
-- ============================================================================

-- Nel file template_ratings.php, dopo INSERT/UPDATE/DELETE:
-- $stmt = $pdo->prepare("CALL UpdateTemplateRatingStats(?)");
-- $stmt->execute([$template_id]);

-- Nel file create_workout_from_template.php, dopo la creazione:
-- $stmt = $pdo->prepare("CALL UpdateTemplateUsageCount(?)");
-- $stmt->execute([$template_id]);


