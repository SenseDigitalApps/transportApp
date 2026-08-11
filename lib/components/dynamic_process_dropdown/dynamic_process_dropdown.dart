import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/api_requests/api_base_url.dart';
import '/backend/api_requests/api_manager.dart';
import '/backend/api_requests/interceptor.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// A dropdown selector for dynamic processes.
///
/// For relational fields, fetches options from the API (users, registers, masters).
/// For status/dropdown fields, uses the field's options config.
class DynamicProcessDropdown extends StatefulWidget {
  const DynamicProcessDropdown({
    super.key,
    required this.processName,
    required this.fieldSlug,
    required this.moduleName,
    required this.onValueChanged,
    required this.currentValue,
    this.relationsType,
    this.relatedModuleName,
  });

  final String processName;
  final String fieldSlug;
  final String moduleName;
  final Function(String value, String condition) onValueChanged;
  final String currentValue;
  final String? relationsType;
  final String? relatedModuleName;

  @override
  State<DynamicProcessDropdown> createState() => _DynamicProcessDropdownState();
}

class _DynamicProcessDropdownState extends State<DynamicProcessDropdown> {
  String? _fieldType;
  String? _relationsType;
  String? _relatedModuleName;
  List<String> _statusOptions = [];
  bool _isLoading = true;
  bool _isLoadingOptions = false;
  String? _selectedValue;
  String _condition = 'igual';

