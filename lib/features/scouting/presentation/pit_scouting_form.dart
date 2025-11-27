import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/data_service.dart';

class PitScoutingForm extends StatefulWidget {
  const PitScoutingForm({super.key});

  @override
  State<PitScoutingForm> createState() => _PitScoutingFormState();
}

class _PitScoutingFormState extends State<PitScoutingForm> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Map<String, dynamic> _formData = {
    'teamInfo': {},
    'specs': {
      'drivetrain': 'Tank',
      'weight': '',
      'motorType': 'Falcon 500',
    },
    'capabilities': {
      'autoMove': false,
      'autoLow': false,
      'autoHigh': false,
      'climb': false,
      'wheelOfFortune': false,
    },
    'comments': '',
  };

  final TextEditingController _teamNumberController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _teamNumberController.dispose();
    _teamNameController.dispose();
    _weightController.dispose();
    _commentsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      _formData['teamInfo'] = {
        'teamNumber': _teamNumberController.text,
        'teamName': _teamNameController.text,
      };
      _formData['specs']['weight'] = _weightController.text;
      _formData['comments'] = _commentsController.text;

      try {
        await DataService().submitPitScoutingData(_formData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pit data submitted successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pit Scouting'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentPage ? AppColors.primary : AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildTeamInfoPage(),
                  _buildSpecsPage(),
                  _buildCapabilitiesPage(),
                  _buildCommentsPage(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceHighlight)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              TextButton.icon(
                onPressed: _prevPage,
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                label: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              const SizedBox(width: 80),

            if (_currentPage < 3)
              ElevatedButton.icon(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              )
            else
              ElevatedButton.icon(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GENERAL INFO',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Team Details',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildTextField('Team Number', _teamNumberController, Icons.numbers, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildTextField('Team Name', _teamNameController, Icons.group, keyboardType: TextInputType.name),
        ],
      ),
    );
  }

  Widget _buildSpecsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROBOT SPECS',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Physical Attributes',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildTextField('Weight (lbs)', _weightController, Icons.monitor_weight, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildDropdown(
            'Drivetrain Type',
            _formData['specs']['drivetrain'],
            ['Tank', 'Mecanum', 'Swerve', 'H-Drive', 'Other'],
            (val) => setState(() => _formData['specs']['drivetrain'] = val),
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            'Motor Type',
            _formData['specs']['motorType'],
            ['Falcon 500', 'NEO 550', 'NEO v1.1', 'Kraken x60', 'Kraken x44','Other'],
            (val) => setState(() => _formData['specs']['motorType'] = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CAPABILITIES',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Robot Actions',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildToggleCard(
            'Auto Move',
            'Can move in autonomous?',
            _formData['capabilities']['autoMove'],
            (val) => setState(() => _formData['capabilities']['autoMove'] = val),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            'Auto Low Goal',
            'Scores in low port during auto?',
            _formData['capabilities']['autoLow'],
            (val) => setState(() => _formData['capabilities']['autoLow'] = val),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            'Auto High Goal',
            'Scores in high port during auto?',
            _formData['capabilities']['autoHigh'],
            (val) => setState(() => _formData['capabilities']['autoHigh'] = val),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            'Climb',
            'Can climb the generator switch?',
            _formData['capabilities']['climb'],
            (val) => setState(() => _formData['capabilities']['climb'] = val),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            'Control Panel',
            'Can manipulate the control panel?',
            _formData['capabilities']['wheelOfFortune'],
            (val) => setState(() => _formData['capabilities']['wheelOfFortune'] = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUMMARY',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Additional Notes',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildTextField(
            'Comments / Strategy',
            _commentsController,
            Icons.comment,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildToggleCard(String title, String subtitle, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? AppColors.primary : AppColors.surfaceHighlight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: value ? AppColors.primary : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
