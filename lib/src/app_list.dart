import 'dart:ui';

import 'package:belnet_mobile/src/app_list_provider.dart';
import 'package:belnet_mobile/src/model/installed_apps_model.dart';
import 'package:belnet_mobile/src/model/theme_set_provider.dart';
import 'package:belnet_mobile/src/providers/loader_provider.dart';
import 'package:belnet_mobile/src/utils/show_toast.dart';
import 'package:belnet_mobile/src/vpn_controller.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
// //import 'package:mobile/src/app_list_provider.dart';

// class InstalledAppsList extends StatefulWidget {
//   const InstalledAppsList({super.key});

//   @override
//   State<InstalledAppsList> createState() => _InstalledAppsListState();
// }

// class _InstalledAppsListState extends State<InstalledAppsList> {
//   List<AppInfo> _allApps = [];
//   bool _showSystemApps = false;

//   @override
//   void initState() {
//     super.initState();
//     getInstalledAppsDetails();
//   }

//   Future<void> getInstalledAppsDetails() async {
//     final apps = await InstalledApps.getInstalledApps(true, true);
//     apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
//     setState(() {
//       _allApps = apps;
//     });
//   }


// bool _isSystemApp(String packageName) {
//   return packageName.startsWith('com.android.') ||
//          packageName.startsWith('com.google.android.') ||
//          packageName == 'android' ||
//          packageName.startsWith('com.samsung.') ||  // Optional: manufacturer-specific
//          packageName.startsWith('com.mi.') ||       // Xiaomi / MIUI
//          packageName.startsWith('com.huawei.') ||
//          packageName.startsWith('com.oppo.') ||
//          packageName.startsWith('com.vivo.');
// }



//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<AppSelectionProvider>(context);
//     final selectedPackages = provider.selectedApps;

//     final includedApps = _allApps
//         .where((app) => selectedPackages.contains(app.packageName))
//         .toList();

//     final availableApps = _allApps
//         .where((app) =>
//             !selectedPackages.contains(app.packageName) &&
//             (_showSystemApps || !_isSystemApp(app.packageName)))
//         .toList();






//     return Scaffold(
//       appBar: AppBar(title: Text('Split Tunneling')),
//       body: Column(
//         children: [
//           SwitchListTile(
//             title: Text("Show system apps"),
//             value: _showSystemApps,
//             onChanged: (val) {
//               setState(() => _showSystemApps = val);
//             },
//           ),

//           if (includedApps.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text("Included Apps", style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           if (includedApps.isNotEmpty)
//             Expanded(
//               flex: 1,
//               child: ListView.builder(
//                 itemCount: includedApps.length,
//                 itemBuilder: (context, index) {
//                   final app = includedApps[index];
//                   return ListTile(
//                     leading: app.icon != null
//                         ? Image.memory(app.icon!, width: 40, height: 40)
//                         : Icon(Icons.android),
//                     title: Text(app.name),
//                     subtitle: Text(app.packageName),
//                     trailing: IconButton(
//                       icon: Icon(Icons.remove_circle_outline, color: Colors.red),
//                       onPressed: () => provider.toggleApp(app.packageName),
//                     ),
//                   );
//                 },
//               ),
//             ),

//           if (availableApps.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text("Installed Apps", style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           Expanded(
//             flex: 2,
//             child: availableApps.isEmpty
//                 ? Center(child: Text('No apps to show'))
//                 : ListView.builder(
//                     itemCount: availableApps.length,
//                     itemBuilder: (context, index) {
//                       final app = availableApps[index];
//                       return ListTile(
//                         leading: app.icon != null
//                             ? Image.memory(app.icon!, width: 40, height: 40)
//                             : Icon(Icons.android),
//                         title: Text(app.name),
//                         subtitle: Text(app.packageName),
//                         trailing: IconButton(
//                           icon: Icon(Icons.add_circle_outline, color: Colors.green),
//                           onPressed: () => provider.toggleApp(app.packageName),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }


bool isEnabled = true;
TextEditingController searchController = TextEditingController();


class SplitTunnelingScreen extends StatefulWidget {
  final List<AppInfos> allApps;

  const SplitTunnelingScreen({super.key, required this.allApps});

