package cn.mancando.cordovaplugin.platevincodetest;

import android.content.Context;
import android.content.pm.FeatureInfo;
import android.graphics.Color;
import android.hardware.Camera;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.ProgressDialog;
import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Vibrator;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.ResultPoint;
import com.journeyapps.barcodescanner.BarcodeResult;
import com.journeyapps.barcodescanner.DefaultDecoderFactory;
import com.journeyapps.barcodescanner.camera.CameraSettings;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * This class echoes a string called from JavaScript.
 */
public class PlateVinCodeTest extends CordovaPlugin implements PlateVinCallback {
  public static final int ACTIVITY_REQUEST_CODE_SCAN = 20120317;
  public static final int ACTIVITY_REQUEST_CODE_GET_IMAGE = 20130317;
  public static final int REQUEST_PERMISSION_SCAN = 0;
  public static final int REQUEST_PERMISSION_GET_IMAGE = 1;
  public static final int PERMISSION_DENIED_ERROR = 20;

  private CallbackContext callbackContext;
  private ProgressDialog progressDialog;
  private int currentCameraId = Camera.CameraInfo.CAMERA_FACING_BACK;
  private boolean cameraClosing;
  private static Boolean flashAvailable;
  private boolean lightOn = false;
  private boolean showing = false;
  private boolean prepared = false;
  private String[] permissions = {Manifest.permission.CAMERA};
  private boolean cameraPreviewing;
  private boolean previewing = false;
  private boolean shouldScanAgain;
  private boolean oneTime = true;
  private boolean denied;
  private boolean authorized;
  private boolean restricted;
  private boolean scanning = false;

  private boolean keepDenied = false;
  private boolean appPausedWithActivePreview = false;

  private CallbackContext nextScanCallback;

  private PlateVinView  plateVinView;

  private boolean switchFlashOn = false;

  static class QRScannerError {
    private static final int UNEXPECTED_ERROR = 0,
      CAMERA_ACCESS_DENIED = 1,
      CAMERA_ACCESS_RESTRICTED = 2,
      BACK_CAMERA_UNAVAILABLE = 3,
      FRONT_CAMERA_UNAVAILABLE = 4,
      CAMERA_UNAVAILABLE = 5,
      SCAN_CANCELED = 6,
      LIGHT_UNAVAILABLE = 7,
      OPEN_SETTINGS_UNAVAILABLE = 8;
  }

