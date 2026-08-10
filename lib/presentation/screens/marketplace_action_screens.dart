import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community_models.dart';
import '../../state/auth_providers.dart';
import 'marketplace_tabs.dart';
import 'order_profile_screens.dart';
import 'splash_screen.dart';

class BuyScreen extends ConsumerWidget {
  const BuyScreen({super.key, required this.apartment});

  final Apartment apartment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Buy', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items to buy...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MarketplaceListing>>(
              stream: ref
                  .read(communityServiceProvider)
                  .watchApartmentListings(apartment.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  );
                }
                final listings = (snapshot.data ?? const [])
                    .where((item) => !item.isRental)
                    .toList();
                if (listings.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    message: 'No items are for sale in this apartment yet.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  itemCount: listings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFE0E4E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F2EB),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: listing.imageUrls.isEmpty
                              ? const Icon(
                                  Icons.inventory_2_outlined,
                                  color: primaryGreen,
                                  size: 34,
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Image.network(
                                    listing.imageUrls.first,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        title: Text(
                          listing.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${listing.priceLabel}\n${listing.condition} • ${listing.sellerName}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReservationScreen(
                              apartment: apartment,
                              listing: listing,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({
    super.key,
    required this.apartment,
    required this.isRental,
  });

  final Apartment apartment;
  final bool isRental;

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _deposit = TextEditingController();
  final _description = TextEditingController();
  final _houseNumber = TextEditingController();
  final _images = <({String name, Uint8List bytes})>[];
  String _category = 'Furniture';
  String _condition = 'Used';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _deposit.dispose();
    _description.dispose();
    _houseNumber.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item photo.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(communityServiceProvider);
      final imageUrls = await service.uploadListingImages(
        apartment: widget.apartment,
        images: _images,
      );
      await service.createListing(
        apartment: widget.apartment,
        title: _title.text,
        category: _category,
        condition: _condition,
        description: _description.text,
        price: double.parse(_price.text.trim()),
        isRental: widget.isRental,
        securityDeposit: double.tryParse(_deposit.text.trim()),
        pickupHouseNumber: _houseNumber.text,
        imageUrls: imageUrls,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your listing is now live.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not publish this listing.')),
      );
    }
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _images.length;
    if (remaining <= 0) return;
    List<XFile> selected;
    try {
      selected = await ImagePicker().pickMultiImage(
        imageQuality: 82,
        limit: remaining,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final needsRestart = error.code == 'channel-error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            needsRestart
                ? 'Image access was just installed. Fully stop and reopen the app, then try again.'
                : 'Could not open your photo library. Please check photo permissions.',
          ),
        ),
      );
      return;
    }
    if (selected.isEmpty) return;
    final additions = <({String name, Uint8List bytes})>[];
    for (final image in selected.take(remaining)) {
      additions.add((name: image.name, bytes: await image.readAsBytes()));
    }
    if (mounted) setState(() => _images.addAll(additions));
  }

  @override
  Widget build(BuildContext context) {
    final rental = widget.isRental;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          rental ? 'Rent an Item' : 'Sell an Item',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Draft saved on this device.')),
            ),
            child: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Item photos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${_images.length}/5',
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Add up to 5 clear photos.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + (_images.length < 5 ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return InkWell(
                      key: const Key('addListingPhotosButton'),
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        width: 94,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F5),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFFD8DEDA)),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: primaryGreen,
                          size: 34,
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(
                          _images[index].bytes,
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 3,
                        top: 3,
                        child: InkWell(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Listing details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _FormFieldLabel('Item Title'),
            TextFormField(
              key: const Key('listingTitleField'),
              controller: _title,
              decoration: _decoration('e.g. 3 Seater Sofa'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an item title'
                  : null,
            ),
            const SizedBox(height: 16),
            _FormFieldLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _decoration(''),
              items:
                  const [
                        'Furniture',
                        'Electronics',
                        'Appliances',
                        'Gaming',
                        'Baby Items',
                        'Other',
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            _FormFieldLabel('Condition'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'New', label: Text('New')),
                ButtonSegment(value: 'Like New', label: Text('Like New')),
                ButtonSegment(value: 'Used', label: Text('Used')),
              ],
              selected: {_condition},
              onSelectionChanged: (values) =>
                  setState(() => _condition = values.first),
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FormFieldLabel(
              rental ? 'Daily Rental Price (KSh)' : 'Price (KSh)',
            ),
            TextFormField(
              key: const Key('listingPriceField'),
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: _decoration('Enter your price'),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Enter a valid price'
                  : null,
            ),
            if (rental) ...[
              const SizedBox(height: 16),
              _FormFieldLabel('Security Deposit (optional)'),
              TextFormField(
                controller: _deposit,
                keyboardType: TextInputType.number,
                decoration: _decoration('e.g. 1000'),
              ),
            ],
            const SizedBox(height: 16),
            _FormFieldLabel('Description'),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 6,
              decoration: _decoration('Describe the item and pickup details'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Add a short description'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: const Color(0xFFF4F7F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              leading: const Icon(
                Icons.location_on_outlined,
                color: primaryGreen,
              ),
              title: Text(widget.apartment.name),
              subtitle: const Text('Verified property'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Private pickup details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _FormFieldLabel('House / Unit Number'),
            TextFormField(
              key: const Key('pickupHouseNumberField'),
              controller: _houseNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('e.g. Block A, House 12'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the pickup house or unit number'
                  : null,
            ),
            const SizedBox(height: 6),
            const Text(
              'Kept private from the public listing and used for pickup coordination.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('publishListingButton'),
                onPressed: _saving ? null : _publish,
                style: FilledButton.styleFrom(backgroundColor: primaryGreen),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publish Listing',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({
    super.key,
    required this.apartment,
    required this.listing,
  });

  final Apartment apartment;
  final MarketplaceListing listing;

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  bool _placing = false;

  Future<void> _messageSeller() async {
    try {
      final chatId = await ref
          .read(communityServiceProvider)
          .getOrCreateChat(
            apartment: widget.apartment,
            listing: widget.listing,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadScreen(
            apartment: widget.apartment,
            chatId: chatId,
            otherName: widget.listing.sellerName,
            listingTitle: widget.listing.title,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this conversation.')),
      );
    }
  }

  Future<void> _reserveItem() async {
    setState(() => _placing = true);
    try {
      final id = await ref
          .read(communityServiceProvider)
          .createReservation(
            apartment: widget.apartment,
            listing: widget.listing,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReservationStatusScreen(
            apartment: widget.apartment,
            reservationId: id,
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reserve this item.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        'Reserve Item',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: widget.listing.imageUrls.isEmpty
                  ? const Icon(Icons.inventory_2_outlined, color: primaryGreen)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        widget.listing.imageUrls.first,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
              title: Text(widget.listing.title),
              subtitle: Text('by ${widget.listing.sellerName}'),
              trailing: Text(
                widget.listing.priceLabel,
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _messageSeller,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Message Seller'),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Pickup', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ListTile(
            tileColor: const Color(0xFFF4F7F5),
            leading: const Icon(
              Icons.location_on_outlined,
              color: primaryGreen,
            ),
            title: Text('Pickup at ${widget.apartment.name}'),
            subtitle: const Text(
              'Arrange the exact pickup time and unit directly with the seller in chat.',
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Agreed price',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: widget.listing.isRental ? 'Daily price' : 'Asking price',
            value: widget.listing.priceLabel,
            strong: true,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primaryGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Doorstep Market does not collect or hold payment. Agree on payment and inspect the item directly with the seller at pickup.',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('reserveItemButton'),
              onPressed: _placing ? null : _reserveItem,
              style: FilledButton.styleFrom(backgroundColor: primaryGreen),
              child: _placing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirm Reservation',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: primaryGreen,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Item Reserved',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Reservation #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            color: strong ? primaryGreen : null,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

InputDecoration _decoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: const BorderSide(color: Color(0xFFDDE3DF)),
  ),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: const BorderSide(color: primaryGreen, width: 1.5),
  ),
);

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 56),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
