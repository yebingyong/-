package cn.mancando.cordovaplugin.platevincodetest;

/**
 *
 */
public class Size implements Comparable<cn.mancando.cordovaplugin.platevincodetest.Size> {
  public final int width;
  public final int height;

  public Size(int width, int height) {
    this.width = width;
    this.height = height;
  }

  /**
   * Swap width and height.
   *
   * @return a new Size with swapped width and height
   */
  public cn.mancando.cordovaplugin.platevincodetest.Size rotate() {
    //noinspection SuspiciousNameCombination
    return new cn.mancando.cordovaplugin.platevincodetest.Size(height, width);
  }

  /**
   * Scale by n / d.
   *
   * @param n numerator
   * @param d denominator
   * @return the scaled size
   */
  public com.journeyapps.barcodescanner.Size scale(int n, int d) {
    return new com.journeyapps.barcodescanner.Size(width * n / d, height * n / d);
  }

  /**
   * Scales the dimensions so that it fits entirely inside the parent.One of width or height will
   * fit exactly. Aspect ratio is preserved.
   *
   * @param into the parent to fit into
   * @return the scaled size
   */
  public com.journeyapps.barcodescanner.Size scaleFit(com.journeyapps.barcodescanner.Size into) {
    if(width * into.height >= into.width * height) {
      // match width
      return new com.journeyapps.barcodescanner.Size(into.width, height * into.width / width);
    } else {
      // match height
      return new com.journeyapps.barcodescanner.Size(width * into.height / height, into.height);
    }
  }
  /**
   * Scales the size so that both dimensions will be greater than or equal to the corresponding
   * dimension of the parent. One of width or height will fit exactly. Aspect ratio is preserved.
   *
   * @param into the parent to fit into
   * @return the scaled size
   */
  public com.journeyapps.barcodescanner.Size scaleCrop(com.journeyapps.barcodescanner.Size into) {
    if(width * into.height <= into.width * height) {
      // match width
      return new com.journeyapps.barcodescanner.Size(into.width, height * into.width / width);
    } else {
      // match height
      return new com.journeyapps.barcodescanner.Size(width * into.height / height, into.height);
    }
  }


  /**
   * Checks if both dimensions of the other size are at least as large as this size.
   *
   * @param other the size to compare with
   * @return true if this size fits into the other size
   */
  public boolean fitsIn(com.journeyapps.barcodescanner.Size other) {
    return width <= other.width && height <= other.height;
  }

  /**
   * Default sort order is ascending by size.
   */
  @Override
  public int compareTo(cn.mancando.cordovaplugin.platevincodetest.Size other) {
    int aPixels = this.height * this.width;
    int bPixels = other.height * other.width;
    if (bPixels < aPixels) {
      return 1;
    }
    if (bPixels > aPixels) {
      return -1;
    }
    return 0;
  }

  public String toString() {
    return width + "x" + height;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;

    com.journeyapps.barcodescanner.Size size = (com.journeyapps.barcodescanner.Size) o;

    if (width != size.width) return false;
    return height == size.height;

  }

  @Override
  public int hashCode() {
    int result = width;
    result = 31 * result + height;
    return result;
  }
}

