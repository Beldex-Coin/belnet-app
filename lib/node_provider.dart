import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// class NodeProvider extends ChangeNotifier {
//   List<dynamic> _nodeData = [];

//   bool isLoading = false;
//   bool hasError = false;

//   List<dynamic> get nodeData => _nodeData;

//   Future<void> fetchNodes() async {
//     isLoading = true;
//     hasError = false;
//     notifyListeners();

//     try {
//       final response = await http.get(Uri.parse('https://testdeb.beldex.dev/Beldex-Projects/Belnet/android/exitlist/exitnode-bns-list.json'));

//       if (response.statusCode == 200) {
//         _nodeData = json.decode(response.body);
//         isLoading = false;
//         notifyListeners();
//       } else {
//         throw Exception('Failed to load data');
//       }
//     } catch (e) {
//       isLoading = false;
//       hasError = true;
//       notifyListeners();
//     }
//   }

//   Map<String, List<String>> groupByCountry(String type) {
//     final nodes = _nodeData.firstWhere(
//       (item) => item['type'] == type,
//       orElse: () => {'node': []},
//     )['node'] as List<dynamic>;

//     final Map<String, List<String>> grouped = {};
//     for (var node in nodes) {
//       String country = node['country'];
//       String name = node['name'];
//       if (!grouped.containsKey(country)) {
//         grouped[country] = [];
//       }
//       grouped[country]!.add(name);
//     }
//     return grouped;
//   }
// }

class NodeProvider extends ChangeNotifier {
  List<dynamic> _nodeData = [];
  int? _selectedNodeId;
  
  String? _selectedExitNodeName;
  String? _selectedExitNodeCountry;


  bool isLoading = false;
  bool hasError = false;

  List<dynamic> get nodeData => _nodeData;
  int? get selectedNodeId => _selectedNodeId;

  String? get selectedExitNodeName => _selectedExitNodeName;
  String? get selectedExitNodeCountry => _selectedExitNodeCountry;

  static const String selectedNodeKey = 'selected_node_id';

  static const String selectedNodeName = 'selected_node_name';

  static const String selectedNodeCountry = 'selected_node_country';

  NodeProvider() {
    _loadSelectedNode();
    fetchNodes();
  }

  Future<void> fetchNodes() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://testdeb.beldex.dev/Beldex-Projects/Belnet/android/exitlist/exitnode-bns-list.json'));

      if (response.statusCode == 200) {
        _nodeData = json.decode(response.body);
        isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      isLoading = false;
      hasError = true;
      notifyListeners();
    }
  }


Map<String, Map<String, dynamic>> groupByCountryWithIcon(String type) {
  final nodes = _nodeData.firstWhere(
    (item) => item['type'] == type,
    orElse: () => {'node': []},
  )['node'] as List<dynamic>;

  final Map<String, Map<String, dynamic>> grouped = {};

  for (var node in nodes) {
    String country = node['country'];
    if (!grouped.containsKey(country)) {
      grouped[country] = {
        'icon': node['icon'],
        'nodes': [],
      };
    }
    grouped[country]!['nodes'].add(node);
  }

  return grouped;
}

  // Map<String, List<Map<String, dynamic>>> groupByCountry(String type) {
  //   final nodes = _nodeData.firstWhere(
  //     (item) => item['type'] == type,
  //     orElse: () => {'node': []},
  //   )['node'] as List<dynamic>;

  //   final Map<String, List<Map<String, dynamic>>> grouped = {};
  //   for (var node in nodes) {
  //     String country = node['country'];
  //     if (!grouped.containsKey(country)) {
  //       grouped[country] = [];
  //     }
  //     grouped[country]!.add(node);
  //   }
  //   return grouped;
  // }

  Future<void> selectNode(int id,String name, String country) async {
    _selectedNodeId = id;
    _selectedExitNodeName = name;
    _selectedExitNodeCountry = country;
    notifyListeners();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(selectedNodeKey, id);
    await prefs.setString(selectedNodeName, name);
    await prefs.setString(selectedNodeCountry, country);
  }

  Future<void> _loadSelectedNode() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedNodeId = prefs.getInt(selectedNodeKey);
    _selectedExitNodeName = prefs.getString(selectedNodeName);
    _selectedExitNodeCountry = prefs.getString(selectedNodeCountry);
    notifyListeners();
  }
 
  int getNodeCount(String type) {
  final nodes = _nodeData.firstWhere(
    (item) => item['type'] == type,
    orElse: () => {'node': []},
  )['node'] as List<dynamic>;

  return nodes.length;
}

}











// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'node_provider.dart';


class NodeTabScreen extends StatefulWidget {
  @override
  _NodeTabScreenState createState() => _NodeTabScreenState();
}

class _NodeTabScreenState extends State<NodeTabScreen> {
  final List<String> tabTypes = ['Beldex Official', 'Contributor exit node'];
  String selectedType = 'Beldex Official';

  @override
  void initState() {
    super.initState();
    // Future.microtask(() {
    //   Provider.of<NodeProvider>(context, listen: false).fetchNodes();
    // });
  }

  @override
  Widget build(BuildContext context) {
    final nodeProvider = Provider.of<NodeProvider>(context);

    if (nodeProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (nodeProvider.hasError) {
      return Center(child: Text('Failed to load data'));
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
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: tabTypes.map((type){
      final isSelected = type == selectedType;
      final count = nodeProvider.getNodeCount(type);
      return Expanded(
        child: GestureDetector(
          onTap: (){
            setState(() {
                        selectedType = type;
                      });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer container for the gradient border
              Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color:selectedType == 'Beldex Official' && type== 'Beldex Official' ? Color(0xFF00DC00) : selectedType == 'Contributor exit node' && type== 'Contributor exit node' ?Color(0xFF0094FF) : Colors.transparent,
                                     width: 0.4),
                  gradient: LinearGradient(
                    colors: [
                     // Color(0xff464663),
                      Color(0xFF464663),
                     selectedType == 'Beldex Official' && type== 'Beldex Official' ? Color(0xFF00DC00).withOpacity(0.6) : selectedType == 'Contributor exit node' && type== 'Contributor exit node' ?Color(0xFF0094FF).withOpacity(0.6): Colors.transparent,
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
                  margin: EdgeInsets.only(right: 1,left: 1),
                  decoration: BoxDecoration(
                    color: Color(0xff464663).withOpacity(0.5), //Colors.transparent,
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
                      //SvgPicture.asset('assets/images/dark_theme/add_exit_node.svg', color: Color(0xFF00DC00)),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(type == 'Contributor exit node' ? ' Contributor Nodes' : 'Beldex Nodes', //type,
                          //'Beldex Nodes',
                          style: TextStyle(
                            color: selectedType == 'Contributor exit node' && type == 'Contributor exit node'  ? Color(0xFF0094FF) : selectedType == 'Beldex Official' && type== 'Beldex Official' ?  Color(0xFF00DC00) : Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: selectedType != type ? FontWeight.w100 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text('$count', style:TextStyle(
                            color: selectedType == 'Contributor exit node' && type == 'Contributor exit node'  ? Color(0xFF0094FF) : selectedType == 'Beldex Official' && type== 'Beldex Official' ?  Color(0xFF00DC00) : Colors.grey,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: selectedType != type ? FontWeight.w100 : FontWeight.w600,
                          ) ,)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList()
    
    
    
    
    
    
    
    
  ),
),
























          // Grouped List by Country
          Expanded(
  child: RawScrollbar(
    thumbVisibility: true,  // always show scrollbar
    thumbColor: Color(0xffACACAC),
    thickness: 5,           // adjust thickness as needed
    radius: Radius.circular(8), // rounded scrollbar
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
                Image.network(
                  countryIcon,
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.flag), // fallback icon if loading fails
                ),
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
              final isSelected = nodeProvider.selectedNodeId == node['id'];
              return GestureDetector(
                onTap: (){
                  nodeProvider.selectNode(node['id'],node['name'],country);

                },
                child: Container(
                  height: 58,width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color:isSelected ? Color(0xff00DC00) : const Color(0xffACACAC).withOpacity(0.5),width: 0.8),
                    ),
                    padding: EdgeInsets.all(10),
                   child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
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

