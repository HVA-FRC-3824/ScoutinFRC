import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/data_service.dart';

class MatchScoutingForm extends StatefulWidget {
  const MatchScoutingForm({super.key});

  @override
  State<MatchScoutingForm> createState() => _MatchScoutingFormState();
}

class _MatchScoutingFormState extends State<MatchScoutingForm> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form Data
  final Map<String, dynamic> _formData = {
    'matchInfo': {},
    'auto': {
      'moved': false,
      'low': 0,
      'outer': 0,
      'inner': 0,
    },
    'teleop': {
      'low': 0,
      'outer': 0,
      'inner': 0,
      'rotationControl': false,
      'positionControl': false,
    },
    'endgame': {
      'hang': 'None', // None, Park, Hang, Level
      'level': false,
    },
  };

  // Controllers
  final TextEditingController _matchNumberController = TextEditingController();
  final TextEditingController _teamNumberController = TextEditingController();
  final TextEditingController _scouterNameController = TextEditingController();

  @override
  void dispose() {
    _matchNumberController.dispose();
    _teamNumberController.dispose();
    _scouterNameController.dispose();
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
      
      _formData['matchInfo'] = {
        'matchNumber': _matchNumberController.text,
        'teamNumber': _teamNumberController.text,
        'scouterName': _scouterNameController.text,
      };

      try {
        await DataService().submitMatchData(_formData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match data submitted successfully!')),
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
        title: const Text('Infinite Recharge Scouting'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Custom Progress Indicator
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
                  _buildPreMatchPage(),
                  _buildAutoPage(),
                  _buildTeleopPage(),
                  _buildEndgamePage(),
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

  Widget _buildPreMatchPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRE-MATCH',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Match Information',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildTextField('Match Number', _matchNumberController, Icons.numbers),
          const SizedBox(height: 20),
          _buildTextField('Team Number', _teamNumberController, Icons.group),
          const SizedBox(height: 20),
          _buildTextField('Scouter Name', _scouterNameController, Icons.person),
        ],
      ),
    );
  }

  Widget _buildAutoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUTONOMOUS',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Power Cell Scoring',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          _buildToggleCard(
            'Initiation Line',
            'Did the robot cross the line?',
            _formData['auto']['moved'],
            (val) => setState(() => _formData['auto']['moved'] = val),
          ),
          
          const SizedBox(height: 20),
          _buildCounter('Bottom Port', _formData['auto']['low'], (val) => setState(() => _formData['auto']['low'] = val)),
          const SizedBox(height: 15),
          _buildCounter('Outer Port', _formData['auto']['outer'], (val) => setState(() => _formData['auto']['outer'] = val)),
          const SizedBox(height: 15),
          _buildCounter('Inner Port', _formData['auto']['inner'], (val) => setState(() => _formData['auto']['inner'] = val)),
        ],
      ),
    );
  }

  Widget _buildTeleopPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TELEOP',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Teleop Performance',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          _buildCounter('Bottom Port', _formData['teleop']['low'], (val) => setState(() => _formData['teleop']['low'] = val)),
          const SizedBox(height: 15),
          _buildCounter('Outer Port', _formData['teleop']['outer'], (val) => setState(() => _formData['teleop']['outer'] = val)),
          const SizedBox(height: 15),
          _buildCounter('Inner Port', _formData['teleop']['inner'], (val) => setState(() => _formData['teleop']['inner'] = val)),
          
          const SizedBox(height: 30),
          const Text('Control Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildToggleCard(
            'Rotation Control',
            'Stage 2: Spin 3-5 times',
            _formData['teleop']['rotationControl'],
            (val) => setState(() => _formData['teleop']['rotationControl'] = val),
          ),
          const SizedBox(height: 10),
          _buildToggleCard(
            'Position Control',
            'Stage 3: Spin to color',
            _formData['teleop']['positionControl'],
            (val) => setState(() => _formData['teleop']['positionControl'] = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEndgamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENDGAME',
            style: TextStyle(color: AppColors.primary, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Shield Generator',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          const Text('Hang Status', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceHighlight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _formData['endgame']['hang'],
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                items: ['None', 'Park', 'Hang'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _formData['endgame']['hang'] = val),
              ),
            ),
          ),
          
          if (_formData['endgame']['hang'] == 'Hang') ...[
            const SizedBox(height: 20),
            _buildToggleCard(
              'Level?',
              'Is the switch level?',
              _formData['endgame']['level'],
              (val) => setState(() => _formData['endgame']['level'] = val),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
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

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          Row(
            children: [
              _buildIconButton(Icons.remove, () {
                if (value > 0) onChanged(value - 1);
              }),
              SizedBox(width: 40, child: Center(child: Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
              _buildIconButton(Icons.add, () => onChanged(value + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
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
