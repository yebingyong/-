package cn.mancando.cordovaplugin.platevincodetest.platevincode;

/**
 *
 */
public interface RotationCallback {
  /**
   * Rotation changed.
   *
   * @param rotation the current value of windowManager.getDefaultDisplay().getRotation()
   */
  void onRotationChanged(int rotation);
}
