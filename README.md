### Computational Images: Mosaic Reconstruction Lab

#### Given:
A 600mb folder containing 5,882 images representing the video frames from the 1971 movie Willy Wonka & the Chocolate Factory (1 frame was taken from each second of the movie).

#### Task:

Reconstruct a target image (or video input from the webcam) with a mosaic built using the provided images as mosaic pixels, and maintaining the correct color values for each sub region of the image. 

#### Solution/Approach:

Created a color-space bucket data structure that grouped images into size-constricted color-space buckets during the initial loading from file process. Color space comparison and thresholding was calculated using the euclidean distance between the average RGB value of each image (calculated just once during initial image loading). 

With this design, the image searching component of the mosaic construction code was kept far below `O(n)` time (`n` in this case would be the total number of images, 5882), which enabled running it real-time on the webcam. The exact time complexity of each image search (one search is performed for each pixel of the mosaic) has an upper bound of `O(B+E)`, where `B` is the number of buckets (produced dynamically, and typically about 3-5% of the size of `n`), and `E` is the maximum number of elements in any bucket, which is determined by the `max_bucket_size` variable. This makes the total upper-bound time complexity of a full mosaic image creation `O(m\*(B + E))`, where `m` is the size (number of pixels/tiles) in the mosaic.


### Willie Wonka poster
![oops, image link is broken. check the sample/ folder](sample/mosaic.png)


### Webcam

<p align="center">
  <img src="sample/capture.png" alt="oops, image link is broken. check the sample/ folder">
</p>
  

