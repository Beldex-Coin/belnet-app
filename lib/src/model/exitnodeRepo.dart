import 'package:belnet_mobile/src/model/exitnodeCategoryModel.dart';
import 'package:get/get_connect/http/src/_http/interface/request_base.dart';

import 'exitnodeModel.dart';
import 'package:http/http.dart' as http;
class DataRepo{
   Future<List<ExitnodeList>> getDataFromNet()async {
    var response =await http.get(Uri.parse('https://testdeb.beldex.dev/Beldex-Projects/Belnet/android/exitlist/jsonSample.json')); //https://deb.beldex.io/Beldex-projects/Belnet/exitlist.json
    //var mydata;
    try{
      if(response.statusCode == 200){
         print(response.body);
      }
    }  
    catch(e){
      print(e.toString());
    }
    return exitnodeListFromJson(response.body);
   }


Future<List<ExitNodeDataList>> getListData() async {
    var response = await http.get(Uri.parse(
        'https://testdeb.beldex.dev/Beldex-Projects/Belnet/android/exitlist/modeljson.json'));;
     //https://deb.beldex.io/Beldex-projects/Belnet/exitlist.json
    //var mydata;
    try {
      //response 
      if (response.statusCode == 200) {
        print(response.body);
      }
    } catch (e) {
      print(e.toString());
    }
    return exitNodeDataListFromJson(response.body);
  }



}