  // For relational fields: fetched options
  List<Map<String, String>> _relationalOptions = [];
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue.isEmpty ? null : widget.currentValue;
    _relationsType = widget.relationsType;
    _relatedModuleName = widget.relatedModuleName;
    _fetchFieldConfig();
  }

  @override
  void didUpdateWidget(DynamicProcessDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentValue != widget.currentValue) {
      setState(() {
        _selectedValue =
            widget.currentValue.isEmpty ? null : widget.currentValue;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFieldConfig() async {
    try {
      final response = await GetCustomFieldsPerModuleCall.call(
        tenant: FFAppState().organizacion,
        moduleName: widget.moduleName,
        token: FFAppState().token,
      );

      if (response.succeeded && response.jsonBody != null) {
        final data = getJsonField(response.jsonBody, r'''$.data''', true);
        if (data is List) {
          for (final field in data) {
            if (field is Map &&
                field['slug']?.toString() == widget.fieldSlug) {
              final fieldMap = Map<String, dynamic>.from(field);
              setState(() {
                _fieldType = fieldMap['field_type']?.toString() ?? '';
                _relationsType ??=
                    fieldMap['relations_type']?.toString() ?? '';
                _relatedModuleName ??=
                    fieldMap['related_module_name']?.toString();
                final relatedModule = fieldMap['related_module'];
                if (relatedModule != null && _relatedModuleName == null) {
                  // Try to resolve module name from ID
                  _relatedModuleName = _resolveModuleName(
                      relatedModule.toString());
                }
                _parseOptions(fieldMap);
              });

              // Fetch relational options if needed
              if (_fieldType == 'relational' && _relationsType!.isNotEmpty) {
                await _fetchRelationalOptions();
              }

              setState(() => _isLoading = false);
              return;
            }
          }
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching field config: $e');
      setState(() => _isLoading = false);
    }
  }

  String _resolveModuleName(String moduleId) {
    for (final m in FFAppState().moduleList) {
      if (m is Map && m['id'].toString() == moduleId) {
        return m['name']?.toString() ?? '';
      }
    }
    return '';
  }

  void _parseOptions(Map<String, dynamic> field) {
    final fieldType = field['field_type']?.toString() ?? '';
    if (fieldType == 'status' ||
        fieldType == 'dropdown' ||
        fieldType == 'radio') {
      final optionsRaw = field['options']?.toString() ?? '';
      if (optionsRaw.isNotEmpty) {
        _statusOptions = optionsRaw.split(',').map((o) {
          final parts = o.split('|');
          return parts.first.trim();
        }).where((s) => s.isNotEmpty).toList();
      }
    }
  }

  Future<void> _fetchRelationalOptions([String? search]) async {
    setState(() => _isLoadingOptions = true);
    try {
      final searchParam = search != null && search.isNotEmpty
          ? '&search=${Uri.encodeComponent(search)}'
          : '';

      if (_relationsType == 'user') {
        // Fetch users
        final apiPath =
            'users/?page=1&items_per_page=50$searchParam';
        final apiUrl = ApiBaseUrl.forTenantCall(
          tenant: FFAppState().organizacion,
          apiPath: apiPath,
        );
        final response = await FFApiInterceptor.makeApiCall(
          ApiCallOptions(
            callName: 'getUsersForProcess',
            apiUrl: apiUrl,
            callType: ApiCallType.GET,
            headers: {'Authorization': 'Bearer ${FFAppState().token}'},
            params: {},
            returnBody: true,
            encodeBodyUtf8: true,
            decodeUtf8: true,
            cache: false,
            alwaysAllowBody: false,
          ),
          [ExpiredSessionInterceptor()],
        );

        if (response.succeeded && response.jsonBody != null) {
          final data = getJsonField(response.jsonBody, r'''$.data''', true);
          if (data is List) {
            setState(() {
              _relationalOptions = data.map<Map<String, String>>((u) {
                final fullName =
                    getJsonField(u, r'''$.full_name''')?.toString() ?? '';
                final username =
                    getJsonField(u, r'''$.username''')?.toString() ?? '';
                final email =
                    getJsonField(u, r'''$.email''')?.toString() ?? '';
                final label =
                    (fullName.isNotEmpty ? fullName : username.isNotEmpty ? username : email)
                        .trim();
                return {'value': label, 'label': label};
              }).where((o) => o['label']!.isNotEmpty).toList();
            });
          }
        }
      } else {
        // Fetch registers or masters from related module
        final moduleName = _relatedModuleName ?? '';
        if (moduleName.isEmpty) {
          setState(() => _isLoadingOptions = false);
          return;
        }
        final table = _relationsType == 'module' ? 'register' : 'master';
        final apiPath =
            'v2/$table/?page=1&items_per_page=50&filter_module=$moduleName$searchParam';
        final apiUrl = ApiBaseUrl.forTenantCall(
          tenant: FFAppState().organizacion,
          apiPath: apiPath,
        );
        final response = await FFApiInterceptor.makeApiCall(
          ApiCallOptions(
            callName: 'getRegistersForProcess',
            apiUrl: apiUrl,
            callType: ApiCallType.GET,
            headers: {'Authorization': 'Bearer ${FFAppState().token}'},
            params: {},
            returnBody: true,
            encodeBodyUtf8: true,
            decodeUtf8: true,
            cache: false,
            alwaysAllowBody: false,
          ),
          [ExpiredSessionInterceptor()],
        );

        if (response.succeeded && response.jsonBody != null) {
          final data = getJsonField(response.jsonBody, r'''$.data''', true);
          if (data is List) {
            setState(() {
              _relationalOptions = data.map<Map<String, String>>((r) {
                final consecutivo =
                    getJsonField(r, r'''$.consecutivo''')?.toString() ?? '';
                final title =
                    getJsonField(r, r'''$.title''')?.toString() ?? '';
                final id = getJsonField(r, r'''$.id''')?.toString() ?? '';
                final label = consecutivo.isNotEmpty
                    ? '$consecutivo - $title'
                    : title.isNotEmpty
                        ? title
                        : '#$id';
                return {'value': id, 'label': label.trim()};
              }).where((o) => o['label']!.isNotEmpty).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching relational options: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  String get _displayName {
    return widget.processName
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),
      );
    }

    // Status/dropdown field → simple dropdown
    if (_fieldType == 'status' ||
        _fieldType == 'dropdown' ||
        _fieldType == 'radio') {
      return _buildStatusDropdown();
    }

    // Relational field → searchable dropdown
    if (_fieldType == 'relational') {
      return _buildRelationalDropdown();
    }

    // Fallback: text input
    return _buildTextInput();
  }

  Widget _buildStatusDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedValue,
          hint: Text(
            _displayName,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: FlutterFlowTheme.of(context).primary,
            size: 18,
          ),
          items: _statusOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : w)
                    .join(' '),
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                    ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedValue = value);
            widget.onValueChanged(value ?? '', _condition);
          },
        ),
      ),
    );
  }

  Widget _buildRelationalDropdown() {
    return GestureDetector(
      onTap: () {
        if (_relationalOptions.isEmpty) {
          _fetchRelationalOptions().then((_) {
            if (mounted) _showOptionsSheet();
          });
        } else {
          _showOptionsSheet();
        }
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 10.0, 0.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(30.0),
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
                child: Text(
                  _selectedValue ?? _displayName,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: _selectedValue != null
                            ? FlutterFlowTheme.of(context).primaryText
                            : FlutterFlowTheme.of(context).secondaryText,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            if (_selectedValue != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedValue = null);
                  widget.onValueChanged('', _condition);
                },
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              )
            else
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: FlutterFlowTheme.of(context).primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      height: 36,
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: TextEditingController(text: _selectedValue ?? ''),
        decoration: InputDecoration(
          hintText: _displayName,
          hintStyle: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Outfit',
                fontSize: 11,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color:
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color:
                  FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary,
            ),
          ),
          suffixIcon: _selectedValue != null && _selectedValue!.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    setState(() => _selectedValue = null);
                    widget.onValueChanged('', _condition);
                  },
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                )
              : null,
        ),
        style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Outfit',
              fontSize: 12,
            ),
        onSubmitted: (value) {
          setState(() =>
              _selectedValue = value.isEmpty ? null : value);
          widget.onValueChanged(value, _condition);
        },
      ),
    );
  }

  /// Show bottom sheet with searchable options for relational fields.
  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _RelationalOptionsSheet(
          title: _displayName,
          options: _relationalOptions,
          isLoading: _isLoadingOptions,
          selectedValue: _selectedValue,
          onSelected: (value) {
            setState(() => _selectedValue = value);
            widget.onValueChanged(value, _condition);
            Navigator.pop(ctx);
          },
          onSearch: (term) {
            _searchTerm = term;
            _fetchRelationalOptions(term);
          },
        );
      },
    );
  }
}

