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
const _kGreen = Color(0xFF00B42A);
const _kGreenBg = Color(0xFFE8FFEA);
const _kPageShadow = Color(0x0A000000);

/// 附件：按设计稿排版；无接口写死演示。
class EmployeeAttachmentTab extends StatelessWidget {
  const EmployeeAttachmentTab({super.key});

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
                    '档案附件',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '共 6 个文件 · 34.6 MB',
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                  const Spacer(),
                  AppButton.primary(
                    onPressed: () {
                      AppToast.show(context: context, title: '上传附件待接入');
                    },
                    leading: const Icon(
                      Icons.upload_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    child: const Text('上传附件'),
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
                              _HCell('文件名称', 240),
                              _HCell('分类', 88),
                              _HCell('大小', 80),
                              _HCell('上传时间', 110),
                              _HCell('上传人', 80),
                              _HCell('可见范围', 130),
                              _HCell('操作', 64),
                            ],
                          ),
                        ),
                        for (var i = 0; i < _files.length; i++)
                          _FileRow(row: _files[i], zebra: i.isOdd),
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

enum _VisTone { hr, all, dept }

class _FileData {
  const _FileData({
    required this.name,
    required this.category,
    required this.size,
    required this.time,
    required this.uploader,
    required this.visibility,
    required this.tone,
  });

  final String name;
  final String category;
  final String size;
  final String time;
  final String uploader;
  final String visibility;
  final _VisTone tone;
}

const _files = <_FileData>[
  _FileData(
    name: '身份证正反面扫描件.pdf',
    category: '证件',
    size: '2.1 MB',
    time: '2019-03-11',
    uploader: '罗野',
    visibility: '仅 HR 与本人',
    tone: _VisTone.hr,
  ),
  _FileData(
    name: '学历学位证.pdf',
    category: '学历',
    size: '3.4 MB',
    time: '2019-03-11',
    uploader: '罗野',
    visibility: '全员可见',
    tone: _VisTone.all,
  ),
  _FileData(
    name: '竞业保密协议（2023 续签）.pdf',
    category: '合同',
    size: '5.8 MB',
    time: '2023-03-11',
    uploader: '罗野',
    visibility: '仅 HR 与本人',
    tone: _VisTone.hr,
  ),
  _FileData(
    name: '入职登记表.pdf',
    category: '入职材料',
    size: '0.9 MB',
    time: '2019-03-11',
    uploader: '罗野',
    visibility: '仅 HR 与本人',
    tone: _VisTone.hr,
  ),
  _FileData(
    name: '2025 作品集与案例.pdf',
    category: '作品',
    size: '11.2 MB',
    time: '2025-01-20',
    uploader: '陈思远',
    visibility: '部门负责人可见',
    tone: _VisTone.dept,
  ),
  _FileData(
    name: '2024 年度绩效报告.pdf',
    category: '绩效',
    size: '1.2 MB',
    time: '2024-12-08',
    uploader: '罗野',
    visibility: '仅 HR 与本人',
    tone: _VisTone.hr,
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

class _FileRow extends StatelessWidget {
  const _FileRow({required this.row, required this.zebra});

  final _FileData row;
  final bool zebra;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (row.tone) {
      _VisTone.hr => (_kOrange, _kOrangeBg),
      _VisTone.all => (_kGreen, _kGreenBg),
      _VisTone.dept => (_kPrimary, _kBlueBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: zebra ? const Color(0xFFFAFBFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            child: AppInkWell(
              onPressed: () {
                AppToast.show(context: context, title: '预览待接入');
              },
              child: Text(
                row.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),
          _DCell(row.category, 88),
          _DCell(row.size, 80, muted: true),
          _DCell(row.time, 110, muted: true),
          _DCell(row.uploader, 80),
          SizedBox(
            width: 130,
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
                  row.visibility,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: AppInkWell(
              onPressed: () {
                AppToast.show(context: context, title: '下载待接入');
              },
              child: const Text(
                '下载',
                style: TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
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
        maxLines: 1,
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
