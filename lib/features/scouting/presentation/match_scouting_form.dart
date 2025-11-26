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
    'auto': {},
    'teleop': {},
    'endgame': {},
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
      
      // Update match info
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
      appBar: AppBar(
        title: const Text('Match Scouting'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: Form(
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: _prevPage,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface),
                child: const Text('Previous'),
              )
            else
              const SizedBox(width: 100), // Spacer

            if (_currentPage < 3)
              ElevatedButton(
                onPressed: _nextPage,
                child: const Text('Next'),
              )
            else
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreMatchPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pre-Match Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _matchNumberController,
            decoration: const InputDecoration(labelText: 'Match Number'),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _teamNumberController,
            decoration: const InputDecoration(labelText: 'Team Number'),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _scouterNameController,
            decoration: const InputDecoration(labelText: 'Scouter Name'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPage() {
    return const Center(
      child: Text('Auto Page (To Be Implemented)', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTeleopPage() {
    return const Center(
      child: Text('Teleop Page (To Be Implemented)', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildEndgamePage() {
    return const Center(
      child: Text('Endgame Page (To Be Implemented)', style: TextStyle(color: Colors.white)),
    );
  }
}