/// Bottom sheet for selecting relational options.
class _RelationalOptionsSheet extends StatefulWidget {
  const _RelationalOptionsSheet({
    required this.title,
    required this.options,
    required this.isLoading,
    this.selectedValue,
    required this.onSelected,
    required this.onSearch,
  });

  final String title;
  final List<Map<String, String>> options;
  final bool isLoading;
  final String? selectedValue;
  final Function(String) onSelected;
  final Function(String) onSearch;

  @override
  State<_RelationalOptionsSheet> createState() =>
      _RelationalOptionsSheetState();
}

class _RelationalOptionsSheetState extends State<_RelationalOptionsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              widget.title,
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchTerm = value);
                widget.onSearch(value);
              },
            ),
          ),
          // Options
          Expanded(
            child: widget.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  )
                : widget.options.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron resultados',
                          style: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .override(
                                fontFamily: 'Outfit',
                                color: FlutterFlowTheme.of(context)
                                    .secondaryText,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.options.length,
                        itemBuilder: (ctx, index) {
                          final option = widget.options[index];
                          final isSelected =
                              option['value'] == widget.selectedValue;
                          return ListTile(
                            dense: true,
                            title: Text(
                              option['label'] ?? '',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? FlutterFlowTheme.of(context)
                                            .primary
                                        : null,
                                  ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: FlutterFlowTheme.of(context)
                                        .primary,
                                    size: 18,
                                  )
                                : null,
                            onTap: () =>
                                widget.onSelected(option['value'] ?? ''),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Checks if a process filtros string is a dynamic slug.
bool isDynamicProcessFiltros(String? filtros) {
  if (filtros == null || filtros.isEmpty) return false;
  final normalized = filtros.trim();
  return normalized.isNotEmpty &&
      !normalized.contains(',') &&
      !normalized.contains('|') &&
      !normalized.contains('^') &&
      !normalized.startsWith('filter(');
}
