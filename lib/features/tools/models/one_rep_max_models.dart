// lib/features/tools/models/one_rep_max_models.dart

/// Model per i risultati del calcolo 1RM
class OneRepMaxResult {
  final double oneRM;
  final double weight;
  final int reps;
  final String formula;
  final Map<String, double> percentages;

  const OneRepMaxResult({
    required this.oneRM,
    required this.weight,
    required this.reps,
    required this.formula,
    required this.percentages,
  });

  /// Crea risultato da calcolo Epley
  factory OneRepMaxResult.fromEpley(double weight, int reps) {
    final oneRM = OneRepMaxCalculator.epley(weight, reps);
    return OneRepMaxResult(
      oneRM: oneRM,
      weight: weight,
      reps: reps,
      formula: 'Epley',
      percentages: OneRepMaxCalculator.getPercentages(oneRM),
    );
  }

  /// Crea risultato da calcolo Brzycki
  factory OneRepMaxResult.fromBrzycki(double weight, int reps) {
    final oneRM = OneRepMaxCalculator.brzycki(weight, reps);
    return OneRepMaxResult(
      oneRM: oneRM,
      weight: weight,
      reps: reps,
      formula: 'Brzycki',
      percentages: OneRepMaxCalculator.getPercentages(oneRM),
    );
  }

  /// Formattazione del 1RM
  String get formattedOneRM => '${oneRM.toStringAsFixed(1)} kg';

  /// Formattazione dell'input
  String get formattedInput => '${weight.toStringAsFixed(1)} kg × $reps reps';

  @override
  String toString() => 'OneRepMaxResult(oneRM: $oneRM, formula: $formula)';
}

/// Enum per le formule di calcolo disponibili
enum OneRepMaxFormula {
  epley('Epley', 'Peso × (1 + reps/30)'),
  brzycki('Brzycki', 'Peso × 36/(37-reps)'),
  lander('Lander', 'Peso × 100/(101.3-2.67123×reps)'),
  lombardi('Lombardi', 'Peso × reps^0.10');

  const OneRepMaxFormula(this.name, this.description);

  final String name;
  final String description;
}

/// Classe helper per validazione input
class OneRepMaxInput {
  final double? weight;
  final int? reps;

  const OneRepMaxInput({this.weight, this.reps});

  /// Validazione peso
  String? validateWeight() {
    if (weight == null) return 'Inserisci il peso';
    if (weight! <= 0) return 'Il peso deve essere maggiore di 0';
    if (weight! > 1000) return 'Peso troppo elevato (max 1000 kg)';
    return null;
  }

  /// Validazione ripetizioni
  String? validateReps() {
    if (reps == null) return 'Inserisci le ripetizioni';
    if (reps! < 1) return 'Le ripetizioni devono essere almeno 1';
    if (reps! > 50) return 'Troppi reps (max 50)';
    return null;
  }

  /// Validazione completa
  bool get isValid => validateWeight() == null && validateReps() == null;

  /// Errori di validazione
  List<String> get validationErrors {
    final errors = <String>[];
    final weightError = validateWeight();
    final repsError = validateReps();

    if (weightError != null) errors.add(weightError);
    if (repsError != null) errors.add(repsError);

    return errors;
  }
}

/// Service statico per calcoli 1RM
class OneRepMaxCalculator {

  /// Formula Epley: peso × (1 + reps/30)
  /// La più comune e accurata per 1-10 reps
  static double epley(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + (reps / 30));
  }

  /// Formula Brzycki: peso × (36 / (37 - reps))
  /// Buona per 2-10 reps, tende a sovrastimare per reps alti
  static double brzycki(double weight, int reps) {
    if (reps == 1) return weight;
    if (reps >= 37) return weight * 2; // Evita divisione per zero
    return weight * (36 / (37 - reps));
  }

  /// Formula Lander: peso × (100 / (101.3 - 2.67123 × reps))
  /// Conservativa, buona per principianti
  static double lander(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (100 / (101.3 - 2.67123 * reps));
  }

  /// Formula Lombardi: peso × reps^0.10
  /// Meno accurata, per riferimento
  static double lombardi(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (reps * 0.10 + 1);
  }

  /// Calcola percentuali di allenamento comuni
  static Map<String, double> getPercentages(double oneRM) {
    return {
      '95%': oneRM * 0.95, // 1-2 reps
      '90%': oneRM * 0.90, // 2-4 reps
      '85%': oneRM * 0.85, // 4-6 reps
      '80%': oneRM * 0.80, // 6-8 reps
      '75%': oneRM * 0.75, // 8-10 reps
      '70%': oneRM * 0.70, // 10-12 reps
      '65%': oneRM * 0.65, // 12-15 reps
      '60%': oneRM * 0.60, // 15+ reps
    };
  }

  /// Calcola 1RM con formula specificata
  static double calculate(double weight, int reps, OneRepMaxFormula formula) {
    switch (formula) {
      case OneRepMaxFormula.epley:
        return epley(weight, reps);
      case OneRepMaxFormula.brzycki:
        return brzycki(weight, reps);
      case OneRepMaxFormula.lander:
        return lander(weight, reps);
      case OneRepMaxFormula.lombardi:
        return lombardi(weight, reps);
    }
  }

  /// Suggerisce la formula migliore in base alle ripetizioni
  static OneRepMaxFormula suggestFormula(int reps) {
    if (reps <= 5) return OneRepMaxFormula.epley;
    if (reps <= 10) return OneRepMaxFormula.brzycki;
    return OneRepMaxFormula.lander;
  }

  /// Calcola range di confidenza (min-max tra formule diverse)
  static Map<String, double> calculateRange(double weight, int reps) {
    final epleyResult = epley(weight, reps);
    final brzyckiResult = brzycki(weight, reps);
    final landerResult = lander(weight, reps);

    final results = [epleyResult, brzyckiResult, landerResult];

    return {
      'min': results.reduce((a, b) => a < b ? a : b),
      'max': results.reduce((a, b) => a > b ? a : b),
      'average': results.reduce((a, b) => a + b) / results.length,
    };
  }
}