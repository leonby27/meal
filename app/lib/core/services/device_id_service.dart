import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable per-install identifier minted once and persisted forever.
///
/// We pass this as `PurchaseParam.applicationUserName` on every IAP
/// purchase — iOS surfaces it as `appAccountToken` inside the signed
/// transaction, Google as `obfuscatedExternalAccountId`. The server uses
/// it to bind anonymous (pre-login) purchases to a device and later, via
/// `POST /api/iap/link`, to a user account.
///
/// Lives in SharedPreferences. Reinstall ⇒ new id, which is fine: a
/// reinstall is a clean slate for the local profile anyway, and any
/// already-purchased subscription will resurface via StoreKit/Play
/// restore (with its existing appAccountToken from the original
/// transaction) — so the server entitlement row stays consistent.
class DeviceIdService {
  static const String _prefsKey = 'device_install_uuid';
  static String? _cached;

  static Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_prefsKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_prefsKey, id);
    }
    _cached = id;
    return id;
  }

  /// Synchronous read after [getOrCreate] has run at least once. Returns
  /// null before initialization — call sites that hit IAP flows must
  /// await [getOrCreate] in their own init.
  static String? get cached => _cached;
}
