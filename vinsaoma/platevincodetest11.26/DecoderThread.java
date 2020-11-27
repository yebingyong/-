package cn.mancando.cordovaplugin.platevincodetest;


import android.app.Activity;
import android.app.Service;
import android.graphics.Bitmap;
import android.graphics.Rect;
import android.hardware.Camera;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.widget.Toast;

import com.google.zxing.LuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.ResultPoint;
import com.google.zxing.client.android.R;
import com.journeyapps.barcodescanner.BarcodeResult;
import com.journeyapps.barcodescanner.SourceData;
import com.journeyapps.barcodescanner.Util;
import com.journeyapps.barcodescanner.camera.CameraInstance;
import com.journeyapps.barcodescanner.camera.PreviewCallback;

import java.util.List;
import com.etop.vin.VINAPI;
import cn.mancando.cordovaplugin.platecode.plate.PlateApi;

/**
 *
 */
public class DecoderThread extends Activity {
  private static final String TAG = DecoderThread.class.getSimpleName();

  private CameraInstance cameraInstance;
  private HandlerThread thread;
  private Handler handler;
  private Decoder decoder;
  private Handler resultHandler;
  private Rect cropRect;
  private boolean running = false;
  private final Object LOCK = new Object();
  private VINAPI vinApi;
  private PlateApi plateApi;
  //屏幕宽高
  private int screenWidth;
  private int screenHeight;

  private final Handler.Callback callback = new Handler.Callback() {
    @Override
    public boolean handleMessage(Message message) {
      if (message.what == R.id.zxing_decode) {
        decode((SourceData) message.obj);
      }
      return true;
    }
  };

  public DecoderThread(CameraInstance cameraInstance, Decoder decoder, Handler resultHandler,PlateApi plateApi,VINAPI vinApi) {
    com.journeyapps.barcodescanner.Util.validateMainThread();

    this.cameraInstance = cameraInstance;
    this.decoder = decoder;
    this.resultHandler = resultHandler;
    this.plateApi = plateApi;
    this.vinApi = vinApi;
  }

  public Decoder getDecoder() {
    return decoder;
  }

  public void setDecoder(Decoder decoder) {
    this.decoder = decoder;
  }

  public Rect getCropRect() {
    return cropRect;
  }

  public void setCropRect(Rect cropRect) {
    this.cropRect = cropRect;
  }

  /**
   * Start decoding.
   *
   * This must be called from the UI thread.
   */
  public void start() {
    com.journeyapps.barcodescanner.Util.validateMainThread();

    thread = new HandlerThread(TAG);
    thread.start();
    handler = new Handler(thread.getLooper(), callback);
    running = true;
    requestNextPreview();
  }


  /**
   * Stop decoding.
   *
   * This must be called from the UI thread.
   */
  public void stop() {
    Util.validateMainThread();

    synchronized (LOCK) {
      running = false;
      handler.removeCallbacksAndMessages(null);
      thread.quit();
    }
  }


  private final PreviewCallback previewCallback = new PreviewCallback() {
    @Override
    public void onPreview(SourceData sourceData) {
      // Only post if running, to prevent a warning like this:
      //   java.lang.RuntimeException: Handler (android.os.Handler) sending message to a Handler on a dead thread

      // synchronize to handle cases where this is called concurrently with stop()
      synchronized (LOCK) {
        if (running) {
          // Post to our thread.
          handler.obtainMessage(R.id.zxing_decode, sourceData).sendToTarget();
        }
      }
    }
  };

  private void requestNextPreview() {
    if (cameraInstance.isOpen()) {
      cameraInstance.requestPreview(previewCallback);
    }
  }

  protected LuminanceSource createSource(SourceData sourceData) {
    if (this.cropRect == null) {
      return null;
    } else {
      return sourceData.createSource();
    }
  }

  //识别车牌号
  public void usePlate(byte[] data, int nv21Width,int nv21Height) {
    int t;
    int b;
    int l;
    int r;
    l = nv21Height / 5;
    r = nv21Width * 3 / 5;
    t = 4;
    b = nv21Width - 4;
    double proportion = (double) nv21Height / (double) nv21Width;
    l = (int) (l / proportion);
    t = 0;
    r = (int) (r / proportion);
    b = nv21Height;
    int borders[] = {l, t, r, b};
    plateApi.setPlateROI(borders, nv21Width, nv21Height);

    int bufferLen = 256;
    char buffer[] = new char[bufferLen];

    int pLineWarp[] = new int[800 * 45];

    int r1 = plateApi.recognizePlateNV21(data, 1, nv21Width, nv21Height, buffer, bufferLen, pLineWarp);
    if (r1 == 0) {
      String plateNo = plateApi.getResult(0);
      String plateColor = plateApi.getResult(1);

      if (plateNo != null) {
        if (resultHandler != null) {
          PlateVinResult plateVinResult = new PlateVinResult(plateNo);
          Message message = Message.obtain(resultHandler, R.id.zxing_decode_succeeded, plateVinResult);
          Bundle bundle = new Bundle();
          message.setData(bundle);
          message.sendToTarget();
        }
      } else {
        if (resultHandler != null) {
          Message message = Message.obtain(resultHandler, R.id.zxing_decode_failed);
          message.sendToTarget();
        }
      }
      if (resultHandler != null) {
        List<ResultPoint> resultPoints = decoder.getPossibleResultPoints();
        Message message = Message.obtain(resultHandler, R.id.zxing_possible_result_points, resultPoints);
        message.sendToTarget();
      }
    }
  }

  //vin识别
  public void useVin(byte[] data, int nv21Width,int nv21Height) {
    int t, b, l, r;
    l = 0;
    r = nv21Height;
    t = nv21Width / 2 - 100;
    b = nv21Width / 2 + 100;
    int borders[] = {l, t, r, b};
    vinApi.VinSetROI(borders, nv21Height, nv21Width);
    int buffl = 30;
    char recogval[] = new char[buffl];
    int pLineWarp[] = new int[32000];
    int rot = vinApi.VinRecognizeNV21Android(data, nv21Width, nv21Height, recogval, buffl, pLineWarp, 1);
    if (rot == 0) {
      String recogResult = vinApi.VinGetResult();
      if (recogResult != null) {
        if (resultHandler != null) {
          PlateVinResult plateVinResult = new PlateVinResult(recogResult);
          Message message = Message.obtain(resultHandler, R.id.zxing_decode_succeeded, plateVinResult);
          Bundle bundle = new Bundle();
          message.setData(bundle);
          message.sendToTarget();
        }
      } else {
        if (resultHandler != null) {
          Message message = Message.obtain(resultHandler, R.id.zxing_decode_failed);
          message.sendToTarget();
        }
      }
      if (resultHandler != null) {
        List<ResultPoint> resultPoints = decoder.getPossibleResultPoints();
        Message message = Message.obtain(resultHandler, R.id.zxing_possible_result_points, resultPoints);
        message.sendToTarget();
      }
    }
  }

  private void decode(SourceData sourceData) {
    long start = System.currentTimeMillis();
    Result rawResult = null;
    sourceData.setCropRect(cropRect);
    LuminanceSource source = createSource(sourceData);
    //车牌识别
    usePlate(sourceData.getData(),sourceData.getDataWidth(),sourceData.getDataHeight());
    //vin识别
    useVin(sourceData.getData(),sourceData.getDataWidth(),sourceData.getDataHeight());

    requestNextPreview();
  }

}
