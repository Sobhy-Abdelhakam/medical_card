import 'package:flutter/material.dart';
import '../widget/color.dart';
import 'data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.primary],
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

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Map<String, String>> categories = [
    {'title': 'المستشفيات', 'image': 'hospital.jpg', 'item': 'مستشفى'},
    {'title': 'مراكز الأشعة', 'image': 'scan.jpg', 'item': 'مراكز الأشعة'},
    {'title': 'معامل التحاليل', 'image': 'medicaltests.jpg', 'item': 'معمل تحاليل'},
    {'title': 'مراكز متخصصة', 'image': 'clinic.jpg', 'item': 'مركز متخصص'},
    {'title': 'العيادات', 'image': 'clinic.jpg', 'item': 'عيادة'},
    {'title': 'الصيدليات', 'image': 'pharmacy.jpg', 'item': 'صيدلية'},
    {'title': 'العلاج الطبيعي', 'image': 'physical.jpg', 'item': 'علاج طبيعي'},
    {'title': 'البصريات', 'image': 'optometry.jpg', 'item': 'بصريات'},

  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowData(item: category['item']!),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.red.withOpacity(0.3),
            child: Card(
              elevation: 12,
              shadowColor: Colors.black,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0), // تقليل المسافة العلوية والسفلية
                    child: Text(
                      category['title']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
