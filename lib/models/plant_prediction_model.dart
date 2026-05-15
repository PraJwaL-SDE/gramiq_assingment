class PlantPrediction {
  final String diseaseName;
  final double confidence;
  final String severity;
  final List<String> symptoms;
  final List<String> treatment;
  final String imagePath;
  final DateTime dateTime;

  PlantPrediction({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.symptoms,
    required this.treatment,
    required this.imagePath,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'disease_name': diseaseName,
        'confidence': confidence,
        'severity': severity,
        'symptoms': symptoms,
        'treatment': treatment,
        'image_path': imagePath,
        'date_time': dateTime.toIso8601String(),
      };

  factory PlantPrediction.fromJson(Map<String, dynamic> json) => PlantPrediction(
        diseaseName: json['disease_name'],
        confidence: json['confidence'].toDouble(),
        severity: json['severity'],
        symptoms: List<String>.from(json['symptoms']),
        treatment: List<String>.from(json['treatment']),
        imagePath: json['image_path'],
        dateTime: DateTime.parse(json['date_time']),
      );
}