  @Override
  public boolean execute(String action,final JSONArray args,final CallbackContext callbackContext) throws JSONException {
    this.callbackContext = callbackContext;
    if (action.equals("show")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          show(callbackContext);
        }
      });
      return true;
    }else if (action.equals("scan")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          scan(callbackContext);
        }
      });
      return true;
    }else if (action.equals("prepare")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
              try {
                currentCameraId = args.getInt(0);
              } catch (JSONException e) {
              }
              prepare(callbackContext);
            }
          });
        }
      });
      return true;
    }

    return false;
  }

  @Override
  public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
    for (int r : grantResults) {
      if (r == PackageManager.PERMISSION_DENIED) {
        this.callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, PERMISSION_DENIED_ERROR));
        return;
      }
    }
    switch (requestCode) {
      case REQUEST_PERMISSION_SCAN:
//                scan();
        break;
      case REQUEST_PERMISSION_GET_IMAGE:
        break;
    }
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == ACTIVITY_REQUEST_CODE_SCAN) {
      switch (resultCode) {
        case 1:// 扫描成功
          String number = data.getStringExtra("number");
          //String picPath = data.getStringExtra("picPath");
          this.callbackContext.success(number);
          break;
        case 2:// 扫描取消，不做处理
          break;
        case 3:// 扫描失败
          String message = data.getStringExtra("message");
          callbackContext.error(message);
          break;
      }
    } else if (requestCode == ACTIVITY_REQUEST_CODE_GET_IMAGE) {

    }
  }

  @Override
  public void barcodeResult(BarcodeResult barcodeResult) {
    if (this.nextScanCallback == null) {
      return;
    }

    if(barcodeResult.getText() != null) {
      scanning = false;
      this.nextScanCallback.success(barcodeResult.getText());
      this.nextScanCallback = null;
      //震动
      Vibrator vibrator = (Vibrator) cordova.getActivity().getSystemService(Context.VIBRATOR_SERVICE);
      vibrator.vibrate(500);
    }
    else {
      scan(this.nextScanCallback);
    }
  }

  @Override
  public void possibleResultPoints(List<ResultPoint> list) {
  }

  // ---- BEGIN EXTERNAL API ----
  private void prepare(final CallbackContext callbackContext) {
    if(!prepared) {
      if(currentCameraId == Camera.CameraInfo.CAMERA_FACING_BACK) {
        if (hasCamera()) {
          if (!hasPermission()) {
            requestPermission(33);
          } else {
            setupCamera(callbackContext);
            if (!scanning)
              getStatus(callbackContext);
          }
        } else {
          callbackContext.error(PlateVinCodeTest.QRScannerError.BACK_CAMERA_UNAVAILABLE);
        }
      } else if(currentCameraId == Camera.CameraInfo.CAMERA_FACING_FRONT) {
        if (hasFrontCamera()) {
          if (!hasPermission()) {
            requestPermission(33);
          } else {
            setupCamera(callbackContext);
            if (!scanning)
              getStatus(callbackContext);
          }
        } else {
          callbackContext.error(PlateVinCodeTest.QRScannerError.FRONT_CAMERA_UNAVAILABLE);
        }
      } else {
        callbackContext.error(PlateVinCodeTest.QRScannerError.CAMERA_UNAVAILABLE);
      }
    } else {
      prepared = false;
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
//          mBarcodeView.pause();
        }
      });
      if(cameraPreviewing) {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
//            ((ViewGroup) mBarcodeView.getParent()).removeView(mBarcodeView);
            cameraPreviewing = false;
          }
        });

        previewing = true;
        lightOn = false;
      }
      setupCamera(callbackContext);
      getStatus(callbackContext);
    }
  }

  private void getStatus(CallbackContext callbackContext) {

    if(oneTime) {
      boolean authorizationStatus = hasPermission();

      authorized = false;
      if (authorizationStatus)
        authorized = true;

      if(keepDenied && !authorized)
        denied = true;
      else
        denied = false;

      //No applicable API
      restricted = false;
    }
    boolean canOpenSettings = true;

    boolean canEnableLight = hasFlash();

    if(currentCameraId == Camera.CameraInfo.CAMERA_FACING_FRONT)
      canEnableLight = false;

    HashMap status = new HashMap();
    status.put("authorized",boolToNumberString(authorized));
    status.put("denied",boolToNumberString(denied));
    status.put("restricted",boolToNumberString(restricted));
    status.put("prepared",boolToNumberString(prepared));
    status.put("scanning",boolToNumberString(scanning));
    status.put("previewing",boolToNumberString(previewing));
    status.put("showing",boolToNumberString(showing));
    status.put("lightEnabled",boolToNumberString(lightOn));
    status.put("canOpenSettings",boolToNumberString(canOpenSettings));
    status.put("canEnableLight",boolToNumberString(canEnableLight));
    status.put("canChangeCamera",boolToNumberString(canChangeCamera()));
    status.put("currentCamera",Integer.toString(getCurrentCameraId()));

    JSONObject obj = new JSONObject(status);
    PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
    callbackContext.sendPluginResult(result);
  }

  private void setupCamera(CallbackContext callbackContext) {
    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        // Create our Preview view and set it as the content of our activity.
        plateVinView = new PlateVinView(cordova.getActivity());

        //Configure the decoder
        ArrayList<BarcodeFormat> formatList = new ArrayList<BarcodeFormat>();
        //扫描二维码
        formatList.add(BarcodeFormat.QR_CODE);
        //扫描条形码
        formatList.add(BarcodeFormat.UPC_A);
        formatList.add(BarcodeFormat.UPC_E);
        formatList.add(BarcodeFormat.EAN_13);
        formatList.add(BarcodeFormat.EAN_8);
        formatList.add(BarcodeFormat.CODE_39);
        formatList.add(BarcodeFormat.CODE_93);
        formatList.add(BarcodeFormat.CODE_128);
        formatList.add(BarcodeFormat.ITF);
        formatList.add(BarcodeFormat.DATA_MATRIX);
        plateVinView.setDecoderFactory(new DefaultDecoderFactory(formatList, null, null));

        //Configure the camera (front/back)
        CameraSettings settings = new CameraSettings();
        settings.setRequestedCameraId(getCurrentCameraId());
        plateVinView.setCameraSettings(settings);

        //全屏
        FrameLayout.LayoutParams cameraPreviewParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        //设置扫描区域
//                int currentHeiht = new Double(screenHeight*0.32).intValue();
//                int marginTop = new Double(screenHeight*(0.3)).intValue();
//                FrameLayout.LayoutParams cameraPreviewParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.FILL_PARENT, currentHeiht);
//                cameraPreviewParams.setMargins(0,marginTop,0,0);
        ((ViewGroup) webView.getView().getParent()).addView(plateVinView, cameraPreviewParams);

        cameraPreviewing = true;
        webView.getView().bringToFront();

        plateVinView.resume();
      }
    });
    prepared = true;
    previewing = true;
    if(shouldScanAgain)
      scan(callbackContext);
  }

  private void scan(final CallbackContext callbackContext) {
    scanning = true;
    if (!prepared) {
      shouldScanAgain = true;
      if (hasCamera()) {
        if (!hasPermission()) {
          requestPermission(33);
        } else {
          setupCamera(callbackContext);
        }
      }
    } else {
      if(!previewing) {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            if(plateVinView != null) {
              plateVinView.resume();
              previewing = true;
              if(switchFlashOn)
                lightOn = true;
            }
          }
        });
      }
      shouldScanAgain = false;
      this.nextScanCallback = callbackContext;
      final PlateVinCallback b = this;
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          if (plateVinView != null) {
            plateVinView.decodeSingle(b);
          }
        }
      });
    }
  }

  private void show(final CallbackContext callbackContext) {
    this.cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        webView.getView().setBackgroundColor(Color.argb(1, 0, 0, 0));
        showing = true;
        getStatus(callbackContext);
      }
    });
  }

  private boolean canChangeCamera() {
    int numCameras= Camera.getNumberOfCameras();
    for(int i=0;i<numCameras;i++){
      Camera.CameraInfo info = new Camera.CameraInfo();
      Camera.getCameraInfo(i, info);
      if(info.CAMERA_FACING_FRONT == info.facing){
        return true;
      }
    }
    return false;
  }

  private boolean hasFlash() {
    if (flashAvailable == null) {
      flashAvailable = false;
      final PackageManager packageManager = this.cordova.getActivity().getPackageManager();
      for (final FeatureInfo feature : packageManager.getSystemAvailableFeatures()) {
        if (PackageManager.FEATURE_CAMERA_FLASH.equalsIgnoreCase(feature.name)) {
          flashAvailable = true;
          break;
        }
      }
    }
    return flashAvailable;
  }

  public int getCurrentCameraId() {
    return this.currentCameraId;
  }

  //是否有摄像头
  private boolean hasCamera() {
    if (this.cordova.getActivity().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA)){
      return true;
    } else {
      return false;
    }
  }

  //是否有前置摄像头
  private boolean hasFrontCamera() {
    if (this.cordova.getActivity().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)){
      return true;
    } else {
      return false;
    }
  }

  public boolean hasPermission() {
    for(String p : permissions)
    {
      if(!PermissionHelper.hasPermission(this, p))
      {
        return false;
      }
    }
    return true;
  }

  private void requestPermission(int requestCode) {
    PermissionHelper.requestPermissions(this, requestCode, permissions);
  }

  private String boolToNumberString(Boolean bool) {
    if(bool)
      return "1";
    else
      return "0";
  }

//    private void scan() {
//        if (!PermissionHelper.hasPermission(this, Manifest.permission.CAMERA)) {
//            PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.CAMERA);
//        } else if (!PermissionHelper.hasPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)) {
//            PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.READ_EXTERNAL_STORAGE);
//        } else if (!PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
//            PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.WRITE_EXTERNAL_STORAGE);
//        } else {
//            Intent intent = new Intent(this.cordova.getActivity(),ScanActivity.class);
//            this.cordova.startActivityForResult((CordovaPlugin) this, intent, ACTIVITY_REQUEST_CODE_SCAN);
//        }
//    }
}
