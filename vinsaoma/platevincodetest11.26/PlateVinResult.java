package cn.mancando.cordovaplugin.platevincodetest;

import com.google.zxing.Result;
import com.journeyapps.barcodescanner.SourceData;
import com.etop.vin.VINAPI;

public class PlateVinResult {
  private String number;

  public PlateVinResult(String number) {
    this.number = number;
  }

  public String getNumber() {
    return number;
  }

}

