import 'dart:convert';

/// 从 vCard（.vcf）文本解析出可回填联系人表单的字段。
class ContactVcfData {
  const ContactVcfData({
    this.nameZh,
    this.nameEn,
    this.gender,
    this.mobile,
    this.phone,
    this.email,
    this.address,
    this.province,
    this.city,
    this.title,
    this.org,
    this.role,
    this.remark,
  });

  final String? nameZh;
  final String? nameEn;
  /// 表单性别值：`1` 男 / `2` 女。
  final String? gender;
  final String? mobile;
  final String? phone;
  final String? email;
  final String? address;
  final String? province;
  final String? city;
  final String? title;
  final String? org;
  final String? role;
  final String? remark;

  bool get hasAny =>
      nameZh != null ||
      nameEn != null ||
      gender != null ||
      mobile != null ||
      phone != null ||
      email != null ||
      address != null ||
      province != null ||
      city != null ||
      title != null ||
      org != null ||
      role != null ||
      remark != null;

  /// 省 + 市拼接，供现有城市拆分逻辑使用。
  String? get combinedCity {
    final p = province?.trim() ?? '';
    final c = city?.trim() ?? '';
    if (p.isEmpty && c.isEmpty) return null;
    if (p.isEmpty) return c;
    if (c.isEmpty) return p;
    if (c.startsWith(p)) return c;
    return '$p$c';
  }
}

class ContactVcfParseException implements Exception {
  ContactVcfParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 解析文件中全部 vCard（多联系人）；无效块跳过。
List<ContactVcfData> parseContactVcfAll(String source) {
  final text = source.trim();
  if (text.isEmpty) {
    throw ContactVcfParseException('VCF 文件为空');
  }
  final lines = _unfoldLines(text);
  final hasBegin = lines.any(
    (l) => l.toUpperCase().startsWith('BEGIN:VCARD'),
  );
  if (!hasBegin) {
    throw ContactVcfParseException('不是有效的 vCard 文件');
  }

  final cards = <ContactVcfData>[];
  List<String>? current;
  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    final upper = line.toUpperCase();
    if (upper.startsWith('BEGIN:VCARD')) {
      current = <String>[];
      continue;
    }
    if (upper.startsWith('END:VCARD')) {
      if (current != null) {
        final card = _parseVcardLines(current);
        if (card != null && card.hasAny) cards.add(card);
      }
      current = null;
      continue;
    }
    current?.add(line);
  }
  // 无 END:VCARD 的残缺块仍尝试解析。
  if (current != null && current.isNotEmpty) {
    final card = _parseVcardLines(current);
    if (card != null && card.hasAny) cards.add(card);
  }

  if (cards.isEmpty) {
    throw ContactVcfParseException('未从 VCF 中解析到可用的联系人字段');
  }
  return cards;
}

/// 解析首个有效 vCard（兼容旧调用）。
ContactVcfData parseContactVcf(String source) => parseContactVcfAll(source).first;

ContactVcfData? _parseVcardLines(List<String> lines) {
  String? fn;
  String? family;
  String? given;
  String? gender;
  String? title;
  String? org;
  String? role;
  String? note;
  String? street;
  String? locality;
  String? region;
  final mobiles = <String>[];
  final phones = <String>[];
  final emails = <String>[];

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    if (line.isEmpty) continue;
    final upper = line.toUpperCase();
    if (upper.startsWith('BEGIN:') ||
        upper.startsWith('END:') ||
        upper.startsWith('VERSION:') ||
        upper.startsWith('PRODID:') ||
        upper.startsWith('REV:')) {
      continue;
    }

    final parsed = _parseLine(line);
    if (parsed == null) continue;
    final name = parsed.name.toUpperCase();
    final params = parsed.params;
    final value = parsed.value;
    if (value.isEmpty) continue;

    switch (name) {
      case 'FN':
        fn = value;
      case 'N':
        final parts = value.split(';');
        family = parts.isNotEmpty ? parts[0].trim() : null;
        given = parts.length > 1 ? parts[1].trim() : null;
      case 'NICKNAME':
        // 仅当尚无 FN 时作姓名兜底。
        fn ??= value.split(',').first.trim();
      case 'GENDER':
      case 'X-GENDER':
      case 'SEX':
        gender = _mapGender(value);
      case 'TITLE':
        title = value;
      case 'ORG':
        org = value.split(';').first.trim();
      case 'ROLE':
        role = value;
      case 'NOTE':
        note = value;
      case 'EMAIL':
        emails.add(value);
      case 'TEL':
        final digits = value.trim();
        if (digits.isEmpty) break;
        if (_isMobileTel(params, digits)) {
          mobiles.add(digits);
        } else {
          phones.add(digits);
        }
      case 'ADR':
        final parts = value.split(';');
        // po;ext;street;locality;region;postal;country
        if (parts.length > 2 && parts[2].trim().isNotEmpty) {
          street = parts[2].trim();
        }
        if (parts.length > 3 && parts[3].trim().isNotEmpty) {
          locality = parts[3].trim();
        }
        if (parts.length > 4 && parts[4].trim().isNotEmpty) {
          region = parts[4].trim();
        }
      default:
        break;
    }
  }

  final nameZh = _preferChineseName(fn, family, given);
  final nameEn = _preferEnglishName(fn, family, given, nameZh);

  return ContactVcfData(
    nameZh: nameZh,
    nameEn: nameEn,
    gender: gender,
    mobile: mobiles.isEmpty ? null : mobiles.join(';'),
    phone: phones.isEmpty ? null : phones.join(';'),
    email: emails.isEmpty ? null : emails.join(';'),
    address: street,
    province: region,
    city: locality,
    title: title,
    org: org,
    role: role,
    remark: note,
  );
}

List<String> _unfoldLines(String text) {
  final raw = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final out = <String>[];
  for (final line in raw) {
    if (line.isEmpty) {
      out.add(line);
      continue;
    }
    // RFC：以空格/Tab 开头为折叠续行；QP 软换行 `=` 在行尾也并入。
    if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
      out[out.length - 1] = out.last + line.substring(1);
    } else if (out.isNotEmpty && out.last.endsWith('=')) {
      out[out.length - 1] =
          out.last.substring(0, out.last.length - 1) + line;
    } else {
      out.add(line);
    }
  }
  return out;
}

class _VcfLine {
  _VcfLine({required this.name, required this.params, required this.value});
  final String name;
  final Map<String, String> params;
  final String value;
}

_VcfLine? _parseLine(String line) {
  final colon = line.indexOf(':');
  if (colon <= 0) return null;
  final left = line.substring(0, colon);
  var value = line.substring(colon + 1);

  final segments = left.split(';');
  if (segments.isEmpty) return null;
  var name = segments.first.trim();
  // item1.TEL / item1.EMAIL
  final dot = name.lastIndexOf('.');
  if (dot >= 0 && dot < name.length - 1) {
    name = name.substring(dot + 1);
  }

  final params = <String, String>{};
  var quotedPrintable = false;
  var charset = 'UTF-8';
  for (var i = 1; i < segments.length; i++) {
    final part = segments[i].trim();
    if (part.isEmpty) continue;
    final eq = part.indexOf('=');
    if (eq < 0) {
      final key = part.toUpperCase();
      params[key] = '';
      // vCard 2.1：`TEL;CELL:` / `TEL;HOME:` 无 TYPE=
      continue;
    }
    final key = part.substring(0, eq).trim().toUpperCase();
    final val = part.substring(eq + 1).trim();
    params[key] = val;
    if (key == 'ENCODING' &&
        (val.toUpperCase() == 'QUOTED-PRINTABLE' ||
            val.toUpperCase() == 'QP')) {
      quotedPrintable = true;
    }
    if (key == 'CHARSET' && val.isNotEmpty) {
      charset = val.toUpperCase();
    }
  }

  if (quotedPrintable) {
    value = _decodeQuotedPrintable(value, charset: charset);
  }
  value = value.replaceAll(r'\,', ',').replaceAll(r'\;', ';').trim();
  return _VcfLine(name: name, params: params, value: value);
}

