-- ============================================================================
-- NOTIFICATION SYSTEM - FASE 1
-- Database Schema per Sistema Notifiche In-App
-- ============================================================================

-- Tabella principale per le notifiche
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sender_id INT NOT NULL,           -- Gym owner o Trainer che invia
    sender_type ENUM('gym', 'trainer') NOT NULL,
    recipient_id INT,                 -- NULL per broadcast a tutti gli utenti della palestra
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('message', 'announcement', 'reminder') DEFAULT 'message',
    priority ENUM('low', 'normal', 'high') DEFAULT 'normal',
    status ENUM('sent', 'delivered', 'read') DEFAULT 'sent',
    is_broadcast BOOLEAN DEFAULT FALSE, -- TRUE se inviata a tutti gli utenti della palestra
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    
    -- Indici per performance
    INDEX idx_sender (sender_id),
    INDEX idx_recipient (recipient_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_broadcast (is_broadcast),
    
    -- Foreign keys
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabella per tracciare le notifiche broadcast (per statistiche)
CREATE TABLE notification_broadcast_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    notification_id INT NOT NULL,
    recipient_id INT NOT NULL,
    delivered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    
    INDEX idx_notification (notification_id),
    INDEX idx_recipient (recipient_id),
    
    FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
