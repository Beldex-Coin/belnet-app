import 'package:belnet_mobile/src/app_list.dart';
import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/widget/aboutpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {



 @override
  void initState() {
    super.initState();
    // Refresh app list in the background when screen opens
    AppCache.instance.loadApps().then((_) {
      if (mounted) setState(() {});
    });
  }





  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
     final allApps = AppCache.instance.apps;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text( 'Settings', style: TextStyle(fontFamily: 'Poppins',fontSize: 18),),
            centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left:  8.0),
          child: Row(
                      children: [
                       Image.asset('assets/images/belnet_ic.png',height: 28,color:Colors.white),
                       Text('Belnet',style: TextStyle(fontFamily: 'Poppins',),),
                       
                      ],
                    
                    ),
        ),
        leadingWidth: 100,
        actions: [
         provider.currentView == SettingsView.splitTunneling ? Container(
          padding: EdgeInsets.all(7),
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
           borderRadius: BorderRadius.circular(8)
          ),
          child: SvgPicture.asset('assets/images/dark_theme/light_Theme.svg')): SizedBox.shrink()
        ],
        bottom: PreferredSize(
          preferredSize:Size.fromHeight(provider.currentView == SettingsView.splitTunneling ? 42 :20), // height of the bottom area
        child:provider.currentView == SettingsView.splitTunneling ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal:  8.0,vertical: 8),
                          child: GestureDetector(
                            onTap: provider.showGeneral,
                            child: Row(
                              children: [
                                SvgPicture.asset('assets/images/dark_theme/back_split_tunnel.svg'),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal:  8.0),
                                  child: Text('Split Tunneling',style: TextStyle(fontFamily: 'Poppins',fontSize: 16),),
                                )
                              ],
                            ),
                          ),
                        ): Text(''),
        
        ),
      ),
      body: Container(

        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: provider.currentView == SettingsView.general
              ? GeneralSettingsView(onSplitTunnelingTap: provider.showSplitTunneling)
              : SplitTunnelingScreen(allApps: allApps,) //const SplitTunnelingView(),
        ),
      ),
    );

  }
}


// General Settings View
class GeneralSettingsView extends StatefulWidget {
  final VoidCallback onSplitTunnelingTap;

  const GeneralSettingsView({super.key, required this.onSplitTunnelingTap});

  @override
  State<GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<GeneralSettingsView> {

  
   bool _isSharing = false;
   bool _isReporting = false;


  @override
  Widget build(BuildContext context) {
        final provider = context.read<SettingsProvider>();
        final appSelectingProvider = Provider.of<AppSelectingProvider>(context);

    return Column(
      children: [

         GlassContainer.clearGlass(
              height: MediaQuery.of(context).size.height*2.23/3,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal:10),
              blur: 4.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        borderColor: Color(0xffA1A1AF),
        borderWidth: 0.2,
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General',style: TextStyle(
              fontFamily: 'Poppins',fontSize: 15,color: Color(0xffA1A1AF),fontWeight: FontWeight.w400
            ),),


GlassContainer.clearGlass(
  height: 50,width: double.infinity,
   blur: 21.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        borderColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 10),
 child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        SvgPicture.asset('assets/images/dark_theme/light_Themes.svg'),
        Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text('Dark Theme',style: TextStyle(fontFamily: 'Poppins',fontSize: 14),))
      ],
    ),
    FlutterSwitch(
              width: 45.0,
              height: 24.0,
              toggleSize: 19.0,
              value: true,//showSystemApps,
              borderRadius: 30.0,
              padding: 2.0,
              //activeIcon: SvgPicture.asset('assets/images/'),
              activeToggleColor: Color(0xff00DC00), // We’ll apply gradient manually
              inactiveToggleColor: Color(0xff929492),
              //switchBorder: Border.all(width: 0.2),
              activeSwitchBorder: Border.all(
                  color: Color(0xffA1A1AF), width: 0.3),
              inactiveSwitchBorder:
                  Border.all(color: Color(0xffA1A1AF), width: 0.3),
              activeColor: Colors.transparent, // Make track transparent
              inactiveColor: Colors.transparent,
              // toggleGradient: LinearGradient(
              //   colors: [Colors.greenAccent, Colors.green],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
              onToggle: (value) {
                //Provider.of<AppSelectingProvider>(context, listen: false).toggleSystemApps(value);
              },
            ),
  ],
 ),
),

SizedBox(height: 8,),

//SettingOptionContainer(onPressed:provider.showSplitTunneling,height: 60,name:'Split Tunneling',icon:'assets/images/dark_theme/Split Tunneling.svg',isArrow: false,),


