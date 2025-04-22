class Subcategory {
  final String id;
  final String title;
  final String categoryId;
  final String? description;
  final String? letOp;
  final String? ctaText;
  final String? ctaUrl;
  
  Subcategory({
    required this.id,
    required this.title,
    required this.categoryId,
    this.description,
    this.letOp,
    this.ctaText,
    this.ctaUrl,
  });
  
  factory Subcategory.fromMap(Map<String, dynamic> map, String documentId) {
    return Subcategory(
      id: documentId,
      title: map['title'] ?? '',
      categoryId: map['categoryId'] ?? '',
      description: map['description'],
      letOp: map['letOp'],
      ctaText: map['ctaText'],
      ctaUrl: map['ctaUrl'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'categoryId': categoryId,
      'description': description,
      'letOp': letOp,
      'ctaText': ctaText,
      'ctaUrl': ctaUrl,
    };
  }
}