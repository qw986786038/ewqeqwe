import 'package:flutter/material.dart';
import 'package:yidivination/bokong/widget/app_empty_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: AppEmptyState(title: Text('首页建设中')));
  }
}
