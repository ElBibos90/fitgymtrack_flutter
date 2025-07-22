# SafeRow Widget

## Descrizione
Il widget `SafeRow` è un wrapper intelligente per il widget `Row` di Flutter che gestisce automaticamente gli overflow di layout.

## Caratteristiche
- ✅ **Gestione automatica overflow**: Se i widget non entrano in una riga, usa automaticamente `Wrap`
- ✅ **Compatibilità**: Mantiene tutte le proprietà di `Row`
- ✅ **Responsive**: Si adatta automaticamente alla larghezza disponibile
- ✅ **Spacing automatico**: Supporta spacing tra i widget
- ✅ **Fallback sicuro**: Se `wrapIfNeeded = false`, usa una `Row` normale

## Utilizzo

### Sostituzione semplice di Row
```dart
// Prima (può causare overflow)
Row(
  children: [
    Icon(Icons.star),
    Text('Testo molto lungo che potrebbe causare overflow'),
    ElevatedButton(onPressed: () {}, child: Text('Bottone')),
  ],
)

// Dopo (gestisce automaticamente l'overflow)
SafeRow(
  children: [
    Icon(Icons.star),
    Text('Testo molto lungo che potrebbe causare overflow'),
    ElevatedButton(onPressed: () {}, child: Text('Bottone')),
  ],
)
```

### Con spacing personalizzato
```dart
SafeRow(
  spacing: 16.w,
  children: [
    Icon(Icons.star),
    Text('Testo'),
    ElevatedButton(onPressed: () {}, child: Text('Bottone')),
  ],
)
```

### Con allineamento personalizzato
```dart
SafeRow(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Icon(Icons.star),
    Text('Testo'),
    ElevatedButton(onPressed: () {}, child: Text('Bottone')),
  ],
)
```

### Disabilitare il wrapping automatico
```dart
SafeRow(
  wrapIfNeeded: false, // Usa sempre Row, mai Wrap
  children: [
    Icon(Icons.star),
    Text('Testo'),
    ElevatedButton(onPressed: () {}, child: Text('Bottone')),
  ],
)
```

## Quando usare SafeRow

### ✅ Usa SafeRow quando:
- Hai una Row con contenuto dinamico
- Il testo potrebbe essere lungo
- Hai molti widget in una riga
- Vuoi evitare overflow di layout
- L'app deve essere responsive

### ❌ Non usare SafeRow quando:
- Hai bisogno di controllo preciso sul layout
- I widget devono sempre stare in una riga
- Stai creando layout molto specifici

## Migrazione

Per migrare da `Row` a `SafeRow`:

1. **Importa il widget**:
```dart
import 'package:your_app/shared/widgets/safe_row_widget.dart';
```

2. **Sostituisci Row con SafeRow**:
```dart
// Prima
Row(children: [...])

// Dopo  
SafeRow(children: [...])
```

3. **Mantieni tutte le proprietà esistenti**:
```dart
// Tutte queste proprietà funzionano con SafeRow
SafeRow(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [...],
)
```

## Esempi pratici

### Esempio 1: Card con informazioni
```dart
SafeRow(
  spacing: 8.w,
  children: [
    Icon(Icons.fitness_center, size: 20.w),
    Text('Peso: 80 kg'),
    Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text('Completato'),
    ),
  ],
)
```

### Esempio 2: Header con azioni
```dart
SafeRow(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Allenamento',
      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
    ),
    SafeRow(
      spacing: 8.w,
      children: [
        IconButton(icon: Icon(Icons.edit), onPressed: () {}),
        IconButton(icon: Icon(Icons.delete), onPressed: () {}),
      ],
    ),
  ],
)
```

## Note tecniche

- Il widget stima la larghezza necessaria per decidere se usare `Row` o `Wrap`
- La stima è conservativa per evitare overflow
- Se `wrapIfNeeded = false`, usa sempre `Row` (comportamento originale)
- Il widget è ottimizzato per performance e non causa rebuild inutili 