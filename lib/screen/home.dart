import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PinkCardsPage extends StatelessWidget {
  const PinkCardsPage({super.key});

  // قائمة بالصفحات المتاحة
  final List<Map<String, dynamic>> pages = const [
    {
      'title': 'Page 1',
      'icon': Icons.pageview,
      'route': '/page1',
      'color': Colors.pinkAccent,
    },
    {
      'title': 'Page 2',
      'icon': Icons.pages,
      'route': '/page2',
      'color': Colors.pink,
    },
    {
      'title': 'Page 3',
      'icon': Icons.article,
      'route': '/page3',
      'color': Colors.pink,
    },
    {
      'title': 'Page 4',
      'icon': Icons.description,
      'route': '/page4',
      'color': Colors.pink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pink Cards Navigation'),
        backgroundColor: Colors.pink[200],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: OrientationBuilder(
            builder: (context, orientation) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isLandscape ? 3 : 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: isLandscape ? 1.2 : 1.0,
                ),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPinkCard(
                    context,
                    pages[index]['title'],
                    pages[index]['icon'],
                    pages[index]['route'],
                    pages[index]['color'],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPinkCard(
      BuildContext context,
      String title,
      IconData icon,
      String routeName,
      Color color,
      ) {
    return Card(
      elevation: 6.w,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.w),
      ),
      shadowColor: Colors.pink.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.w),
        onTap: () {
          Navigator.pushNamed(context, routeName);
        },
        onHover: (hovering) {
          // يمكن إضافة تأثيرات عند hover إذا لزم الأمر
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.w),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40.w,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}