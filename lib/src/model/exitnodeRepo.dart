import 'package:get/get_connect/http/src/_http/interface/request_base.dart';

import 'exitnodeModel.dart';
import 'package:http/http.dart' as http;
class DataRepo{
   Future<List<ExitnodeList>> getDataFromNet()async {
    var response =await http.get(Uri.parse('https://deb.beldex.io/Beldex-projects/Belnet/exitlist.json'));
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
}