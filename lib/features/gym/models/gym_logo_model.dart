// lib/features/gym/models/gym_logo_model.dart

class GymLogoModel {
  final String? logoFilename;
  final String logoUrl;
  final bool hasCustomLogo;
  final int? gymId;
  final String? gymName;
  
  const GymLogoModel({
    this.logoFilename,
    required this.logoUrl,
    required this.hasCustomLogo,
    this.gymId,
    this.gymName,
  });
  
  /// Factory per creare il modello dalla risposta API di gyms.php
  factory GymLogoModel.fromJson(Map<String, dynamic> json) {
    final logoFilename = json['logo_filename'] as String?;
    
    return GymLogoModel(
      logoFilename: logoFilename,
      logoUrl: logoFilename != null 
        ? '/api/serve_image.php?filename=$logoFilename&type=logo'
        : '',
      hasCustomLogo: logoFilename != null && logoFilename.isNotEmpty,
      gymId: json['id'] as int?,
      gymName: json['name'] as String?,
    );
  }
  
  /// Factory per creare un modello vuoto (fallback)
  factory GymLogoModel.empty() {
    return const GymLogoModel(
      logoFilename: null,
      logoUrl: '',
      hasCustomLogo: false,
      gymId: null,
      gymName: null,
    );
  }
  
  /// Converte il modello in JSON (per debug)
  Map<String, dynamic> toJson() {
    return {
      'logo_filename': logoFilename,
      'logo_url': logoUrl,
      'has_custom_logo': hasCustomLogo,
      'gym_id': gymId,
      'gym_name': gymName,
    };
  }
  
  @override
  String toString() {
    return 'GymLogoModel(logoFilename: $logoFilename, hasCustomLogo: $hasCustomLogo, gymId: $gymId, gymName: $gymName)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GymLogoModel &&
      other.logoFilename == logoFilename &&
      other.logoUrl == logoUrl &&
      other.hasCustomLogo == hasCustomLogo &&
      other.gymId == gymId &&
      other.gymName == gymName;
  }
  
  @override
  int get hashCode {
    return logoFilename.hashCode ^
      logoUrl.hashCode ^
      hasCustomLogo.hashCode ^
      gymId.hashCode ^
      gymName.hashCode;
  }
}
