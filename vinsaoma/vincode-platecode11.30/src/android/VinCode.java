package cn.mancando.cordovaplugin.vincode;

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
import android.os.Handler;
import android.os.Message;

import cn.mancando.cordovaplugin.vincode.activity.ScanActivity;
import cn.mancando.cordovaplugin.vincode.vin.VinApi;
import cn.mancando.cordovaplugin.vincode.utils.FileHelper;

/**
 * This class echoes a string called from JavaScript.
 */
public class VinCode extends CordovaPlugin {
    public static final int ACTIVITY_REQUEST_CODE_SCAN = 20120317;
    public static final int ACTIVITY_REQUEST_CODE_GET_IMAGE = 20130317;
    public static final int REQUEST_PERMISSION_SCAN = 0;
    public static final int REQUEST_PERMISSION_GET_IMAGE = 1;
    public static final int PERMISSION_DENIED_ERROR = 20;

    private CallbackContext callbackContext;
    private ProgressDialog progressDialog;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        if (action.equals("scan")) {
            this.scan();
            return true;
        } else if (action.equals("getImage")) {
            this.getImage();
            return true;
        } else if (action.equals("recognizeImageFile")) {
            String file = args.getString(0);
            this.recognizeImageFile(file);
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
            case REQUEST_PERMISSION_GET_IMAGE:
                getImage();
                break;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == ACTIVITY_REQUEST_CODE_SCAN) {
            switch (resultCode) {
                case 1:// 扫描成功
                    String vin = data.getStringExtra("vin");
                    //String picPath = data.getStringExtra("picPath");
                    this.callbackContext.success(vin);
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

    private void recognizeImageFile(String imgFile) {
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
        }
    }

    private Handler handler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            // 关闭ProgressDialog
            progressDialog.dismiss();
        }
    };

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
}
