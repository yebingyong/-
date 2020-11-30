package cn.mancando.cordovaplugin.platevincodetest.platevincode;

import com.google.zxing.DecodeHintType;

import java.util.Map;

import com.etop.vin.VINAPI;
import cn.mancando.cordovaplugin.platecode.plate.PlateApi;

/**
 * 工厂来创建解码器实例。通常每个DecoderThread将创建一个实例
 * Factory to create Decoder instances. Typically one instance will be created per DecoderThread.
 *
 */
public interface DecoderFactory {

  /**
   * 创建新解码器。
   *
   * *
   *
   * *虽然此方法只能从单个线程调用，但创建的解码器将
   *
   * *从不同的线程使用。每个解码器只能从一个线程使用。
   * Create a new Decoder.
   *
   * While this method will only be called from a single thread, the created Decoder will
   * be used from a different thread. Each decoder will only be used from a single thread.
   *
   * @param baseHints default hints. Typically specifies DecodeHintType.NEED_RESULT_POINT_CALLBACK.
   * @return a new Decoder
   */
  Decoder createDecoder(Map<DecodeHintType, ?> baseHints,PlateApi plateApi);
}
