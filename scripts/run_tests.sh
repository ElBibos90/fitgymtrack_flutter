#!/bin/bash

# 🧪 SCRIPT ESECUZIONE TEST COMPLETI
# 
# Questo script esegue tutti i test del progetto FitGymTrack:
# - Test unitari
# - Test widget
# - Test di integrazione
# - Test E2E

set -e  # Esci se qualsiasi comando fallisce

echo "🧪 FITGYMTRACK TEST SUITE"
echo "=========================="
echo ""

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare messaggi colorati
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Funzione per verificare se un comando esiste
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica prerequisiti
print_status "Verifica prerequisiti..."

if ! command_exists flutter; then
    print_error "Flutter non è installato o non è nel PATH"
    exit 1
fi

if ! command_exists dart; then
    print_error "Dart non è installato o non è nel PATH"
    exit 1
fi

print_success "Prerequisiti verificati"

# Funzione per eseguire test con timeout
run_test_with_timeout() {
    local test_name="$1"
    local test_command="$2"
    local timeout_seconds="${3:-300}"  # Default 5 minuti
    
    print_status "Esecuzione: $test_name"
    print_status "Comando: $test_command"
    print_status "Timeout: ${timeout_seconds}s"
    
    if timeout "$timeout_seconds" bash -c "$test_command"; then
        print_success "$test_name completato con successo"
        return 0
    else
        print_error "$test_name fallito o timeout"
        return 1
    fi
}

# Funzione per generare mock
generate_mocks() {
    print_status "Generazione mock per i test..."
    
    if dart run build_runner build --delete-conflicting-outputs; then
        print_success "Mock generati con successo"
    else
        print_warning "Errore nella generazione mock, continuando..."
    fi
}

# Funzione per pulire cache
clean_cache() {
    print_status "Pulizia cache Flutter..."
    flutter clean
    flutter pub get
    print_success "Cache pulita"
}

# Funzione per analisi del codice
run_analysis() {
    print_status "Esecuzione analisi del codice..."
    
    if flutter analyze --no-fatal-infos; then
        print_success "Analisi completata"
    else
        print_warning "Analisi ha rilevato warning"
    fi
}

# Funzione per test unitari
run_unit_tests() {
    print_status "Esecuzione test unitari..."
    
    local unit_test_command="flutter test test/unit/"
    
    if run_test_with_timeout "Test Unitari" "$unit_test_command" 180; then
        print_success "Test unitari completati"
    else
        print_error "Test unitari falliti"
        return 1
    fi
}

# Funzione per test widget
run_widget_tests() {
    print_status "Esecuzione test widget..."
    
    local widget_test_command="flutter test test/widget/"
    
    if run_test_with_timeout "Test Widget" "$widget_test_command" 300; then
        print_success "Test widget completati"
    else
        print_error "Test widget falliti"
        return 1
    fi
}

# Funzione per test di integrazione
run_integration_tests() {
    print_status "Esecuzione test di integrazione..."
    
    local integration_test_command="flutter test integration_test/"
    
    if run_test_with_timeout "Test Integrazione" "$integration_test_command" 600; then
        print_success "Test integrazione completati"
    else
        print_error "Test integrazione falliti"
        return 1
    fi
}

# Funzione per test E2E
run_e2e_tests() {
    print_status "Esecuzione test E2E..."
    
    # Verifica se un dispositivo è connesso
    if ! flutter devices | grep -q "connected"; then
        print_warning "Nessun dispositivo connesso per test E2E"
        print_status "Avvia un emulatore o connetti un dispositivo fisico"
        return 0
    fi
    
    local e2e_test_command="flutter test test/e2e/"
    
    if run_test_with_timeout "Test E2E" "$e2e_test_command" 900; then
        print_success "Test E2E completati"
    else
        print_error "Test E2E falliti"
        return 1
    fi
}

# Funzione per test specifici
run_specific_tests() {
    local test_type="$1"
    
    case "$test_type" in
        "unit")
            run_unit_tests
            ;;
        "widget")
            run_widget_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "e2e")
            run_e2e_tests
            ;;
        "analysis")
            run_analysis
            ;;
        *)
            print_error "Tipo di test non riconosciuto: $test_type"
            print_status "Tipi disponibili: unit, widget, integration, e2e, analysis"
            exit 1
            ;;
    esac
}

# Funzione per generare report
generate_report() {
    print_status "Generazione report test..."
    
    local report_dir="test_reports"
    mkdir -p "$report_dir"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$report_dir/test_report_$timestamp.txt"
    
    echo "FITGYMTRACK TEST REPORT" > "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "Flutter Version: $(flutter --version | head -n 1)" >> "$report_file"
    echo "" >> "$report_file"
    
    print_success "Report generato: $report_file"
}

# Funzione principale
main() {
    local test_type="${1:-all}"
    
    echo "🧪 Avvio test suite FitGymTrack"
    echo "Tipo di test: $test_type"
    echo ""
    
    # Setup iniziale
    clean_cache
    generate_mocks
    
    # Esecuzione test in base al tipo
    if [ "$test_type" = "all" ]; then
        print_status "Esecuzione suite completa..."
        
        # Analisi del codice
        run_analysis
        
        # Test unitari
        if ! run_unit_tests; then
            print_error "Test unitari falliti, interrompendo esecuzione"
            exit 1
        fi
        
        # Test widget
        if ! run_widget_tests; then
            print_error "Test widget falliti, interrompendo esecuzione"
            exit 1
        fi
        
        # Test integrazione
        if ! run_integration_tests; then
            print_error "Test integrazione falliti, interrompendo esecuzione"
            exit 1
        fi
        
        # Test E2E (opzionale)
        run_e2e_tests
        
        print_success "🎉 Tutti i test completati con successo!"
        
    else
        run_specific_tests "$test_type"
    fi
    
    # Generazione report
    generate_report
    
    echo ""
    echo "🧪 Test suite completata!"
    echo "=========================="
}

# Gestione argomenti
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "🧪 FITGYMTRACK TEST SUITE"
        echo ""
        echo "Uso: $0 [tipo_test]"
        echo ""
        echo "Tipi di test disponibili:"
        echo "  all          - Esegue tutti i test (default)"
        echo "  unit         - Solo test unitari"
        echo "  widget       - Solo test widget"
        echo "  integration  - Solo test integrazione"
        echo "  e2e          - Solo test end-to-end"
        echo "  analysis     - Solo analisi del codice"
        echo "  help         - Mostra questo messaggio"
        echo ""
        echo "Esempi:"
        echo "  $0              # Esegue tutti i test"
        echo "  $0 unit         # Solo test unitari"
        echo "  $0 e2e          # Solo test E2E"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 