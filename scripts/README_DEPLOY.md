# FITGYMTRACK DEPLOY SYSTEM

## FLUSSO CORRETTO DI RILASCIO

### LOGICA: PRIMA PUBBLICHI, POI AGGIORNI

1. **PUBBLICAZIONE** (con versione corrente)
   - Build AAB con versione attuale
   - Carica su Google Play Console
   - Pubblica la release

2. **AGGIORNAMENTO VERSIONI** (dopo pubblicazione)
   - Aggiorna pubspec.yaml
   - Aggiorna database
   - Prepara per prossima release

---

## SCRIPT DISPONIBILI

### DEPLOY FINAL FIXED (COMPLETO) - UNICO SCRIPT NECESSARIO
```bash
powershell -ExecutionPolicy Bypass -File scripts/deploy_final_fixed.ps1
```
- Aggiorna VERSIONI (pubspec.yaml)
- AGGIORNA DATABASE automaticamente
- SUPPORTO AGGIORNAMENTI CRITICI
- BUILD AAB automatico
- VERSION CODE calcolato automaticamente
- USO: Deploy completo in un unico comando

---

## PROCEDURA RACCOMANDATA

### DEPLOY COMPLETO (RACCOMANDATO)
```bash
# Un unico comando per tutto!
powershell -ExecutionPolicy Bypass -File scripts/deploy_final_fixed.ps1
```

**Questo script fa tutto automaticamente:**
1. Legge versione corrente
2. Richiede nuova versione
3. Richiede se è aggiornamento critico
4. Richiede messaggio aggiornamento
5. Aggiorna pubspec.yaml
6. Calcola version code automaticamente
7. Trova Python automaticamente
8. Installa mysql-connector se necessario
9. Aggiorna database automaticamente (con flag critico)
10. Pulisce build precedente
11. Aggiorna dipendenze
12. Compila AAB
13. Fornisce istruzioni per Google Play Console

---

## CONFIGURAZIONE DATABASE

### Credenziali Database
```json
{
  "host": "104.248.103.182",
  "user": "ElBibo", 
  "password": "Groot00",
  "database": "Workout",
  "port": 3306
}
```

### Aggiornamento Automatico Database
Lo script aggiorna automaticamente il database con supporto per aggiornamenti critici:
- Trova Python automaticamente
- Installa mysql-connector se necessario
- Esegue le query di aggiornamento
- Supporta flag `update_required` e `update_message`
- Fornisce fallback manuale se necessario

---

## SISTEMA AGGIORNAMENTI CRITICI

### 🚨 Aggiornamenti Forzati
Lo script ora supporta aggiornamenti critici che:
- Vengono sempre controllati (ignorano intervallo 6 ore)
- Mostrano dialog non chiudibile
- Hanno messaggi personalizzabili
- Sono visivamente distinti (icona arancione)

### 📝 Esempi di Uso

#### **Aggiornamento Normale:**
```
Aggiornamento forzato/critico? (y/N): n
Messaggio aggiornamento (opzionale): Miglioramenti generali
```

#### **Aggiornamento Critico:**
```
Aggiornamento forzato/critico? (y/N): y
Messaggio aggiornamento (opzionale): Aggiornamento di sicurezza obbligatorio
```

---

## STRUTTURA FILE

```
scripts/
├── deploy_final_fixed.ps1          # SCRIPT TOTALE (UNICO NECESSARIO)
├── deploy_config.json              # Configurazione database
└── README_DEPLOY.md                # Questa documentazione
```

---

## TROUBLESHOOTING

### Errore pubspec.yaml
```bash
# Verifica formato versione
# Deve essere: version: 1.2.3+45
```

### Errore connessione database
```bash
# Verifica credenziali
# Host: 104.248.103.182
# User: ElBibo
# Database: Workout
```

### Errore Python
```bash
# Installa Python se necessario
winget install Python.Python.3.11
```

---

## ESEMPIO FLUSSO COMPLETO

```bash
# DEPLOY COMPLETO (versione 1.0.10+10 -> 1.0.11+11)
powershell -ExecutionPolicy Bypass -File scripts/deploy_final_fixed.ps1

# Inserisci:
# - Nuova versione: 1.0.11+11
# - Aggiornamento critico: y
# - Messaggio: Aggiornamento di sicurezza
# - Conferma: y

# Lo script fa tutto automaticamente:
# 1. Aggiorna pubspec.yaml: 1.0.11+11
# 2. Calcola version code: 1010011
# 3. Aggiorna database con flag critico
# 4. Build AAB: app-release.aab
# 5. Pronto per Google Play Console
```

---

## STATO ATTUALE

### SISTEMA FUNZIONANTE:
- Script PowerShell per aggiornamento versioni
- Aggiornamento automatico database
- Supporto aggiornamenti critici
- Build AAB per Google Play Console
- Sistema aggiornamenti ogni 6 ore
- Validazione token intelligente
- Configurazione database per produzione
- Deploy totale automatizzato

### VERSIONE ATTUALE:
- **pubspec.yaml:** `1.0.10+10`
- **Database:** `1.0.10+10` (attiva)
- **AAB:** Pronto per Google Play Console

---

## SUPPORTO

Per problemi o domande:
1. Verifica la connessione database
2. Controlla i log degli script
3. Testa manualmente i comandi Flutter
4. Verifica le credenziali nel file di configurazione

---

## COMANDO DEFINITIVO

**Per il deploy completo, usa sempre:**
```bash
powershell -ExecutionPolicy Bypass -File scripts/deploy_final_fixed.ps1
```

**Questo è il tuo script definitivo per tutto!** 