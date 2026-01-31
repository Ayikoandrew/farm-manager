import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../router/app_router.dart';

/// Cached documentation content to avoid reloading
class _DocCache {
  static String? content;
  static List<_DocSection>? sections;
  static List<_TableOfContentsItem>? toc;
}

/// A section of documentation for lazy rendering
class _DocSection {
  final String id;
  final String title;
  final int level;
  final String content;
  
  _DocSection({
    required this.id,
    required this.title,
    required this.level,
    required this.content,
  });
}

/// Documentation screen for the web platform
/// Optimized with section-based lazy loading
class DocumentationScreen extends StatefulWidget {
  final String? initialSection;

  const DocumentationScreen({super.key, this.initialSection});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  List<_DocSection> _sections = [];
  List<_TableOfContentsItem> _tableOfContents = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showTableOfContents = true;
  String? _selectedSectionId;
  
  // Cache the stylesheet
  MarkdownStyleSheet? _styleSheet;

  @override
  void initState() {
    super.initState();
    _loadDocumentation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentation() async {
    // Use cached content if available
    if (_DocCache.sections != null && _DocCache.toc != null) {
      setState(() {
        _sections = _DocCache.sections!;
        _tableOfContents = _DocCache.toc!;
        _isLoading = false;
        _selectedSectionId = widget.initialSection ?? _sections.firstOrNull?.id;
      });
      return;
    }

    try {
      final content = await rootBundle.loadString('docs/documentation.md');
      final sections = _parseIntoSections(content);
      final toc = _buildTableOfContents(sections);
      
      // Cache for future use
      _DocCache.content = content;
      _DocCache.sections = sections;
      _DocCache.toc = toc;
      
      setState(() {
        _sections = sections;
        _tableOfContents = toc;
        _isLoading = false;
        _selectedSectionId = widget.initialSection ?? sections.firstOrNull?.id;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load documentation: $e';
        _isLoading = false;
      });
    }
  }

  /// Parse markdown into sections for lazy rendering
  List<_DocSection> _parseIntoSections(String content) {
    final lines = content.split('\n');
    final sections = <_DocSection>[];
    
    String currentTitle = 'Introduction';
    int currentLevel = 1;
    String currentId = 'introduction';
    final buffer = StringBuffer();
    
    for (final line in lines) {
      if (line.startsWith('## ')) {
        // Save previous section
        if (buffer.isNotEmpty) {
          sections.add(_DocSection(
            id: currentId,
            title: currentTitle,
            level: currentLevel,
            content: buffer.toString().trim(),
          ));
          buffer.clear();
        }
        
        currentTitle = line.substring(3).trim();
        currentLevel = 2;
        currentId = _generateAnchor(currentTitle);
        buffer.writeln(line);
      } else {
        buffer.writeln(line);
      }
    }
    
    // Add last section
    if (buffer.isNotEmpty) {
      sections.add(_DocSection(
        id: currentId,
        title: currentTitle,
        level: currentLevel,
        content: buffer.toString().trim(),
      ));
    }
    
    return sections;
  }

  List<_TableOfContentsItem> _buildTableOfContents(List<_DocSection> sections) {
    final items = <_TableOfContentsItem>[];
    
    for (final section in sections) {
      items.add(_TableOfContentsItem(
        title: section.title,
        anchor: section.id,
        level: section.level,
      ));
      
      // Parse subsections (### headings) within each section
      final lines = section.content.split('\n');
      for (final line in lines) {
        if (line.startsWith('### ')) {
          final title = line.substring(4).trim();
          items.add(_TableOfContentsItem(
            title: title,
            anchor: _generateAnchor(title),
            level: 3,
          ));
        }
      }
    }
    
    return items;
  }

  String _generateAnchor(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  List<_DocSection> _getFilteredSections() {
    if (_searchQuery.isEmpty) {
      return _sections;
    }
    
    final query = _searchQuery.toLowerCase();
    return _sections.where((section) {
      return section.title.toLowerCase().contains(query) ||
          section.content.toLowerCase().contains(query);
    }).toList();
  }

  void _scrollToSection(String sectionId) {
    setState(() {
      _selectedSectionId = sectionId;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    // Cache stylesheet
    _styleSheet ??= _buildMarkdownStyleSheet(theme);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme, isDesktop),
      body: _buildBody(theme, isDesktop),
      floatingActionButton: !isDesktop ? _buildFab() : null,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDesktop) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            coordinator.replace(LandingRoute());
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.farmGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book, color: AppTheme.farmGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Documentation',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search documentation...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
        const SizedBox(width: 8),
        if (isDesktop)
          IconButton(
            icon: Icon(_showTableOfContents ? Icons.menu_open : Icons.menu),
            tooltip: _showTableOfContents ? 'Hide contents' : 'Show contents',
            onPressed: () => setState(() => _showTableOfContents = !_showTableOfContents),
          ),
        IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Go to app',
          onPressed: () => coordinator.replace(LandingRoute()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading documentation...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error Loading Documentation', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                _DocCache.sections = null;
                _DocCache.toc = null;
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadDocumentation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showTableOfContents)
            SizedBox(
              width: 280,
              child: _buildTableOfContentsWidget(theme),
            ),
          Expanded(child: _buildContentArea(theme)),
        ],
      );
    }

