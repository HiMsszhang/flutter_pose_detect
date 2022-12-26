import 'package:flutter/foundation.dart';

abstract class PointF3D {
  double getX();

  double getY();

  double getZ();

  static PointF3D from(double x, double y, double z) {
    zza var3 = zza(x, y, z);
    return var3;
  }
}

class zza extends PointF3D {
  final double _zza;
  final double _zzb;
  final double _zzc;

  zza(this._zza, this._zzb, this._zzc);

  @override
  double getX() => _zza;

  @override
  double getY() => _zzb;

  @override
  double getZ() => _zzc;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'PointF3DValue')}('
        'x=$_zza'
        'y=$_zzb'
        'z=$_zzc)';
  }

  @override
  bool operator ==(Object other) {
    if (other == this) {
      return true;
    }
    if ((other as PointF3D).getX() == _zza && other.getY() == _zzb && other.getZ() == _zzc) {
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(_zza, _zzb, _zzc);
}
