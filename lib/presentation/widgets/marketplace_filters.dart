import 'package:flutter/material.dart';

import '../../models/community_models.dart';
import '../screens/splash_screen.dart';

enum MarketplaceSort { newest, priceLow, priceHigh }

class MarketplaceFilters {
  const MarketplaceFilters({
    this.minimumPrice,
    this.maximumPrice,
    this.rental,
    this.condition,
    this.availability,
    this.sort = MarketplaceSort.newest,
  });

  final double? minimumPrice;
  final double? maximumPrice;
  final bool? rental;
  final String? condition;
  final DateTimeRange? availability;
  final MarketplaceSort sort;

  bool get isActive =>
      minimumPrice != null ||
      maximumPrice != null ||
      rental != null ||
      condition != null ||
      availability != null ||
      sort != MarketplaceSort.newest;
}

List<MarketplaceListing> filterMarketplaceListings(
  Iterable<MarketplaceListing> source, {
  required MarketplaceFilters filters,
  String query = '',
  bool? forcedRental,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final items = source.where((item) {
    if (forcedRental != null && item.isRental != forcedRental) return false;
    if (filters.rental != null && item.isRental != filters.rental) return false;
    if (filters.minimumPrice != null && item.price < filters.minimumPrice!) {
      return false;
    }
    if (filters.maximumPrice != null && item.price > filters.maximumPrice!) {
      return false;
    }
    if (filters.condition != null && item.condition != filters.condition) {
      return false;
    }
    final availability = filters.availability;
    if (availability != null) {
      if (!item.isRental ||
          item.availableFrom == null ||
          item.availableTo == null ||
          item.availableFrom!.isAfter(availability.end) ||
          item.availableTo!.isBefore(availability.start)) {
        return false;
      }
    }
    if (normalizedQuery.isEmpty) return true;
    return <String>[
      item.title,
      item.category,
      item.description,
      item.condition,
      item.sellerName,
      item.price.toString(),
      item.priceLabel,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }).toList();

  items.sort(
    (a, b) => switch (filters.sort) {
      MarketplaceSort.priceLow => a.price.compareTo(b.price),
      MarketplaceSort.priceHigh => b.price.compareTo(a.price),
      MarketplaceSort.newest => (b.createdAt ?? DateTime(1970)).compareTo(
        a.createdAt ?? DateTime(1970),
      ),
    },
  );
  return items;
}

Future<MarketplaceFilters?> showMarketplaceFilters(
  BuildContext context, {
  required MarketplaceFilters current,
  bool allowListingType = true,
}) => showModalBottomSheet<MarketplaceFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _MarketplaceFilterSheet(
    current: current,
    allowListingType: allowListingType,
  ),
);

class _MarketplaceFilterSheet extends StatefulWidget {
  const _MarketplaceFilterSheet({
    required this.current,
    required this.allowListingType,
  });

  final MarketplaceFilters current;
  final bool allowListingType;

  @override
  State<_MarketplaceFilterSheet> createState() =>
      _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState extends State<_MarketplaceFilterSheet> {
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  bool? _rental;
  String? _condition;
  DateTimeRange? _availability;
  late MarketplaceSort _sort;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _minimum = TextEditingController(text: current.minimumPrice?.toString());
    _maximum = TextEditingController(text: current.maximumPrice?.toString());
    _rental = current.rental;
    _condition = current.condition;
    _availability = current.availability;
    _sort = current.sort;
  }

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  Future<void> _pickAvailability() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
      initialDateRange: _availability,
    );
    if (range != null && mounted) setState(() => _availability = range);
  }

  void _apply() {
    final minimum = double.tryParse(_minimum.text.trim());
    final maximum = double.tryParse(_maximum.text.trim());
    if (minimum != null && maximum != null && minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum price cannot exceed maximum.')),
      );
      return;
    }
    Navigator.pop(
      context,
      MarketplaceFilters(
        minimumPrice: minimum,
        maximumPrice: maximum,
        rental: widget.allowListingType ? _rental : null,
        condition: _condition,
        availability: _availability,
        sort: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filter listings',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, const MarketplaceFilters()),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Price range',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _priceField(_minimum, 'Minimum KSh')),
              const SizedBox(width: 10),
              Expanded(child: _priceField(_maximum, 'Maximum KSh')),
            ],
          ),
          if (widget.allowListingType) ...[
            const SizedBox(height: 18),
            const Text(
              'Listing type',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: false, label: Text('Sale')),
                ButtonSegment(value: true, label: Text('Rental')),
              ],
              selected: {_rental},
              onSelectionChanged: (value) =>
                  setState(() => _rental = value.first),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Condition',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _condition,
            decoration: _inputDecoration('Any condition'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any condition')),
              DropdownMenuItem(value: 'New', child: Text('New')),
              DropdownMenuItem(value: 'Like New', child: Text('Like New')),
              DropdownMenuItem(value: 'Used', child: Text('Used')),
            ],
            onChanged: (value) => setState(() => _condition = value),
          ),
          const SizedBox(height: 18),
          const Text(
            'Rental availability',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ListTile(
            onTap: _pickAvailability,
            tileColor: const Color(0xFFF4F7F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: const Icon(Icons.date_range_outlined, color: primaryGreen),
            title: Text(
              _availability == null
                  ? 'Any dates'
                  : '${_availability!.start.day}/${_availability!.start.month}/${_availability!.start.year} – ${_availability!.end.day}/${_availability!.end.month}/${_availability!.end.year}',
            ),
            trailing: _availability == null
                ? const Icon(Icons.chevron_right_rounded)
                : IconButton(
                    onPressed: () => setState(() => _availability = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          const SizedBox(height: 18),
          const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<MarketplaceSort>(
            initialValue: _sort,
            decoration: _inputDecoration('Sort listings'),
            items: const [
              DropdownMenuItem(
                value: MarketplaceSort.newest,
                child: Text('Newest first'),
              ),
              DropdownMenuItem(
                value: MarketplaceSort.priceLow,
                child: Text('Lowest price'),
              ),
              DropdownMenuItem(
                value: MarketplaceSort.priceHigh,
                child: Text('Highest price'),
              ),
            ],
            onChanged: (value) => setState(() => _sort = value!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Apply filters'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _priceField(TextEditingController controller, String hint) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _inputDecoration(hint),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF4F7F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primaryGreen),
    ),
  );
}
