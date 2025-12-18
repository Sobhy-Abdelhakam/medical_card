import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using a simple, clean background color for a more modern look.
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: EdgeInsets.only(bottom: 50.h),
        child: const CategoryGrid(),
      ),
    );
  }
}

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  _CategoryGridState createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  final List<Map<String, String>> categories = [
    {'title': 'المستشفيات', 'image': 'hospital.jpg', 'item': 'مستشفى'},
    {'title': 'مراكز الأشعة', 'image': 'scan.jpg', 'item': 'مركز أشعة'},
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
    // Using a responsive grid that adjusts the number of columns based on screen width.
    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.w, // Max width for each item
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        // Applying a staggered animation to each grid item.
        return AnimatedGridItem(
          index: index,
          child: _CategoryCard(category: category),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final Map<String, String> category;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior:
          Clip.antiAlias, // Ensures content respects the border radius
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowData(item: category['item']!),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with a FadeIn effect
            FadeInImage(
              placeholder: const AssetImage('assets/images/logo.jpg'),
              image: AssetImage('assets/images/${category['image']}'),
              fit: BoxFit.cover,
            ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.6, 1.0],
                ),
              ),
            ),
            // Positioned Title
            Positioned(
              bottom: 12.h,
              right: 12.w,
              left: 12.w,
              child: Text(
                category['title']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black54,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A wrapper widget to provide a staggered fade-in and slide-up animation.
class AnimatedGridItem extends StatefulWidget {
  final int index;
  final Widget child;

  const AnimatedGridItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  _AnimatedGridItemState createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<AnimatedGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Stagger the animation based on the item's index.
    final delay = Duration(milliseconds: widget.index * 80);
    Timer(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
