import 'package:flutter/material.dart';

const _kTitle = Color(0xFF1D2129);
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);

/// HRM 子菜单占位页（接口与业务页待接入）。
class HrmPlaceholderPage extends StatelessWidget {
  const HrmPlaceholderPage({super.key, required this.menuId});

  final String menuId;

  static const titles = <String, String>{
    'hrm_post': '岗位管理',
    'hrm_post_seq': '岗位序列',
    'hrm_seat': '席位',
    'hrm_archive': '人事档案',
    'hrm_directory': '企业通讯录',
    'hrm_workplace': '工作地点',
  };

  static String titleOf(String menuId) => titles[menuId] ?? 'HRM';

  @override
  Widget build(BuildContext context) {
    final title = titleOf(menuId);
    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kTitle,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction_outlined,
                    size: 40,
                    color: _kMuted.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '功能开发中，敬请期待',
                    style: TextStyle(fontSize: 13, color: _kMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
