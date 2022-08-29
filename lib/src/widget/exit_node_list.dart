

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

import '../model/theme_set_provider.dart';

class ExitNodeList extends StatefulWidget {
  const ExitNodeList({Key? key}) : super(key: key);

  @override
  State<ExitNodeList> createState() => _ExitNodeListState();
}

class _ExitNodeListState extends State<ExitNodeList> {

List exitNodes = [
  // '7a4cpzri7qgqen9a3g3hgfjrijt9337qb19rhcdmx5y7yttak33o.bdx',
  // 'gosihdxzcwwcc4zibikc9fte7i8dxqkaohcgyqcjcwj5cncyy36o.bdx',
  // 'c17bqguk87hroszro9s69bm5ne6edrronpasfkcyp9mcwogikdmo.bdx',
  'exit.bdx',
  'service.bdx',
  'belnet.bdx',
  'beldex.bdx',
  'exit1.bdx'
];

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: appModel.darkTheme
              ? [
            Color(0xFF242430),
            Color(0xFF1C1C26),
          ]
              : [
            Color(0xFFF9F9F9),
            Color(0xFFEBEBEB),
          ],
        ),
      ),
      child: Scaffold(
       backgroundColor: Colors.transparent,
        appBar: AppBar(

          title: Text(
            'Exit Node',
            style: Theme.of(context)
                .textTheme
                .headline6!
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        body:ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(20),
          children: [
            // RichText(
            //     text: TextSpan(
            //         text: 'Premuim',
            //         style: Theme.of(context)
            //             .textTheme
            //             .subtitle2!
            //             .copyWith(fontWeight: FontWeight.w700),
            //         children: [
            //           TextSpan(
            //               text: 'Servers',
            //               style: Theme.of(context)
            //                   .textTheme
            //                   .subtitle2!
            //                   .copyWith(fontWeight: FontWeight.normal))
            //         ])),
            // SizedBox(
            //   height: 20,
            // ),
            // Container(
            //   child: ListView.separated(
            //     shrinkWrap: true,
            //     itemCount: exitNodes.length,
            //     itemBuilder: (_, index) {
            //       return ServerItemWidget(
            //           isFaded: true,
            //           label: exitNodes[index],
            //           icon: Icons.lock,
            //           flagAsset: exitNodes[index],
            //           onTap: () {});
            //     },
            //     separatorBuilder: (_, index) => SizedBox(height: 10),
            //   ),
            // ),
            SizedBox(height: 30),
            RichText(
                text: TextSpan(
                    text: 'Custom exit node ',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(fontWeight: FontWeight.w700),
                    children: [
                      // TextSpan(
                      //     text: 'Servers',
                      //     style: Theme.of(context)
                      //         .textTheme
                      //         .subtitle2!
                      //         .copyWith(fontWeight: FontWeight.normal))
                    ])),

            SizedBox(height: 20),
            Container(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: 2,
                itemBuilder: (_, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color:Color(0xff00DC00)),
                      color: appModel.darkTheme ? Color(0xff242430) : Color(0xff00000033),
                    ),



                    child: Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: TextField()

                    ),
                  );
                },
                separatorBuilder: (_, index) => SizedBox(height: 10),
              ),
            ),
            RichText(
                text: TextSpan(
                    text: 'Custom exit node ',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(fontWeight: FontWeight.w700),
                    children: [
                      // TextSpan(
                      //     text: 'Servers',
                      //     style: Theme.of(context)
                      //         .textTheme
                      //         .subtitle2!
                      //         .copyWith(fontWeight: FontWeight.normal))
                    ])),
            SizedBox(
              height: 20,
            ),
            Container(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: exitNodes.length,
                itemBuilder: (_, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color:Color(0xff00DC00)),
                      color: appModel.darkTheme ? Color(0xff242430) : Color(0xff00000033),
                    ),



                    child: Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.black,
                                backgroundImage: ExactAssetImage(
                                  'assets/images/belnet_ic.png',
                                ),
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: Text(
                                  exitNodes[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color:appModel.darkTheme ? Color(0xff00DC00) : Color(0xff0094FF),
                                      fontSize: MediaQuery.of(context).size.height*0.06/3, fontWeight:FontWeight.w900,

                                  )
                                ),
                              ),
                            ],
                          ),
                          RoundCheckBox(
                            borderColor: Color(0xff00DC00),
                            onTap: (bool? value) {  },

                              )
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, index) => SizedBox(height: 10),
              ),
            )
          ],
        ),
        // ListView.builder(
        //     itemCount: exitNodes.length,
        //     itemBuilder: (BuildContext context, int index) {
        //       return Container(
        //         color: appModel.darkTheme ? Color(0xff292937) : Colors.white,
        //
        //         child: Padding(
        //           padding: EdgeInsets.all(10),
        //           child: ListTile(
        //             title: Text(
        //               exitNodes[index],
        //               style: TextStyle(
        //                 fontSize: 20,
        //                 color: Colors.white,
        //               ),
        //             ),
        //             // leading: CircleAvatar(
        //             //   child: Text(
        //             //     exitNodes[index],
        //             //     style:
        //             //     TextStyle(fontSize: 15, fontWeight: FontWeight.bold,color:Colors.white),
        //             //   ),
        //             // ),
        //             //trailing: Text("\$ ${stocksList[index].price}"),
        //           ),
        //         ),
        //       );
        //     }),
      ),
    );
  }
}



class ServerItemWidget extends StatelessWidget {
  const ServerItemWidget(
      {Key? key,
        required this.label,
        required this.icon,
        required this.flagAsset,
        required this.onTap, this.isFaded = false})
      : super(key: key);

  final String label;
  final IconData icon;
  final String flagAsset;
  final Function onTap;
  final isFaded;

  @override
  Widget build(BuildContext context) {
    final appModel =  Provider.of<AppModel>(context);
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  backgroundImage: ExactAssetImage(
                    flagAsset,
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Text(
                  label,
                  style:TextStyle(color:appModel.darkTheme ? Color(0xff00DC00) : Color(0xff0094FF),
                  fontSize: MediaQuery.of(context).size.height*0.06/3, fontWeight:FontWeight.w900
                  ) //Theme.of(context).textTheme.bodyText1,
                ),
              ],
            ),
            IconButton(
              icon: Icon(icon),
              onPressed: onTap(),
              iconSize: 18,
              color: isFaded ? Colors.grey : Theme.of(context).iconTheme.color,
            )
          ],
        ),
      ),
    );
  }
}