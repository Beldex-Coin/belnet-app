import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/graph_ui.dart';
import 'package:belnet_mobile/src/providers/ip_provider.dart';
import 'package:belnet_mobile/src/providers/log_provider.dart';
import 'package:belnet_mobile/src/widget/LineChartSample10.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';

class ChartScreen extends StatefulWidget {
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with SingleTickerProviderStateMixin{


late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _widthAnimation;
 bool value = false;

 bool canShowIP = false;
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1), // From top
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _widthAnimation = Tween<double>(
      begin: 0.2,  // Narrow (20% of full width)
      end: 1.0,    // Full width
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

checkRunning();

  }


  void checkRunning()async{
     value = await BelnetLib.isRunning.asStream().first;
     setState(() {
       
     });
     print('THE STREAM VALUE FROM THE RUNNING STATUS ${value}');
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for changes in log list and auto-scroll
    final logProvider = Provider.of<LogProvider>(context);
    logProvider.addListener(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }




  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }










  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final ipProvider = Provider.of<IpProvider>(context);
        final logProvider = Provider.of<LogProvider>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text( 'Analytics', style: TextStyle(fontFamily: 'Poppins',fontSize: 18,fontWeight: FontWeight.w500),),
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
      body: GlassContainer.clearGlass(
         width: double.infinity,
   height: height*2.26/3,
      margin: EdgeInsets.all(10),
      blur: 5.0,
        color: Colors.black.withOpacity(0.03), //.black38, // Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        borderColor: Color(0xffACACAC).withOpacity(0.6),
        borderWidth: 0.3,
        padding: EdgeInsets.symmetric(vertical: 15,horizontal: 10),
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer.clearGlass(
              blur: 15.0,
              color: Colors.white.withOpacity(0.01),
              height: MediaQuery.of(context).size.height*0.53/3, //130,
              width: double.infinity,
              borderRadius: BorderRadius.circular(14),
              borderColor: Colors.transparent,
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IP Address',style: TextStyle(fontFamily: 'Poppins'),),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children:[
                      Expanded(
                        child: GlassContainer(
                          height:  height*0.33/3,
                           blur: 15.0,
                                      color: Colors.white.withOpacity(0.06),
                                         borderRadius: BorderRadius.circular(14),
                                      borderColor: Colors.transparent,
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('My IP  ',style: TextStyle(color: Color(0xffACACAC),fontSize: 12,fontFamily: 'Poppins'),),
                                              GestureDetector(
                                                onTap: ()=>setState(() {
                                                  canShowIP = !canShowIP;
                                                }),
                                                child: SvgPicture.asset('assets/images/dark_theme/view_IP.svg')),
                                                //Icon(Icons)
                                            ],

                                          ),
                                          SizedBox(height: 10,),
                                      !canShowIP ? Text( '***.**.**.***',style: TextStyle(fontFamily: 'Poppins',fontSize: 12),)
                                      : Text( '${ipProvider.realIp}',style: TextStyle(fontFamily: 'Poppins',fontSize: 12),),

                                        ],
                                      ),
                        ),
                      ),
                      SizedBox(width: 5,),
                      Expanded(
                        child: GlassContainer(
                          height: height*0.33/3,
                           blur: 15.0,
                                      color: Colors.white.withOpacity(0.06),
                                         borderRadius: BorderRadius.circular(14),
                                      borderColor: Colors.transparent,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children:[
                                          RichText(
                          textAlign: TextAlign.justify,
                            text: TextSpan(
                                text: "IPV4: ",
                                style: TextStyle(
                                    fontSize:12, //mHeight * 0.060 / 3,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Color(0xff00DC00)),
                                children: [
                              TextSpan(
                                  text:ipProvider.currentIPv4,
                                      style: TextStyle(
                                      fontSize:12, //mHeight * 0.056 / 3,
                                      fontWeight: FontWeight.w100,
                                      fontFamily: 'Poppins',
                                      color: Color(0xffffffff)
                                          ))
                            ])),
                              RichText(
                          textAlign: TextAlign.justify,
                            text: TextSpan(
                                text: "IPV6: ",
                                style: TextStyle(
                                    fontSize:12, //mHeight * 0.060 / 3,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Color(0xff00A3FF)),
                                children: [
                              TextSpan(
                                  text:ipProvider.currentIPv6,
                                      style: TextStyle(
                                      fontSize:12, //mHeight * 0.056 / 3,
                                      fontWeight: FontWeight.w100,
                                      fontFamily: 'Poppins',
                                      color: Color(0xffffffff)
                                          ))
                            ])),
                                        ]
                                      ),
                        ),
                      )
                      ]
                    ),
                  )
                ],
              ),
            ),
            //DynamicNetworkSpeedChart(),
               Row(
                 mainAxisAlignment: MainAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       CircleAvatar(radius: 3, backgroundColor: Color(0xff00DC00)),
                       SizedBox(width: 5),
                       Text('Download', style: TextStyle(color: Color(0xffACACAC),fontFamily: 'Poppins',fontSize: 9)),
                     ],
                   ),
                   SizedBox(width: 10),
                   Row(
                     children: [
                       CircleAvatar(radius: 3, backgroundColor: Color(0xff00A3FF)),
                       SizedBox(width: 5),
                       Text('Upload', style: TextStyle(color: Color(0xffACACAC),fontFamily: 'Poppins',fontSize: 9)),
                     ],
                   ),
                 ],
               ),
            //ChartData(),
            Container(
              height: 180,
              child: ChartWidget()),
           // NetworkSpeedChart(),
            Flexible(
              child: SlideTransition(
                position: _slideAnimation,
                child: AnimatedBuilder(
                  
                  builder: (context, snapshot) {
                    return GlassContainer.clearGlass(
                      color: Colors.grey.withOpacity(0.05),
                      width: screenWidth * _widthAnimation.value,
                      borderColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Logs',style: TextStyle(fontFamily: 'Poppins',fontSize: 14),),
                              Spacer(),
                              Row(
                                children: [
                                //   Container(
                                //     height: 33,//width: 70,
                                // padding: EdgeInsets.symmetric(vertical:  8,horizontal: 10),
                                //     decoration: BoxDecoration(
                                //       color: Colors.grey.withOpacity(0.06),
                                //       borderRadius: BorderRadius.circular(20)
                                //     ),
                                //     child: Row(
                                //       children:[
                                //          SvgPicture.asset(),
                                //          SizedBox(width: 5,),
                                //         Text('Clear',style: TextStyle(fontFamily: 'Poppins',fontSize: 11),)
                                //       ]
                                //     ),
                                //   ),
                              optionButton(icon: 'assets/images/dark_theme/clear_logs.svg', text: 'Clear', onPressed: ()=> print('Cleared')),

                                ],
                              ),
                              SizedBox(width: 5,),
                              optionButton(onPressed: ()=>print('Log copied'),text: 'Copy',icon:'assets/images/dark_theme/copy_logs.svg',)
                            ],
                          ),
                          Expanded(
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 3,
                    radius: Radius.circular(5),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SelectableText.rich(
                          TextSpan(
                            children: logProvider.logs.map(_buildStyledLog).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                        ],
                      ),
                    );
                  }, animation: _widthAnimation,
                ),
              ),
            ),
            
           // DynamicNetworkSpeedChart()
           // NetworkSpeedGraph(),
          ],
        ),
      )
      //Center(child: Text('Working', style: TextStyle(fontSize: 24))),
    );
  }
  TextSpan _buildStyledLog(LogEntry log) {
    final formattedTime = log.timestamp.millisecondsSinceEpoch.toString();
    final fullMessage = "$formattedTime: ${log.message}";
    final parts = fullMessage.split("Daemon");

    if (parts.length == 2) {
      return TextSpan(
        style: TextStyle(fontSize: 11),
        children: [

        TextSpan(text: parts[0], style: const TextStyle(color: Color(0xffACACAC))),
        const TextSpan(text: "Daemon", style: TextStyle(color: Color(0xff00DC00), fontWeight: FontWeight.bold)),
        TextSpan(text: parts[1] + "\n", style: const TextStyle(color: Colors.white)),
      ]);
    } else {
      return TextSpan(
        children: [
          TextSpan(text: formattedTime,style: const TextStyle(color: Color(0xffACACAC),fontSize: 11)),
          TextSpan(text: ": "+log.message + "\n", style: const TextStyle(color: Colors.white,fontSize: 11)
)
        ],
        
        );
    }
  }
}






class optionButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onPressed;
  const optionButton({
    super.key, required this.icon, required this.text, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 33,//width: 70,
        padding: EdgeInsets.symmetric(vertical:  8,horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20)
        
        ),
        child: Row(
          children:[
             SvgPicture.asset(icon),
             SizedBox(width: 5,),
            Text(text,style: TextStyle(fontFamily: 'Poppins',fontSize: 11),)
          ]
        ),
      ),
    );
  }
}