  @override
  _SplitTunnelingScreenState createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {


bool isTosplitTunnel = false;


  @override
  void initState() {
    super.initState();
    searchController.clear();
    //  Provider.of<AppSelectingProvider>(context, listen: false)
    //                           .updateSearchQuery('');
     // Delay the provider update until the first frame is rendered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<AppSelectingProvider>(context, listen: false)
        .updateSearchQuery('');
  });
    // Refresh app list in the background when screen opens
    // AppCache.instance.loadApps().then((_) {
    //   if (mounted) setState(() {});
    // });
  }

  @override
  Widget build(BuildContext context) {
    // Use cached apps immediately
    // if(widget.allApps.isEmpty){

    // }
  // final allApps = AppCache.instance.apps;
   final appSelectingProvider = Provider.of<AppSelectingProvider>(context);
   final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context);
   final appModel = Provider.of<AppModel>(context);
    return 
        Column(
                      children: [
                                 GlassContainer.clearGlass(
                      height: 50,width: double.infinity,
                      blur: 30.0,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      padding: EdgeInsets.symmetric(horizontal:  15.0),
                              color: Colors.grey.withOpacity(0.1), //Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              borderColor: Colors.transparent,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                    Row(
                      children: [
                         SvgPicture.asset('assets/images/dark_theme/Split Tunneling.svg'),
                         Padding(
                           padding: const EdgeInsets.only(left: 8.0),
                           child: Text('Split tunneling',style: TextStyle(fontFamily: 'Poppins',
                                       fontSize: 14,
                                       fontWeight: FontWeight.w500,),),
                         )
                      ],
                    ),
                loaderVideoProvider.conStatus == ConnectionStatus.CONNECTING || loaderVideoProvider.conStatus == ConnectionStatus.CONNECTED ?
                    
                      FlutterSwitch(
                        //disabled: true,
                        //   inactiveToggleColor: appModel.darkTheme
                        // ? const Color(0xff9595B5).withOpacity(0.4)
                        // : const Color(0xffC5C5C5).withOpacity(0.08),
                        width: 45.0,
                        height: 24.0,
                        toggleSize: 19.0,
                        value: appSelectingProvider.isSPEnabled,//showSystemApps,
                        borderRadius: 30.0,
                        padding: 2.0,
                        //activeIcon: SvgPicture.asset('assets/images/'),
                        activeToggleColor: Color(0xff00DC00).withOpacity(0.5), // We’ll apply gradient manually
                        inactiveToggleColor: Color(0xff929492).withOpacity(0.5),
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
                          showMessage("Please disconnect the current node to modify split tunneling settings.");
                          // FocusScope.of(context).unfocus();
                          // appSelectingProvider.toggle();
                        },
                                    ):
        
                  FlutterSwitch(
                    width: 45.0,
                    height: 24.0,
                    toggleSize: 19.0,
                    value: appSelectingProvider.isSPEnabled,//showSystemApps,
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
                      FocusScope.of(context).unfocus();
                      appSelectingProvider.toggle();
                    },
                                ) ,
         
                     
                                ],
                              ),
                    ),
        
                   
        
                        // widget.allApps.isEmpty
                        //     ?
                        //      Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       crossAxisAlignment: CrossAxisAlignment.center,
                        //       children: [
                        //         SizedBox(height: 200,),
                        //         const Center(child: CircularProgressIndicator(color: Color(0xff00DC00),)),
                        //       ],
                        //     )
                        //     : 
                            Expanded(child: _AppListView(allApps: widget.allApps)),
                      ],
                    );
              //     ),
              //   ),
              // );
           // ],
        //  ),
        //),
    //  ),
    //);
  }
}

class _AppListView extends StatelessWidget {
  final List<AppInfos> allApps;

  const _AppListView({required this.allApps});
   
  // Helper method to estimate if an app is a system app based on package name
  bool _isSystemApp(AppInfos app) {
    final packageName = app.packageName.toLowerCase();
    const systemPrefixes = [
      'com.android.',
      'com.google.',
      'android.',
    ];
    final isSystem = systemPrefixes.any((prefix) => packageName.startsWith(prefix));
    print('App: ${app.name}, Package: ${app.packageName}, IsSystem: $isSystem');
    return isSystem;
  }

  @override
  Widget build(BuildContext context) {
       final appSelectingProvider = Provider.of<AppSelectingProvider>(context);
    final appModel = Provider.of<AppModel>(context);
    final loaderVideoProvider = Provider.of<LoaderVideoProvider>(context);
    return GlassContainer.clearGlass(
      height:double.infinity, //MediaQuery.of(context).size.height*1.90/3,
      margin: EdgeInsets.only(top: 10,left:10,right:10),
      blur: 18.0,
        color: appModel.darkTheme ? Color(0xff080C29).withOpacity(0.7) : Color(0x33BEBEBE).withOpacity(0.02), //s.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        borderColor: Color(0xffA1A1AF),
        borderWidth: 0.3,
        boxShadow:appModel.darkTheme ? [] : [
                      BoxShadow(
                  color: Color(0xff00FFDD).withOpacity(0.03) //Color(0xFF00DC00).withOpacity(0.2) ,// Colors.black12,,
                 
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  spreadRadius: -01.0,
                  blurRadius: 23.5,
                  offset: Offset(-3.0, 4.5),
                )
                   ],
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(15),
      //   border: Border.all(color: Color(0xffA1A1AF),width: 0.1)
      // ),
     // padding: EdgeInsets.all(8),
      child: 
       allApps.isEmpty
                            ?
                             Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                               // SizedBox(height: 200,),
                                const Center(child: CircularProgressIndicator(color: Color(0xff00DC00),)),
                              ],
                            )
                            :
      
