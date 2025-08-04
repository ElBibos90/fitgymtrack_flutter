-- ============================================================================
-- MIGRAZIONE DATABASE: SISTEMA VERSIONING TARGETED
-- ============================================================================

-- STEP 1: Aggiungere campo is_tester alla tabella users
ALTER TABLE users ADD COLUMN is_tester BOOLEAN DEFAULT FALSE;

-- STEP 2: Aggiungere campi per targeting alla tabella app_versions
ALTER TABLE app_versions 
ADD COLUMN platform ENUM('android', 'ios', 'both') DEFAULT 'both',
ADD COLUMN target_audience ENUM('production', 'test', 'both') DEFAULT 'production';

-- STEP 3: Aggiornare la versione corrente come "punto zero" di produzione
-- Questa sarà la versione base da cui partire
UPDATE app_versions 
SET platform = 'both', 
    target_audience = 'production',
    update_message = 'Versione base di produzione - punto di partenza per il sistema di versioning targeted'
WHERE is_active = 1;

-- STEP 4: Creare indici per ottimizzare le query di targeting
CREATE INDEX idx_app_versions_platform ON app_versions(platform);
CREATE INDEX idx_app_versions_target_audience ON app_versions(target_audience);
CREATE INDEX idx_app_versions_active_platform ON app_versions(is_active, platform, target_audience);

-- STEP 5: Verifica della migrazione
SELECT 
    'Database migration completed successfully' as status,
    COUNT(*) as total_users,
    SUM(CASE WHEN is_tester = 1 THEN 1 ELSE 0 END) as test_users
FROM users;

SELECT 
    'Current active version' as info,
    version_name,
    build_number,
    platform,
    target_audience,
    update_required,
    update_message
FROM app_versions 
WHERE is_active = 1; 