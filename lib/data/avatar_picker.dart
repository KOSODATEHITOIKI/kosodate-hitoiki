import 'package:image_picker/image_picker.dart';

import '../domain/models/picked_avatar.dart';

/// 端末の写真から、アカウント画像を選ぶ。テストでは、差し替える。
abstract class AvatarPicker {
  /// 選んだ画像を返す。選ばずに戻ったときは`null`。送れない画像は[AvatarPickException]。
  Future<PickedAvatar?> pick();
}

/// `image_picker`で、端末の写真から選ぶ。512px四方に収まるよう、選んだ時点で縮小する
/// (API契約2節。縮小はアプリ側の仕事)。
class ImagePickerAvatarPicker implements AvatarPicker {
  ImagePickerAvatarPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxSide = 512.0;

  @override
  Future<PickedAvatar?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedAvatar.fromBytes(await file.readAsBytes());
  }
}
