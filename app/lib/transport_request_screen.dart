import 'package:flutter/material.dart';

import 'cargo_catalog.dart';

class TransportRequestScreen extends StatefulWidget {
  const TransportRequestScreen({super.key, this.catalog});
  final CargoCatalog? catalog;

  @override
  State<TransportRequestScreen> createState() => _TransportRequestScreenState();
}

class _TransportRequestScreenState extends State<TransportRequestScreen> {
  late Future<CargoCatalog> _catalog;
  CargoCategory? _category;
  CargoSupplier? _supplier;
  CargoGroup? _group;
  CargoProduct? _product;
  String? _location;
  final _origin = TextEditingController();
  final _details = TextEditingController();
  final _destination = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog == null
        ? CargoCatalog.load()
        : Future.value(widget.catalog);
  }

  @override
  void dispose() {
    _origin.dispose();
    _details.dispose();
    _destination.dispose();
    super.dispose();
  }

  String get _originLabel => _supplier == null
      ? ''
      : _supplier!.isRecipient
          ? _origin.text.trim()
          : '${_supplier!.name} · ${_supplier!.locations.isEmpty ? _origin.text.trim() : _location ?? ''}';

  bool get _complete =>
      _product != null &&
      (_supplier!.locations.isEmpty
          ? _origin.text.trim().isNotEmpty
          : _location != null) &&
      (!_product!.requiresDetails || _details.text.trim().isNotEmpty) &&
      _destination.text.trim().isNotEmpty;

  void _chooseSupplier(CargoSupplier supplier) {
    setState(() {
      if (_supplier?.isRecipient != supplier.isRecipient) _destination.clear();
      _supplier = supplier;
      _location =
          supplier.locations.length == 1 ? supplier.locations.single : null;
      _origin.clear();
      _details.clear();
      _group = supplier.groups.length == 1 ? supplier.groups.single : null;
      _product = _group?.products.length == 1 ? _group!.products.single : null;
    });
  }

  Future<void> _review() async {
    if (!_complete) return;
    final request = TransportRequest(
      category: _category!.name,
      supplier: _supplier!.name,
      group: _group!.name,
      product:
          _product!.requiresDetails ? _details.text.trim() : _product!.name,
      origin: _originLabel,
      destination: _supplier!.isRecipient
          ? '${_supplier!.name} · ${_destination.text.trim()}'
          : _destination.text.trim(),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운송 요청 확인'),
        content: Text('${request.category} / ${request.group}\n'
            '${request.product}\n\n${request.origin}\n→ ${request.destination}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('다시 선택')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('요청 내용 저장')),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context, request);
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) name,
    required ValueChanged<T?> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: DropdownButtonFormField<T>(
          key: ValueKey(
              '$label-${_category?.id}-${_supplier?.id}-${_group?.id}'),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          hint: const Text('선택해 주세요'),
          items: items
              .map((item) => DropdownMenuItem(
                  value: item, child: Text(name(item), maxLines: 2)))
              .toList(),
          onChanged: onChanged,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('운송 요청하기')),
        body: FutureBuilder<CargoCatalog>(
          future: _catalog,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: TextButton(
                onPressed: () => setState(() {
                  _catalog = CargoCatalog.load();
                }),
                child: const Text('화물 분류를 다시 불러오기'),
              ));
            }
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heading('운송할 화물 종류'),
                  const Text('화물 종류와 관련 업체를 고른 뒤 세부 품목을 선택해 주세요.'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final category in snapshot.data!.categories)
                      ChoiceChip(
                        label: Text(category.name),
                        selected: _category == category,
                        onSelected: (_) => setState(() {
                          _category = category;
                          _supplier = null;
                          _group = null;
                          _product = null;
                          _location = null;
                          _origin.clear();
                          _details.clear();
                          _destination.clear();
                        }),
                      ),
                  ]),
                  if (_category != null) ...[
                    Text(_category!.description),
                    _heading('관련 업체·품목'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final supplier in _category!.suppliers)
                        ChoiceChip(
                            label: Text(supplier.name),
                            selected: _supplier == supplier,
                            onSelected: (_) => _chooseSupplier(supplier)),
                    ]),
                  ],
                  if (_supplier != null) ...[
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_supplier!.description)),
                    if (_supplier!.locations.isEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextField(
                            key: ValueKey('origin-${_supplier!.id}'),
                            controller: _origin,
                            maxLength: 200,
                            decoration: const InputDecoration(
                                labelText: '출하자·상차지',
                                border: OutlineInputBorder()),
                            onChanged: (_) => setState(() {}),
                          ))
                    else
                      _dropdown<String>(
                          label: '출하 공장',
                          value: _location,
                          items: _supplier!.locations,
                          name: (value) => value,
                          onChanged: (value) => setState(() {
                                _location = value;
                              })),
                    _dropdown<CargoGroup>(
                        label: '세부 분류',
                        value: _group,
                        items: _supplier!.groups,
                        name: (value) => value.name,
                        onChanged: (value) => setState(() {
                              _group = value;
                              _product = value?.products.length == 1
                                  ? value!.products.single
                                  : null;
                              _details.clear();
                            })),
                    if (_group != null) ...[
                      _dropdown<CargoProduct>(
                          label: '운송 품목',
                          value: _product,
                          items: _group!.products,
                          name: (value) => value.name,
                          onChanged: (value) => setState(() {
                                _product = value;
                                _details.clear();
                              })),
                      if (_group!.note != null) Text(_group!.note!),
                    ],
                    if (_product?.note != null) Text(_product!.note!),
                    if (_product?.requiresDetails == true)
                      TextField(
                          controller: _details,
                          maxLength: 120,
                          decoration:
                              const InputDecoration(labelText: '실제 원료 품목'),
                          onChanged: (_) => setState(() {})),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                      controller: _destination,
                      maxLength: 200,
                      decoration: InputDecoration(
                          labelText: '하차지',
                          border: const OutlineInputBorder(),
                          hintText: _supplier?.isRecipient == true
                              ? 'SPC 납품 공장·거점명'
                              : '도착할 주소나 거점명'),
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  if (_complete)
                    Text(
                        '${_category!.name} / ${_product!.requiresDetails ? _details.text.trim() : _product!.name}\n$_originLabel'),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: _complete ? _review : null,
                      child: const Text('선택한 화물 확인')),
                  const SizedBox(height: 8),
                  const Text('현재 앱에서 요청 내용을 확인하고 저장합니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      );
}
