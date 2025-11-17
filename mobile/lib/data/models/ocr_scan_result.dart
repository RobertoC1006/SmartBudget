class OcrScanResult {
  OcrScanResult({
    this.description,
    this.amount,
    this.category,
    this.expenseDate,
    this.rawText,
    this.provider = 'n8n-webhook',
    this.payload,
    this.ocrConfidence,
  });

  final String? description;
  final double? amount;
  final String? category;
  final DateTime? expenseDate;
  final String? rawText;
  final String provider;
  final dynamic payload;
  final double? ocrConfidence;

  OcrScanResult copyWith({
    String? description,
    double? amount,
    String? category,
    DateTime? expenseDate,
    String? rawText,
    String? provider,
    dynamic payload,
    double? ocrConfidence,
  }) {
    return OcrScanResult(
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      rawText: rawText ?? this.rawText,
      provider: provider ?? this.provider,
      payload: payload ?? this.payload,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
    );
  }
}
