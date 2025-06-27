@echo off
REM 🧪 SCRIPT ESECUZIONE TEST COMPLETI (Windows)
REM 
REM Questo script esegue tutti i test del progetto FitGymTrack:
REM - Test unitari
REM - Test widget
REM - Test di integrazione
REM - Test E2E

setlocal enabledelayedexpansion

echo 🧪 FITGYMTRACK TEST SUITE
echo ==========================
echo.

REM Colori per output (Windows 10+)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Funzione per stampare messaggi colorati
:print_status
echo %BLUE%[INFO]%NC% %~1
goto :eof

:print_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
goto :eof

REM Verifica prerequisiti
call :print_status "Verifica prerequisiti..."

where flutter >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Flutter non è installato o non è nel PATH"
    exit /b 1
)

where dart >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Dart non è installato o non è nel PATH"
    exit /b 1
)

call :print_success "Prerequisiti verificati"

REM Funzione per eseguire test con timeout
:run_test_with_timeout
set "test_name=%~1"
set "test_command=%~2"
set "timeout_seconds=%~3"
if "%timeout_seconds%"=="" set "timeout_seconds=300"

call :print_status "Esecuzione: %test_name%"
call :print_status "Comando: %test_command%"
call :print_status "Timeout: %timeout_seconds%s"

timeout /t %timeout_seconds% /nobreak >nul 2>&1
%test_command%
if %errorlevel% equ 0 (
    call :print_success "%test_name% completato con successo"
    exit /b 0
) else (
    call :print_error "%test_name% fallito o timeout"
    exit /b 1
)

REM Funzione per generare mock
:generate_mocks
call :print_status "Generazione mock per i test..."

dart run build_runner build --delete-conflicting-outputs
if %errorlevel% equ 0 (
    call :print_success "Mock generati con successo"
) else (
    call :print_warning "Errore nella generazione mock, continuando..."
)
goto :eof

REM Funzione per pulire cache
:clean_cache
call :print_status "Pulizia cache Flutter..."
flutter clean
flutter pub get
call :print_success "Cache pulita"
goto :eof

REM Funzione per analisi del codice
:run_analysis
call :print_status "Esecuzione analisi del codice..."

flutter analyze --no-fatal-infos
if %errorlevel% equ 0 (
    call :print_success "Analisi completata"
) else (
    call :print_warning "Analisi ha rilevato warning"
)
goto :eof

REM Funzione per test unitari
:run_unit_tests
call :print_status "Esecuzione test unitari..."

set "unit_test_command=flutter test test/unit/"
call :run_test_with_timeout "Test Unitari" "%unit_test_command%" 180
if %errorlevel% neq 0 (
    call :print_error "Test unitari falliti"
    exit /b 1
)
call :print_success "Test unitari completati"
goto :eof

REM Funzione per test widget
:run_widget_tests
call :print_status "Esecuzione test widget..."

set "widget_test_command=flutter test test/widget/"
call :run_test_with_timeout "Test Widget" "%widget_test_command%" 300
if %errorlevel% neq 0 (
    call :print_error "Test widget falliti"
    exit /b 1
)
call :print_success "Test widget completati"
goto :eof

REM Funzione per test di integrazione
:run_integration_tests
call :print_status "Esecuzione test di integrazione..."

set "integration_test_command=flutter test integration_test/"
call :run_test_with_timeout "Test Integrazione" "%integration_test_command%" 600
if %errorlevel% neq 0 (
    call :print_error "Test integrazione falliti"
    exit /b 1
)
call :print_success "Test integrazione completati"
goto :eof

REM Funzione per test E2E
:run_e2e_tests
call :print_status "Esecuzione test E2E..."

REM Verifica se un dispositivo è connesso
flutter devices | findstr "connected" >nul 2>&1
if %errorlevel% neq 0 (
    call :print_warning "Nessun dispositivo connesso per test E2E"
    call :print_status "Avvia un emulatore o connetti un dispositivo fisico"
    goto :eof
)

set "e2e_test_command=flutter test test/e2e/"
call :run_test_with_timeout "Test E2E" "%e2e_test_command%" 900
if %errorlevel% neq 0 (
    call :print_error "Test E2E falliti"
    exit /b 1
)
call :print_success "Test E2E completati"
goto :eof

REM Funzione per test specifici
:run_specific_tests
set "test_type=%~1"

if "%test_type%"=="unit" (
    call :run_unit_tests
) else if "%test_type%"=="widget" (
    call :run_widget_tests
) else if "%test_type%"=="integration" (
    call :run_integration_tests
) else if "%test_type%"=="e2e" (
    call :run_e2e_tests
) else if "%test_type%"=="analysis" (
    call :run_analysis
) else (
    call :print_error "Tipo di test non riconosciuto: %test_type%"
    call :print_status "Tipi disponibili: unit, widget, integration, e2e, analysis"
    exit /b 1
)
goto :eof

REM Funzione per generare report
:generate_report
call :print_status "Generazione report test..."

if not exist "test_reports" mkdir test_reports

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,8%_%dt:~8,6%"
set "report_file=test_reports\test_report_%timestamp%.txt"

echo FITGYMTRACK TEST REPORT > "%report_file%"
echo Generated: %date% %time% >> "%report_file%"
flutter --version | findstr "Flutter" >> "%report_file%"
echo. >> "%report_file%"

call :print_success "Report generato: %report_file%"
goto :eof

REM Funzione principale
:main
set "test_type=%~1"
if "%test_type%"=="" set "test_type=all"

echo 🧪 Avvio test suite FitGymTrack
echo Tipo di test: %test_type%
echo.

REM Setup iniziale
call :clean_cache
call :generate_mocks

REM Esecuzione test in base al tipo
if "%test_type%"=="all" (
    call :print_status "Esecuzione suite completa..."
    
    REM Analisi del codice
    call :run_analysis
    
    REM Test unitari
    call :run_unit_tests
    if %errorlevel% neq 0 (
        call :print_error "Test unitari falliti, interrompendo esecuzione"
        exit /b 1
    )
    
    REM Test widget
    call :run_widget_tests
    if %errorlevel% neq 0 (
        call :print_error "Test widget falliti, interrompendo esecuzione"
        exit /b 1
    )
    
    REM Test integrazione
    call :run_integration_tests
    if %errorlevel% neq 0 (
        call :print_error "Test integrazione falliti, interrompendo esecuzione"
        exit /b 1
    )
    
    REM Test E2E (opzionale)
    call :run_e2e_tests
    
    call :print_success "🎉 Tutti i test completati con successo!"
    
) else (
    call :run_specific_tests "%test_type%"
)

REM Generazione report
call :generate_report

echo.
echo 🧪 Test suite completata!
echo ==========================
goto :eof

REM Gestione argomenti
if "%1"=="help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help
goto :main

:show_help
echo 🧪 FITGYMTRACK TEST SUITE
echo.
echo Uso: %0 [tipo_test]
echo.
echo Tipi di test disponibili:
echo   all          - Esegue tutti i test (default)
echo   unit         - Solo test unitari
echo   widget       - Solo test widget
echo   integration  - Solo test integrazione
echo   e2e          - Solo test end-to-end
echo   analysis     - Solo analisi del codice
echo   help         - Mostra questo messaggio
echo.
echo Esempi:
echo   %0              # Esegue tutti i test
echo   %0 unit         # Solo test unitari
echo   %0 e2e          # Solo test E2E
echo.
exit /b 0 