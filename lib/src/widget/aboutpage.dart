import 'package:clipboard/clipboard.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/theme_set_provider.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AboutPage> with SingleTickerProviderStateMixin{
  final ScrollController scrollController = ScrollController();


  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;



 @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),//300
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward(); // Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }






  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final mHeight = MediaQuery.of(context).size.height;
    final mWidth = MediaQuery.of(context).size.width;
    return SlideTransition(
      position: _offsetAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left:  8.0),
            child:  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                        text: TextSpan(
                            text: 'About',
                            style: TextStyle(
                                fontSize: mHeight *
                                    0.09 /
                                    3,
                                //fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                                color: appModel.darkTheme
                                    ? Colors.white
                                    : Colors.black),
                            children: [
                          TextSpan(
                              text: ' Belnet',
                              style: TextStyle(
                                  fontSize:
                                      mHeight *
                                          0.09 /
                                          3,
                                  //fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  color:const Color(0xff23DC27)))
                        ])),
                    
                  ],
                )
          ),
          leadingWidth: 170,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:  12.0),
              child: GestureDetector(
                        onTap: (() {
                          Navigator.pop(context);
                        }),
                        child: Container(
                          child: SvgPicture.asset(
                              appModel.darkTheme
                                  ? 'assets/images/About_Close_dark.svg'
                                  : 'assets/images/Close_about_white_theme.svg',
                              width: mHeight * 0.09 / 3,
                              height: mHeight * 0.09 / 3),
                        ),
                      ),
            )
          ],
        ),
        // appBar: PreferredSize(
        //     preferredSize: Size.fromHeight(
        //         mHeight * 0.80 / 3),
        //     child: Container(
        //         height: mHeight * 0.45 / 3,
        //         padding: EdgeInsets.only(
        //             left:mHeight * 0.08 / 3,
        //             right: mHeight * 0.08 / 3,
        //             top: mHeight * 0.13 / 3),
        //         decoration: BoxDecoration(color: Colors.transparent),
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             RichText(
        //                 text: TextSpan(
        //                     text: 'About',
        //                     style: TextStyle(
        //                         fontSize: mHeight *
        //                             0.09 /
        //                             3,
        //                         fontWeight: FontWeight.w900,
        //                         fontFamily: 'Poppins',
        //                         color: appModel.darkTheme
        //                             ? Colors.white
        //                             : Colors.black),
        //                     children: [
        //                   TextSpan(
        //                       text: ' Belnet',
        //                       style: TextStyle(
        //                           fontSize:
        //                               mHeight *
        //                                   0.09 /
        //                                   3,
        //                           fontWeight: FontWeight.w900,
        //                           fontFamily: 'Poppins',
        //                           color:const Color(0xff23DC27)))
        //                 ])),
        //             GestureDetector(
        //               onTap: (() {
        //                 Navigator.pop(context);
        //               }),
        //               child: Container(
        //                 child: SvgPicture.asset(
        //                     appModel.darkTheme
        //                         ? 'assets/images/About_Close_dark.svg'
        //                         : 'assets/images/Close_about_white_theme.svg',
        //                     width: mHeight * 0.09 / 3,
        //                     height: mHeight * 0.09 / 3),
        //               ),
        //             )
        //           ],
        //         ))),
        body: Container(
            // color: Colors.black,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/dark_theme/BG.png'), // <-- your image
                  fit: BoxFit.cover,
                ),
              ),
            // padding: EdgeInsets.only(right:mHeight*0.05/3),
            child: GlassContainer.clearGlass(
                color: Colors.black.withOpacity(0.5),
                borderColor: Colors.transparent,
              child: SafeArea(
                child: Container(
                    margin: EdgeInsets.only(top:25, bottom: 15,left:10,right:10),
                    decoration: BoxDecoration(
                     // color: Colors.black.withOpacity(0.5),
                     border: Border.all(color: Color(0xffACACAC).withOpacity(0.3),width: 0.5),
                                        borderRadius: BorderRadius.circular(12),
      
                    ),
                   
                    padding: EdgeInsets.only(top: 20,right: 10),
                    
                  child: ScrollConfiguration(
                    behavior: NoGlowScrollBehavior(),
                    child: RawScrollbar(
                              thumbColor:
                      appModel.darkTheme ? const Color(0xffACACAC) :const Color(0xffC7C7C7),
                              //controller: scrollController,
                              thumbVisibility: true,
                              thickness: 4,
                              radius: Radius.circular(10),
                              child: Container(
                    //color: appModel.darkTheme ?const Color(0xff111117) :const Color(0xffE3E3E3),
                                    padding: EdgeInsets.only(left: 5.0),
                    child: SingleChildScrollView(
                      physics: ClampingScrollPhysics(),
                        child: Padding(
                      
                      padding: EdgeInsets.only(
                          left: 8, right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            """BelNet is a decentralized VPN service built on top of the Beldex Network.The BelNet dVPN utilizes Beldex masternodes to route your connection.\n\n A unique onion routing protocol is used to encrypt and route your data.""",
                            style: TextStyle(
                                fontSize:13, //mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                            textAlign: TextAlign.justify,
                          ),
                          Text(
                            "\nWhat are exit nodes?",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          Text(
                            """Exit nodes on the Beldex network helps you browse the internet without exposing your IP address. They also hide your geographical location.BelNet has several uses and chief among them are,""",
                            style: TextStyle(
                                fontSize:13, //mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                                     textAlign: TextAlign.justify
                          ),
                          RichText(
                            textAlign: TextAlign.justify,
                              text: TextSpan(
                                  text: "\nUnblocking content:",
                                  style: TextStyle(
                                      fontSize:13, //mHeight * 0.060 / 3,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: appModel.darkTheme
                                          ? Colors.white
                                          : Colors.black),
                                  children: [
                                TextSpan(
                                    text:
                                        """ Certain websites may be blocked in your region. BelNet can be used to unblock these websites. For example, a streaming platform may be restricted in your region. With BelNet, you can unblock this website, pay for the streaming service and enjoy watching the content that you love!""",
                                    style: TextStyle(
                                        fontSize:13, //mHeight * 0.056 / 3,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                            ))
                              ])),
                          RichText(
                            textAlign: TextAlign.justify,
                              text: TextSpan(
                                  text: "\nMasking your IP & Location:",
                                  style: TextStyle(
                                      fontSize:13,// mHeight * 0.060 / 3,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: appModel.darkTheme
                                          ? Colors.white
                                          : Colors.black),
                                  children: [
                                TextSpan(
                                    text:
                                        """ The websites that you visit only see the exit node’s IP address while your IP remains concealed. It is also hidden from your Internet Service Provider (ISP), mobile network operator, and even prying regulators. Your online activity remains truly anonymous!""",
                                    style: TextStyle(
                                        fontSize:13,// mHeight * 0.056 / 3,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                            ))
                              ])),
                          RichText(
                            textAlign: TextAlign.justify,
                              text: TextSpan(
                                  text: "\nSecurity:",
                                  style: TextStyle(
                                      fontSize:13,// mHeight * 0.060 / 3,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: appModel.darkTheme
                                          ? Colors.white
                                          : Colors.black),
                                  children: [
                                TextSpan(
                                    text:
                                        """ You are protected from hackers and malicious actors that try to steal your information. Since all data about you remains confidential when you’re browsing, there’s very little window of opportunity for bad actors to pilfer your personal and confidential information. """,
                                    style: TextStyle(
                                        fontSize:13,// mHeight * 0.056 / 3,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                            ))
                              ])),
                          RichText(
                            textAlign: TextAlign.justify,
                              text: TextSpan(
                                  text: "\nProtects your identity:",
                                  style: TextStyle(
                                      fontSize:13,// mHeight * 0.060 / 3,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: appModel.darkTheme
                                          ? Colors.white
                                          : Colors.black),
                                  children: [
                                TextSpan(
                                    text:
                                        """ Masking your IP also protects your identity online. Your browsing history, purchase history, and any financial information is only available to you. That means, no more cookies, trackers, and relevant ads that pursue you no matter where you go.""",
                                    style: TextStyle(
                                        fontSize:13,// mHeight * 0.056 / 3,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Poppins',
                                        color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                            ))
                              ])),
                          Text(
                            "\nDoes BelNet block ads? ",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          Text(
                            """BelNet conceals your IP. Thus, your browsing history remains confidential and inaccessible to the destination website and third parties. However, you may still be shown ads that aren’t relevant to your browsing history.""",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                                     textAlign: TextAlign.justify
                          ),
                          Text(
                            "\nWhere are the current exit nodes located?",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          Text(
                            """There are currently three active exit nodes maintained by the Beldex foundation. They are located in the Netherlands (2) and France (1).""",
                            style: TextStyle(
                                fontSize:13, //mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                                     textAlign: TextAlign.justify
                          ),
                          Text(
                            "\nCan you set up an exit node?",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          RichText(
                            textAlign: TextAlign.justify,
                              text: TextSpan(
                                  text:
                                      """Yes, anyone can set up an exit node. Check the """,
                                  style: TextStyle(
                                      fontSize:13,// mHeight * 0.056 / 3,
                                      //fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                          ),
                                  children: [
                                    TextSpan(
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = (() async {
                                            if (await canLaunchUrl(Uri.parse(
                                                "https://belnet.beldex.io/"))) {
                                              await launchUrl(
                                                  Uri.parse(
                                                      "https://belnet.beldex.io/"),
                                                  mode:
                                                      LaunchMode.externalApplication);
                                            } else {
                                              throw 'Could not launch https://belnet.beldex.io/';
                                            }
                                          }),
                                        text: """Belnet""",
                                        style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            fontSize:13,// mHeight * 0.056 / 3,
                                            fontFamily: "Poppins",
                                            color: Colors.blue)),
                                    TextSpan(
                                      text:
                                          """ website for complete documentation on how to set up an exit node.\nYou can also find the setup guide under """,
                                      style: TextStyle(
                                          fontSize:13,// mHeight * 0.056 / 3,
                                          fontFamily: "Poppins",
                                          color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                              ),
                                    ),
                                    TextSpan(
                                        text: """Beldex docs""",
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = (() async {
                                            if (await canLaunchUrl(Uri.parse(
                                                "https://docs.beldex.io/belnet/exit-node-setup-guide"))) {
                                              await launchUrl(
                                                  Uri.parse(
                                                      "https://docs.beldex.io/belnet/exit-node-setup-guide"),
                                                  mode:
                                                      LaunchMode.externalApplication);
                                            } else {
                                              throw 'Could not launch https://docs.beldex.io/belnet/exit-node-setup-guide';
                                            }
                                          }),
                                        style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            fontSize:12,// mHeight * 0.056 / 3,
                                            fontFamily: "Poppins",
                                            color: Colors.blue)),
                                    TextSpan(
                                      text:
                                          """. Exit node contributors will be rewarded and their node will be added to the BelNet app. To add your exit node to the BelNet app, reach out to """,
                                      style: TextStyle(
                                          fontSize:13,// mHeight * 0.056 / 3,
                                          fontFamily: "Poppins",
                                          color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                              ),
                                               
                                    ),
                                   TextSpan(
                                      text: """outreach@beldex.io""",
                                      recognizer: TapGestureRecognizer()..onTap = (() {
                                         FlutterClipboard.copy("outreach@beldex.io")
                                    .then((value) => ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            backgroundColor: appModel.darkTheme
                                                ? Colors.black.withOpacity(0.50)
                                                : Colors.white,
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(milliseconds: 200),
                                            width: 200,
                                            content: Text(
                                              "Copied to clipboard!",
                                              style: TextStyle(
                                                  color: appModel.darkTheme
                                                      ? Colors.white
                                                      : Colors.black),
                                              textAlign: TextAlign.center,
                                            )
                                            //content: Text("Sending Message"),
                                            )));
                    
                                      }),
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                            fontSize:12,// mHeight * 0.056 / 3,
                                            fontFamily: "Poppins",
                                            color: Colors.blue
                                      )
                                   )
                            
                                  ])),
                          Text(
                            "\nWhat are MN Apps? ",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          Text(
                            """MN Apps are decentralized applications hosted on BelNet.MN Apps are confidentiality-focused applications and do not collect or reveal any personal information about the user.They can be accessed only by connecting to BelNet.Below is a sample MNApp that you can access by enabling BelNet:""",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                                     textAlign: TextAlign.justify
                          ),
                          GestureDetector(
                            onTap: () async {
                              //FlutterClipboard.copy("http://cw41adqqhykuxw51xmagkkb3fixyieat1josbux13jn6o973tqgy.bdx/");
                              if (await canLaunchUrl(Uri.parse(
                                  "http://explorer.bdx/"))) {
                                await launchUrl(
                                    Uri.parse(
                                        "http://explorer.bdx/"),
                                    mode: LaunchMode.externalApplication);
                              } else {
                                throw 'Could not launch http://explorer.bdx/';
                              }
                            },
                            child: Text(
                              """http://explorer.bdx/""",
                              style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontSize:13,// mHeight * 0.056 / 3,
                                  fontFamily: "Poppins",
                                  color: Colors.blue),
                            ),
                          ),
                          Text(
                            "\nWhat are BNS Names?",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          Text(
                            """BNS stands for Beldex Name Service. BNS names are human readable domain names on BelNet. BNS is a censorship-free, decentralized, unstoppable domain name service. 
                    
                    It has many utilities. For example, BNS names could be mapped to MN Apps to make them easily readable and discoverable.
                    
                    The Beldex team is researching the possibility of mapping BNS names to BChat IDs and your wallet address so you can send and receive messages as well as BDX with your BNS name.
                    
                    BNS names end with the top level domain .bdx
                     Example: yourname.bdx""",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                                     textAlign: TextAlign.justify
                          ),
                          Text(
                            "\nCredits:",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.060 / 3,
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                color:
                                    appModel.darkTheme ? Colors.white : Colors.black),
                          ),
                          Text(
                            """BelNet uses several protocols that were designed by the open source projects Tor, I2P, and Lokinet.\n""",
                            style: TextStyle(
                                fontSize:13,// mHeight * 0.056 / 3,
                                fontFamily: "Poppins",
                                color: appModel.darkTheme
                                    ?  Color(0xffACACAC)  //Color(0xffA1A1C1) 
                                    : Color(0xff24242F)  //Color(0xff56566F)
                                    ),
                                     textAlign: TextAlign.justify
                          ),
                        ],
                      ),
                    )),
                              ),
                            ),
                  ),
                ),
              ),
            )),
      ),
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