    return _buildContentArea(theme);
  }

  Widget _buildTableOfContentsWidget(ThemeData theme) {
    final filteredToc = _searchQuery.isEmpty
        ? _tableOfContents
        : _tableOfContents.where((item) =>
            item.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Table of Contents',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredToc.length,
              itemBuilder: (context, index) {
                final item = filteredToc[index];
                final isSelected = item.anchor == _selectedSectionId;
                
                return InkWell(
                  onTap: () => _scrollToSection(item.anchor),
                  child: Container(
                    color: isSelected ? AppTheme.farmGreen.withValues(alpha: 0.1) : null,
                    padding: EdgeInsets.only(
                      left: item.level == 2 ? 16 : 32,
                      right: 16,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Row(
                      children: [
                        if (isSelected)
                          Container(
                            width: 3,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.farmGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: item.level == 2 ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.farmGreen
                                  : item.level == 2
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(ThemeData theme) {
    final filteredSections = _getFilteredSections();

    if (filteredSections.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No results found for "$_searchQuery"', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear search'),
            ),
          ],
        ),
      );
    }

    // Find the selected section or show all
    final sectionsToShow = _selectedSectionId != null && _searchQuery.isEmpty
        ? filteredSections.where((s) => s.id == _selectedSectionId).toList()
        : filteredSections;

    // If selected section not found, show all
    final displaySections = sectionsToShow.isEmpty ? filteredSections : sectionsToShow;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        itemCount: displaySections.length + 1, // +1 for navigation
        itemBuilder: (context, index) {
          if (index == displaySections.length) {
            // Navigation footer
            return _buildNavigationFooter(theme, filteredSections);
          }

          final section = displaySections[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: RepaintBoundary(
                child: MarkdownBody(
                  key: ValueKey(section.id),
                  data: section.content,
                  selectable: true,
                  styleSheet: _styleSheet,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      if (href.startsWith('#')) {
                        _scrollToSection(href.substring(1));
                      } else {
                        launchUrl(Uri.parse(href));
                      }
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationFooter(ThemeData theme, List<_DocSection> allSections) {
    if (_selectedSectionId == null || _searchQuery.isNotEmpty) {
      return const SizedBox(height: 100);
    }

    final currentIndex = allSections.indexWhere((s) => s.id == _selectedSectionId);
    final prevSection = currentIndex > 0 ? allSections[currentIndex - 1] : null;
    final nextSection = currentIndex < allSections.length - 1 ? allSections[currentIndex + 1] : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Row(
            children: [
              if (prevSection != null)
                Expanded(
                  child: _NavigationCard(
                    title: prevSection.title,
                    isNext: false,
                    onTap: () => _scrollToSection(prevSection.id),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedSectionId = null),
                icon: const Icon(Icons.list),
                label: const Text('View All'),
              ),
              const SizedBox(width: 16),
              if (nextSection != null)
                Expanded(
                  child: _NavigationCard(
                    title: nextSection.title,
                    isNext: true,
                    onTap: () => _scrollToSection(nextSection.id),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFab() {
    return FloatingActionButton(
      onPressed: _showMobileSearch,
      backgroundColor: AppTheme.farmGreen,
      child: const Icon(Icons.search, color: Colors.white),
    );
  }

  void _showMobileSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search documentation...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _tableOfContents.length,
                    itemBuilder: (context, index) {
                      final item = _tableOfContents[index];
                      if (_searchQuery.isNotEmpty &&
                          !item.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        leading: Icon(
                          item.level == 2 ? Icons.article : Icons.subdirectory_arrow_right,
                          size: 20,
                        ),
                        title: Text(item.title),
                        onTap: () {
                          Navigator.pop(context);
                          _scrollToSection(item.anchor);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      h1: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h2: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h3: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h4: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      p: theme.textTheme.bodyLarge?.copyWith(
        height: 1.7,
        color: theme.colorScheme.onSurface,
      ),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      a: const TextStyle(
        color: AppTheme.farmGreen,
        decoration: TextDecoration.underline,
      ),
      code: GoogleFonts.firaCode(
        fontSize: 14,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.primary,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      listBullet: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.farmGreen),
      listIndent: 24,
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.farmGreen, width: 4)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      tableHead: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      tableBody: theme.textTheme.bodyMedium,
      tableBorder: TableBorder.all(color: theme.colorScheme.outlineVariant, width: 1),
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      h1Padding: const EdgeInsets.only(top: 32, bottom: 16),
      h2Padding: const EdgeInsets.only(top: 24, bottom: 12),
      h3Padding: const EdgeInsets.only(top: 20, bottom: 8),
      pPadding: const EdgeInsets.only(bottom: 12),
      blockSpacing: 16,
    );
  }
}

class _TableOfContentsItem {
  final String title;
  final String anchor;
  final int level;

  _TableOfContentsItem({
    required this.title,
    required this.anchor,
    required this.level,
  });
}

class _NavigationCard extends StatelessWidget {
  final String title;
  final bool isNext;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.title,
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNext) const Icon(Icons.arrow_back, size: 16, color: AppTheme.farmGreen),
                  if (!isNext) const SizedBox(width: 4),
                  Text(
                    isNext ? 'Next' : 'Previous',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.farmGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isNext) const SizedBox(width: 4),
                  if (isNext) const Icon(Icons.arrow_forward, size: 16, color: AppTheme.farmGreen),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: isNext ? TextAlign.end : TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
