#!/bin/bash

# =============================================================================
# SETUP CRON JOB - PROMEMORIA CORSI AUTOMATICI
# =============================================================================
# Script per configurare il cron job che invia promemoria automatici
# per i corsi 1 ora prima dell'inizio
# =============================================================================

echo "🚀 SETUP CRON JOB PROMEMORIA CORSI"
echo "=================================="

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per log colorato
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# VERIFICA PREREQUISITI
# =============================================================================

log_info "Verificando prerequisiti..."

# Verifica che siamo in ambiente Linux/Unix
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
    log_error "Questo script funziona solo su Linux/macOS"
    exit 1
fi

# Verifica che il file cron job esista
CRON_FILE="/var/www/html/api/course_reminder_cron.php"
if [ ! -f "$CRON_FILE" ]; then
    log_error "File cron job non trovato: $CRON_FILE"
    log_info "Assicurati di aver copiato course_reminder_cron.php nella directory API"
    exit 1
fi

log_success "File cron job trovato: $CRON_FILE"

# Verifica permessi di esecuzione
if [ ! -x "$CRON_FILE" ]; then
    log_info "Impostando permessi di esecuzione..."
    chmod +x "$CRON_FILE"
    log_success "Permessi impostati"
fi

# Verifica che PHP sia installato
if ! command -v php &> /dev/null; then
    log_error "PHP non è installato o non è nel PATH"
    exit 1
fi

PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2)
log_success "PHP trovato: versione $PHP_VERSION"

# Verifica che crontab sia disponibile
if ! command -v crontab &> /dev/null; then
    log_error "crontab non è disponibile"
    exit 1
fi

log_success "crontab disponibile"

# =============================================================================
# TEST DEL SISTEMA
# =============================================================================

log_info "Testando il sistema promemoria..."

# Test manuale del cron job
log_info "Eseguendo test manuale..."
TEST_OUTPUT=$(php "$CRON_FILE" manual_run 2>&1)
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    log_success "Test manuale completato con successo"
    echo "$TEST_OUTPUT"
else
    log_error "Test manuale fallito (exit code: $TEST_EXIT_CODE)"
    echo "$TEST_OUTPUT"
    log_warning "Controlla i log per dettagli: /var/www/html/api/logs/course_reminders_$(date +%Y-%m).log"
fi

# =============================================================================
# CONFIGURAZIONE CRON JOB
# =============================================================================

log_info "Configurando cron job..."

# Backup del crontab esistente
log_info "Creando backup del crontab..."
crontab -l > /tmp/crontab_backup_$(date +%Y%m%d_%H%M%S).txt 2>/dev/null || true

# Verifica se il cron job esiste già
if crontab -l 2>/dev/null | grep -q "course_reminder_cron.php"; then
    log_warning "Cron job per promemoria corsi già esistente"
    read -p "Vuoi sovrascriverlo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Configurazione annullata"
        exit 0
    fi
    
    # Rimuovi il cron job esistente
    log_info "Rimuovendo cron job esistente..."
    crontab -l 2>/dev/null | grep -v "course_reminder_cron.php" | crontab -
fi

# Aggiungi il nuovo cron job
log_info "Aggiungendo nuovo cron job..."
(crontab -l 2>/dev/null; echo "# Promemoria corsi automatici - ogni 15 minuti") | crontab -
(crontab -l 2>/dev/null; echo "*/15 * * * * /usr/bin/php $CRON_FILE >> /var/www/html/api/logs/cron_reminders.log 2>&1") | crontab -

log_success "Cron job configurato con successo!"

# =============================================================================
# VERIFICA CONFIGURAZIONE
# =============================================================================

log_info "Verificando configurazione..."

echo ""
echo "📋 CRON JOB CONFIGURATO:"
echo "========================="
crontab -l | grep -A1 -B1 "course_reminder_cron.php"

echo ""
echo "⏰ SCHEDULE: Ogni 15 minuti"
echo "🎯 FUNZIONE: Invia promemoria 1 ora prima dei corsi"
echo "📁 LOG FILE: /var/www/html/api/logs/course_reminders_YYYY-MM.log"
echo "🔧 TEST MANUALE: php $CRON_FILE manual_run"

# =============================================================================
# CREAZIONE DIRECTORY LOG
# =============================================================================

log_info "Creando directory log..."
mkdir -p /var/www/html/api/logs
chmod 755 /var/www/html/api/logs

log_success "Directory log creata: /var/www/html/api/logs"

# =============================================================================
# INFORMAZIONI FINALI
# =============================================================================

echo ""
echo "🎉 SETUP COMPLETATO CON SUCCESSO!"
echo "=================================="
echo ""
echo "📋 PROSSIMI PASSI:"
echo "1. Il cron job inizierà a funzionare automaticamente"
echo "2. Controlla i log per verificare il funzionamento:"
echo "   tail -f /var/www/html/api/logs/course_reminders_$(date +%Y-%m).log"
echo ""
echo "🧪 TEST MANUALE:"
echo "   php $CRON_FILE manual_run"
echo ""
echo "🔧 GESTIONE CRON JOB:"
echo "   - Visualizza: crontab -l"
echo "   - Rimuovi: crontab -e (elimina la riga)"
echo "   - Log cron: tail -f /var/www/html/api/logs/cron_reminders.log"
echo ""
echo "📱 NOTIFICHE:"
echo "   - Inviate 1 ora prima del corso"
echo "   - Solo a utenti con FCM token valido"
echo "   - Evita duplicati automaticamente"
echo ""

log_success "Setup completato! Il sistema promemoria è attivo."

