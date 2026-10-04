import 'package:flutter/material.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends State<DestinationSearchScreen> {
  final TextEditingController searchController =
  TextEditingController();

  final List<String> destinations = [
    'Ahmedabad',
    'Amritsar',
    'Goa',
    'Jaipur',
    'Manali',
    'Mumbai',
    'New Delhi',
    'Shimla',
    'Udaipur',
    'Varanasi',
  ];

  List<String> filteredDestinations = [];

  @override
  void initState() {
    super.initState();
    filteredDestinations = destinations;
  }

  void searchDestination(String value) {
    setState(() {
      filteredDestinations = destinations
          .where(
            (destination) => destination
            .toLowerCase()
            .contains(value.toLowerCase()),
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Destinations'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: searchDestination,

              decoration: InputDecoration(
                hintText: 'Search destination...',
                prefixIcon: const Icon(Icons.search),

                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchDestination('');
                  },
                )
                    : null,

                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: filteredDestinations.isEmpty
                  ? const Center(
                child: Text(
                  'No destinations found',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: filteredDestinations.length,

                itemBuilder: (context, index) {
                  final destination =
                  filteredDestinations[index];

                  return Card(
                    margin:
                    const EdgeInsets.only(bottom: 10),

                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                      ),

                      title: Text(
                        destination,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),

                      onTap: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              '$destination selected',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}