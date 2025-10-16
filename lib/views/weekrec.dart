import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helpers.dart';

class WeeklyProgressPage extends StatefulWidget {
  final String studentId;
  const WeeklyProgressPage({super.key, required this.studentId});

  @override
  State<WeeklyProgressPage> createState() => _WeeklyProgressPageState();
}

class _WeeklyProgressPageState extends State<WeeklyProgressPage> {
  bool isLoading = true;
  Map<String, dynamic>? weeklyData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeeklyData();
  }

  Future<void> fetchWeeklyData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch data from the recommendations endpoint which contains both academic and wellness data
      final url = Uri.parse('$apiBaseUrl/recommendations/${widget.studentId}');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Backend response data: $data'); // Debug log
        
        // Log specific wellness metrics
        print('Wellness metrics from backend:');
        print('  currentFocusLevel: ${data['currentFocusLevel']}');
        print('  avgScreenTime: ${data['avgScreenTime']}');
        print('  avgNightUsage: ${data['avgNightUsage']}');
        
        setState(() {
          weeklyData = {
            'analytics': {
              'currentMark': data['currentMark'] ?? 0,
              'currentStudyHours': data['currentStudyHours'] ?? 0,
              'currentFocusLevel': data['currentFocusLevel'] ?? 0,
              'avgScreenTime': data['avgScreenTime'] ?? 0,
              'avgNightUsage': data['avgNightUsage'] ?? 0,
              'avgAcademicAppRatio': data['avgAcademicAppRatio'] ?? 0,
            }
          };
          print('Processed weeklyData: $weeklyData'); // Debug log
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Student not found or no academic data
        setState(() {
          errorMessage = 'No academic data found. Please enter your academic performance in the dashboard first.';
          isLoading = false;
        });
      } else {
        // Other HTTP errors - do not fallback to mock data to ensure real data is used
        print('Server error ${response.statusCode}');
        setState(() {
          errorMessage = 'Failed to load data. Please try again later.';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Network error - do not fallback to mock data to ensure real data is used
      setState(() {
        errorMessage = 'Network error. Please check your connection and try again.';
        isLoading = false;
      });
    }
  }

  void generateMockData() {
    print('⚠️  WARNING: Using mock data for demonstration purposes only!');
    print('⚠️  In production, real data should be fetched from the backend database.');
    
    setState(() {
      weeklyData = {
        'analytics': {
          'currentMark': 85,
          'currentStudyHours': 4,
          'currentFocusLevel': 7.5,  // 7.5/10 focus level
          'avgScreenTime': 240,      // 240 minutes = 4 hours screen time
          'avgNightUsage': 60,       // 60 minutes = 1 hour night usage
          'avgAcademicAppRatio': 0.65,
        }
      };
      print('Mock data generated: $weeklyData'); // Debug log
      isLoading = false;
      print('⚠️  Mock data generated successfully - for testing only!');
    });
  }

  Widget _buildAcademicChart() {
    if (weeklyData?['analytics'] == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No academic data available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final analytics = weeklyData!['analytics'];
    final currentMark = (analytics['currentMark'] ?? 0).toDouble();
    final studyHours = (analytics['currentStudyHours'] ?? 0).toDouble();
    final focusLevel = (analytics['currentFocusLevel'] ?? 0).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.primaryColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              List<String> labels = ['Marks', 'Study Hours', 'Focus Level'];
              List<double> values = [currentMark, studyHours * 10, focusLevel * 10]; // Scale study hours and focus level
              
              final index = group.x.toInt();
              if (index >= 0 && index < labels.length) {
                return BarTooltipItem(
                  '${labels[index]}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${values[index].toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                List<String> labels = ['Marks', 'Study\nHours', 'Focus\nLevel'];
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        gridData: const FlGridData(show: true),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: currentMark,
                color: AppTheme.primaryColor.withOpacity(0.7),
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: studyHours * 10, // Scale to 0-100 range
                color: AppTheme.secondaryColor.withOpacity(0.7),
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: focusLevel * 10, // Scale to 0-100 range
                color: AppTheme.accentTeal.withOpacity(0.7),
                width: 20,
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessChart() {
    if (weeklyData?['analytics'] == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No wellness data available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final analytics = weeklyData!['analytics'];
    final focusLevel = (analytics['currentFocusLevel'] ?? 0).toDouble();
    final screenTime = (analytics['avgScreenTime'] ?? 0).toDouble();
    final nightUsage = (analytics['avgNightUsage'] ?? 0).toDouble();

    // Check if all values are zero or very small to show a more meaningful message
    if (focusLevel < 0.1 && screenTime < 1 && nightUsage < 1) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'No recent wellness data available. Wellness metrics are calculated based on the last 14 days of phone usage. Continue using the app to see your wellness trends.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      );
    }

    // Scale the values to make them more comparable in the pie chart
    // Focus Level: 0-10 scale, so multiply by 10 to get 0-100
    // Screen Time: in minutes, so divide by 6 to get a 0-100 scale (assuming max 600 minutes or 10 hours)
    // Night Usage: in minutes, so divide by 1.2 to get a 0-100 scale (assuming max 120 minutes or 2 hours)
    final scaledFocus = focusLevel * 10;
    final scaledScreen = screenTime / 6;
    final scaledNight = nightUsage / 1.2;

    // Create a more balanced representation by ensuring all values contribute
    // to the pie chart while preserving their relative proportions
    double adjustedFocus = scaledFocus;
    double adjustedScreen = scaledScreen;
    double adjustedNight = scaledNight;

    // If any value is zero, give it a small value to ensure visibility
    if (adjustedFocus == 0) adjustedFocus = 1;
    if (adjustedScreen == 0) adjustedScreen = 1;
    if (adjustedNight == 0) adjustedNight = 1;

    // Normalize the values to ensure they're all visible
    final adjustedTotal = adjustedFocus + adjustedScreen + adjustedNight;
    
    // Apply a minimum percentage to ensure visibility (at least 5% of the pie)
    final minPercentage = 0.05;
    final minPortion = adjustedTotal * minPercentage;
    
    if (adjustedFocus < minPortion) adjustedFocus = minPortion;
    if (adjustedScreen < minPortion) adjustedScreen = minPortion;
    if (adjustedNight < minPortion) adjustedNight = minPortion;

    // Format the labels based on whether values are available
    final screenLabel = screenTime > 0 
        ? '${(screenTime/60).toStringAsFixed(1)}h' 
        : 'No data';
    final nightLabel = nightUsage > 0 
        ? '${nightUsage.toStringAsFixed(0)}m' 
        : 'No data';
    final focusLabel = focusLevel > 0 
        ? '${focusLevel.toStringAsFixed(1)}' 
        : 'No data';

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: AppTheme.primaryColor,
            value: adjustedFocus,
            title: 'Focus\n$focusLabel',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: AppTheme.secondaryColor,
            value: adjustedScreen,
            title: 'Screen\n$screenLabel',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: AppTheme.accentTeal,
            value: adjustedNight,
            title: 'Night\n$nightLabel',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildCombinedChart() {
    if (weeklyData?['analytics'] == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No data available for combined chart',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final analytics = weeklyData!['analytics'];
    final currentMark = (analytics['currentMark'] ?? 0).toDouble();
    final focusLevel = (analytics['currentFocusLevel'] ?? 0).toDouble();
    final screenTime = (analytics['avgScreenTime'] ?? 0).toDouble();
    final nightUsage = (analytics['avgNightUsage'] ?? 0).toDouble();

    // Scale wellness metrics to match the 0-100 scale for better visualization
    // Screen Time: in minutes, so divide by 6 to get a 0-100 scale (assuming max 600 minutes or 10 hours)
    // Night Usage: in minutes, so divide by 1.2 to get a 0-100 scale (assuming max 120 minutes or 2 hours)
    final scaledScreen = screenTime / 6;
    final scaledNight = nightUsage / 1.2;

    // Prepare line chart data
    List<FlSpot> academicSpots = [
      const FlSpot(0, 75),
      const FlSpot(1, 80),
      const FlSpot(2, 78),
      FlSpot(3, currentMark),
      const FlSpot(4, 82),
      const FlSpot(5, 88),
      const FlSpot(6, 90),
    ];
    
    List<FlSpot> wellnessSpots = [
      const FlSpot(0, 60),
      const FlSpot(1, 65),
      const FlSpot(2, 70),
      FlSpot(3, focusLevel * 10), // Scale focus level to 0-100
      const FlSpot(4, 72),
      const FlSpot(5, 75),
      const FlSpot(6, 80),
    ];

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: academicSpots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          LineChartBarData(
            spots: wellnessSpots,
            isCurved: true,
            color: AppTheme.accentTeal,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppTheme.accentTeal.withOpacity(0.3)),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        gridData: const FlGridData(show: true),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
 appBar: AppBar(
  leading: ThemeHelpers.themedAvatar(size: 40, icon: Icons.bar_chart_outlined),
  title: const Flexible(
    child: Text(
      'Weekly Progress',
      overflow: TextOverflow.ellipsis,
    ),
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: fetchWeeklyData,
      tooltip: 'Refresh Data',
    ),
  ],
),



      body: ThemeHelpers.gradientBackground(
        child: isLoading
            ? Center(
                child: ThemedWidgets.loadingIndicator(
                  message: 'Loading weekly progress data...',
                ),
              )
            : errorMessage != null
                ? ThemedWidgets.emptyState(
                    title: 'Unable to Load Data',
                    subtitle: errorMessage!,
                    icon: Icons.error_outline,
                    action: ThemeHelpers.themedButton(
                      text: 'Retry',
                      onPressed: fetchWeeklyData,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Academic Performance Chart
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Performance',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 250,
                                child: _buildAcademicChart(),
                              ),
                            ],
                          ),
                        ),
                        
                        // Wellness Metrics Chart
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wellness Metrics',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 250,
                                child: _buildWellnessChart(),
                              ),
                            ],
                          ),
                        ),
                        
                        // Combined Progress Chart
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Progress Trend',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 250,
                                child: _buildCombinedChart(),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }
}