      Stack(
        children: [
         
          Selector<AppSelectingProvider, (List<String>, bool, String)>(
            selector: (_, provider) => (
              provider.selectedApps,
              provider.showSystemApps,
              provider.searchQuery
            ),
            builder: (context, data, child) {
              print('Selector rebuilding');
              final selectedApps = allApps
                  .where((app) => data.$1.contains(app.packageName))
                  .toList()
                  ..sort((a, b) {
        final nameA = a.name?.toLowerCase() ?? '';
        final nameB = b.name?.toLowerCase() ?? '';
        return nameA.compareTo(nameB);
      });
              final installedApps = allApps
                  .where((app) => !data.$1.contains(app.packageName))
                  .toList();
              final filteredInstalledApps = data.$2
                  ? installedApps
                  : installedApps.where((app) => !_isSystemApp(app)).toList();
              final searchQuery = data.$3.toLowerCase();
              final searchedApps = searchQuery.isEmpty
                  ? filteredInstalledApps
                  : filteredInstalledApps
                      .where((app) =>
                          (app.name?.toLowerCase().contains(searchQuery) ?? false) ||
                          app.packageName.toLowerCase().contains(searchQuery))
                      .toList();
              // 🔽 Sort alphabetically by app name (case-insensitive)
               searchedApps.sort((a, b) {
               final nameA = a.name?.toLowerCase() ?? '';
               final nameB = b.name?.toLowerCase() ?? '';
               return nameA.compareTo(nameB);
             });
              return CustomScrollView(
                slivers: [
                 selectedApps.length > 0 ? SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                         Text(
                          'Included Apps (${selectedApps.length})',
                          style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14,
              color:appModel.darkTheme ? Color(0xffA1A1AF) : Color(0xff4D4D4D),
              fontWeight: FontWeight.w500,),
                        ),
                        
                      ]),
                    ),
                  ): SliverPadding(padding: EdgeInsets.all(0)),
      
      
      
      
       selectedApps.length > 0 ? SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            sliver: SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color:appModel.darkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color:appModel.darkTheme ? const Color(0xff3A496266).withOpacity(0.2) :Colors.transparent),
        ),
        padding: const EdgeInsets.all(8),
        child:
        Column(
  children: List.generate(selectedApps.length, (index) {
    final app = selectedApps[index];
    return Container(
      key: ValueKey(app.packageName),
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
      child: Row(
        children: [
          // App Icon
          app.icon != null
              ? Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: appModel.darkTheme
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xff3A4962).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: appModel.darkTheme
                            ? const Color(0xff3A496266).withOpacity(0.1)
                            : Colors.transparent),
                  ),
                  child: Image.memory(
                    app.icon!,
                    width: 25,
                    height: 25,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 25,
                    cacheHeight: 25,
                  ),
                )
              : const Icon(Icons.android, size: 40, color: Colors.white),
          const SizedBox(width: 12),

          // App Name
          Expanded(
            child: Text(
              app.name ?? app.packageName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Remove Button
          loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED
              ? GestureDetector(
                  onTap: () {
                    Provider.of<AppSelectingProvider>(context, listen: false)
                        .removeApp(app.packageName);
                  },
                  child: SvgPicture.asset(
                      'assets/images/dark_theme/removelist.svg'),
                )
              : GestureDetector(
                  onTap: () => showMessage(
                      "Please disconnect the current node to modify split tunneling settings."),
                  child: SvgPicture.asset(
                      'assets/images/dark_theme/removelist.svg',
                      color: const Color(0xffA1A1A1).withOpacity(0.6))),
        ],
      ),
    );
  }),
)
        //  ListView.builder(
        //   shrinkWrap: true, // important to avoid unbounded height
        //   physics: const NeverScrollableScrollPhysics(), // disable inner scroll
        //   itemCount: selectedApps.length,
        //   itemBuilder: (context, index) {
        //     final app = selectedApps[index];
        //     return Container(
        //       key: ValueKey(app.packageName),
        //       padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
        //       child: Row(
        //         children: [
        //           // App Icon
        //           app.icon != null
        //               ? Container(
        //                   padding: const EdgeInsets.all(7),
        //                   decoration: BoxDecoration(
        //                     color:appModel.darkTheme ? Colors.white.withOpacity(0.05)  : Color(0xff3A4962).withOpacity(0.1),
        //                     borderRadius: BorderRadius.circular(12),
        //                     border: Border.all(
        //                         color:appModel.darkTheme ? const Color(0xff3A496266).withOpacity(0.1): Colors.transparent),
        //                   ),
        //                   child: Image.memory(
        //                     app.icon!,
        //                     width: 25,
        //                     height: 25,
        //                     fit: BoxFit.cover,
        //                     gaplessPlayback: true,
        //                     cacheWidth: 25,
        //                     cacheHeight: 25,
        //                   ),
        //                 )
        //               : const Icon(Icons.android, size: 40, color: Colors.white
        //               ),
                
        //           const SizedBox(width: 12),
                
        //           // App Name
        //           Expanded(
        //             child: Text(
        //               app.name ?? app.packageName,
        //               style: const TextStyle(
        //                 fontFamily: 'Poppins',
        //                 fontSize: 14,
        //                 fontWeight: FontWeight.w500,
        //               ),
        //               overflow: TextOverflow.ellipsis,
        //             ),
        //           ),
                
        //           const SizedBox(width: 8),
        //          loaderVideoProvider.conStatus  == ConnectionStatus.DISCONNECTED ?
        //           // Remove Button
        //           GestureDetector(
        //             onTap: () {
        //               Provider.of<AppSelectingProvider>(context, listen: false)
        //                   .removeApp(app.packageName);
        //             },
        //             child: SvgPicture.asset(
        //                 'assets/images/dark_theme/removelist.svg'),
        //           ): GestureDetector(
        //               onTap: ()=> showMessage("Please disconnect the current node to modify split tunneling settings."),
        //               child: SvgPicture.asset('assets/images/dark_theme/removelist.svg', color: Color(0xffA1A1A1).withOpacity(0.6))),
        //         ],
        //       ),
        //     );
        //   },
        // ),
      ),
            ),
          ) : SliverPadding(padding: EdgeInsets.all(0)),
      
      
      
      
      
      
          //         SliverPadding(
          //           padding: const EdgeInsets.symmetric(horizontal: 0.0),
          //           sliver: SliverList.builder(
          //             itemCount: selectedApps.length,
          //             itemBuilder: (context, index) {
          //               final app = selectedApps[index];
          //               return 
                        
          //               Container(
          //   key: ValueKey(app.packageName),
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          //   child: Row(
          //     children: [
          //       // App Icon
          //       app.icon != null
          //   ? Container(
          //     padding: EdgeInsets.all(7),
          //     decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.05),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Color(0xff3A496266).withOpacity(0.1)),
          //   ),
          //     child: Image.memory(
          //         app.icon!,
          //         width: 25,
          //         height: 25,
          //         fit: BoxFit.cover,
          //         gaplessPlayback: true,
          //         cacheWidth: 25,
          //         cacheHeight: 25,
          //       ),
          //   )
          //   : const Icon(Icons.android, size: 40, color: Colors.white),
          
          //       const SizedBox(width: 12),
          
          //       // App Name
          //       Expanded(
          // child: Text(
          //   app.name ?? app.packageName,
          //   style: const TextStyle(
          //     //color: Colors.white,
          //     fontFamily: 'Poppins',
          //     fontSize: 14,
          //     fontWeight: FontWeight.w500,
          //   ),
          //   overflow: TextOverflow.ellipsis,
          // ),
          //       ),
          
          //       const SizedBox(width: 8),
          
          //       // Remove Button
          //       GestureDetector(
          // onTap: () {
          //   Provider.of<AppSelectingProvider>(context, listen: false)
          //       .removeApp(app.packageName);
          // },
          // child: SvgPicture.asset('assets/images/dark_theme/removelist.svg')
          //       ),
          //     ],
          //   ),
          // );
          
          //               // ListTile(
          //               //   key: ValueKey(app.packageName),
          //               //   leading: app.icon != null
          //               //       ? Image.memory(
          //               //           app.icon!,
          //               //           width: 32,
          //               //           height: 32,
          //               //           gaplessPlayback: true,
          //               //           cacheWidth: 32,
          //               //           cacheHeight: 32,
          //               //         )
          //               //       : const Icon(Icons.android, size: 32),
          //               //   title: Text(app.name ?? app.packageName),
          //               //   trailing: IconButton(
          //               //     icon: const Icon(Icons.remove_circle),
          //               //     onPressed: () {
          //               //       Provider.of<AppSelectingProvider>(context, listen: false)
          //               //           .removeApp(app.packageName);
          //               //     },
          //               //   ),
          //               // );
          //             },
          //           ),
          //         ),
      
      SliverPadding(
            padding: const EdgeInsets.only(top: 10.0,left:10,right:10,bottom: 10),
            sliver: SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color:appModel.darkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color:appModel.darkTheme ? const Color(0xff3A496266).withOpacity(0.2) : Colors.transparent),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              height: 45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: appModel.darkTheme ? Colors.white.withOpacity(0.05):Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color:appModel.darkTheme ? const Color(0xff3A496266).withOpacity(0.1) : Colors.transparent),
              ),
              child: VisibilityDetector(
                key: const Key('text-field'),
                onVisibilityChanged: (VisibilityInfo info) { 
                  if(info.visibleFraction == 0){
                     FocusScope.of(context).unfocus();
                  }
                 },
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search apps',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.trim().isNotEmpty ? GestureDetector(
                    onTap: (){
                       searchController.clear();
                      Provider.of<AppSelectingProvider>(context, listen: false)
                              .updateSearchQuery('');
                    },
                    child: Icon(Icons.close,color: appModel.darkTheme ? Colors.white : Colors.black,) //SvgPicture.asset('assets/images/dark_theme/clear_text_search.svg' ,color:appModel.darkTheme ? Colors.white : Colors.black,)
                    )
                    : SizedBox.shrink(),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                            
                  ),
                  onChanged: (value) {
                    Provider.of<AppSelectingProvider>(context, listen: false)
                        .updateSearchQuery(value);
                  },
                ),
              ),
            ),
           searchedApps.isEmpty ? SizedBox.shrink() : const SizedBox(height: 16),
      
            // System Apps Toggle
           searchedApps.isEmpty ? SizedBox.shrink() : Selector<AppSelectingProvider, bool>(
              selector: (_, provider) => provider.showSystemApps,
              builder: (context, showSystemApps, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Show System Apps',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    FlutterSwitch(
                      width: 45.0,
                      height: 24.0,
                      toggleSize: 19.0,
                      value: showSystemApps,
                      borderRadius: 30.0,
                      padding: 2.0,
                      activeToggleColor: const Color(0xff00DC00),
                      inactiveToggleColor: const Color(0xff929492),
                      activeSwitchBorder: Border.all(color: const Color(0xffA1A1AF), width: 0.3),
                      inactiveSwitchBorder: Border.all(color: const Color(0xffA1A1AF), width: 0.3),
                      activeColor: Colors.transparent,
                      inactiveColor: Colors.transparent,
                      onToggle: (value) {
                        Provider.of<AppSelectingProvider>(context, listen: false)
                            .toggleSystemApps(value);
                      },
                    ),
                  ],
                );
              },
            ),
           searchedApps.isEmpty ? SizedBox.shrink() : const SizedBox(height: 16),
      
            // App List
            searchedApps.isEmpty && searchController.text.trim().isNotEmpty
                ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No Apps found on this name!',
                    style: TextStyle(fontSize: 14,fontFamily: 'Poppins',color: Color(0xffA1A1AF)),
                  ),
                )
                : 
                Column(
  children: List.generate(searchedApps.length, (index) {
    final app = searchedApps[index];
    return Container(
      key: ValueKey(app.packageName),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // App Icon
          app.icon != null
              ? Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: appModel.darkTheme
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xff3A4962).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: appModel.darkTheme
                            ? const Color(0xff3A496266).withOpacity(0.1)
                            : Colors.transparent),
                  ),
                  child: Image.memory(
                    app.icon!,
                    width: 25,
                    height: 25,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 25,
                    cacheHeight: 25,
                  ),
                )
              : const Icon(Icons.android, size: 40, color: Colors.white),
          const SizedBox(width: 12),

          // App Name
          Expanded(
            child: Text(
              app.name ?? app.packageName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Add Button
          loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED
              ? GestureDetector(
                  onTap: () {
                    Provider.of<AppSelectingProvider>(context, listen: false)
                        .addApp(app.packageName);
                  },
                  child: SvgPicture.asset(
                      'assets/images/dark_theme/addlist.svg'),
                )
              : GestureDetector(
                  onTap: () => showMessage(
                      "Please disconnect the current node to modify split tunneling settings."),
                  child: SvgPicture.asset(
                      'assets/images/dark_theme/addlist.svg',
                      color: const Color(0xff00DC00).withOpacity(0.18)),
                ),
        ],
      ),
    );
  }),
)
                // ListView.builder(
                //     shrinkWrap: true,
                //     physics: const NeverScrollableScrollPhysics(),
                //     itemCount: searchedApps.length,
                //     itemBuilder: (context, index) {
                //       final app = searchedApps[index];
                //       return Container(
                //         key: ValueKey(app.packageName),
                //         padding: const EdgeInsets.symmetric( vertical: 5),
                //         child: Row(
                //           children: [
                //             // App Icon
                //             app.icon != null
                //                 ? Container(
                //                     padding: const EdgeInsets.all(7),
                //                     decoration: BoxDecoration(
                //                       color:appModel.darkTheme ? Colors.white.withOpacity(0.05) : Color(0xff3A4962).withOpacity(0.1),
                //                       borderRadius: BorderRadius.circular(12),
                //                       border: Border.all(
                //                           color:appModel.darkTheme ? const Color(0xff3A496266).withOpacity(0.1) : Colors.transparent),
                //                     ),
                //                     child: Image.memory(
                //                       app.icon!,
                //                       width: 25,
                //                       height: 25,
                //                       fit: BoxFit.cover,
                //                       gaplessPlayback: true,
                //                       cacheWidth: 25,
                //                       cacheHeight: 25,
                //                     ),
                //                   )
                //                 : const Icon(Icons.android, size: 40, color: Colors.white
                //                 ),
                        
                //             const SizedBox(width: 12),
                        
                //             // App Name
                //             Expanded(
                //               child: Text(
                //                 app.name ?? app.packageName,
                //                 style: const TextStyle(
                //                   //color: Colors.white,
                //                   fontFamily: 'Poppins',
                //                   fontSize: 14,
                //                   fontWeight: FontWeight.w500,
                //                 ),
                //                 overflow: TextOverflow.ellipsis,
                //               ),
                //             ),
                        
                //             const SizedBox(width: 8),
                //          loaderVideoProvider.conStatus == ConnectionStatus.DISCONNECTED ?
                //             // Add Button
                //             GestureDetector(
                //               onTap: () {
                //                 Provider.of<AppSelectingProvider>(context, listen: false)
                //                     .addApp(app.packageName);
                //               },
                //               child: SvgPicture.asset(
                //                   'assets/images/dark_theme/addlist.svg'),
                //             ):GestureDetector(
                //                 onTap: ()=> showMessage("Please disconnect the current node to modify split tunneling settings."),
                //                 child: SvgPicture.asset(
                //                       'assets/images/dark_theme/addlist.svg',color:Color(0xff00DC00).withOpacity(0.18)//  Color(0xffA1A1A1).withOpacity(0.8),
                //                       ),
                //               )
                //           ],
                //         ),
                //       );
                //     },
                //   ),
          ],
        ),
      ),
            ),
          ),
      
      
      
      
      
      
      
      
      
      
      
      
      
          //         SliverList(
          //           delegate: SliverChildListDelegate.fixed([
          //             Container(
          //               height: 45,width: double.infinity,
          //               decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.05),
          //     borderRadius: BorderRadius.circular(20),
          //     border: Border.all(color: Color(0xff3A496266).withOpacity(0.1)),
          //   ),
          // //                blur: 18.0,
          // // color: Colors.transparent,
          // // borderRadius: BorderRadius.circular(14),
          // // borderColor: Colors.transparent,
          //               child: TextField(
          //                 decoration: InputDecoration(
          //                   hintText: 'Search apps',
          //                   prefixIcon: const Icon(Icons.search),
          //                   border: InputBorder.none,
          //                   hintStyle: TextStyle(
          //                     fontFamily: 'Poppins',
          //     fontSize: 14,
          //     fontWeight: FontWeight.w500,
          //                   )
          //                   // OutlineInputBorder(
          //                   //   borderRadius: BorderRadius.circular(8.0),
          //                   // ),
          //                 ),
          //                 onChanged: (value) {
          //                   Provider.of<AppSelectingProvider>(context, listen: false)
          //                       .updateSearchQuery(value);
          //                 },
          //               ),
          //             ),
          //             const SizedBox(height: 16),
          //             Selector<AppSelectingProvider, bool>(
          //               selector: (_, provider) => provider.showSystemApps,
          //               builder: (context, showSystemApps, child) {
          //                 return Row(
          //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                   children: [
          //                     const Text(
          //                       'Show System Apps',
          //                       style: TextStyle(fontFamily: 'Poppins',
          //     fontSize: 14,
          //     fontWeight: FontWeight.w500,),
          //                     ),
          //                       FlutterSwitch(
          //       width: 45.0,
          //       height: 24.0,
          //       toggleSize: 19.0,
          //       value: showSystemApps,
          //       borderRadius: 30.0,
          //       padding: 2.0,
          //       //activeIcon: SvgPicture.asset('assets/images/'),
          //       activeToggleColor: Color(0xff00DC00), // We’ll apply gradient manually
          //       inactiveToggleColor: Color(0xff929492),
          //       //switchBorder: Border.all(width: 0.2),
          //       activeSwitchBorder: Border.all(
          //           color: Color(0xffA1A1AF), width: 0.3),
          //       inactiveSwitchBorder:
          //           Border.all(color: Color(0xffA1A1AF), width: 0.3),
          //       activeColor: Colors.transparent, // Make track transparent
          //       inactiveColor: Colors.transparent,
          //       // toggleGradient: LinearGradient(
          //       //   colors: [Colors.greenAccent, Colors.green],
          //       //   begin: Alignment.topLeft,
          //       //   end: Alignment.bottomRight,
          //       // ),
          //       onToggle: (value) {
          //         Provider.of<AppSelectingProvider>(context, listen: false).toggleSystemApps(value);
          //       },
          //     ),
          //                     // Switch(
          //                     //   value: showSystemApps,
          //                     //   onChanged: (value) {
          //                     //     Provider.of<AppSelectingProvider>(context, listen: false)
          //                     //         .toggleSystemApps(value);
          //                     //   },
          //                     // ),
          //                   ],
          //                 );
          //               },
          //             ),
          //     //         const Text(
          //     //           'Installed Apps',
          //     //           style: TextStyle(fontFamily: 'Poppins',
          //     // fontSize: 14,
          //     // color: Color(0xffA1A1AF),
          //     // fontWeight: FontWeight.w500,),                    ),
          //             const SizedBox(height: 8),
          //           ]
          //           ),
          //         ),
          //         SliverPadding(
          //           padding: const EdgeInsets.symmetric(horizontal: 0.0),
          //           sliver: searchedApps.isEmpty
          //               ? SliverList(
          //                   delegate: SliverChildListDelegate.fixed([
          //                     const Padding(
          //                       padding: EdgeInsets.symmetric(vertical: 16.0),
          //                       child: Text(
          //                         'No apps found',
          //                         style: TextStyle(fontSize: 16),
          //                         textAlign: TextAlign.center,
          //                       ),
          //                     ),
          //                   ]),
          //                 )
          //               : SliverList.builder(
          //                   itemCount: searchedApps.length,
          //                   itemBuilder: (context, index) {
          //                     final app = searchedApps[index];
          //                     return 
          
          //                       Container(
          //   key: ValueKey(app.packageName),
          //   //margin: const EdgeInsets.symmetric(vertical: 6),
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          //   child: Row(
          //     children: [
          //       // App Icon
          //       app.icon != null
          //   ? Container(
          //     padding: EdgeInsets.all(7),
          //     decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.05),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Color(0xff3A496266).withOpacity(0.1)),
          //   ),
          //     child: Image.memory(
          //         app.icon!,
          //         width: 25,
          //         height: 25,
          //         fit: BoxFit.cover,
          //         gaplessPlayback: true,
          //         cacheWidth: 25,
          //         cacheHeight: 25,
          //       ),
          //   )
          //   : const Icon(Icons.android, size: 40, color: Colors.white),
          
          //       const SizedBox(width: 12),
          
          //       // App Name
          //       Expanded(
          // child: Text(
          //   app.name ?? app.packageName,
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontFamily: 'Poppins',
          //     fontSize: 14,
          //     fontWeight: FontWeight.w500,
          //   ),
          //   overflow: TextOverflow.ellipsis,
          // ),
          //       ),
          
          //       const SizedBox(width: 8),
          
          //       // Remove Button
          //       GestureDetector(
          // onTap: () {
          //  Provider.of<AppSelectingProvider>(context, listen: false)
          //   .addApp(app.packageName);
          // },
          // child: SvgPicture.asset('assets/images/dark_theme/addlist.svg')
          //       ),
          //     ],
          //   ),
          // );
          
          //                     // ListTile(
          //                     //   key: ValueKey(app.packageName),
          //                     //   leading: app.icon != null
          //                     //       ? Image.memory(
          //                     //           app.icon!,
          //                     //           width: 32,
          //                     //           height: 32,
          //                     //           gaplessPlayback: true,
          //                     //           cacheWidth: 32,
          //                     //           cacheHeight: 32,
          //                     //         )
          //                     //       : const Icon(Icons.android, size: 32),
          //                     //   title: Text(app.name ?? app.packageName),
          //                     //   trailing: IconButton(
          //                     //     icon: const Icon(Icons.add_circle),
          //                     //     onPressed: () {
          //                     //       Provider.of<AppSelectingProvider>(context, listen: false)
          //                     //           .addApp(app.packageName);
          //                     //     },
          //                     //   ),
          //                     // );
          //                   },
          //                 ),
          //         ),
                ],
              );
            },
          ),
        !appSelectingProvider.isSPEnabled ? GlassContainer.clearGlass(
           blur:appModel.darkTheme ? 2.0 : 2.0, // 1.1,
      color:appModel.darkTheme ? Color(0x333A4962).withOpacity(0.03) //Colors.black54
       : Color(0x33BEBEBE).withOpacity(0.03), //s.grey.shade400.withOpacity(0.04), //transparent,(0xffBEBEBE).withOpacity(0.9) ,//
      borderRadius: BorderRadius.circular(14),
      borderColor: Colors.transparent,
         ): SizedBox()
        
        
        ],
      ),
    );
  }
}





