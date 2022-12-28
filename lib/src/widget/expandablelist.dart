import 'package:belnet_mobile/src/model/one.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../model/sone.dart';

class ExpandDropdownList extends StatefulWidget {
  const ExpandDropdownList({Key? key}) : super(key: key);

  @override
  State<ExpandDropdownList> createState() => _ExpandDropdownListState();
}

class _ExpandDropdownListState extends State<ExpandDropdownList> {
  List<ExitNodeDataList> exitData = [];

  @override
  void initState() {
    getListData();
    saveData();
    super.initState();
  }

  Future<List<ExitNodeDataList>> getListData() async {
    var response = await http.get(Uri.parse(
        'https://testdeb.beldex.io/Beldex-Projects/Belnet/android/exitlist/modeljson.json')); //https://deb.beldex.io/Beldex-projects/Belnet/exitlist.json
    //var mydata;
    try {
      if (response.statusCode == 200) {
        print(response.body);
      }
    } catch (e) {
      print(e.toString());
    }
    return exitNodeDataListFromJson(response.body);
  }

  saveData() async {
    var res = await getListData();
    exitData.addAll(res);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //drawer: _drawer(data),
      appBar: AppBar(
        title: const Text('Expandable ListView'),
      ),
      body: ListView.builder(
          itemCount: exitData.length,
          itemBuilder: (BuildContext context, int index) {
            print("data inside listview ${exitData[index]}");
            return ExpansionTile(
              title: Text(
                exitData[index].type,
                style: TextStyle(
                    color: index == 0 ? Color(0xff1CBE20) : Color(0xff1994FC),
                    fontSize: MediaQuery.of(context).size.height * 0.06 / 3,
                    fontWeight: FontWeight.bold),
              ),
              iconColor: index == 0 ? Color(0xff1CBE20) : Color(0xff1994FC),
              collapsedIconColor:
                  index == 0 ? Color(0xff1CBE20) : Color(0xff1994FC),
              subtitle: Text(
                "${exitData[index].node.length} Nodes",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: MediaQuery.of(context).size.height * 0.04 / 3),
              ),
              children: <Widget>[
                Column(
                  children: _buildExpandableContent(exitData[index].node),
                ),
              ],
            );
          }
          // _buildList(exitData[index]),
          ),
    );
  }

  _buildExpandableContent(List<Node> vnode) {
    List<Widget> columnContent = [];
    for (int i = 0; i < vnode.length; i++) {
      columnContent.add(ListTile(
        onTap: () {
          print("$i th index ");
        },
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vnode[i].name,
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.height * 0.05 / 3),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              vnode[i].country,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: MediaQuery.of(context).size.height * 0.04 / 3),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        leading: SvgPicture.network(
          vnode[i].icon,
          height: MediaQuery.of(context).size.height * 0.10 / 3,
          width: MediaQuery.of(context).size.height * 0.15 / 3,
        ),
        trailing: Container(
          height: 5.0,
          width: 5.0,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: vnode[i].isActive == "true" ? Colors.green : Colors.red),
        ),
      ));
    }
    return columnContent;
  }
}
