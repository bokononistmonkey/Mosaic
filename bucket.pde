/**
 * @author bokononistmonkey
 * Feb 06, 2019
 * Mosaic Maker
 */
 
/**
 * Element, Bucket, and BigBucket classes
 *
 * The advantage of using a Bucket data structure is that
 * the time required to search for a matching image does not 
 * increase linearly with the size of the image array.
 * Instead, the worst case time complexity for each search
 * is O(B + E), where B is the number of buckets,
 * and E is the maximum number of elements in a bucket,
 * which is determined by the variable `max_bucket_size`.
 *
 * This makes the mosaic construction considerably faster, 
 * which is especially noticeable when running it on the webcam-
 * even when all 5883 images are loaded, and the small img dimensions
 * are set to 9x6, it still runs in real-time.
 */
 
 
 // FUTURE TODO: remove or destructively combine buckets with near-identical color spaces
 
import java.util.Arrays;
/**
 * A wrapper class to hold a PImage and its color values,
 * and also keep track of how frequently it is used.
 *
 * Each Element holds a reference to a single PImage.
 */
class Element {
  PImage image;
  int rd, gr, bl;
  int use_freq;

  public int[] getRGB() {
    return new int[]{rd, gr, bl};
  }

  public Element(int r, int g, int b, PImage img) {
    rd = r;
    gr = g;
    bl = b;
    image = img;
    use_freq = 0;
  }
}

/**
 * Each Bucket holds an unsorted array of Elements,
 * which all have very similar image color spaces.
 **/
class Bucket {

  final int MAX_IMG_REPEATS = 3;

  ArrayList<Element> elements;
  int[] avg_color;
  
  public Bucket(int[] targetRGB) {
    elements = new ArrayList();
    avg_color = targetRGB;
  }

  public Bucket(Element e) {
    elements = new ArrayList();
    avg_color = e.getRGB();
    elements.add(e);
  }

  public Bucket(ArrayList<Element> elmnts) {
    elements = elmnts;
    avg_color = new int[3];
    recalcAvg();
  }

  public void add(Element e) {
    elements.add(e);
    // recalculate average after each new element is added. this ensures that 
    // the Bucket's average rgb value is always accurate for future insertions
    recalcAvg();
  }

  public int getSize() {
    return this.elements.size();
  }

  /**
   * Note: Sometimes it is unavoidable to reuse an image many times
   * in the mosaic, i.e. if that image resides in a unique color space,
   * because there will not be any other images in its bucket.
   */
  public Element getClosest(int[] targetRGB) {

    if (elements.isEmpty()) { // just for safety, should never be true
      return null;
    }

    // instead of null, start with first element to avoid returning null
    Element closest = elements.get(0);
    double min_dist = Double.MAX_VALUE;
    double dist;
    for (Element e : elements) {

      if (e.equals(closest)) {
        continue;
      }

      dist = euclid_dist(e, targetRGB);  
      if (dist < min_dist) {
        
        // prefer elements that have been used less frequently
        if (e.use_freq < MAX_IMG_REPEATS || e.use_freq < closest.use_freq) {
          closest = e;
          min_dist = dist;
          e.use_freq++;
        } else {
          // decrement Element's use_freq if it would have been used, but its current
          // use_freq value prevented it from being chosen
          e.use_freq--;
        }
      }
    }
    closest.use_freq++;
    return closest;
  }

  // recalculate average of all images currently in the bucket
  private void recalcAvg() {
    int r=0, g=0, b=0;
    for (Element e : elements) {
      r += e.rd;
      g += e.gr;
      b += e.bl;
    }
    avg_color[0] = (int) Math.round(r / (double) elements.size());
    avg_color[1] = (int) Math.round(g / (double) elements.size());
    avg_color[2] = (int) Math.round(b / (double) elements.size());
  }

  private double euclid_dist(Element n1, Element n2) {
    return Math.pow(
      Math.pow(n1.rd - n2.rd, 2) +
      Math.pow(n1.gr - n2.gr, 2) +
      Math.pow(n1.bl - n2.bl, 2), 0.5);
  }

  public double euclid_dist(Element n, int[] rgb) {
    return Math.pow(
      Math.pow(n.rd - rgb[0], 2) +
      Math.pow(n.gr - rgb[1], 2) +
      Math.pow(n.bl - rgb[2], 2), 0.5);
  }

  public double euclid_dist(int[] rgb1, int[] rgb2) {
    return Math.pow(
      Math.pow(rgb1[0] - rgb2[0], 2) +
      Math.pow(rgb1[1] - rgb2[1], 2) +
      Math.pow(rgb1[2] - rgb2[2], 2), 0.5);
  }

  public boolean isEmpty() {
    return this.elements.size() == 0;
  }
}

/**
 * Container class to hold a List of Bucket objects
 */
class BigBucket {

  ArrayList<Bucket> buckets;
  
  // metric used to compare RGB euclidean distances and determine
  // whether to create a new bucket or add to an existing one
  private double distance_threshold;

  public BigBucket(double dist_thresh) {
    this.distance_threshold = dist_thresh;
    buckets = new ArrayList();
  }

  public void add(Bucket b) {
    this.buckets.add(b);
  }

  public int getSize() {
    return this.buckets.size();
  }

  private Bucket getFirst() {
    if (! this.buckets.isEmpty()) {
      return this.buckets.get(0);
    }
    return null;
  }

