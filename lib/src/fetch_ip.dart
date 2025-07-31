// // import 'package:http/http.dart' as http;
// // import 'dart:convert';

// // Future<String> getPublicIp() async {
// //   final response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
// //   if (response.statusCode == 200) {
// //     final data = json.decode(response.body);
// //     return data['ip'];
// //   } else {
// //     throw Exception('Failed to get IP');
// //   }
// // }

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// class GlowingBouncingImage extends StatefulWidget {
//   @override
//   _GlowingBouncingImageState createState() => _GlowingBouncingImageState();
// }

// class _GlowingBouncingImageState extends State<GlowingBouncingImage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _glowAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration( milliseconds: 50),
//       vsync: this,
//     )..repeat(reverse: true);

//     _glowAnimation = Tween<double>(begin: 80, end: 100).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.bounceInOut,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           Center(
//             child: AnimatedBuilder(
//               animation: _glowAnimation,
//               builder: (context, child) {
//                 return Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Glowing bouncing background
//                     Container(
//                       width: _glowAnimation.value,
//                       height: _glowAnimation.value,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.red.withOpacity(0.4),
//                             blurRadius: 10,
//                             spreadRadius: 3,
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Front blurred transparent round image
//                     ClipOval(
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
//                         child: Container(
//                           width: 200,
//                           height: 200,
//                           color: Colors.white.withOpacity(0.1),
//                           child: SvgPicture.asset(
//                             'assets/images/light_theme/disconnect.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//            Center(
//             child: AnimatedBuilder(
//               animation: _glowAnimation,
//               builder: (context, child) {
//                 return Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Glowing bouncing background
//                     Container(
//                       width: _glowAnimation.value,
//                       height: _glowAnimation.value,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Color(0xFF00DC00).withOpacity(0.4),
//                             blurRadius: 10,
//                             spreadRadius: 3,
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Front blurred transparent round image
//                     ClipOval(
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
//                         child: Container(
//                           width: 200,
//                           height: 200,
//                           color: Colors.white.withOpacity(0.1),
//                           child: SvgPicture.asset(
//                             'assets/images/light_theme/connect.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