class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const GlassmorphicContainer({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2), // Semi-transparent background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3), // Subtle border
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Apply blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent, // Required for BackdropFilter
              ),
            ),
            // Content
            child,
          ],
        ),
      ),
    );
  }
}










//////////////////////////
// class _AppListView extends StatelessWidget {
//   final List<AppInfo> allApps;

//   const _AppListView({required this.allApps});

//   // Helper method to estimate if an app is a system app based on package name
//   bool _isSystemApp(AppInfo app) {
//     final packageName = app.packageName.toLowerCase();
//     const systemPrefixes = [
//       'com.android.',
//       'com.google.',
//       'android.',
//     ];
//     final isSystem = systemPrefixes.any((prefix) => packageName.startsWith(prefix));
//     print('App: ${app.name}, Package: ${app.packageName}, IsSystem: $isSystem');
//     return isSystem;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Selector<AppSelectingProvider, (List<String>, bool)>(
//       selector: (_, provider) => (provider.selectedApps, provider.showSystemApps),
//       builder: (context, data, child) {
//         print('Selector rebuilding');
//         final selectedApps = allApps
//             .where((app) => data.$1.contains(app.packageName))
//             .toList();
//         final installedApps = allApps
//             .where((app) => !data.$1.contains(app.packageName))
//             .toList();
//         final filteredInstalledApps = data.$2
//             ? installedApps
//             : installedApps.where((app) => !_isSystemApp(app)).toList();

