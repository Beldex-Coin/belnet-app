import 'package:get/get_connect/http/src/_http/interface/request_base.dart';

import 'exitnodeModel.dart';
import 'package:http/http.dart' as http;
class DataRepo{
   Future<List<ExitNodeList>> getDataFromNet()async {
    var response =await http.get(Uri.parse('http://10.0.2.2:3000/list/exitnodes'));
    //var mydata;
    try{
      if(response.statusCode == 200){
         print(response.body);
      }
    }  
    catch(e){
      print(e.toString());
    }
    return exitNodeListFromJson(response.body);
   }
}