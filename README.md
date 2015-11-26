# FurrySketch
##### Using Apple Pencil's Azimuth &amp; Altitude Data for Creating Furry Brush Strokes

##### _Companion project to this blog post: http://flexmonkey.blogspot.co.uk/2015/11/furrysketch-hirsute-drawing-with-apple.html_

![image](/FurrySketch/assets/furry.jpg)


After my recent experiments (mis)using my Apple Pencil for nefarious and alternative uses, I thought it was about time to play with the Pencil for its intended purpose, sketching, and see how I could use its orientation data to affect brush strokes. 

FurrySketch is a Pencil powered drawing application that draws a sort of multicoloured hair and, most excitingly, the hair's direction matches the angle of the Pencil. It was super simple to write and, at least in my opinion, gives really nice results.

The basic mechanics are lifted from my ForceSketch project: I use a `CIImageAccumulator` with each new bitmap (created inside `touchesMoved`) composited over the previously accumulated images with a Core Image `CISourceOverCompositing` filter.  

The interesting part for Pencil fans is creating the hairy brush strokes:

## Hirsute Brush Mechanics

Inside `touchesMoved`, I loop over the coalesced touches (you can read about coalesced touches in my Advanced Touch Handling blog post). For each of the intermediate touches, I want to find its location in the view, its altitude angle and its azimuth vector. This vector points in the direction of the Pencil's azimuth angle and by multiplying it with the normalised altitude angle, I get an offset I can use when drawing my little hairs:

```swift
    for coalescedTouch in coalescedTouces
    {
        let touchLocation = coalescedTouch.locationInView(view)
        
        let normalisedAlititudeAngle =  (halfPi - touch.altitudeAngle) / halfPi
        let dx = coalescedTouch.azimuthUnitVectorInView(view).dx * 20 * normalisedAlititudeAngle
        let dy = coalescedTouch.azimuthUnitVectorInView(view).dy * 20 * normalisedAlititudeAngle
```

I then use the touch's force to decide how many hairs to draw...

```swift
    let count = 10 + Int((coalescedTouch.force / coalescedTouch.maximumPossibleForce) * 100)
```

Now I iterate `count` times. With each iteration, I create a random angle and create constants for the inner radius and start point for each hair:

```swift
    let innerRandomRadius = drand48() * 20
    let innerRandomX = CGFloat(sin(randomAngle) * innerRandomRadius)

    let innerRandomY = CGFloat(cos(randomAngle) * innerRandomRadius)
```

Although the start point of the hair isn't affected by the Pencil's orientation, the end point is. Here, I create another, larger, random radius, use the same angle and offset the end point by dx and dy I created above:

```swift
    randomRadius = innerRandomRadius + drand48() * 40 * Double(normalisedAlititudeAngle)
    
    let outerRandomX = CGFloat(sin(randomAngle) * outerRandomRadius) - dx
    let outerRandomY = CGFloat(cos(randomAngle) * outerRandomRadius) - dy
```

With those values, I can draw the hairs to my context and repeat over:

```swift
    CGContextMoveToPoint(cgContext,
        touchLocation.x + innerRandomX,
        touchLocation.y + innerRandomY)
    
    CGContextAddLineToPoint(cgContext,
        touchLocation.x + outerRandomX,
        touchLocation.y + outerRandomY)
    
    CGContextStrokePath(cgContext)
```    

A quick reminder on `CIImageAccumulator`: once the big, hairy loop is finished, I can get the newly generated image from the context and use the `CISourceOverCompositing` filter to composite that image for that touch move over the previous and finally display it in an `UIImageView`:

```swift
    let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    compositeFilter.setValue(CIImage(image: drawnImage),
        forKey: kCIInputImageKey)
    compositeFilter.setValue(imageAccumulator.image(),
        forKey: kCIInputBackgroundImageKey)
    
    imageAccumulator.setImage(compositeFilter.valueForKey(kCIOutputImageKey) as! CIImage)
    
    imageView.image = UIImage(CIImage: imageAccumulator.image())
```

## In Conclusion

If you are writing drawing apps, adding Pencil support is not only super easy, it adds real value for your users. The technique I've used here to draw hair is only a few lines of code way from spray cans and air brushes and I genuinely believe the iPad Pro will prove to be an amazing device for creatives.
