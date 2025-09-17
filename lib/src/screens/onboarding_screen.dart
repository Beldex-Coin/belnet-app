
import 'package:belnet_mobile/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});



 _goToHome(BuildContext context)async{
     final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isFirstLaunch', false);
                              Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) =>  MainBottomNavbar()) ); 
 }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
       extendBody: true,
       body:  Stack(
         children: [
           Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/dark_theme/Dark_background.png'), // <-- your image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Center(
                      child: Column(
                        children: [
                          Spacer(),
                          Column(
                            children: [
                              SvgPicture.asset('assets/images/belnet_logo_dark_theme.svg'),
                              Text('1.3.2')
                            ],
                          ),
                          Spacer(flex: 5,),
                          Container(
                           // height: MediaQuery.of(context).size.height*0.50/3,
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Color(0xffACACAC),width: 0.5)
                            ),
                            child: SvgPicture.asset('assets/images/dark_theme/Fast & Secure dVPN.svg',height: 120,fit: BoxFit.cover,)
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height*0.20/3),
                          //SizedBox(height: 15,),
                          GestureDetector(
                            onTap:()=> _goToHome(context),
                            child: GlassContainer.clearGlass(
                              height: 60,
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              padding: EdgeInsets.all(15),
                               color: Color(0xff3A4962).withOpacity(0.01), //s.white.withOpacity(0.02),
                              borderColor: Color(0xff00DC00),
                              borderRadius:BorderRadius.circular(10),
                                child: Center(child: Text('Next',style: TextStyle(color: Color(0xff00DC00),fontSize: 20,fontWeight: FontWeight.w700),)),
                              ),
                          ),
                          SizedBox(height: 15)
                        ],
                      ),
                    ),
                  )
         ],
       ),
    );
  }
}