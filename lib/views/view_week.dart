import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helpers.dart';

class ViewWeeklyAcademicSummary extends StatefulWidget {
  const ViewWeeklyAcademicSummary({super.key});

  @override
  State<ViewWeeklyAcademicSummary> createState() => _ViewWeeklyAcademicSummaryState();
}

class _ViewWeeklyAcademicSummaryState extends State<ViewWeeklyAcademicSummary> {
  bool isLoading = true;
  Map<String, dynamic>? summaryData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeeklyAcademicData();
  }

  Future<void> fetchWeeklyAcademicData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch weekly academic summary data from the new endpoint
      final summaryUrl = Uri.parse('$apiBaseUrl/weekly-academic-summary');
      final summaryResponse = await http.get(
        summaryUrl,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (summaryResponse.statusCode == 200) {
        final summaryData = jsonDecode(summaryResponse.body);
        
        setState(() {
          this.summaryData = summaryData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch weekly academic summary from server';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildAggregateStats() {
    if (summaryData == null) {
      return Container();
    }
    
    final aggregateStats = summaryData!['aggregateStats'];
    final int totalStudents = aggregateStats['totalStudents'];
    
    if (totalStudents == 0) {
      return Container(
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
        child: Text(
          'No academic data available',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    final double avgStudyHours = aggregateStats['avgStudyHours'].toDouble();
    final double avgFocusLevel = aggregateStats['avgFocusLevel'].toDouble();
    final double highFocusPercentage = aggregateStats['highFocusPercentage'].toDouble();
    final double highStudyPercentage = aggregateStats['highStudyPercentage'].toDouble();
    
    return Container(
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
            'Weekly Academic Averages',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatisticCard(
                'Avg. Study Hours/Day',
                avgStudyHours.toStringAsFixed(1),
                Icons.access_time,
              ),
              _buildStatisticCard(
                'Avg. Focus Level (10)',
                avgFocusLevel.toStringAsFixed(1),
                Icons.center_focus_strong,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Performance Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPercentageCard(
                '% with Focus > 7',
                highFocusPercentage.toStringAsFixed(1),
                AppTheme.accentTeal,
              ),
              _buildPercentageCard(
                '% Studying > 3 hrs/day',
                highStudyPercentage.toStringAsFixed(1),
                AppTheme.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildTopInsights() {
    if (summaryData == null) {
      return Container();
    }
    
    final aggregateStats = summaryData!['aggregateStats'];
    final double avgStudyHours = aggregateStats['avgStudyHours'].toDouble();
    final double avgFocusLevel = aggregateStats['avgFocusLevel'].toDouble();
    final double highFocusPercentage = aggregateStats['highFocusPercentage'].toDouble();
    final double highStudyPercentage = aggregateStats['highStudyPercentage'].toDouble();
    
    // Generate insights based on real data
    List<String> insights = [];
    
    if (avgFocusLevel > 7.0) {
      insights.add('Focus levels are generally high (${avgFocusLevel.toStringAsFixed(1)}/10) across students');
    } else if (avgFocusLevel < 5.0) {
      insights.add('Focus levels are generally low (${avgFocusLevel.toStringAsFixed(1)}/10) across students');
    } else {
      insights.add('Focus levels are moderate (${avgFocusLevel.toStringAsFixed(1)}/10) across students');
    }
    
    if (highFocusPercentage > 70) {
      insights.add('${highFocusPercentage.toStringAsFixed(1)}% of students have high focus levels (>7)');
    }
    
    if (avgStudyHours > 4.0) {
      insights.add('Average study hours are high (${avgStudyHours.toStringAsFixed(1)} hrs/day)');
    } else if (avgStudyHours < 2.0) {
      insights.add('Average study hours are low (${avgStudyHours.toStringAsFixed(1)} hrs/day)');
    } else {
      insights.add('Average study hours are moderate (${avgStudyHours.toStringAsFixed(1)} hrs/day)');
    }
    
    if (highStudyPercentage > 60) {
      insights.add('${highStudyPercentage.toStringAsFixed(1)}% of students study more than 3 hours daily');
    }

    return Container(
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
            'Top Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          ...insights.asMap().entries.map((entry) {
            int idx = entry.key;
            String insight = entry.value;
            IconData icon = idx == 0 ? Icons.trending_up : 
                           idx == 1 ? Icons.trending_down : 
                           Icons.bar_chart;
            Color color = idx == 0 ? AppTheme.accentTeal : 
                         idx == 1 ? AppTheme.accentOrange : 
                         AppTheme.primaryColor;
            
            return Column(
              children: [
                _buildInsightCard(insight, icon, color),
                if (idx < insights.length - 1) const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ThemeHelpers.themedAvatar(
              size: 40,
              icon: Icons.school_outlined,
            ),
            const SizedBox(width: 12),
            Text(
              'Weekly Summary',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchWeeklyAcademicData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: ThemeHelpers.gradientBackground(
        child: isLoading
            ? Center(
                child: ThemedWidgets.loadingIndicator(
                  message: 'Loading academic summary...',
                ),
              )
            : errorMessage != null
                ? ThemedWidgets.emptyState(
                    title: 'Unable to Load Data',
                    subtitle: errorMessage!,
                    icon: Icons.error_outline,
                    action: ThemeHelpers.themedButton(
                      text: 'Retry',
                      onPressed: fetchWeeklyAcademicData,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aggregate statistics
                        _buildAggregateStats(),
                        
                        // Top insights
                        _buildTopInsights(),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatisticCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageCard(String title, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}