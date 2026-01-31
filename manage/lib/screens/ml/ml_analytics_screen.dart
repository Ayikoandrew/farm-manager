import 'package:flutter/material.dart';

import 'tabs/analytics_dashboard_tab.dart';
import 'tabs/health_analytics_tab.dart';
import 'tabs/weight_predictions_tab.dart';

class MLAnalyticsScreen extends StatefulWidget {
  const MLAnalyticsScreen({super.key});

  @override
  State<MLAnalyticsScreen> createState() => _MLAnalyticsScreenState();
}

class _MLAnalyticsScreenState extends State<MLAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = ['Overview', 'Weight', 'Health'];
    final List<Widget> widgets = [
      const AnalyticsDashboardTab(),
      const WeightPredictionsTab(),
      const HealthAnalyticsTab(),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: TabBar(
            tabs: tabs.map((String name) => Tab(text: name)).toList(),
          ),
        ),
        body: TabBarView(children: widgets),
      ),
    );
  }
}


// Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Analytics'),
//         elevation: 0,
//         centerTitle: true,
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: AppTheme.farmGreen,
//           unselectedLabelColor: Colors.grey,
//           indicatorColor: AppTheme.farmGreen,
//           indicatorWeight: 3,
//           labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//           tabs: const [
//             Tab(text: 'Overview'),
//             Tab(text: 'Weight'),
//             Tab(text: 'Health'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
        // children: const [
        //   AnalyticsDashboardTab(),
        //   WeightPredictionsTab(),
        //   HealthAnalyticsTab(),
        // ],
//       ),
//     );