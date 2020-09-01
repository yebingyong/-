package cn.mancando.cordovaplugin.newscanner;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PermissionHelper;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.Manifest;

import com.google.zxing.client.android.CaptureActivity;
import com.google.zxing.client.android.encode.EncodeActivity;
import com.google.zxing.client.android.Intents;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;

import android.util.Log;
import android.widget.Toast;

/**
 * This class echoes a string called from JavaScript.
 */
public class NewScanner extends CordovaPlugin {

  public static final int REQUEST_CODE = 0x0ba7c0de;

  private static final String CANCELLED = "cancelled";
  private static final String FORMAT = "format";
  private static final String TEXT = "text";
  private static final String PREFER_FRONTCAMERA = "preferFrontCamera";
  private static final String ORIENTATION = "orientation";
  private static final String SHOW_FLIP_CAMERA_BUTTON = "showFlipCameraButton";
  private static final String RESULTDISPLAY_DURATION = "resultDisplayDuration";
  private static final String SHOW_TORCH_BUTTON = "showTorchButton";
  private static final String TORCH_ON = "torchOn";
  private static final String FORMATS = "formats";
  private static final String PROMPT = "prompt";

  private static final String LOG_TAG = "BarcodeScanner";

  public static final int REQUEST_PERMISSION_SCAN = 1000;

  private String [] permissions = { Manifest.permission.CAMERA };

  private JSONArray requestArgs;
  private CallbackContext callbackContext;

  private JSONArray postData;

  private Context getApplicationContext() {
    return this.cordova.getActivity().getApplicationContext();
  }

