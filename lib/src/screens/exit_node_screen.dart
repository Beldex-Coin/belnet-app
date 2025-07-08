import 'package:belnet_mobile/node_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';

class ExitNodesScreen extends StatefulWidget {
  @override
  State<ExitNodesScreen> createState() => _ExitNodesScreenState();
}

class _ExitNodesScreenState extends State<ExitNodesScreen> with SingleTickerProviderStateMixin{

 late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    // _controller = AnimationController(
    //   duration: const Duration(milliseconds: 600),
    //   vsync: this,
    // );

    // _offsetAnimation = Tween<Offset>(
    //   begin: const Offset(0.0, 1.0), // Start off-screen (bottom)
    //   end: Offset.zero,              // End at normal position
    // ).animate(
    //   CurvedAnimation(
    //     parent: _controller,
    //     curve: Curves.easeOut,
    //   ),
    // );

    // // Start the animation when screen is loaded
    // _controller.forward();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Slower animation (1.2 sec)
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),  // Start lower
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,   // Smooth, natural slide
      ),
    );
    
    _controller.forward();
  }


void showCustomDialog(BuildContext context,AppModel appModel) {

   showDialog(
                                  useSafeArea: false,
                                  // barrierColor: Colors.white.withOpacity(0.09),
                                  context: context,
                                  builder: (BuildContext dcontext) => Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: appModel.darkTheme ?
                                        GlassContainer.clearGlass(
                                         color: Colors.black.withOpacity(0.3), //s.white.withOpacity(0.8),
                                         blur: 10.0,
                                         borderColor: Colors.transparent,
                                          child: Dialog(
                                           // scrollable: true,
                                           insetPadding: EdgeInsets.all(18),
                                            backgroundColor: Colors.transparent, 
                                            //contentPadding: EdgeInsets.all(0.0),
                                            child:CustomAddExitNodeDialog() //containerWidget(dcontext,mHeight,appModel),
                                          ),
                                        )
                                        : GlassContainer.clearGlass(
                                         color:  Color(0x80FFFFFF), //s.white.withOpacity(0.8),
                                         //blur: 10.0,
                                         borderColor: Colors.transparent,
                                          child: Dialog(
                                           // scrollable: true,
                                           insetPadding: EdgeInsets.all(18),
                                            backgroundColor: Colors.transparent,
                                            //contentPadding: EdgeInsets.all(0.0),
                                            child:CustomAddExitNodeDialog() //containerWidget(dcontext,mHeight,appModel),
                                          ),
                                        ),
                                      ));
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text( 'Change node', style: TextStyle(fontFamily: 'Poppins',fontSize: 18,fontWeight: FontWeight.w500),),
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
       Container(
          padding: EdgeInsets.all(7),
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
           borderRadius: BorderRadius.circular(8)
          ),
          child: SvgPicture.asset('assets/images/dark_theme/light_Theme.svg'))
        ],
        ),
      body:GlassContainer.clearGlass(
         //height: double.infinity ,
         width: double.infinity,
   height: MediaQuery.of(context).size.height*2.26/3,
      margin: EdgeInsets.all(10),
      blur: 9.0,
        color: Colors.black.withOpacity(0.03), //.black38, // Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        borderColor: Color(0xffA1A1AF),
        borderWidth: 0.3,
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
         Stack(
      alignment: Alignment.center,
      children: [
        // Outer container for the gradient border
        Container(
          width: 154,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: Color(0xfff00DC00),width: 0.3),
            gradient: LinearGradient(
              colors: [
                Color(0xFF464663), // Gradient start color
                Color(0xFF00DC00).withOpacity(0.6), // Gradient end color
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Inner container for the background and inner shadow
        ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: Container(
            width: 152, // Slightly smaller to account for the 1px border
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent, //(0xFF3A4962).withOpacity(0.4), // Background color with 40% opacity
              borderRadius: BorderRadius.circular(44),
              boxShadow: [
                BoxShadow(
                  //color: Color(0xFF0094FF), // Inner shadow color
                  offset: Offset(-3, 3), // X: -2, Y: 2
                  blurRadius: 14, // Blur: 12
                  spreadRadius: -2, // Negative spread to create inner shadow
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/dark_theme/add_exit_node.svg',color: Color(0xFF00DC00)),
                Padding(
                  padding: const EdgeInsets.only(left:8.0),
                  child: Text('Add Exit Node',style: TextStyle(color: Color(0xFF00DC00),fontFamily: 'Poppins',fontWeight: FontWeight.w600,fontSize: 12),),
                )
              ],
            ),
          ),
        ),
      ],
    ),  

Expanded(child: SlideTransition(
  position: _offsetAnimation,
  child: NodeTabScreen()))

          ],

        ),
        
      )
    );

  }
}


class NodeTabScreen extends StatefulWidget {
  @override
  _NodeTabScreenState createState() => _NodeTabScreenState();
}

class _NodeTabScreenState extends State<NodeTabScreen> {
  final List<String> tabTypes = ['Beldex Official', 'Contributor exit node'];
  String selectedType = 'Beldex Official';
  bool isConnect = false;
  @override
  void initState() {
    super.initState();
    // Future.microtask(() {
    //   Provider.of<NodeProvider>(context, listen: false).fetchNodes();
    // });
    checkRunning();
  }