GestureDetector(
  onTap: provider.showSplitTunneling,
  child: GlassContainer.clearGlass(
    height: 60,width: double.infinity,
     blur: 20.0,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          borderColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
       Row(
         children: [
           SvgPicture.asset('assets/images/dark_theme/Split Tunneling.svg'),
           Padding(
         padding: const EdgeInsets.only(left: 5.0),
         child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Split Tunneling',style: TextStyle(fontFamily: 'Poppins',fontSize: 14)),
            Text(appSelectingProvider.isSPEnabled ? 'On' : 'Off',style: TextStyle(fontFamily: 'Poppins',fontSize: 12,color: Color(0xffA1A1C1)))
          ],
         ),
       ),
         ],
       ),
       
         Padding(
           padding: const EdgeInsets.symmetric(horizontal:  8.0),
           child: SvgPicture.asset('assets/images/dark_theme/arrow_settings.svg'),
         ),
    ],
  ),
  ),
),
SizedBox(height: 8,),

SettingOptionContainer(onPressed:invitePeople,height: 50,name:'Invite People',icon:'assets/images/dark_theme/Invite People.svg',isArrow: false,),



SizedBox(
  height: 10,
),
Text('About App',style: TextStyle(
              fontFamily: 'Poppins',fontSize: 15,color: Color(0xffA1A1AF),fontWeight: FontWeight.w400
            ),),
SizedBox(height: 10,),

SettingOptionContainer(onPressed:reportIssue,height: 50,name:'Report an Issue',icon:'assets/images/dark_theme/Report an Issue.svg',isArrow: false,),
SizedBox(height: 10,),

SettingOptionContainer(onPressed:(){
  Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => AboutPage(),
    transitionDuration: Duration(microseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Start from right
      const end = Offset.zero;       // Slide to center
      const curve = Curves.ease;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  ),
);

}
  //Navigator.push(context, MaterialPageRoute(builder: (context)=> AboutPage()))
,height: 50,name:'About',icon:'assets/images/dark_theme/About.svg',isArrow: true,)
          ],
        ),
            )
      ],
    );
    
  }

  Widget optionContainer(String name,double height,String icon,) {
    return GestureDetector(
onTap:reportIssue,
child: GlassContainer.clearGlass(
  height: 50,width: double.infinity,
   blur: 20.0,
         color: Colors.grey.shade600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        borderColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 10),
child:Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
        SvgPicture.asset('assets/images/dark_theme/Report an Issue.svg'),
        Padding(
          padding: EdgeInsets.only(left: 5),
          child: Text('Report an Issue',style: TextStyle(fontFamily: 'Poppins',fontSize: 14),))
      ],
    ),
    
  ],
 ) ,
),
);
  }
   void reportIssue() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'stepan@beldex.io', // Replace with your target email
    query: Uri.encodeFull('subject=Issue Report&body='),
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    // Optionally, handle the error if no email app is available
    print('Could not launch email app');
  }
}


// void reportIssue() async {
//   if (_isReporting) return;

//   _isReporting = true; // Set immediately before any async call

//   final Uri emailUri = Uri(
//     scheme: 'mailto',
//     path: 's@gmail.com',
//     query: Uri.encodeFull('subject=Belnet_Android_Feedback Report&body='),
//   );

//   try {
//     if (await canLaunchUrl(emailUri)) {
//       await launchUrl(emailUri);
//     } else {
//       print('Could not launch email app');
//     }
//   } catch (e) {
//     print('Error launching email: $e');
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isReporting = false;
//       });
//     } else {
//       _isReporting = false;
//     }
//   }
// }







void invitePeople() async{
   if (_isSharing) return; // Ignore if already sharing
   setState(() {
     
   });
   _isSharing = true; // Set flag to block further clicks
  const String playStoreUrl = 'https://play.google.com/store/apps/details?id=io.beldex.belnet'; // Replace with your real Play Store URL
 final result = await SharePlus.instance.share(ShareParams(text:"Hey, I've been using BelNet to browse confidentially. Try it yourself! Download it at $playStoreUrl") ); //.share('Check out this app: $playStoreUrl');

   _isSharing = false; 

 if (result.status == ShareResultStatus.success) {
      print('Shared successfully');
    } else if (result.status == ShareResultStatus.dismissed) {
      print('Share dismissed');
    }

}
}

class SettingOptionContainer extends StatelessWidget {
  final VoidCallback onPressed;
  final String name;
  final double height;
  final String icon;
  final bool isArrow;
  const SettingOptionContainer({
    super.key, required this.onPressed, required this.name, required this.height, required this.icon, required this.isArrow
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer.clearGlass(
        height: height,width: double.infinity,
         blur: 25.0,
              color: Colors.grey.shade600.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              borderColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 10),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(icon), //'assets/images/dark_theme/About.svg'
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(name,style: TextStyle(fontFamily: 'Poppins',fontSize: 14),))
            ],
          ),
          isArrow == true ? Padding(
               padding: const EdgeInsets.symmetric(horizontal:  8.0),
               child: SvgPicture.asset('assets/images/dark_theme/arrow_settings.svg'),
             ): SizedBox(),
        ],
       ) ,
      ),
    );
  }
}





