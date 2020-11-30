package cn.mancando.cordovaplugin.platecode;

import android.net.Uri;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;

import android.app.Activity;
import android.app.ProgressDialog;
import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;

import cn.mancando.cordovaplugin.platecode.activity.ScanActivity;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class PlateCode extends CordovaPlugin {
    public static final int ACTIVITY_REQUEST_CODE_SCAN = 20120317;
    public static final int REQUEST_PERMISSION_SCAN = 0;
    public static final int PERMISSION_DENIED_ERROR = 20;

    private CallbackContext callbackContext;
    private ProgressDialog progressDialog;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        if (action.equals("scan")) {
            this.scan();
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
                scan();
                break;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == ACTIVITY_REQUEST_CODE_SCAN) {
            switch (resultCode) {
                case 1:// 扫描成功
                    String plateNo = data.getStringExtra("plateNo");
                    String plateColor = data.getStringExtra("plateColor");

                    JSONObject result = new JSONObject();
                    try {
                        result.put("plate", plateNo);
                        result.put("color", plateColor);
                    } catch (JSONException e) {
                        this.callbackContext.error(e.getMessage());
                    }

                    this.callbackContext.success(result);
                    break;
                case 2:// 扫描取消，不做处理
                    break;
                case 3:// 扫描失败
                    String message = data.getStringExtra("message");
                    callbackContext.error(message);
                    break;
            }
        }
    }

    private void scan() {
        if (!PermissionHelper.hasPermission(this, Manifest.permission.CAMERA)) {
            PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.CAMERA);
        } else if (!PermissionHelper.hasPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)) {
            PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.READ_EXTERNAL_STORAGE);
        } else if (!PermissionHelper.hasPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
            PermissionHelper.requestPermission(this, REQUEST_PERMISSION_SCAN, Manifest.permission.WRITE_EXTERNAL_STORAGE);
        } else {
            Intent intent = new Intent(this.cordova.getActivity(),ScanActivity.class);
            this.cordova.startActivityForResult((CordovaPlugin) this, intent, ACTIVITY_REQUEST_CODE_SCAN);
        }
    }
}
