#!/bin/bash

# setup_cronjobs.sh
# Script per configurare i cronjob Stripe automaticamente

echo "🔧 Configurazione Cronjob Stripe per FitGymTrack"
echo "================================================"

# Directory base
BASE_DIR="/var/www/html/api/stripe"
CRON_DIR="/etc/cron.d"

# Verifica permessi
if [ "$EUID" -ne 0 ]; then
    echo "❌ Questo script deve essere eseguito come root (sudo)"
    exit 1
fi

echo "📁 Directory base: $BASE_DIR"
echo "📁 Directory cron: $CRON_DIR"

# 1. Cronjob per controllo scadenze (giornaliero alle 6:00)
echo "⏰ Configurazione cronjob controllo scadenze..."
cat > "$CRON_DIR/fitgymtrack-subscription-check" << EOF
# FitGymTrack - Controllo scadenze subscription
# Esegue ogni giorno alle 6:00 AM
0 6 * * * www-data /usr/bin/php $BASE_DIR/cron_subscription_check.php >> $BASE_DIR/logs/subscription_cron.log 2>&1
EOF

# 2. Cronjob per controllo rinnovi (ogni 6 ore)
echo "🔄 Configurazione cronjob controllo rinnovi..."
cat > "$CRON_DIR/fitgymtrack-renewal-check" << EOF
# FitGymTrack - Controllo rinnovi automatici
# Esegue ogni 6 ore (00:00, 06:00, 12:00, 18:00)
0 */6 * * * www-data /usr/bin/php $BASE_DIR/cron_renewal_check.php >> $BASE_DIR/logs/renewal_cron.log 2>&1
EOF

# Imposta permessi corretti
chmod 644 "$CRON_DIR/fitgymtrack-subscription-check"
chmod 644 "$CRON_DIR/fitgymtrack-renewal-check"

# Crea directory log se non esiste
mkdir -p "$BASE_DIR/logs"
chown -R www-data:www-data "$BASE_DIR/logs"
chmod 755 "$BASE_DIR/logs"

echo "✅ Cronjob configurati con successo!"
echo ""
echo "📋 Cronjob installati:"
echo "   1. Controllo scadenze: 0 6 * * * (giornaliero alle 6:00)"
echo "   2. Controllo rinnovi: 0 */6 * * * (ogni 6 ore)"
echo ""
echo "📁 File di configurazione:"
echo "   - $CRON_DIR/fitgymtrack-subscription-check"
echo "   - $CRON_DIR/fitgymtrack-renewal-check"
echo ""
echo "📝 Log files:"
echo "   - $BASE_DIR/logs/subscription_cron.log"
echo "   - $BASE_DIR/logs/renewal_cron.log"
echo ""
echo "🔍 Per verificare i cronjob:"
echo "   crontab -l"
echo ""
echo "🧪 Per testare manualmente:"
echo "   php $BASE_DIR/cron_subscription_check.php"
echo "   php $BASE_DIR/cron_renewal_check.php"
echo ""
echo "🌐 Per testare via web:"
echo "   http://yourdomain.com/api/stripe/test_renewal_check.php?manual_run=1"
echo ""
echo "🎉 Configurazione completata!"
