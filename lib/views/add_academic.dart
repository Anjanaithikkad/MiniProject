import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Provides apiBaseUrl
import '../theme/app_theme.dart';
import '../theme/theme_helpers.dart';

class AddAcademicPage extends StatefulWidget {
  final String studentId;
  const AddAcademicPage({super.key, required this.studentId});

  @override
  State<AddAcademicPage> createState() => _AddAcademicPageState();
}

class _AddAcademicPageState extends State<AddAcademicPage> {
  List<Map<String, dynamic>> subjects = [
    {"name": "", "mark": ""}
  ];
  TextEditingController studyHoursController = TextEditingController();
  TextEditingController focusLevelController = TextEditingController();
  int overallMark = 0;
  bool _isConfirming = false;
  List<String> _markErrors = []; // To track validation errors

  void calculateOverallMark() {
    int total = 0;
    int count = 0;
    _markErrors.clear(); // Clear previous errors
    
    for (int i = 0; i < subjects.length; i++) {
      var subj = subjects[i];
      if (subj["mark"].toString().isNotEmpty) {
        int? mark = int.tryParse(subj["mark"].toString());
        if (mark != null) {
          // Validate mark is between 0 and 100
          if (mark < 0 || mark > 100) {
            if (_markErrors.length <= i) {
              _markErrors.add("Mark must be between 0 and 100");
            } else {
              _markErrors[i] = "Mark must be between 0 and 100";
            }
          } else {
            if (_markErrors.length <= i) {
              _markErrors.add(""); // No error
            } else {
              _markErrors[i] = ""; // No error
            }
            total += mark;
            count++;
          }
        } else {
          if (_markErrors.length <= i) {
            _markErrors.add("Invalid number format");
          } else {
            _markErrors[i] = "Invalid number format";
          }
        }
      } else {
        if (_markErrors.length <= i) {
          _markErrors.add(""); // No error for empty field
        } else {
          _markErrors[i] = ""; // No error for empty field
        }
      }
    }
    
    setState(() {
      overallMark = (count > 0) ? (total ~/ count) : 0;
    });
  }

Future<void> saveAcademicData() async {
  // Validate all marks before saving
  bool hasErrors = false;
  _markErrors.clear();
  
  for (int i = 0; i < subjects.length; i++) {
    var subj = subjects[i];
    if (subj["mark"].toString().isNotEmpty) {
      int? mark = int.tryParse(subj["mark"].toString());
      if (mark != null) {
        if (mark < 0 || mark > 100) {
          if (_markErrors.length <= i) {
            _markErrors.add("Mark must be between 0 and 100");
          } else {
            _markErrors[i] = "Mark must be between 0 and 100";
          }
          hasErrors = true;
        } else {
          if (_markErrors.length <= i) {
            _markErrors.add("");
          } else {
            _markErrors[i] = "";
          }
        }
      } else {
        if (_markErrors.length <= i) {
          _markErrors.add("Invalid number format");
        } else {
          _markErrors[i] = "Invalid number format";
        }
        hasErrors = true;
      }
    } else {
      if (_markErrors.length <= i) {
        _markErrors.add("");
      } else {
        _markErrors[i] = "";
      }
    }
  }
  
  // Also validate that subjects have names
  for (int i = 0; i < subjects.length; i++) {
    var subj = subjects[i];
    if (subj["name"].toString().isEmpty) {
      hasErrors = true;
      // We won't show an error for this since it's not related to marks validation
    }
  }
  
  // Validate study hours and focus level
  if (studyHoursController.text.isNotEmpty) {
    double? studyHours = double.tryParse(studyHoursController.text);
    if (studyHours == null || studyHours < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Study hours must be a valid positive number")),
      );
      setState(() => _isConfirming = false);
      return;
    }
  }
  
  if (focusLevelController.text.isNotEmpty) {
    double? focusLevel = double.tryParse(focusLevelController.text);
    if (focusLevel == null || focusLevel < 0 || focusLevel > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Focus level must be between 0 and 10")),
      );
      setState(() => _isConfirming = false);
      return;
    }
  }

  if (hasErrors) {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please correct the errors in marks before saving")),
    );
    setState(() => _isConfirming = false);
    return;
  }

  try {
    final url = Uri.parse("$apiBaseUrl/academics/add");

    final Map<String, dynamic> data = {
      "studentId": widget.studentId,
      "subjects": subjects,
      "studyHours": studyHoursController.text,
      "focusLevel": focusLevelController.text,
      "overallMark": overallMark,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData["message"] ?? "Saved!")),
      );
      // Return true to indicate data was updated
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to Save: ${response.body}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    setState(() => _isConfirming = false);
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemeHelpers.dashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header section with themed avatar and title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.textOnPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ThemeHelpers.themedAvatar(
                      size: 50,
                      icon: Icons.school_outlined, // Academic/education icon
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Add Academic Data',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            Text(
              "Subjects & Marks",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Subject List
            Column(
              children: List.generate(subjects.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Subject",
                                  labelStyle: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (val) {
                                  subjects[index]["name"] = val;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Mark",
                                  labelStyle: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  // Show error text if there's a validation error
                                  errorText: index < _markErrors.length && _markErrors[index].isNotEmpty 
                                    ? _markErrors[index] 
                                    : null,
                                ),
                                onChanged: (val) {
                                  subjects[index]["mark"] = val;
                                  calculateOverallMark();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: AppTheme.errorColor,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  subjects.removeAt(index);
                                  // Also remove the error for this index
                                  if (index < _markErrors.length) {
                                    _markErrors.removeAt(index);
                                  }
                                  calculateOverallMark();
                                });
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            Center(
              child: ThemeHelpers.themedButton(
                text: "Add Another Subject",
                onPressed: () {
                  setState(() {
                    subjects.add({"name": "", "mark": ""});
                    _markErrors.add(""); // Add empty error for new subject
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 187, 129, 75),
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Study Hours (per day)",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: studyHoursController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter study hours",
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Focus Level (out of 10)",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: focusLevelController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter focus level",
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Overall Marks",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.secondaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                overallMark.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: ThemeHelpers.themedButton(
                text: _isConfirming ? "Saving..." : "Confirm",
                onPressed: _isConfirming
                    ? () {}
                    : () async {
                        setState(() => _isConfirming = true);
                        await saveAcademicData();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 98, 66, 2),
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_isConfirming) ...[
              const SizedBox(height: 16),
              Center(
                child: ThemedWidgets.loadingIndicator(message: 'Saving academic data...'),
              ),
            ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}