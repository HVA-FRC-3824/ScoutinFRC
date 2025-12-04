import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AllianceSelectionPage extends StatefulWidget {
  const AllianceSelectionPage({super.key});

  @override
  State<AllianceSelectionPage> createState() => _AllianceSelectionPageState();
}

class _AllianceSelectionPageState extends State<AllianceSelectionPage> {
  final List<String> _pickList = ['254', '1678', '118', '1323', '2910'];
  final List<String> _doNotPickList = ['9999', '0000'];
  final TextEditingController _teamController = TextEditingController();

  void _addTeam() {
    if (_teamController.text.isNotEmpty) {
      setState(() {
        _pickList.add(_teamController.text);
        _teamController.clear();
      });
    }
  }

  void _moveToDoNotPick(String team) {
    setState(() {
      _pickList.remove(team);
      _doNotPickList.add(team);
    });
  }

  void _moveToPickList(String team) {
    setState(() {
      _doNotPickList.remove(team);
      _pickList.add(team);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alliance Selection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildAddTeamBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildPickList(),
                ),
                Container(width: 1, color: AppColors.surfaceHighlight),
                Expanded(
                  flex: 1,
                  child: _buildDoNotPickList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTeamBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceHighlight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _teamController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add Team to Pick List',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _addTeam(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
            onPressed: _addTeam,
          ),
        ],
      ),
    );
  }

  Widget _buildPickList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('PICK LIST', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final String item = _pickList.removeAt(oldIndex);
                _pickList.insert(newIndex, item);
              });
            },
            children: [
              for (int index = 0; index < _pickList.length; index++)
                _buildPickListItem(index, _pickList[index]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickListItem(int index, String team) {
    return Container(
      key: ValueKey(team),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          child: Text('${index + 1}'),
        ),
        title: Text(
          team,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _moveToDoNotPick(team),
        ),
      ),
    );
  }

  Widget _buildDoNotPickList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('DNP', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _doNotPickList.length,
            itemBuilder: (context, index) {
              final team = _doNotPickList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: ListTile(
                  title: Text(
                    team,
                    style: const TextStyle(color: Colors.white70, decoration: TextDecoration.lineThrough),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.undo, color: AppColors.success),
                    onPressed: () => _moveToPickList(team),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
