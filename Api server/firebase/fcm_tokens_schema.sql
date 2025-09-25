-- fitgymtrack_flutter/Api server/firebase/fcm_tokens_schema.sql

-- Tabella per memorizzare i token FCM degli utenti
CREATE TABLE user_fcm_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    fcm_token TEXT NOT NULL,
    platform ENUM('android', 'ios', 'web', 'unknown') DEFAULT 'unknown',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_token (user_id, fcm_token(255))
);

-- Indice per ottimizzare le query sui token
CREATE INDEX idx_fcm_token ON user_fcm_tokens(fcm_token(255));
CREATE INDEX idx_user_platform ON user_fcm_tokens(user_id, platform);
CREATE INDEX idx_active_tokens ON user_fcm_tokens(is_active, platform);
