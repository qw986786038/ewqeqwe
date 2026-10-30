import 'package:flutter/widgets.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

import 'package:yidivination/bokong/utils/widget_size.dart';

/// 添加设备 ·「维保巡检」Tab。
class LcdDevicesAddMaintenanceTab extends StatelessWidget {
  const LcdDevicesAddMaintenanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompanyBlock(
          companyLabel: '物业公司',
          companyName: 'property_name',
          personName: 'property_person',
          phoneName: 'property_phone',
        ),
        _CompanyBlock(
          companyLabel: '维保公司',
          companyName: 'maintenance_company',
          personName: 'maintenance_person',
          phoneName: 'maintenance_phone',
        ),
        _CompanyBlock(
          companyLabel: '巡检公司',
          companyName: 'inspection_department',
          personName: 'inspector',
          phoneName: 'inspection_phone',
        ),
      ],
    );
  }
}

class _CompanyBlock extends StatelessWidget {
  const _CompanyBlock({
    required this.companyLabel,
    required this.companyName,
    required this.personName,
    required this.phoneName,
  });

  final String companyLabel;
  final String companyName;
  final String personName;
  final String phoneName;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextFormField(
          name: companyName,
          label: companyLabel,
          required: true,
          hintText: '请输入内容',
          validator: AppValidators.required(message: '不能为空'),
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextFormField(
              name: personName,
              label: '负责人',
              required: true,
              hintText: '请输入内容',
              validator: AppValidators.required(message: '不能为空'),
            ).expanded(),
            AppTextFormField(
              name: phoneName,
              label: '负责人电话',
              required: true,
              hintText: '请输入内容',
              validator: AppValidators.required(message: '不能为空'),
            ).expanded(),
          ],
        ),
      ],
    );
  }
}
