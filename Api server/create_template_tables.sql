-- ============================================================================
-- SISTEMA TEMPLATE SCHEDE PROFESSIONALI - CREAZIONE TABELLE
-- ============================================================================
-- Questo script crea le tabelle necessarie per il sistema di template
-- Le tabelle sono aggiuntive e non modificano la struttura esistente

-- Tabella per le categorie dei template
CREATE TABLE IF NOT EXISTS template_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(7) DEFAULT '#667EEA',
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sort_order (sort_order),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella per i template professionali
CREATE TABLE IF NOT EXISTS workout_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    difficulty_level ENUM('beginner', 'intermediate', 'advanced') NOT NULL,
    goal ENUM('strength', 'hypertrophy', 'endurance', 'weight_loss', 'general') NOT NULL,
    muscle_groups JSON, -- Array di gruppi muscolari target
    equipment_required JSON, -- Array di attrezzature necessarie
    duration_weeks INT DEFAULT 4,
    sessions_per_week INT DEFAULT 3,
    estimated_duration_minutes INT DEFAULT 60,
    is_premium BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    rating_average DECIMAL(3,2) DEFAULT 0.00,
    rating_count INT DEFAULT 0,
    usage_count INT DEFAULT 0,
    created_by_user_id INT DEFAULT NULL, -- NULL per template professionali
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES template_categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_category_id (category_id),
    INDEX idx_difficulty_level (difficulty_level),
    INDEX idx_goal (goal),
    INDEX idx_is_premium (is_premium),
    INDEX idx_is_featured (is_featured),
    INDEX idx_rating_average (rating_average),
    INDEX idx_is_active (is_active),
    INDEX idx_created_by_user_id (created_by_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella per gli esercizi dei template
CREATE TABLE IF NOT EXISTS template_exercises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_id INT NOT NULL,
    exercise_id INT NOT NULL,
    order_index INT NOT NULL,
    sets INT NOT NULL DEFAULT 3,
    reps_min INT NOT NULL DEFAULT 8,
    reps_max INT NOT NULL DEFAULT 12,
    weight_percentage DECIMAL(5,2) DEFAULT NULL, -- Percentuale del 1RM
    rest_seconds INT DEFAULT 90,
    set_type ENUM('normal', 'superset', 'dropset', 'rest_pause', 'giant_set', 'circuit') DEFAULT 'normal',
    linked_to_previous BOOLEAN DEFAULT FALSE,
    is_rest_pause BOOLEAN DEFAULT FALSE,
    rest_pause_reps TEXT DEFAULT NULL, -- JSON array per reps rest-pause
    rest_pause_rest_seconds INT DEFAULT 15,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES esercizi(id) ON DELETE RESTRICT,
    INDEX idx_template_id (template_id),
    INDEX idx_exercise_id (exercise_id),
    INDEX idx_order_index (order_index),
    UNIQUE KEY unique_template_exercise_order (template_id, order_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella per i rating dei template da parte degli utenti
CREATE TABLE IF NOT EXISTS user_template_ratings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    template_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_template_rating (user_id, template_id),
    INDEX idx_user_id (user_id),
    INDEX idx_template_id (template_id),
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella per tracciare l'utilizzo dei template
CREATE TABLE IF NOT EXISTS template_usage_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    template_id INT NOT NULL,
    action ENUM('viewed', 'created_workout', 'rated') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_template_id (template_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================================
-- INSERIMENTO DATI INIZIALI
-- ============================================================================

-- Inserimento categorie template
INSERT INTO template_categories (name, description, icon, color, sort_order) VALUES
('Push/Pull/Legs', 'Allenamenti divisi per gruppi muscolari complementari', 'fitness_center', '#FF6B6B', 1),
('Upper/Lower', 'Divisione tra parte superiore e inferiore del corpo', 'accessibility', '#4ECDC4', 2),
('Full Body', 'Allenamenti che coinvolgono tutto il corpo', 'sports_gymnastics', '#45B7D1', 3),
('Push/Pull', 'Divisione tra movimenti di spinta e trazione', 'sports_mma', '#96CEB4', 4),
('Calisthenics', 'Allenamenti a corpo libero', 'self_improvement', '#FFEAA7', 5),
('Powerlifting', 'Focus su squat, panca e stacco', 'fitness_center', '#DDA0DD', 6),
('Bodybuilding', 'Allenamenti per ipertrofia muscolare', 'sports_gymnastics', '#98D8C8', 7),
('Functional', 'Movimenti funzionali per la vita quotidiana', 'accessibility_new', '#F7DC6F', 8);

-- Inserimento template di esempio (principiante)
INSERT INTO workout_templates (name, description, category_id, difficulty_level, goal, muscle_groups, equipment_required, duration_weeks, sessions_per_week, estimated_duration_minutes, is_premium, is_featured) VALUES
('Full Body Principiante', 'Allenamento completo per chi inizia in palestra. Perfetto per costruire le basi della forza e della tecnica.', 3, 'beginner', 'general', '["tutto il corpo"]', '["manubri", "panca", "squat rack"]', 4, 3, 45, FALSE, TRUE),
('Push/Pull/Legs Base', 'Programma classico per principianti che vogliono allenarsi 3 volte a settimana.', 1, 'beginner', 'hypertrophy', '["petto", "spalle", "tricipiti", "schiena", "bicipiti", "gambe"]', '["manubri", "panca", "squat rack", "lat machine"]', 6, 3, 60, FALSE, TRUE),
('Upper/Lower Principiante', 'Divisione semplice tra parte superiore e inferiore, ideale per chi ha poco tempo.', 2, 'beginner', 'strength', '["parte superiore", "parte inferiore"]', '["manubri", "panca", "squat rack"]', 4, 4, 50, FALSE, FALSE);

-- Inserimento template di esempio (intermedio)
INSERT INTO workout_templates (name, description, category_id, difficulty_level, goal, muscle_groups, equipment_required, duration_weeks, sessions_per_week, estimated_duration_minutes, is_premium, is_featured) VALUES
('Push/Pull/Legs Avanzato', 'Programma intenso per atleti intermedi con esperienza in palestra.', 1, 'intermediate', 'hypertrophy', '["petto", "spalle", "tricipiti", "schiena", "bicipiti", "gambe"]', '["manubri", "bilanciere", "panca", "squat rack", "lat machine", "cavi"]', 8, 6, 75, FALSE, TRUE),
('Powerlifting Base', 'Programma per sviluppare la forza massima nei tre esercizi fondamentali.', 6, 'intermediate', 'strength', '["gambe", "petto", "schiena"]', '["bilanciere", "squat rack", "panca", "piattaforme"]', 12, 3, 90, TRUE, TRUE),
('Calisthenics Intermedio', 'Allenamento a corpo libero per sviluppare forza e controllo del corpo.', 5, 'intermediate', 'strength', '["tutto il corpo"]', '["sbarra", "parallele", "anelli"]', 6, 4, 60, FALSE, FALSE);

-- Inserimento template di esempio (avanzato)
INSERT INTO workout_templates (name, description, category_id, difficulty_level, goal, muscle_groups, equipment_required, duration_weeks, sessions_per_week, estimated_duration_minutes, is_premium, is_featured) VALUES
('Bodybuilding Avanzato', 'Programma intenso per atleti esperti che cercano massima ipertrofia.', 7, 'advanced', 'hypertrophy', '["petto", "spalle", "tricipiti", "schiena", "bicipiti", "gambe", "addominali"]', '["manubri", "bilanciere", "panca", "squat rack", "lat machine", "cavi", "macchine"]', 12, 6, 90, TRUE, TRUE),
('Powerlifting Avanzato', 'Programma per atleti esperti che competono nel powerlifting.', 6, 'advanced', 'strength', '["gambe", "petto", "schiena"]', '["bilanciere", "squat rack", "panca", "piattaforme", "cinture", "fasce"]', 16, 4, 120, TRUE, TRUE);

-- ============================================================================
-- TRIGGER PER AGGIORNARE LE STATISTICHE
-- ============================================================================

-- Trigger per aggiornare il rating medio quando viene aggiunto un nuovo rating
DELIMITER //
CREATE TRIGGER update_template_rating_after_insert
AFTER INSERT ON user_template_ratings
FOR EACH ROW
BEGIN
    DECLARE template_id_var INT;
    SET template_id_var = NEW.template_id;
    
    UPDATE workout_templates 
    SET rating_average = (
        SELECT COALESCE(AVG(rating), 0) 
        FROM user_template_ratings 
        WHERE template_id = template_id_var
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM user_template_ratings 
        WHERE template_id = template_id_var
    )
    WHERE id = template_id_var;
END//

-- Trigger per aggiornare il rating medio quando viene modificato un rating
CREATE TRIGGER update_template_rating_after_update
AFTER UPDATE ON user_template_ratings
FOR EACH ROW
BEGIN
    DECLARE template_id_var INT;
    SET template_id_var = NEW.template_id;
    
    UPDATE workout_templates 
    SET rating_average = (
        SELECT COALESCE(AVG(rating), 0) 
        FROM user_template_ratings 
        WHERE template_id = template_id_var
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM user_template_ratings 
        WHERE template_id = template_id_var
    )
    WHERE id = template_id_var;
END//

-- Trigger per aggiornare il rating medio quando viene eliminato un rating
CREATE TRIGGER update_template_rating_after_delete
AFTER DELETE ON user_template_ratings
FOR EACH ROW
BEGIN
    DECLARE template_id_var INT;
    SET template_id_var = OLD.template_id;
    
    UPDATE workout_templates 
    SET rating_average = (
        SELECT COALESCE(AVG(rating), 0) 
        FROM user_template_ratings 
        WHERE template_id = template_id_var
    ),
    rating_count = (
        SELECT COUNT(*) 
        FROM user_template_ratings 
        WHERE template_id = template_id_var
    )
    WHERE id = template_id_var;
END//

-- Trigger per aggiornare il contatore di utilizzo
CREATE TRIGGER update_template_usage_count
AFTER INSERT ON template_usage_log
FOR EACH ROW
BEGIN
    IF NEW.action = 'created_workout' THEN
        UPDATE workout_templates 
        SET usage_count = usage_count + 1 
        WHERE id = NEW.template_id;
    END IF;
END//

DELIMITER ;

-- ============================================================================
-- INDICI AGGIUNTIVI PER PERFORMANCE
-- ============================================================================

-- Indici compositi per query frequenti
CREATE INDEX idx_template_difficulty_goal ON workout_templates(difficulty_level, goal);
CREATE INDEX idx_template_premium_featured ON workout_templates(is_premium, is_featured);
CREATE INDEX idx_template_rating_usage ON workout_templates(rating_average DESC, usage_count DESC);

-- ============================================================================
-- ALTERNATIVA SENZA TRIGGER (se i trigger non funzionano)
-- ============================================================================

-- Se i trigger causano problemi, puoi usare queste stored procedures
-- e chiamarle manualmente dalle API PHP

DELIMITER //

-- Procedura per aggiornare le statistiche di rating
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
-- FINE SCRIPT
-- ============================================================================