  void checkRunning()async{
     isConnect = await BelnetLib.isRunning.asStream().first;
     setState(() {
       
     });
     print('THE STREAM VALUE FROM THE RUNNING STATUS $isConnect');
  }




  @override
  Widget build(BuildContext context) {
    final nodeProvider = Provider.of<NodeProvider>(context);

    if (nodeProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (nodeProvider.hasError) {
      return Center(child: CircularProgressIndicator(color: Color(0xff00DC00),));
    }

    final groupedNodes = nodeProvider.groupByCountryWithIcon(selectedType);

    return SafeArea(
      child: Column(
        children: [
          // // Custom Tab Buttons
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: tabTypes.map((type) {
          //       final isSelected = type == selectedType;
          //       return 
                
                
          //       Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 8),
          //         child: ElevatedButton(
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: isSelected ? Colors.blue : Colors.grey,
          //           ),
          //           onPressed: () {
          //             setState(() {
          //               selectedType = type;
          //             });
          //           },
          //           child: Text(type, style: TextStyle(color: Colors.white)),
          //         ),
          //       );
          //     }).toList(),
          //   ),
          // ),


Container(
  height: 60,
  width: double.infinity,
  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  padding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xff3A496266).withOpacity(0.2)),
  ),
  child: 
  
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: List.generate(tabTypes.length * 2 - 1, (index) {
    if (index.isOdd) {
      // Insert spacing between items
      return SizedBox(width: 8); // or any width you want
    } else {
      final type = tabTypes[index ~/ 2];
      final isSelected = type == selectedType;
      final count = nodeProvider.getNodeCount(type);
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedType = type;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer container
              Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(
                    color: selectedType == 'Beldex Official' && type == 'Beldex Official'
                        ? Color(0xFF00DC00)
                        : selectedType == 'Contributor exit node' && type == 'Contributor exit node'
                            ? Color(0xFF0094FF)
                            : Colors.transparent,
                    width: 0.4,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF464663),
                      selectedType == 'Beldex Official' && type == 'Beldex Official'
                          ? Color(0xFF00DC00).withOpacity(0.6)
                          : selectedType == 'Contributor exit node' && type == 'Contributor exit node'
                              ? Color(0xFF0094FF).withOpacity(0.6)
                              : Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Inner container
              ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: Container(
                  height: 42,
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: Color(0xff464663).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(44),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(-3, 3),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          type == 'Contributor exit node' ? ' Contributor Nodes' : 'Beldex Nodes',
                          style: TextStyle(
                            color: selectedType == 'Contributor exit node' && type == 'Contributor exit node'
                                ? Color(0xFF0094FF)
                                : selectedType == 'Beldex Official' && type == 'Beldex Official'
                                    ? Color(0xFF00DC00)
                                    : Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: selectedType != type ? FontWeight.w100 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: selectedType != type ? FontWeight.w100 : FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }),
)
    
  // ),
),

          // Grouped List by Country
          Expanded(
  child: RawScrollbar(
    thumbVisibility: true,  // always show scrollbar
    thumbColor: Color(0xffACACAC).withOpacity(0.4),
    thickness: 4,           // adjust thickness as needed
    radius: Radius.circular(8), // rounded scrollbar
    //minThumbLength: 15.0,
    padding: EdgeInsets.symmetric(horizontal:5),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: groupedNodes.entries.map((entry) {
        final country = entry.key;
        final countryIcon = entry.value['icon'] as String;
        final nodes = entry.value['nodes'] as List<dynamic>;
    
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Image.asset(
                  'assets/images/flags/$country.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.flag), // fallback icon if loading fails
                ),
                // Image.network(
                //   countryIcon,
                //   width: 22,
                //   height: 22,
                //   errorBuilder: (context, error, stackTrace) =>
                //       Icon(Icons.flag), // fallback icon if loading fails
                // ),
                SizedBox(width: 8),
                Text(
                  country,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'
                    //decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8,),
            ...nodes.map((node) {
              final isSelected = nodeProvider.selectedExitNodeName == node['name']; //nodeProvider.selectedNodeId == node['id'];
              return GestureDetector(
                onTap: (){
                  nodeProvider.selectNode(node['id'],node['name'],country);

                },
                child: GlassContainer.clearGlass(
                  height: 60,
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  //decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      borderColor: isSelected ? Color(0xff00DC00) : const Color(0xffACACAC).withOpacity(0.5),
                      borderWidth: 0.6,
                   // ),
                    padding: EdgeInsets.all(10),
                   child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal:  8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(node['name'],
                                maxLines: 1,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: 'Poppins'
                                  //fontSize: 16,
                                ),
                                ),
                              ),
                              //SizedBox(height: 5),
                              Text(country,
                                maxLines: 1,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xffACACAC)
                                ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 6,width: 6,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff00DC00)
                        ),
                      )
                    ],
                   ),
                ),
              );
              
              // ListTile(
              //   title: Text(
              //     node['name'],
              //     style: TextStyle(
              //       color: isSelected ? Colors.blue : Colors.black,
              //       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              //     ),
              //   ),
              //   onTap: () {
              //     nodeProvider.selectNode(node['id']);
              //   },
              // );
            }).toList(),
            SizedBox(height: 16),
          ],
        );
      }).toList(),
    ),
  ),
),
        ],
      ),
    );
  }
}