//         return CustomScrollView(
//           slivers: [
//             SliverPadding(
//               padding: const EdgeInsets.all(16.0),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate.fixed([
//                   const Text(
//                     'Include Apps',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   if (selectedApps.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8.0),
//                       child: Text('No apps selected'),
//                     ),
//                 ]),
//               ),
//             ),
//             SliverPadding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               sliver: SliverList.builder(
//                 itemCount: selectedApps.length,
//                 itemBuilder: (context, index) {
//                   final app = selectedApps[index];
//                   return ListTile(
//                     key: ValueKey(app.packageName),
//                     leading: app.icon != null
//                         ? Image.memory(
//                             app.icon!,
//                             width: 32,
//                             height: 32,
//                             gaplessPlayback: true,
//                             cacheWidth: 32,
//                             cacheHeight: 32,
//                           )
//                         : const Icon(Icons.android, size: 32),
//                     title: Text(app.name ?? app.packageName),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.remove_circle),
//                       onPressed: () {
//                         Provider.of<AppSelectingProvider>(context, listen: false)
//                             .removeApp(app.packageName);
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SliverPadding(
//               padding: const EdgeInsets.all(16.0),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate.fixed([
//                   const Divider(),
//                   Selector<AppSelectingProvider, bool>(
//                     selector: (_, provider) => provider.showSystemApps,
//                     builder: (context, showSystemApps, child) {
//                       return Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Show System Apps',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                           Switch(
//                             value: showSystemApps,
//                             onChanged: (value) {
//                               Provider.of<AppSelectingProvider>(context, listen: false)
//                                   .toggleSystemApps(value);
//                             },
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                   const Text(
//                     'Installed Apps',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                 ]),
//               ),
//             ),
//             SliverPadding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               sliver: SliverList.builder(
//                 itemCount: filteredInstalledApps.length,
//                 itemBuilder: (context, index) {
//                   final app = filteredInstalledApps[index];
//                   return ListTile(
//                     key: ValueKey(app.packageName),
//                     leading: app.icon != null
//                         ? Image.memory(
//                             app.icon!,
//                             width: 32,
//                             height: 32,
//                             gaplessPlayback: true,
//                             cacheWidth: 32,
//                             cacheHeight: 32,
//                           )
//                         : const Icon(Icons.android, size: 32),
//                     title: Text(app.name ?? app.packageName),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.add_circle),
//                       onPressed: () {
//                         Provider.of<AppSelectingProvider>(context, listen: false)
//                             .addApp(app.packageName);
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

/////////////////////////////////////////





















// class SplitTunnelingScreen extends StatelessWidget {
//   const SplitTunnelingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Split Tunneling')),
//       body: FutureBuilder<List<AppInfo>>(
//         future: InstalledApps.getInstalledApps(true, true),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading apps'));
//           }
//           final allApps = snapshot.data ?? [];
//           return _AppListView(allApps: allApps);
//         },
//       ),
//     );
//   }
// }

// class _AppListView extends StatelessWidget {
//   final List<AppInfo> allApps;

//   const _AppListView({required this.allApps});

//   // Helper method to estimate if an app is a system app based on package name
//   bool _isSystemApp(AppInfo app) {
//     final packageName = app.packageName.toLowerCase();
//     const systemPrefixes = [
//       'com.android.',
//       'com.google.',
//       'android.',
//     ];
//     return systemPrefixes.any((prefix) => packageName.startsWith(prefix));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AppSelectingProvider>(
//       builder: (context, provider, child) {
//         final selectedApps = allApps
//             .where((app) => provider.selectedApps.contains(app.packageName))
//             .toList();
//         final installedApps = allApps
//             .where((app) =>
//                 !provider.selectedApps.contains(app.packageName) &&
//                 (provider.showSystemApps || !_isSystemApp(app)))
//             .toList();

//         return CustomScrollView(
//           slivers: [
//             SliverPadding(
//               padding: const EdgeInsets.all(16.0),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate.fixed([
//                   const Text(
//                     'Include Apps',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   if (selectedApps.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8.0),
//                       child: Text('No apps selected'),
//                     ),
//                 ]),
//               ),
//             ),
//             SliverPadding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               sliver: SliverList.builder(
//                 itemCount: selectedApps.length,
//                 itemBuilder: (context, index) {
//                   final app = selectedApps[index];
//                   return ListTile(
//                     key: ValueKey(app.packageName),
//                     leading: app.icon != null
//                         ? Image.memory(
//                             app.icon!,
//                             width: 40,
//                             height: 40,
//                             gaplessPlayback: true,
//                           )
//                         : const Icon(Icons.android),
//                     title: Text(app.name ?? app.packageName),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.remove_circle),
//                       onPressed: () {
//                         provider.removeApp(app.packageName);
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SliverPadding(
//               padding: const EdgeInsets.all(16.0),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate.fixed([
//                   const Divider(),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Show System Apps',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                       Switch(
//                         value: provider.showSystemApps,
//                         onChanged: (value) {
//                           provider.toggleSystemApps(value);
//                         },
//                       ),
//                     ],
//                   ),
//                   const Text(
//                     'Installed Apps',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                 ]),
//               ),
//             ),
//             SliverPadding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               sliver: SliverList.builder(
//                 itemCount: installedApps.length,
//                 itemBuilder: (context, index) {
//                   final app = installedApps[index];
//                   return ListTile(
//                     key: ValueKey(app.packageName),
//                     leading: app.icon != null
//                         ? Image.memory(
//                             app.icon!,
//                             width: 40,
//                             height: 40,
//                             gaplessPlayback: true,
//                           )
//                         : const Icon(Icons.android),
//                     title: Text(app.name ?? app.packageName),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.add_circle),
//                       onPressed: () {
//                         provider.addApp(app.packageName);
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }