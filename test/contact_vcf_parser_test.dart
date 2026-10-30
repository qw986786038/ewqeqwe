import 'package:flutter_test/flutter_test.dart';
import 'package:yidivination/pages/customer_archive/dialogs/contact_vcf_parser.dart';

void main() {
  test('解析常见中文 vCard 字段', () {
    const raw = '''
BEGIN:VCARD
VERSION:3.0
N:王;毅力;;;
FN:王毅力
TEL;TYPE=CELL:15422223333
TEL;TYPE=WORK:021-66665555
EMAIL:111@qq.com
ADR;TYPE=HOME:;;市中区济南路1号;呼和浩特市;内蒙古自治区;;中国
TITLE:销售部/销售总监
ORG:内蒙古伊利实业集团股份有限公司
NOTE:王毅力之备注一
GENDER:M
END:VCARD
''';
    final data = parseContactVcf(raw);
    expect(data.nameZh, '王毅力');
    expect(data.gender, '1');
    expect(data.mobile, '15422223333');
    expect(data.phone, '021-66665555');
    expect(data.email, '111@qq.com');
    expect(data.address, '市中区济南路1号');
    expect(data.city, '呼和浩特市');
    expect(data.province, '内蒙古自治区');
    expect(data.title, '销售部/销售总监');
    expect(data.org, '内蒙古伊利实业集团股份有限公司');
    expect(data.remark, '王毅力之备注一');
    expect(data.combinedCity, '内蒙古自治区呼和浩特市');
  });

  test('折叠行与多手机号', () {
    const raw = '''
BEGIN:VCARD
VERSION:3.0
FN:Test User
TEL;TYPE=CELL:13800001111
TEL;TYPE=CELL:13900002222
EMAIL:a@test.com
EMAIL:b@test.com
END:VCARD
''';
    final data = parseContactVcf(raw);
    expect(data.nameEn, 'Test User');
    expect(data.mobile, '13800001111;13900002222');
    expect(data.email, 'a@test.com;b@test.com');
  });

  test('多联系人拆分为多条', () {
    const raw = '''
BEGIN:VCARD
VERSION:3.0
FN:张三
TEL;TYPE=CELL:13800000001
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:李四
TEL;TYPE=CELL:13800000002
EMAIL:lisi@test.com
END:VCARD
''';
    final list = parseContactVcfAll(raw);
    expect(list.length, 2);
    expect(list[0].nameZh, '张三');
    expect(list[0].mobile, '13800000001');
    expect(list[1].nameZh, '李四');
    expect(list[1].mobile, '13800000002');
    expect(list[1].email, 'lisi@test.com');
  });

  test('Quoted-Printable UTF-8 中文姓名', () {
    // 王小明 = E7 8E 8B E5 B0 8F E6 98 8E
    const raw = '''
BEGIN:VCARD
VERSION:2.1
N;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E7=8E=8B;=E5=B0=8F=E6=98=8E;;;
FN;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E7=8E=8B=E5=B0=8F=E6=98=8E
TEL;CELL:13912345678
END:VCARD
''';
    final data = parseContactVcf(raw);
    expect(data.nameZh, '王小明');
    expect(data.mobile, '13912345678');
  });

  test('中文 FN + 英文 N 同时解析 Name', () {
    const raw = '''
BEGIN:VCARD
VERSION:3.0
N:Wang;Xiaoming;;;
FN:王小明
TEL;TYPE=CELL:13900001111
END:VCARD
''';
    final data = parseContactVcf(raw);
    expect(data.nameZh, '王小明');
    expect(data.nameEn, 'Xiaoming Wang');
  });
}