  @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("coolMethod")) {
//            String message = args.getString(0);
//            this.coolMethod(message, callbackContext);
          Log.i("CordovaLog", "开始啦");
          Toast.makeText(getApplicationContext(), "toast消息", Toast.LENGTH_LONG).show();
          postData = args;
          this.checkScanPermission(postData);
            return true;
        }
        return false;
    }

    public void checkScanPermission(final JSONArray args){
      if (!PermissionHelper.hasPermission(this, Manifest.permission.CAMERA)) {
        PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.CAMERA);
      } else if (!PermissionHelper.hasPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)) {
        PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.READ_EXTERNAL_STORAGE);
      } else if (!PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
        PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.WRITE_EXTERNAL_STORAGE);
      }else {
        this.scan(args);
      }
    }
  /**
   * Starts an intent to scan and decode a barcode.
   */
  public void scan(final JSONArray args) {
    final CordovaPlugin that = this;
    if (!PermissionHelper.hasPermission(this, Manifest.permission.CAMERA)) {
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.CAMERA);
    } else if (!PermissionHelper.hasPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)) {
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.READ_EXTERNAL_STORAGE);
    } else if (!PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.WRITE_EXTERNAL_STORAGE);
    }else if(!PermissionHelper.hasPermission(this, Manifest.permission.VIBRATE)){
      //震动
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.VIBRATE);
    }else if(!PermissionHelper.hasPermission(this, Manifest.permission.INTERNET)){
      //允许程序访问网络连接，可能产生GPRS流量
      PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.INTERNET);
    }else {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {

          Intent intentScan = new Intent(that.cordova.getActivity().getBaseContext(), CaptureActivity.class);
          intentScan.setAction(Intents.Scan.ACTION);
          intentScan.addCategory(Intent.CATEGORY_DEFAULT);
          intentScan.putExtra("deviceSerial","woqu");
          // add config as intent extras
          if (args.length() > 0) {

            JSONObject obj;
            JSONArray names;
            String key;
            Object value;

            for (int i = 0; i < args.length(); i++) {

              try {
                obj = args.getJSONObject(i);
              } catch (JSONException e) {
                Log.i("CordovaLog", e.getLocalizedMessage());
                continue;
              }

              names = obj.names();
              for (int j = 0; j < names.length(); j++) {
                try {
                  key = names.getString(j);
                  value = obj.get(key);

                  if (value instanceof Integer) {
                    intentScan.putExtra(key, (Integer) value);
                  } else if (value instanceof String) {
                    intentScan.putExtra(key, (String) value);
                  }

                } catch (JSONException e) {
                  Log.i("CordovaLog", e.getLocalizedMessage());
                }
              }

              intentScan.putExtra(Intents.Scan.CAMERA_ID, obj.optBoolean(PREFER_FRONTCAMERA, false) ? 1 : 0);
              intentScan.putExtra(Intents.Scan.SHOW_FLIP_CAMERA_BUTTON, obj.optBoolean(SHOW_FLIP_CAMERA_BUTTON, false));
              intentScan.putExtra(Intents.Scan.SHOW_TORCH_BUTTON, obj.optBoolean(SHOW_TORCH_BUTTON, false));
              intentScan.putExtra(Intents.Scan.TORCH_ON, obj.optBoolean(TORCH_ON, false));
              if (obj.has(RESULTDISPLAY_DURATION)) {
                intentScan.putExtra(Intents.Scan.RESULT_DISPLAY_DURATION_MS, "" + obj.optLong(RESULTDISPLAY_DURATION));
              }
              if (obj.has(FORMATS)) {
                intentScan.putExtra(Intents.Scan.FORMATS, obj.optString(FORMATS));
              }
              if (obj.has(PROMPT)) {
                intentScan.putExtra(Intents.Scan.PROMPT_MESSAGE, obj.optString(PROMPT));
              }
              if (obj.has(ORIENTATION)) {
                intentScan.putExtra(Intents.Scan.ORIENTATION_LOCK, obj.optString(ORIENTATION));
              }
            }

          }

          // avoid calling other phonegap apps
          intentScan.setPackage(that.cordova.getActivity().getApplicationContext().getPackageName());

          that.cordova.startActivityForResult(that, intentScan, REQUEST_CODE);
        }
      });
    }
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent intent) {
    if (requestCode == REQUEST_CODE) {
      Log.i("CordovaLog", "有反应");
      if (resultCode == Activity.RESULT_OK) {
        JSONObject obj = new JSONObject();
        try {
          obj.put(TEXT, intent.getStringExtra("SCAN_RESULT"));
          obj.put(FORMAT, intent.getStringExtra("SCAN_RESULT_FORMAT"));
          obj.put(CANCELLED, false);
        } catch (JSONException e) {
          Log.d(LOG_TAG, "This should never happen");
        }
        //this.success(new PluginResult(PluginResult.Status.OK, obj), this.callback);
//        this.callbackContext.success(obj);
        Log.i("CordovaLog", "111");
        Log.i("CordovaLog", obj.toString());
      } else if (resultCode == Activity.RESULT_CANCELED) {
        JSONObject obj = new JSONObject();
        try {
          obj.put(TEXT, "");
          obj.put(FORMAT, "");
          obj.put(CANCELLED, true);
        } catch (JSONException e) {
          Log.d(LOG_TAG, "This should never happen");
        }
        //this.success(new PluginResult(PluginResult.Status.OK, obj), this.callback);
//        this.callbackContext.success(obj);
        Log.i("CordovaLog", "222");
        Log.i("CordovaLog", obj.toString());
      } else {
        //this.error(new PluginResult(PluginResult.Status.ERROR), this.callback);
//        this.callbackContext.error("Unexpected error");
        Log.i("CordovaLog", "333");
        Log.i("CordovaLog", "Unexpected error");
      }
    }
  }

  @Override
  public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
    //权限申请时被拒绝后
//    for (int r : grantResults) {
//      if (r == PackageManager.PERMISSION_DENIED) {
//        this.callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, PERMISSION_DENIED_ERROR));
//        return;
//      }
//    }
    switch (requestCode) {
      case REQUEST_PERMISSION_SCAN:
        this.scan(postData);
        break;
    }
  }

    private void coolMethod(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }
}
