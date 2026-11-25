import 'package:belnet_mobile/src/map/shared_globe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setOnHome notifies only on change', () {
    final c = SharedGlobeController.instance;
    var calls = 0;
    void listener() => calls++;
    c.addListener(listener);
    final start = c.onHome;
    c.setOnHome(start);
    expect(calls, 0);
    c.setOnHome(!start);
    expect(calls, 1);
    c.setOnHome(start);
    expect(calls, 2);
    c.removeListener(listener);
  });

  test('rotation and focus are kept, without notifying', () {
    final c = SharedGlobeController.instance;
    var calls = 0;
    void listener() => calls++;
    c.addListener(listener);
    c.syncRotation(10, -20);
    c.setHomeFocus((latitude: 1.0, longitude: 2.0));
    expect(c.latitude, 10);
    expect(c.longitude, -20);
    expect(c.homeFocus, (latitude: 1.0, longitude: 2.0));
    expect(calls, 0);
    c.removeListener(listener);
  });
}
