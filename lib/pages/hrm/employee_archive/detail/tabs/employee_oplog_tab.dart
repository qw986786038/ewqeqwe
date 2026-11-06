import 'package:flutter/material.dart';
import 'package:lemon_shadcn/lemon_shadcn.dart';

const _kPrimary = Color(0xFF1677FF);
const _kMuted = Color(0xFF86909C);
const _kBorder = Color(0xFFE5E6EB);
const _kDivider = Color(0xFFF2F3F5);
const _kTitle = Color(0xFF1D2129);
const _kLabel = Color(0xFF86909C);
const _kHeaderBg = Color(0xFFFAFBFC);
const _kOrange = Color(0xFFD46B08);
const _kOrangeBg = Color(0xFFFFF7E6);
const _kBlueBg = Color(0xFFE8F3FF);
const _kPurple = Color(0xFF722ED1);
const _kPurpleBg = Color(0xFFF9F0FF);
const _kGreen = Color(0xFF00B42A);
const _kGreenBg = Color(0xFFE8FFEA);
const _kGrayBg = Color(0xFFF2F3F5);
const _kPageShadow = Color(0x0A000000);

/// 操作日志：按设计稿排版；无接口写死演示。
class EmployeeOplogTab extends StatelessWidget {
  const EmployeeOplogTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
            boxShadow: const [
              BoxShadow(
                color: _kPageShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    '操作日志',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '仅展示与档案相关的变更与操作行为，保留 3 年',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton.outline(
                    onPressed: () {
                      AppToast.show(context: context, title: '导出日志待接入');
                    },
                    leading: const Icon(
                      Icons.download_outlined,
                      size: 16,
                      color: _kLabel,
                    ),
                    child: const Text('导出日志'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 980),
                    child: Column(
                      children: [
                        Container(
                          color: _kHeaderBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: const Row(
                            children: [
                              _HCell('操作时间', 140),
                              _HCell('操作人', 72),
                              _HCell('角色', 100),
                              _HCell('操作类型', 80),
                              _HCell('变更内容', 320),
                              _HCell('IP 地址', 120),
                            ],
                          ),
                        ),
                        for (var i = 0; i < _logs.length; i++)
                          _LogRow(row: _logs[i], zebra: i.isOdd),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _OpType { edit, view, salary, promote, upload, transfer }

class _LogData {
  const _LogData({
    required this.time,
    required this.operator,
    required this.role,
    required this.type,
    required this.typeLabel,
    required this.content,
    required this.ip,
  });

  final String time;
  final String operator;
  final String role;
  final _OpType type;
  final String typeLabel;
  final String content;
  final String ip;
}

const _logs = <_LogData>[
  _LogData(
    time: '2025-09-28 14:32',
    operator: '罗野',
    role: 'HR 管理员',
    type: _OpType.edit,
    typeLabel: '修改',
    content: '更新办公地点：上海静安 → 上海静安',
    ip: '10.20.11.88',
  ),
  _LogData(
    time: '2025-08-12 09:05',
    operator: '林哲',
    role: '部门负责人',
    type: _OpType.view,
    typeLabel: '查看',
    content: '查看任职组织与项目目标',
    ip: '10.20.11.32',
  ),
  _LogData(
    time: '2025-04-01 10:12',
    operator: '罗野',
    role: 'HR 管理员',
    type: _OpType.salary,
    typeLabel: '调薪',
    content: '年度调薪：28,000 → 31,400（+12%）',
    ip: '10.20.11.88',
  ),
  _LogData(
    time: '2023-04-01 16:40',
    operator: '罗野',
    role: 'HR 管理员',
    type: _OpType.promote,
    typeLabel: '晋升',
    content: '职级 P6 → P7，职务调整为客户总监',
    ip: '10.20.11.88',
  ),
  _LogData(
    time: '2023-03-11 11:20',
    operator: '罗野',
    role: 'HR 管理员',
    type: _OpType.upload,
    typeLabel: '上传',
    content: '上传竞业保密协议（2023 续签）',
    ip: '10.20.11.18',
  ),
  _LogData(
    time: '2021-07-01 09:48',
    operator: '罗野',
    role: 'HR 管理员',
    type: _OpType.transfer,
    typeLabel: '调岗',
    content: '客户二部 → 大客户部',
    ip: '10.20.11.88',
  ),
];

class _HCell extends StatelessWidget {
  const _HCell(this.text, this.width);

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _kLabel,
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.row, required this.zebra});

  final _LogData row;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (row.type) {
      _OpType.edit => (_kPurple, _kPurpleBg),
      _OpType.view => (_kMuted, _kGrayBg),
      _OpType.salary => (_kOrange, _kOrangeBg),
      _OpType.promote => (_kPrimary, _kBlueBg),
      _OpType.upload => (_kGreen, _kGreenBg),
      _OpType.transfer => (_kOrange, _kOrangeBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: zebra ? const Color(0xFFFAFBFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          _DCell(row.time, 140),
          _DCell(row.operator, 72),
          _DCell(row.role, 100, muted: true),
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  row.typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
          _DCell(row.content, 320),
          _DCell(row.ip, 120, muted: true),
        ],
      ),
    );
  }
}

class _DCell extends StatelessWidget {
  const _DCell(this.text, this.width, {this.muted = false});

  final String text;
  final double width;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: muted ? _kMuted : _kTitle,
        ),
      ),
    );
  }
}
