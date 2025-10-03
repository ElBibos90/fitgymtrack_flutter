-- =============================================================================
-- AGGIORNAMENTO DATABASE - SISTEMA PROMEMORIA CORSI
-- =============================================================================
-- Aggiunge campo reminder_sent alla tabella gym_course_enrollments
-- per tracciare se il promemoria è già stato inviato
-- =============================================================================

-- Aggiungi campo reminder_sent
ALTER TABLE gym_course_enrollments 
ADD COLUMN reminder_sent TINYINT(1) DEFAULT 0 COMMENT '1 se promemoria già inviato, 0 altrimenti';

-- Aggiungi campo reminder_sent_at per timestamp
ALTER TABLE gym_course_enrollments 
ADD COLUMN reminder_sent_at TIMESTAMP NULL COMMENT 'Timestamp quando è stato inviato il promemoria';

-- Aggiungi indice per performance
ALTER TABLE gym_course_enrollments 
ADD INDEX idx_reminder_sent (reminder_sent);

-- Aggiungi indice per query promemoria
ALTER TABLE gym_course_enrollments 
ADD INDEX idx_session_reminder (session_id, reminder_sent, status);

-- Verifica che le modifiche siano state applicate
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'gym_course_enrollments' 
AND COLUMN_NAME IN ('reminder_sent', 'reminder_sent_at');

-- Mostra indici della tabella
SHOW INDEX FROM gym_course_enrollments WHERE Key_name LIKE '%reminder%';

