

import 'package:belnet_mobile/src/widget/network_connectivity.dart';
import 'package:get/get.dart';

class NetworkBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<GetNetworkManager>(() => GetNetworkManager());
  }

}