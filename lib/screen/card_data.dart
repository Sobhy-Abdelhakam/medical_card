import 'package:flutter/material.dart';
import 'data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Theme.of(context).colorScheme.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const SingleChildScrollView(
          child: AnimatedCard(),
        ),
      ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  const AnimatedCard({super.key});

  @override
  _AnimatedCardState createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  final List<Map<String, String>> categories = [
    {'title': 'المستشفيات', 'image': 'hospital.jpg', 'item': 'مستشفى'},
    {'title': 'مراكز الأشعة', 'image': 'scan.jpg', 'item': 'مراكز الأشعة'},
    {
      'title': 'معامل التحاليل',
      'image': 'medicaltests.jpg',
      'item': 'معمل تحاليل'
    },
    {'title': 'مراكز متخصصة', 'image': 'clinic.jpg', 'item': 'مركز متخصص'},
    {'title': 'العيادات', 'image': 'clinic.jpg', 'item': 'عيادة'},
    {'title': 'الصيدليات', 'image': 'pharmacy.jpg', 'item': 'صيدلية'},
    {'title': 'العلاج الطبيعي', 'image': 'physical.jpg', 'item': 'علاج طبيعي'},
    {'title': 'البصريات', 'image': 'optometry.jpg', 'item': 'بصريات'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowData(item: category['item']!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: FadeInImage(
                    placeholder: const AssetImage('assets/images/logo.jpg'),
                    image: AssetImage('assets/images/${category['image']}'),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 10.0), // تقليل المسافة العلوية والسفلية
                  child: Text(
                    category['title']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