  /* The main function used for creating all the buckets.
   * 
   * For each new Element, the current Bucket with the closest 
   * average color is retrieved, and then the `distance_threshold` 
   * variable is used to determine whether the Element is added to 
   * this closest Bucket or inserted into a new Bucket
  */
  public void addElement(Element e) {

    Bucket closest = getClosestBucket(e.getRGB());

    if (closest == null) { // this only happens when the very first element is inserted
      this.buckets.add(new Bucket(e));
      return;
    }

    // determine whether Element belongs in closest bucket,
    // or if a new Bucket should be created
    
    double dist_to_e = closest.euclid_dist(closest.avg_color, e.getRGB());

    if (dist_to_e <= distance_threshold) {
      closest.add(e);
    } else {
      this.buckets.add(new Bucket(e));
    }
  }

  /** 
   * Retrieve the bucket with the closest
   * average color to `targetRGB`
   */
  private Bucket getClosestBucket(int[] targetRGB) {

    // initialize with the first bucket instead of null
    Bucket closest = getFirst();
    
    double min_dist = Double.MAX_VALUE;
    double dist;

    for (Bucket b : buckets) { 
      // buckets are never empty so empty checking is not necessary
      dist = b.euclid_dist(b.avg_color, targetRGB);
      if (dist < min_dist) {
        closest = b;
        min_dist = dist;
      }
    }
    return closest;
  }

  /** 
   * The main function called for each square in the target image
   * during the construction of the mosaic. 
   *
   * Retrieves the closest Bucket to `targetRGB`, and then
   * the closest element within that Bucket to `targetRGB`.
   **/
  public Element getClosestElement(int[] targetRGB) {
    Bucket closestBucket = getClosestBucket(targetRGB);
    return closestBucket.getClosest(targetRGB);
  }

  /**
   * This function is used only during the initial construction of the buckets,
   * called by the balanceBuckets() function
   */
  private Bucket combineBuckets(ArrayList<Bucket> bucketList) {

    ArrayList<Element> elements = new ArrayList();
    for (Bucket b : bucketList) {
      elements.addAll(b.elements);
    }
    return new Bucket(elements);
  }

  /**
   * This function is called only once, after all the loaded images have been inserted
   * into buckets. 
   *
   * Buckets that are larger than `max_size` are split up into smaller buckets,
   * all of which will be less than `max_size`. Note that the number of new buckets
   * created is equal to the variable `numb_splits`.
   *
   * Additionally, Buckets that are smaller than `min_size` are searched and all buckets with
   * similar color spaces are combined.
   */
  private void balanceBuckets(int min_size, int max_size, double thresh_for_combining) {

    // it's necessary to construct new arraylists,
    // because modifying a list while iterating through it
    // is bad practice and can create race conditions
    ArrayList<Bucket> tooBigBuckets = new ArrayList();
    ArrayList<Bucket> tooSmallBuckets = new ArrayList();

    for (Bucket b : this.buckets) {
      if (b.getSize() > max_size) {
        tooBigBuckets.add(b);
      }
    }
    
    // these variables just keep track of the number of buckets added and removed 
    // during balancing, to be printed out in the console
    int added = 0;
    int removed = 0;

    for (Bucket b : tooBigBuckets) {

      int size = b.getSize();

      // always round up, to distribute elements more evenly among new buckets
      int numb_splits = (int) Math.ceil(size / (double) max_size);

      int prev = 0;    

      for (int i=1; i<size; i++) {

        // this happens `numb_splits` times, resulting in `numb_splits` new buckets created.
        if ((i % ((int) Math.round(size / (double) numb_splits)) == 0) 
          || (i==size-1)) {

          // create a new bucket containing the elements of Bucket b from `prev` to `i`
          Bucket newBucket = new Bucket(b.avg_color);
          newBucket.elements.addAll(b.elements.subList(prev, i));
          newBucket.recalcAvg();
          this.buckets.add(newBucket);

          // since the upper index in subList() is exclusive,
          // elements[i] has not been included in the above Bucket
          prev = i;

          added++;
        }
      }
      this.buckets.remove(b);
      removed++;
    }
    
    /* 
     * Combine small buckets that have similar color spaces
     *
     * This is run after the big bucket loops, on the off chance that
     * one of the smaller split buckets has fewer than `min_size` elements
     */
    for (Bucket b : this.buckets) {
      if (b.getSize() < min_size) {
        tooSmallBuckets.add(b);
      }
    }

    // keep track of Buckets already removed from main Bucket list
    ArrayList<Bucket> removedBuckets = new ArrayList();

    for (int a=0; a<tooSmallBuckets.size()-1; a++) {
      
      Bucket bucket1 = tooSmallBuckets.get(a);
      if (removedBuckets.contains(bucket1)) {
        continue;
      }

      ArrayList<Bucket> to_be_joined = new ArrayList();

      // search through remainder of list for similar color buckets
      for (int c=a+1; c<tooSmallBuckets.size(); c++) {
        Bucket bucket2 = tooSmallBuckets.get(c);
        if (removedBuckets.contains(bucket2)) {
          continue;
        }

        if (bucket1.euclid_dist(bucket1.avg_color, bucket2.avg_color) <= thresh_for_combining) {
          to_be_joined.add(bucket2);
        }
      }

      if (! to_be_joined.isEmpty()) {

        to_be_joined.add(bucket1); // bucket1 is not added to to_be_joined above, to allow empty check
        this.buckets.add(combineBuckets(to_be_joined));

        added++;

        for (Bucket b : to_be_joined) {
          removedBuckets.add(b);
          this.buckets.remove(b);
          removed++;
        }
      }
    }
    print(String.format("Bucket Balancing Total Changes: %d buckets added, %d buckets removed\n", added, removed));
  }

  public void summarize() {

    print(getSize(), "color space buckets in total\n");

    for (Bucket b : buckets) {
      print(String.format("Bucket with avg color: %s containing %d elements\n", Arrays.toString(b.avg_color), b.getSize()));
    }
  }
}
