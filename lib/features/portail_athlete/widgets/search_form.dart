import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../providers/recent_searches_provider.dart';

class SearchForm extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onSearch;
  final List<RecentSearchEntry> recentSearches;
  final ValueChanged<String>? onRemoveRecent;

  const SearchForm({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.onSearch,
    this.recentSearches = const [],
    this.onRemoveRecent,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSearch(_controller.text);
  }

  void _selectRecent(String msNius) {
    _controller.text = msNius;
    widget.onSearch(msNius);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 48,
                    color: SigsTheme.primaryOrange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Identifiez-vous',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SigsTheme.primaryBlue,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saisissez votre matricule MS-NIUS pour consulter vos licences sportives.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _controller,
                    enabled: !widget.isLoading,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Matricule MS-NIUS',
                      hintText: 'Ex: MS-2500001A',
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir votre MS-NIUS';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (widget.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SigsTheme.dangerRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SigsTheme.dangerRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: SigsTheme.dangerRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.errorMessage!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: SigsTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: widget.isLoading ? null : _submit,
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        widget.isLoading
                            ? 'Recherche en cours...'
                            : 'Rechercher mes licences',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.recentSearches.isNotEmpty) ...[
          const SizedBox(height: 20),
          _RecentSearchesList(
            entries: widget.recentSearches,
            onSelect: _selectRecent,
            onRemove: widget.onRemoveRecent,
            isLoading: widget.isLoading,
          ),
        ],
      ],
    );
  }
}

class _RecentSearchesList extends StatelessWidget {
  final List<RecentSearchEntry> entries;
  final ValueChanged<String> onSelect;
  final ValueChanged<String>? onRemove;
  final bool isLoading;

  const _RecentSearchesList({
    required this.entries,
    required this.onSelect,
    this.onRemove,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          ...entries.map((entry) => _RecentSearchTile(
                entry: entry,
                onTap: isLoading ? null : () => onSelect(entry.msNius),
                onRemove:
                    onRemove != null ? () => onRemove!(entry.msNius) : null,
              )),
        ],
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final RecentSearchEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _RecentSearchTile({
    required this.entry,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SigsTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: SigsTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.msNius,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SigsTheme.primaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (entry.athleteName != null &&
                          entry.athleteName!.isNotEmpty)
                        Text(
                          entry.athleteName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
