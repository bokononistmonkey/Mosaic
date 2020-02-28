/** //<>//
 * @author bokononistmonkey
 * Feb 06, 2019
 * Mosaic Maker
 */

/** //<>// //<>//
 * Vanilla Mosaic Maker (see: http://en.wikipedia.org/wiki/Photo_mosaic)
 * Sep 2014
 *
 * Depending on the number of images you might have to increase
 * the maximum available memory (in the Processing Preferences menu)
 */

import processing.video.*;

//PImage targetImage; 
Capture targetImage;   // webcam

BigBucket colorbuckets; // a container class that holds an array of Bucket objects

// our array of smaller mosaic images
PImage[] imgs;
int num_imgs = 0;

// size of the small mosaic images
int img_width = 6;
int img_height = 6;

int MAX_IMGS = 5883;

// the threshold used to determine whether to put a given image in a new bucket
// or add it to the bucket with the closest avg color value.
// 10.0 is a good threshold number, which I determined through trial and error,
// because it gets a relatively even spread of images across a reasonable number of buckets
double euclid_dist_thresh = 10.0;

// constraints used as parameters in balanceBuckets() function. 
// changing them will affect performance (positively or negatively, depending on the change).
int min_bucket_size = 10;
int max_bucket_size = 80;

public void setup() {

  size(640, 480);

  targetImage = new Capture(this, width, height);
  targetImage.start();

  imgs = new PImage[MAX_IMGS];
  loadSavedImages();
  createBuckets(imgs, num_imgs);
  noStroke();
}

/**
 *  Builds Buckets reactively, inserting images either into Buckets with images 
 *  that have very similar color spaces, or creating new Buckets as needed.
 *
 *  Note that all of the code that actually constructs Buckets is 
 *  within the BigBucket class.
 */
void createBuckets(PImage[] imageArray, int num_imgs) {

  colorbuckets = new BigBucket(euclid_dist_thresh);

  for (int i=0; i<num_imgs; i++) {

    if (imageArray[i] == null) {
      continue;
    }

    int r=0, g=0, b=0;

    for (color c : imageArray[i].pixels) {
      r += (c >> 16) & 0xff;
      g += (c >> 8) & 0xff;
      b += c & 0xff;
    }

    r /= imageArray[i].pixels.length;
    g /= imageArray[i].pixels.length;
    b /= imageArray[i].pixels.length;

    colorbuckets.addElement(new Element(r, g, b, imageArray[i]));
  }
  // use a higher distance threshold for balancing, to allow small buckets to be combined together
  colorbuckets.balanceBuckets(min_bucket_size, max_bucket_size, euclid_dist_thresh * 2);
  colorbuckets.summarize();
}

//load the mosaic images
void loadSavedImages() {

  for (int i = 1; i < MAX_IMGS; i++) {
    try {
      imgs[num_imgs] =  loadImage("snap" + nf(i, 4) + ".jpg"); 
      if (imgs[num_imgs] != null) {
        println("loaded image #", num_imgs);
        num_imgs ++;
      }
    }
    catch(Exception e) {
      print(e.getMessage());
    }
  }
  println(num_imgs, "images loaded.");
}


void draw() {

  //targetImage.loadPixels();

  if (targetImage.available()) {
    targetImage.read();

    for (int x = 0; x < width; x+= img_width) {
      for (int y = 0; y < height; y+= img_height) {

        // map the current pixel location, which is within the smalle image bounds,
        // to a location within the larger target image bounds
        int vx = int(map(x, 0, width, 0, targetImage.width));
        int vy = int(map(y, 0, height, 0, targetImage.height));

        // find actual pixel location in the 1-D array of the target image
        int i = targetImage.width*vy + vx;

        int pixelColor = targetImage.pixels[i];

        // separate the r,g,b values from the 32-bit integer representing the color
        int r = (pixelColor >> 16) & 0xff;
        int g = (pixelColor >> 8) & 0xff;
        int b = pixelColor & 0xff;

        int[] targetRGB = {r, g, b};

        PImage closest = colorbuckets.getClosestElement(targetRGB).image;

        image(closest, x, y, img_width, img_height);
        
      }
    }
  }
}
