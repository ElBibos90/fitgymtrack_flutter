-- ============================================================================
-- TABELLA PER GESTIONE VERSIONI APP
-- ============================================================================

CREATE TABLE IF NOT EXISTS `app_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `version_name` varchar(20) NOT NULL COMMENT 'Versione semantica (es. 1.0.1)',
  `version_code` int(11) NOT NULL COMMENT 'Codice versione numerico (es. 4)',
  `build_number` varchar(10) NOT NULL COMMENT 'Numero build (es. 4)',
  `update_required` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Se l\'aggiornamento è obbligatorio',
  `update_message` text DEFAULT NULL COMMENT 'Messaggio da mostrare per l\'aggiornamento',
  `min_required_version` varchar(20) DEFAULT NULL COMMENT 'Versione minima richiesta',
  `release_notes` text DEFAULT NULL COMMENT 'Note di rilascio',
  `release_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Data di rilascio',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Se questa versione è attiva',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_version_code` (`version_code`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_release_date` (`release_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Gestione versioni dell\'app FitGymTrack';

-- ============================================================================
-- INSERIMENTO VERSIONE INIZIALE
-- ============================================================================

INSERT INTO `app_versions` (
  `version_name`, 
  `version_code`, 
  `build_number`, 
  `update_required`, 
  `update_message`, 
  `min_required_version`, 
  `release_notes`, 
  `release_date`
) VALUES (
  '1.0.1',           -- version_name
  4,                  -- version_code
  '4',               -- build_number
  0,                 -- update_required (non obbligatorio)
  '',                -- update_message
  '1.0.0',           -- min_required_version
  'Versione stabile con miglioramenti generali e correzioni bug', -- release_notes
  NOW()              -- release_date
) ON DUPLICATE KEY UPDATE
  `updated_at` = NOW();

-- ============================================================================
-- PROCEDURA PER AGGIORNARE VERSIONE
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS `UpdateAppVersion`(
  IN p_version_name VARCHAR(20),
  IN p_version_code INT,
  IN p_build_number VARCHAR(10),
  IN p_update_required BOOLEAN,
  IN p_update_message TEXT,
  IN p_min_required_version VARCHAR(20),
  IN p_release_notes TEXT
)
BEGIN
  -- Disattiva tutte le versioni precedenti
  UPDATE `app_versions` SET `is_active` = 0;
  
  -- Inserisci la nuova versione
  INSERT INTO `app_versions` (
    `version_name`,
    `version_code`,
    `build_number`,
    `update_required`,
    `update_message`,
    `min_required_version`,
    `release_notes`,
    `release_date`
  ) VALUES (
    p_version_name,
    p_version_code,
    p_build_number,
    p_update_required,
    p_update_message,
    p_min_required_version,
    p_release_notes,
    NOW()
  );
  
  SELECT 'Version updated successfully' as message;
END$$

DELIMITER ;

-- ============================================================================
-- VISTA PER VERSIONE CORRENTE
-- ============================================================================

CREATE OR REPLACE VIEW `current_app_version` AS
SELECT 
  `version_name`,
  `version_code`,
  `build_number`,
  `update_required`,
  `update_message`,
  `min_required_version`,
  `release_notes`,
  `release_date`
FROM `app_versions`
WHERE `is_active` = 1
ORDER BY `version_code` DESC
LIMIT 1;

-- ============================================================================
-- ESEMPIO DI USO
-- ============================================================================

/*
-- Per aggiornare a una nuova versione:
CALL UpdateAppVersion(
  '1.0.2',           -- nuova versione
  5,                 -- nuovo codice versione
  '5',              -- nuovo build number
  0,                -- aggiornamento non obbligatorio
  'Nuove funzionalità disponibili!', -- messaggio
  '1.0.0',          -- versione minima richiesta
  'Aggiunte nuove funzionalità e miglioramenti performance' -- note di rilascio
);

-- Per rendere obbligatorio un aggiornamento:
CALL UpdateAppVersion(
  '1.0.3',
  6,
  '6',
  1,                -- aggiornamento obbligatorio
  'Aggiornamento di sicurezza obbligatorio', -- messaggio
  '1.0.0',
  'Correzioni di sicurezza critiche'
);
*/ 