// lib/screens/olay_tahtasi_screen.dart

import 'dart:convert'; // JSON formatlama için
import 'dart:html' as html; // Dosya indirme için

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../services/supabase_service.dart';
import '../widgets/add_relationship_dialog.dart';
import '../widgets/node_editor_dialog.dart';
import '../widgets/relationship_editor_dialog.dart'; // Yeni ilişki editörünü import ettik

class OlayTahtasiScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCase;

  const OlayTahtasiScreen({super.key, required this.selectedCase});

  @override
  State<OlayTahtasiScreen> createState() => _OlayTahtasiScreenState();
}

class _OlayTahtasiScreenState extends State<OlayTahtasiScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Graph graph = Graph();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _nodes = [];
  List<Map<String, dynamic>> _relationships = [];
  Node? _sourceNodeForEdge;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // ... Öncekiyle aynı ...
    if (!mounted) return;
    graph.nodes.clear();
    graph.edges.clear();
    setState(() { _isLoading = true; });

    final nodesData = await _supabaseService.fetchNodesForCase(widget.selectedCase['id']);
    final relationshipsData = await _supabaseService.fetchRelationshipsForCase(widget.selectedCase['id']);

    for (var nodeData in nodesData) {
      graph.addNode(Node.Id(nodeData['id']));
    }
    
    for (var relationshipData in relationshipsData) {
      final sourceNode = graph.getNodeUsingId(relationshipData['source_node_id']);
      final targetNode = graph.getNodeUsingId(relationshipData['target_node_id']);
      if (sourceNode != null && targetNode != null) {
        graph.addEdge(sourceNode, targetNode);
      }
    }

    if (!mounted) return;
    setState(() {
      _nodes = nodesData;
      _relationships = relationshipsData;
      _isLoading = false;
    });
  }

  Future<void> _handleExportCase() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vaka verileri hazırlanıyor, lütfen bekleyin...')),
    );

    try {
      final fullCaseData = await _supabaseService.getFullCaseDataForExport(widget.selectedCase['id']);
      
      // JSON'ı okunaklı (girintili) bir şekilde formatla
      const jsonEncoder = JsonEncoder.withIndent('  ');
      final prettyJson = jsonEncoder.convert(fullCaseData);

      // Web üzerinde dosya indirme işlemini yap
      final bytes = utf8.encode(prettyJson);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'case_${widget.selectedCase['id']}.json'; // Dosya adı

      html.document.body!.append(anchor);
      anchor.click(); // İndirmeyi tetikle
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaka başarıyla dışa aktarıldı!'), backgroundColor: Colors.green),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Düzenleme ve Ekleme Fonksiyonları ---

  Future<void> _handleAddNewNode(String nodeType) async { /* ... Öncekiyle aynı ... */ 
    final result = await showNodeEditorDialog(context: context, nodeType: nodeType, allNodes: _nodes, allRelationships: _relationships);
    if (result != null) {
      await _supabaseService.addNode(caseId: widget.selectedCase['id'], nodeType: nodeType, displayData: result['display_data']!, engineData: result['engine_data']!,);
      await _loadData();
    }
  }

  Future<void> _handleEditNode(Map<String, dynamic> nodeData) async { /* ... Öncekiyle aynı ... */
    final result = await showNodeEditorDialog(
      context: context,
      nodeType: nodeData['node_type'],
      initialData: nodeData,
      allNodes: _nodes,
      allRelationships: _relationships,
    );
    if (result != null) {
      await _supabaseService.updateNode(
        nodeId: nodeData['id'],
        data: {
          'display_data': result['display_data']!,
          'engine_data': result['engine_data']!,
          'unlock_conditions': result['unlock_conditions']!,
        },
      );
       await _loadData();
    }
  }

  Future<void> _handleCreateRelationship(Node targetNode) async { /* ... Öncekiyle aynı ... */
    if (_sourceNodeForEdge == null) return;
    final sourceNodeData = _nodes.firstWhere((n) => n['id'] == _sourceNodeForEdge!.key!.value);
    final targetNodeData = _nodes.firstWhere((n) => n['id'] == targetNode.key!.value);
    final availableTypes = _getValidRelationshipTypes(sourceNodeData['node_type'], targetNodeData['node_type']);
    if (availableTypes.isEmpty) {
      // DÜZELTME: BuildContext'i async boşluklarından sonra kullanmadan önce kontrol et
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu iki ikon arasında mantıklı bir ilişki kurulamaz.'), backgroundColor: Colors.red));
      setState(() { _sourceNodeForEdge = null; });
      return;
    }
    final selectedType = await showAddRelationshipDialog(context: context, availableTypes: availableTypes);
    if (selectedType != null) {
      await _supabaseService.addRelationship(caseId: widget.selectedCase['id'], sourceNodeId: sourceNodeData['id'], targetNodeId: targetNodeData['id'], relationshipType: selectedType,);
      await _loadData();
    }
    setState(() { _sourceNodeForEdge = null; });
  }

  // DEĞİŞİKLİK: Yeni ilişki düzenleme fonksiyonu
  Future<void> _handleEditRelationship(Edge edge) async {
    // Tıklanan çizgiye ait ilişki verisini bul
    final relationshipData = _relationships.firstWhere(
      (r) => r['source_node_id'] == edge.source.key!.value && r['target_node_id'] == edge.destination.key!.value
    );

    final result = await showRelationshipEditorDialog(
      context: context, 
      relationshipType: relationshipData['relationship_type'],
      initialData: relationshipData['relationship_data'],
    );

    if (result != null) {
      await _supabaseService.updateRelationship(
        relationshipId: relationshipData['id'], 
        relationshipData: result,
      );
      // Veriyi anında ekranda güncellemek için local state'i de güncelleyebiliriz veya _loadData() çağırabiliriz.
      // Şimdilik en temizi _loadData().
      await _loadData();
    }
  }

  List<String> _getValidRelationshipTypes(String sourceType, String targetType) { /* ... Öncekiyle aynı ... */
    if (sourceType == 'character' && targetType == 'character') return ['Tanıyor', 'Akraba', 'Düşman', 'Sevgili', 'İş Arkadaşı'];
    if (sourceType == 'character' && targetType == 'location') return ['Sahibi', 'Çalışanı', 'Ziyaret Etti', 'Hakkında Bilgisi Var'];
    if (sourceType == 'evidence' && targetType == 'location') return ['İçinde Bulunuyor', 'İçinde Saklı'];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedCase['title']} - Olay Tahtası'),
        actions: [
          // DEĞİŞİKLİK: Dışa Aktar Butonu
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Vakayı JSON Olarak Dışa Aktar',
            onPressed: _handleExportCase,
          ),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showMenu(
            context: context,
            position: const RelativeRect.fromLTRB(100, 100, 0, 0), 
            items: [
              PopupMenuItem(value: 'character', child: const Text('Yeni Şahıs')),
              PopupMenuItem(value: 'location', child: const Text('Yeni Mekan')),
              PopupMenuItem(value: 'evidence', child: const Text('Yeni Kanıt')),
            ],
          ).then((value) {
            if (value != null) {
              _handleAddNewNode(value);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(1000),
              minScale: 0.05,
              maxScale: 2.0,
              child: GraphView(
                graph: graph,
                algorithm: FruchtermanReingoldAlgorithm(iterations: 200),
                paint: Paint()..color = _sourceNodeForEdge != null ? Colors.amber.shade700 : Colors.grey.shade400..strokeWidth = 2..style = PaintingStyle.stroke,
                builder: (Node node) {
                  final nodeData = _nodes.firstWhere((n) => n['id'] == node.key!.value);
                  return _buildNodeWidget(node, nodeData);
                },
              ),
            ),
    );
  }

  Widget _buildNodeWidget(Node node, Map<String, dynamic> nodeData) {
    final nodeType = nodeData['node_type'];
    final displayName = nodeData['display_data']['name'] ?? 'İsimsiz';
    final isSelectedForEdge = _sourceNodeForEdge == node;

    IconData icon; Color color;
    switch (nodeType) {
      case 'character': icon = Icons.person_search; color = Colors.blue.shade400; break;
      case 'location': icon = Icons.location_city; color = Colors.orange.shade400; break;
      case 'evidence': icon = Icons.description_outlined; color = Colors.green.shade400; break;
      default: icon = Icons.help_outline; color = Colors.grey.shade400;
    }

    return GestureDetector(
      onLongPress: () => setState(() { _sourceNodeForEdge = node; }),
      onTap: () {
        if (_sourceNodeForEdge != null) {
          if (_sourceNodeForEdge != node) { _handleCreateRelationship(node); }
          else { setState(() { _sourceNodeForEdge = null; }); }
        } else {
          _handleEditNode(nodeData);
        }
      },
      child: Tooltip(
        message: "$nodeType: $displayName",
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSelectedForEdge ? Colors.amber.shade700 : Colors.white.withOpacity(0.5), width: isSelectedForEdge ? 4 : 1),
            boxShadow: [
              BoxShadow(
                // DÜZELTME: withOpacity yerine withAlpha kullanımı
                color: isSelectedForEdge ? Colors.amber.withAlpha(180) : Colors.black.withAlpha(75),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      )
    );
  }
}