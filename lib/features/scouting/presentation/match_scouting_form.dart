import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/data_service.dart';

class MatchScoutingForm extends StatefulWidget {
  final String? eventKey;
  final int? matchNumber;
  final String? teamNumber;

  const MatchScoutingForm({
    super.key, 
    this.eventKey,
    this.matchNumber,
    this.teamNumber,
  });

  @override
  State<MatchScoutingForm> createState() => _MatchScoutingFormState();
}

class _MatchScoutingFormState extends State<MatchScoutingForm> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Map<String, dynamic> _formData = {
    'matchInfo': {},
    'auto': {
      'moved': false,
      'fuel': 0,
      'l1Climb': false,
    },
    'teleop': {
      'fuel': 0,
    },
    'endgame': {
      'hang': 'None', 
    },
  };

  final TextEditingController _matchNumberController = TextEditingController();
  final TextEditingController _teamNumberController = TextEditingController();
  final TextEditingController _scouterNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScouterName();
    
    if (widget.matchNumber != null) {
      _matchNumberController.text = widget.matchNumber.toString();
    }
    if (widget.teamNumber != null) {
      _teamNumberController.text = widget.teamNumber!;
    }

    if (widget.eventKey != null && widget.matchNumber == null) {
      _matchNumberController.addListener(_fetchMatchDetails);
    }
  }

  @override
  void dispose() {
    _matchNumberController.removeListener(_fetchMatchDetails);
    _matchNumberController.dispose();
    _teamNumberController.dispose();
    _scouterNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadScouterName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _scouterNameController.text = doc.data()?['username'] ?? '';
        });
      }
    }
  }

  Future<void> _fetchMatchDetails() async {
    final matchNum = _matchNumberController.text;
    if (matchNum.isEmpty || widget.eventKey == null) return;

    try {
       final user = FirebaseAuth.instance.currentUser;
       if (user != null) {
         final query = await FirebaseFirestore.instance.collection('scouting_assignments')
             .where('eventCode', isEqualTo: widget.eventKey)
             .where('matchNumber', isEqualTo: int.tryParse(matchNum))
             .where('scouterUid', isEqualTo: user.uid)
             .get();
         
         if (query.docs.isNotEmpty) {
           final assignment = query.docs.first.data();
           setState(() {
             _teamNumberController.text = assignment['teamNumber'].toString();
           });
           
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Found assignment: Team ${assignment['teamNumber']}')),
           );
         } else {
         }
       }
    } catch (e) {
      print('Error fetching match details: $e');
    }
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
        title: const Text('REBUILT 2026 Scouting'),
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
          _buildTextField('Scouter Name', _scouterNameController, Icons.person, keyboardType: TextInputType.name),
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
            'Fuel Scoring',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          _buildToggleCard(
            'Leave',
            'Did the robot leave the starting line?',
            _formData['auto']['moved'],
            (val) => setState(() => _formData['auto']['moved'] = val),
          ),
          
          const SizedBox(height: 20),
          _buildCounter('Fuel Scored', _formData['auto']['fuel'], (val) => setState(() => _formData['auto']['fuel'] = val)),
          
          const SizedBox(height: 20),
          _buildToggleCard(
            'L1 Climb',
            'Did the robot L1 climb in Auto?',
            _formData['auto']['l1Climb'],
            (val) => setState(() => _formData['auto']['l1Climb'] = val),
          ),
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
          
          _buildCounter('Fuel Scored', _formData['teleop']['fuel'], (val) => setState(() => _formData['teleop']['fuel'] = val)),
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
            'Endgame',
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
                items: ['None', 'Park', 'Climb'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _formData['endgame']['hang'] = val),
              ),
            ),
          ),
          
          if (_formData['endgame']['hang'] == 'Climb') ...[
             // Additional climb info can go here if needed, simplified for now
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.number}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
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
