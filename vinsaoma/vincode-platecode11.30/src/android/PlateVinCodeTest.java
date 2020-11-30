package cn.mancando.cordovaplugin.platevincodetest;

import android.app.Activity;
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
import android.hardware.camera2.CameraAccessException;
import android.net.Uri;
import android.os.Handler;
import android.os.Message;
import android.os.Vibrator;
import android.telephony.TelephonyManager;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.Toast;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.ResultPoint;
import com.journeyapps.barcodescanner.camera.CameraSettings;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import com.etop.vin.VINAPI;
import cn.mancando.cordovaplugin.platecode.plate.PlateApi;
import cn.mancando.cordovaplugin.platecode.plate.PlateApiException;
import cn.mancando.cordovaplugin.platevincodetest.platevincode.DefaultDecoderFactory;
import cn.mancando.cordovaplugin.platevincodetest.platevincode.PlateVinCallback;
import cn.mancando.cordovaplugin.platevincodetest.platevincode.PlateVinResult;
import cn.mancando.cordovaplugin.platevincodetest.platevincode.PlateVinView;
import cn.mancando.cordovaplugin.vincode.utils.FileHelper;
import cn.mancando.cordovaplugin.vincode.utils.UserIdUtils;
import cn.mancando.cordovaplugin.vincode.vin.VinApi;

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

  private PlateVinView plateVinView;

  private boolean switchFlashOn = false;
  private boolean switchFlashOff = false;

  private VINAPI vinApi;
  private PlateApi plateApi;
  private boolean vinInitKernal = false;
  private boolean plateInitKernal = true;
  private int screenWidth;
  private int screenHeight;
  private String type;


  static class plateVinError {
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
    this.printResolution(cordova.getActivity());

    if (action.equals("show")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          show(callbackContext);
        }
      });
      return true;
    }else if (action.equals("scan")) {
      initKernal();
      type = args.getString(0);
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          scan(callbackContext,type);
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
    }else if (action.equals("enableLight")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          while (cameraClosing) {
            try {
              Thread.sleep(10);
            } catch (InterruptedException ignore) {
            }
          }
          switchFlashOn = true;
          if (hasFlash()) {
            if (!hasPermission()) {
              requestPermission(33);
            } else
              enableLight(callbackContext);
          } else {
            callbackContext.error(plateVinError.LIGHT_UNAVAILABLE);
          }
        }
      });
      return true;
    }else if (action.equals("disableLight")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          switchFlashOff = true;
          if (hasFlash()) {
            if (!hasPermission()) {
              requestPermission(33);
            } else
              disableLight(callbackContext);
          } else {
            callbackContext.error(plateVinError.LIGHT_UNAVAILABLE);
          }
        }
      });
      return true;
    }else if(action.equals("hide")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          hide(callbackContext);
        }
      });
      return true;
    }else if (action.equals("destroy")) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          destroy(callbackContext);
        }
      });
      return true;
    }else if (action.equals("getImage")) {
      this.close();
      this.getImage();
      return true;
    }

    return false;
  }

  //注销识别接口
  private void close(){
    if(plateApi != null){
      plateApi = null;
    }
    if(vinApi != null){
      vinApi.VinKernalUnInit();
      vinApi = null;
    }

  }
  //初始化识别接口
  private void initKernal() {
    if (vinApi == null) {
      vinApi = new VINAPI();
      String cacheDir = (cordova.getActivity().getExternalCacheDir()).getPath();
      String userIdPath = cacheDir + "/" + UserIdUtils.UserID + ".lic";
      TelephonyManager telephonyManager = (TelephonyManager) cordova.getActivity().getSystemService(Context.TELEPHONY_SERVICE);
      int nRet = vinApi.VinKernalInit("", userIdPath, UserIdUtils.UserID, 0x01, 0x03, telephonyManager, cordova.getActivity());
      if (nRet != 0) {
        Toast.makeText(cordova.getActivity().getApplicationContext(), "激活失败("+nRet+")", Toast.LENGTH_SHORT).show();
        vinInitKernal = false;
        this.callbackContext.error("vin识别激活失败");
      } else {
        vinInitKernal = true;
      }
    }
    
    if(plateApi == null){
      // 初始化识别API
      try {
        plateApi = new PlateApi(cordova.getActivity());
      } catch (PlateApiException e) {
        Toast.makeText(cordova.getActivity().getApplicationContext(), e.getMessage(), Toast.LENGTH_SHORT).show();
        this.callbackContext.error("车牌识别激活失败");
        plateInitKernal = false;
      }
    }

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
      if (resultCode == Activity.RESULT_OK && data != null) {
        Uri uri = data.getData();
        if (uri == null) {
          this.callbackContext.error("未正确选择图片");
        } else {
          progressDialog = new ProgressDialog(cordova.getActivity(), ProgressDialog.THEME_HOLO_LIGHT);
          progressDialog.setTitle("提示");
          progressDialog.setMessage("正在识别...");
          progressDialog.setCancelable(false);
          progressDialog.setIndeterminate(true);
          progressDialog.show();

          final Intent intent = data;
          cordova.getThreadPool().execute(new Runnable() {
            public void run() {
              processImage(intent);
            }
          });
        }
      } else if (resultCode == Activity.RESULT_CANCELED) {
        // 图片选择取消，不做处理
      } else {
        // 没有选择图片，不做处理
      }
    }
  }

  /**
   * 打印不包括虚拟按键的分辨率、屏幕密度dpi、最小宽度sw
   */
  public void printResolution(Context context) {
    DisplayMetrics dm = context.getResources().getDisplayMetrics();
    screenHeight = dm.heightPixels;
    screenWidth = dm.widthPixels;
  }

  @Override
  public void plateVinResult(PlateVinResult plateVinResult) {
    if (this.nextScanCallback == null) {
      return;
    }

    if(plateVinResult.getNumber() != null) {
      scanning = false;
      this.nextScanCallback.success(plateVinResult.getNumber());
      this.nextScanCallback = null;
      //震动
      Vibrator vibrator = (Vibrator) cordova.getActivity().getSystemService(Context.VIBRATOR_SERVICE);
      vibrator.vibrate(500);
    }
    else {
      scan(this.nextScanCallback,type);
    }
  }

  @Override
  public void possibleResultPoints(List<ResultPoint> list) {
  }

  private void getImage() {
    if (!PermissionHelper.hasPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)) {
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_GET_IMAGE, Manifest.permission.READ_EXTERNAL_STORAGE);
    } else if (!PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_GET_IMAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE);
    }  else {
      Intent intent = new Intent();
      intent.setType("image/*");
      intent.setAction(Intent.ACTION_GET_CONTENT);
      intent.addCategory(Intent.CATEGORY_OPENABLE);

      Intent intentChooser = Intent.createChooser(intent, new String("获取图片"));

      this.cordova.startActivityForResult((CordovaPlugin) this, intentChooser, ACTIVITY_REQUEST_CODE_GET_IMAGE);
    }
  }
  private Handler handler = new Handler() {
    @Override
    public void handleMessage(Message msg) {
      // 关闭ProgressDialog
      progressDialog.dismiss();
    }
  };
  //识别照片
  private void processImage(Intent intent) {
    Uri uri = intent.getData();
    if (uri == null) {
      this.callbackContext.error("未正确选择图片");
      return;
    }

    String imgFile = FileHelper.getRealPath(uri, this.cordova.getActivity());

    VinApi vinApi = null;
    try {
      vinApi = new VinApi(this.cordova.getActivity());
      vinApi.recognizeImageFile(imgFile);
      String vin = vinApi.getResult();
      this.callbackContext.success(vin);
    } catch (Exception e) {
      this.callbackContext.error(e.getMessage());
    } finally {
      if (vinApi != null) {
        vinApi.close();
      }
      handler.sendEmptyMessage(0);
    }
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
          callbackContext.error(plateVinError.BACK_CAMERA_UNAVAILABLE);
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
          callbackContext.error(plateVinError.FRONT_CAMERA_UNAVAILABLE);
        }
      } else {
        callbackContext.error(plateVinError.CAMERA_UNAVAILABLE);
      }
    } else {
      prepared = false;
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          plateVinView.pause();
        }
      });
      if(cameraPreviewing) {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            ((ViewGroup) plateVinView.getParent()).removeView(plateVinView);
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
////                FrameLayout.LayoutParams cameraPreviewParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.FILL_PARENT, currentHeiht);
//                cameraPreviewParams.setMargins(0,marginTop,0,marginTop);
        ((ViewGroup) webView.getView().getParent()).addView(plateVinView, cameraPreviewParams);

        cameraPreviewing = true;
        webView.getView().bringToFront();

        plateVinView.resume();
      }
    });
    prepared = true;
    previewing = true;
    if(shouldScanAgain)
      scan(callbackContext,type);
  }

  private void scan(final CallbackContext callbackContext, final String type) {
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
            plateVinView.decodeSingle(b,plateApi,vinApi,type);
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

  private void enableLight(CallbackContext callbackContext) {
    lightOn = true;
    if(hasPermission())
      switchFlash(true, callbackContext);
    else callbackContext.error(plateVinError.CAMERA_ACCESS_DENIED);
  }

  private void disableLight(CallbackContext callbackContext) {
    lightOn = false;
    switchFlashOn = false;
    if(hasPermission())
      switchFlash(false, callbackContext);
    else callbackContext.error(plateVinError.CAMERA_ACCESS_DENIED);
  }

  private void switchFlash(boolean toggleLight, CallbackContext callbackContext) {
    try {
      if (hasFlash()) {
        doswitchFlash(toggleLight, callbackContext);
      } else {
        callbackContext.error(plateVinError.LIGHT_UNAVAILABLE);
      }
    } catch (Exception e) {
      lightOn = false;
      callbackContext.error(plateVinError.LIGHT_UNAVAILABLE);
    }
  }

  private void doswitchFlash(final boolean toggleLight, final CallbackContext callbackContext) throws IOException, CameraAccessException {        //No flash for front facing cameras
    if (getCurrentCameraId() == Camera.CameraInfo.CAMERA_FACING_FRONT) {
      callbackContext.error(plateVinError.LIGHT_UNAVAILABLE);
      return;
    }
    if (!prepared) {
      if (toggleLight)
        lightOn = true;
      else
        lightOn = false;
      prepare(callbackContext);
    }
    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        if (plateVinView != null) {
          plateVinView.setTorch(toggleLight);
          if (toggleLight)
            lightOn = true;
          else
            lightOn = false;
        }
        getStatus(callbackContext);
      }
    });
  }


  private void hide(final CallbackContext callbackContext) {
    makeOpaque();
    getStatus(callbackContext);
  }

  private void makeOpaque() {
    this.cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        webView.getView().setBackgroundColor(Color.TRANSPARENT);
      }
    });
    showing = false;
  }

  private void destroy(CallbackContext callbackContext) {
    prepared = false;
    makeOpaque();
    previewing = false;
    if(scanning) {
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          scanning = false;
          if (plateVinView != null) {
            plateVinView.stopDecoding();
          }
        }
      });
      this.nextScanCallback = null;
    }

    if(cameraPreviewing) {
      this.cordova.getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          ((ViewGroup) plateVinView.getParent()).removeView(plateVinView);
          cameraPreviewing = false;
        }
      });
    }
    if(currentCameraId != Camera.CameraInfo.CAMERA_FACING_FRONT) {
      if (lightOn)
        switchFlash(false, callbackContext);
    }
    closeCamera();
    currentCameraId = 0;
    getStatus(callbackContext);
  }

  private void closeCamera() {
    cameraClosing = true;
    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        if (plateVinView != null) {
          plateVinView.pause();
        }

        cameraClosing = false;
      }
    });
  }
}
