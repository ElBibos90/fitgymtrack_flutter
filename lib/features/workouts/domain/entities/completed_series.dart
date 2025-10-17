/// 🏋️ Completed Series Entity
/// Rappresenta una serie completata di un esercizio
class CompletedSeries {
  final int id;
  final int allenamentoId;
  final int schedaEsercizioId;
  final double peso;
  final int ripetizioni;
  final bool completata;
  final int tempoRecupero;
  final DateTime timestamp;
  final String note;
  final int serieNumber;
  final bool isRestPause;
  final int? restPauseReps;
  final int? restPauseRestSeconds;
  final String esercizioNome;
  final String? gruppoMuscolare;
  final int? esercizioId;

  CompletedSeries({
    required this.id,
    required this.allenamentoId,
    required this.schedaEsercizioId,
    required this.peso,
    required this.ripetizioni,
    required this.completata,
    required this.tempoRecupero,
    required this.timestamp,
    required this.note,
    required this.serieNumber,
    required this.isRestPause,
    this.restPauseReps,
    this.restPauseRestSeconds,
    required this.esercizioNome,
    this.gruppoMuscolare,
    this.esercizioId,
  });

  /// 📊 Factory constructor da JSON
  factory CompletedSeries.fromJson(Map<String, dynamic> json) {
    return CompletedSeries(
      id: json['id'] ?? 0,
      allenamentoId: json['allenamento_id'] ?? 0,
      schedaEsercizioId: json['scheda_esercizio_id'] ?? 0,
      peso: (json['peso'] ?? 0.0).toDouble(),
      ripetizioni: json['ripetizioni'] ?? 0,
      completata: (json['completata'] ?? 0) == 1,
      tempoRecupero: json['tempo_recupero'] ?? 90,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      note: json['note'] ?? '',
      serieNumber: json['serie_number'] ?? 1,
      isRestPause: (json['is_rest_pause'] ?? 0) == 1,
      restPauseReps: json['rest_pause_reps'],
      restPauseRestSeconds: json['rest_pause_rest_seconds'],
      esercizioNome: json['esercizio_nome'] ?? '',
      gruppoMuscolare: json['gruppo_muscolare'],
      esercizioId: json['esercizio_id'],
    );
  }

  /// 📊 Converte in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allenamento_id': allenamentoId,
      'scheda_esercizio_id': schedaEsercizioId,
      'peso': peso,
      'ripetizioni': ripetizioni,
      'completata': completata ? 1 : 0,
      'tempo_recupero': tempoRecupero,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'serie_number': serieNumber,
      'is_rest_pause': isRestPause ? 1 : 0,
      'rest_pause_reps': restPauseReps,
      'rest_pause_rest_seconds': restPauseRestSeconds,
      'esercizio_nome': esercizioNome,
      'gruppo_muscolare': gruppoMuscolare,
      'esercizio_id': esercizioId,
    };
  }

  /// 🔄 Copia con modifiche
  CompletedSeries copyWith({
    int? id,
    int? allenamentoId,
    int? schedaEsercizioId,
    double? peso,
    int? ripetizioni,
    bool? completata,
    int? tempoRecupero,
    DateTime? timestamp,
    String? note,
    int? serieNumber,
    bool? isRestPause,
    int? restPauseReps,
    int? restPauseRestSeconds,
    String? esercizioNome,
    String? gruppoMuscolare,
    int? esercizioId,
  }) {
    return CompletedSeries(
      id: id ?? this.id,
      allenamentoId: allenamentoId ?? this.allenamentoId,
      schedaEsercizioId: schedaEsercizioId ?? this.schedaEsercizioId,
      peso: peso ?? this.peso,
      ripetizioni: ripetizioni ?? this.ripetizioni,
      completata: completata ?? this.completata,
      tempoRecupero: tempoRecupero ?? this.tempoRecupero,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      serieNumber: serieNumber ?? this.serieNumber,
      isRestPause: isRestPause ?? this.isRestPause,
      restPauseReps: restPauseReps ?? this.restPauseReps,
      restPauseRestSeconds: restPauseRestSeconds ?? this.restPauseRestSeconds,
      esercizioNome: esercizioNome ?? this.esercizioNome,
      gruppoMuscolare: gruppoMuscolare ?? this.gruppoMuscolare,
      esercizioId: esercizioId ?? this.esercizioId,
    );
  }

  /// 📊 Calcola la differenza con un'altra serie
  Map<String, double> calculateDifference(CompletedSeries other) {
    return {
      'peso_diff': peso - other.peso,
      'ripetizioni_diff': (ripetizioni - other.ripetizioni).toDouble(),
    };
  }

  /// 📈 Determina se questa serie è un miglioramento rispetto ad un'altra
  bool isImprovement(CompletedSeries other) {
    return peso > other.peso && ripetizioni > other.ripetizioni;
  }

  /// 📉 Determina se questa serie è un peggioramento rispetto ad un'altra
  bool isDecline(CompletedSeries other) {
    return peso < other.peso && ripetizioni < other.ripetizioni;
  }

  /// ⚖️ Determina se questa serie è uguale ad un'altra
  bool isEqual(CompletedSeries other) {
    return peso == other.peso && ripetizioni == other.ripetizioni;
  }

  /// 🎯 Ottiene il trend rispetto ad un'altra serie
  String getTrend(CompletedSeries other) {
    if (isImprovement(other)) return 'improving';
    if (isDecline(other)) return 'declining';
    if (isEqual(other)) return 'stable';
    
    // Trend misto
    if (peso > other.peso && ripetizioni < other.ripetizioni) return 'weight_up_reps_down';
    if (peso < other.peso && ripetizioni > other.ripetizioni) return 'weight_down_reps_up';
    
    return 'mixed';
  }

  /// 📊 Formatta il peso per la visualizzazione
  String get formattedPeso {
    return peso % 1 == 0 ? peso.toInt().toString() : peso.toStringAsFixed(1);
  }

  /// 📊 Formatta le ripetizioni per la visualizzazione
  String get formattedRipetizioni {
    return ripetizioni.toString();
  }

  /// 📊 Formatta il timestamp per la visualizzazione
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} giorni fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ore fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min fa';
    } else {
      return 'Ora';
    }
  }

  /// 📊 Formatta la data per la visualizzazione
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// 📊 Formatta l'ora per la visualizzazione
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'CompletedSeries(id: $id, esercizio: $esercizioNome, serie: $serieNumber, peso: $peso, reps: $ripetizioni)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletedSeries && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
