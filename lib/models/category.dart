class Category {
  final String id;
  final String title;
  final String icon;
  final String image;
  final int order;
  
  Category({
    required this.id,
    required this.title,
    required this.icon,
    required this.image,
    required this.order,
  });
  
  factory Category.fromMap(Map<String, dynamic> map, String documentId) {
    return Category(
      id: documentId,
      title: map['title'] ?? '',
      icon: map['icon'] ?? '',
      image: map['image'] ?? '',
      order: map['order'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'icon': icon,
      'image': image,
      'order': order,
    };
  }
}