String _decodeQuotedPrintable(String input, {String charset = 'UTF-8'}) {
  final literal = StringBuffer();
  final bytes = <int>[];

  void flushBytes() {
    if (bytes.isEmpty) return;
    try {
      if (charset.contains('UTF') || charset == 'UTF8') {
        literal.write(utf8.decode(bytes, allowMalformed: true));
      } else {
        literal.write(latin1.decode(bytes, allowInvalid: true));
      }
    } catch (_) {
      literal.write(String.fromCharCodes(bytes));
    }
    bytes.clear();
  }

  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    // 软换行：行尾单独的 `=`
    if (ch == '=' && i + 1 < input.length &&
        (input[i + 1] == '\n' || input[i + 1] == '\r')) {
      i++;
      if (i < input.length && input[i] == '\r' &&
          i + 1 < input.length && input[i + 1] == '\n') {
        i++;
      }
      continue;
    }
    if (ch == '=' && i + 2 < input.length) {
      final hex = input.substring(i + 1, i + 3);
      final b = int.tryParse(hex, radix: 16);
      if (b != null) {
        bytes.add(b);
        i += 2;
        continue;
      }
    }
    flushBytes();
    if (ch != '\n' && ch != '\r') literal.write(ch);
  }
  flushBytes();
  return literal.toString();
}

bool _isMobileTel(Map<String, String> params, String value) {
  final joined = params.entries
      .map((e) => e.value.isEmpty ? e.key : '${e.key}=${e.value}')
      .join(';')
      .toUpperCase();
  if (joined.contains('CELL') ||
      joined.contains('MOBILE') ||
      joined.contains('IPHONE')) {
    return true;
  }
  if (joined.contains('FAX')) return false;
  if (joined.contains('WORK') || joined.contains('HOME')) {
    return _looksLikeMobile(value);
  }
  return _looksLikeMobile(value);
}

bool _looksLikeMobile(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('1')) return true;
  if (digits.length == 13 && digits.startsWith('86')) return true;
  return false;
}

String? _mapGender(String raw) {
  final s = raw.trim().toUpperCase();
  if (s.isEmpty) return null;
  if (s.startsWith('M') || s == '男' || s == '1' || s == 'MALE') return '1';
  if (s.startsWith('F') || s == '女' || s == '2' || s == 'FEMALE') return '2';
  // vCard 4.0: M;note / F;note
  final head = s.split(';').first.trim();
  if (head == 'M') return '1';
  if (head == 'F') return '2';
  return null;
}

String? _preferChineseName(String? fn, String? family, String? given) {
  final fromN = '${family ?? ''}${given ?? ''}'.trim();
  for (final c in [fn, fromN, family, given]) {
    final t = c?.trim();
    if (t == null || t.isEmpty) continue;
    if (_hasCjk(t)) return t;
  }
  return null;
}

String? _preferEnglishName(
  String? fn,
  String? family,
  String? given,
  String? nameZh,
) {
  final fromNParts = [
    if ((given ?? '').trim().isNotEmpty) given!.trim(),
    if ((family ?? '').trim().isNotEmpty) family!.trim(),
  ];
  final fromN = fromNParts.join(' ').trim();
  for (final c in [fn, fromN]) {
    final t = c?.trim();
    if (t == null || t.isEmpty) continue;
    if (!_hasCjk(t) && t != nameZh) return t;
  }
  // N 中文、FN 英文已在上面处理；若 N 为英文拼音分词也算 Name。
  if (fromN.isNotEmpty && !_hasCjk(fromN) && fromN != nameZh) return fromN;
  return null;
}

bool _hasCjk(String s) => RegExp(r'[\u4e00-\u9fff]').hasMatch(s);
