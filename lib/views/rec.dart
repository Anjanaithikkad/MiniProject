import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../theme/app_theme.dart';
import '../theme/theme_helpers.dart';

class RecommendationPage extends StatefulWidget {
  final String studentId;
  const RecommendationPage({super.key, required this.studentId});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  bool isLoading = true;
  Map<String, dynamic>? recommendationData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

 Future<void> fetchRecommendations() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final url = Uri.parse('$apiBaseUrl/recommendations/${widget.studentId}');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Backend response: $data'); // Debug log

      // Transform backend data to match our UI structure
      setState(() {
        recommendationData = {
          // Extract main recommendation from backend
          'main_recommendation': data['main_recommendation'] ?? {
            'title': 'No Recommendations Available',
            'description': 'Unable to generate recommendations at this time.',
            'reason': 'Insufficient data for analysis.',
            'actionable_steps': ['Please ensure academic data is entered.']
          },
          // Extract extra tips from backend
          'extra_tips': data['extra_tips'] ?? [],
          // Store analytics for future use
          'analytics': {
            'currentMark': data['currentMark'] ?? 0,
            'currentStudyHours': data['currentStudyHours'] ?? 0,
            'currentFocusLevel': data['currentFocusLevel'] ?? 0,
            'avgScreenTime': data['avgScreenTime'] ?? 0,
            'avgNightUsage': data['avgNightUsage'] ?? 0,
            'avgAcademicAppRatio': data['avgAcademicAppRatio'] ?? 0,
          }
        };
        isLoading = false;
      });
    } else if (response.statusCode == 404) {
      // Student not found or no academic data
      setState(() {
        errorMessage = 'No academic data found. Please enter your academic performance in the dashboard first.';
        isLoading = false;
      });
    } else {
      // Other HTTP errors - fallback to mock data
      print('Server error ${response.statusCode}, falling back to demo data');
      generateMockRecommendations(message: 'Server error - using demo recommendations');
    }
  } catch (e) {
    print('Error fetching recommendations: $e');
    // Network error - fallback to mock data for demonstration
    generateMockRecommendations(message: 'Network error - using demo recommendations');
  }
}


// Fixed generateMockRecommendations() with optional message parameter
void generateMockRecommendations({String? message}) {
  print(message ?? 'Generating mock recommendations...'); // Debug output

  setState(() {
    recommendationData = {
      'main_recommendation': {
        'title': 'Sleep-Study Balance',
        'description':
            'Based on your current wellness data showing irregular sleep patterns and your recent academic performance, we recommend shifting your intensive study sessions to 6-8 PM and ensuring 7-8 hours of quality sleep.',
        'reason':
            'Your current data shows that late-night studying is affecting your sleep quality, which directly impacts your academic performance the next day.',
        'actionable_steps': [
          'Move intensive study sessions to 6-8 PM',
          'Aim for 7-8 hours of sleep nightly',
          'Avoid screens 1 hour before bedtime',
          'Create a consistent bedtime routine'
        ]
      },
      'extra_tips': [
        {
          'title': 'Morning Brain Boost',
          'tip': 'Start your day with a healthy breakfast and 10 minutes of light exercise to activate your brain.',
          'icon': 'breakfast_dining'
        },
        {
          'title': 'Study Break Strategy',
          'tip': 'Use the Pomodoro technique: 25 minutes focused study, 5-minute break.',
          'icon': 'timer'
        },
        {
          'title': 'Stress Relief Quick Fix',
          'tip': 'When feeling overwhelmed, try 5 deep breaths or a 2-minute walk.',
          'icon': 'spa'
        },
        {
          'title': 'Hydration Reminder',
          'tip': 'Keep a water bottle at your study desk. Even mild dehydration can affect concentration.',
          'icon': 'local_drink'
        },
        {
          'title': 'Social Learning',
          'tip': 'Schedule one group study session per week. Explaining concepts to others strengthens your own understanding.',
          'icon': 'group'
        }
      ]
    };
    isLoading = false;
    print('Mock recommendations generated successfully');
  });
}



  Widget _buildMainRecommendationCard() {
    if (recommendationData?['main_recommendation'] == null) return const SizedBox();
    
    final recommendation = recommendationData!['main_recommendation'] as Map<String, dynamic>;
    final actionSteps = recommendation['actionable_steps'] as List;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main title
          Text(
            "Here's the Recommendation for Today...",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Recommendation icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  recommendation['title'],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendation['description'],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 16),
          
          // Why this recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why: ${recommendation['reason']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Action steps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Steps:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...actionSteps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraTipsSection() {
    if (recommendationData?['extra_tips'] == null) return const SizedBox();
    
    final tips = recommendationData!['extra_tips'] as List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Extra Tips & Recommendations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        ...tips.map((tip) => _buildTipCard(tip)).toList(),
      ],
    );
  }
  
  Widget _buildTipCard(Map<String, dynamic> tip) {
    IconData tipIcon;
    
    // Set icon based on type
    switch (tip['icon'].toString().toLowerCase()) {
      case 'breakfast_dining':
        tipIcon = Icons.breakfast_dining_outlined;
        break;
      case 'timer':
        tipIcon = Icons.timer_outlined;
        break;
      case 'spa':
        tipIcon = Icons.spa_outlined;
        break;
      case 'local_drink':
        tipIcon = Icons.local_drink_outlined;
        break;
      case 'group':
        tipIcon = Icons.group_outlined;
        break;
      default:
        tipIcon = Icons.lightbulb_outline;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppTheme.primaryColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tipIcon,
                color: AppTheme.accentTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip['title'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip['tip'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Flexible(
          child:Row( 
            children: [
            ThemeHelpers.themedAvatar(
              size: 40,
              icon: Icons.recommend_outlined,
            ),
            const SizedBox(width: 12),
            Text(
              'Recommendations',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            ],
          )
        ),
        actions: [
          // Debug indicator showing data source
          if (recommendationData?['analytics'] != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                //color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRecommendations,
            tooltip: 'Refresh Recommendations',
          ),
        ],
      ),
      body: ThemeHelpers.gradientBackground(
        child: isLoading
          ? Center(
              child: ThemedWidgets.loadingIndicator(
                message: 'Generating personalized recommendations...',
              ),
            )
          : errorMessage != null
            ? ThemedWidgets.emptyState(
                title: 'Unable to Load Recommendations',
                subtitle: errorMessage!,
                icon: Icons.error_outline,
                action: ThemeHelpers.themedButton(
                  text: 'Retry',
                  onPressed: fetchRecommendations,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main recommendation card
                    _buildMainRecommendationCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Extra tips section
                    _buildExtraTipsSection(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}