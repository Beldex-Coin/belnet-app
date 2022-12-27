import 'package:belnet_mobile/src/model/one.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import '../model/sone.dart';

class ExpandDropdownList extends StatefulWidget {
  const ExpandDropdownList({Key? key}) : super(key: key);

  @override
  State<ExpandDropdownList> createState() => _ExpandDropdownListState();
}

class _ExpandDropdownListState extends State<ExpandDropdownList> {
   List<Menu> data = [];
   List<List<ExitNodeDataList>> exitData = [];

  @override
  void initState() {
    getListData();
    saveData();
      dataList.forEach((element) {
      data.add(Menu.fromJson(element));
    });
    super.initState();
  }



Future<List<ExitNodeDataList>> getListData()async {
    var response =await http.get(Uri.parse('https://testdeb.beldex.io/Beldex-Projects/Belnet/android/exitlist/modeljson.json')); //https://deb.beldex.io/Beldex-projects/Belnet/exitlist.json
    //var mydata;
    try{
      if(response.statusCode == 200){
         print(response.body);
      }
    }  
    catch(e){
      print(e.toString());
    }
    return exitNodeDataListFromJson(response.body);
   }


saveData(){

}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: _drawer(data),
        appBar: AppBar(
          title: const Text('Expandable ListView'),
        ),
        body: ListView.builder(
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) =>
              _buildList(data[index]),
        ),
      );
  }
 Widget _drawer (List<Menu> data){
    return Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                UserAccountsDrawerHeader(margin: EdgeInsets.only(bottom: 0.0),
                    accountName: Text('demo'), accountEmail: Text('demo@webkul.com')),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder:(context, index){return _buildList(data[index]);},)
              ],
            ),
          ),
        ));
  }
 
  Widget _buildList(Menu list) {
    if (list.subMenu.isEmpty)
      return Builder(
        builder: (context) {
          return ListTile(
              onTap:() =>{},  //Navigator.push(context, MaterialPageRoute(builder: (context) => SubCategory(list.name))),
              leading: SizedBox(),
              title: Text("list.name.toString()")
          );
        }
      );
    return ExpansionTile(
      leading: Icon(list.icon),
      title: Text(
        list.name.toString(),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: list.subMenu.map(_buildList).toList(),
    );
  }
}