class PageEntity {
  bool? first;
  bool? last;
  int? page;
  int? size;
  int? number;
  int? totalPages;
  int? totalSize;

  PageEntity(
    this.first,
    this.last,
    this.page,
    this.size,
    this.number,
    this.totalPages,
    this.totalSize,
  );

  PageEntity.fromJson(Map<String, dynamic> json) {
    if (json['page'] != null) {
      page = _toInt(json['page']);
      first = page == 1;
    }
    if (json['limit'] != null) {
      size = _toInt(json['limit']);
    }
    if (json['total'] != null) {
      totalSize = _toInt(json['total']);
      if (size != null && size! > 0) {
        totalPages = (totalSize! + size! - 1) ~/ size!;
      }
    }
    if (page != null && size != null && totalSize != null) {
      last = totalSize! <= page! * size!;
      number = totalSize! - (page! - 1) * size!;
    }
  }

  static PageEntity? tryFromResponse(Map<String, dynamic> json) {
    final bool hasPagination =
        json['page'] != null || json['limit'] != null || json['total'] != null;
    if (!hasPagination) return null;
    return PageEntity.fromJson(json);
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> resp = <String, dynamic>{};
    resp['first'] = first;
    resp['last'] = last;
    resp['page'] = page;
    resp['size'] = size;
    resp['number'] = number;
    resp['totalPages'] = totalPages;
    resp['totalSize'] = totalSize;
    return resp;
  }

  @override
  String toString() => toJson().toString();
}
