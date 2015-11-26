//
//  ViewController.swift
//  FurrySketch
//
//  Created by Simon Gladman on 25/11/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//


import UIKit

class ViewController: UIViewController
{
    
    let halfPi = CGFloat(M_PI_2)
    let imageView = UIImageView()
    let compositeFilter = CIFilter(name: "CISourceOverCompositing")!
    
    let slider = UISlider()
    var hue = CGFloat(0)
    
    lazy var imageAccumulator: CIImageAccumulator =
    {
        [unowned self] in
        return CIImageAccumulator(extent: self.view.frame, format: kCIFormatARGB8)
        }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        slider.maximumValue = 1
        slider.addTarget(self, action: "sliderChangeHandler", forControlEvents: .ValueChanged)
        
        view.addSubview(imageView)
        view.addSubview(slider)
        
        view.backgroundColor =  UIColor.blackColor()
        
        sliderChangeHandler()
    }
    
    func sliderChangeHandler()
    {
        hue = CGFloat(slider.value)
        
        slider.minimumTrackTintColor = color
        slider.maximumTrackTintColor = color
        slider.thumbTintColor = color
    }
    
    var color: UIColor
        {
            return UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?)
    {
        if motion == UIEventSubtype.MotionShake
        {
            imageAccumulator.clear()
            imageAccumulator.setImage(CIImage(color: CIColor(string: "00000000")))
            
            imageView.image = nil
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let
            touch = touches.first,
            coalescedTouces = event?.coalescedTouchesForTouch(touch) where
            touch.type == UITouchType.Stylus else
        {
            return
        }
        
        UIGraphicsBeginImageContext(view.frame.size)
        
        let cgContext = UIGraphicsGetCurrentContext()
        
        CGContextSetLineWidth(cgContext, 1)
        
        CGContextSetStrokeColorWithColor(cgContext, color.colorWithAlphaComponent(0.025).CGColor)
        
        for coalescedTouch in coalescedTouces
        {
            let touchLocation = coalescedTouch.locationInView(view)
            
            let normalisedAlititudeAngle =  (halfPi - touch.altitudeAngle) / halfPi
            let dx = coalescedTouch.azimuthUnitVectorInView(view).dx * 20 * normalisedAlititudeAngle
            let dy = coalescedTouch.azimuthUnitVectorInView(view).dy * 20 * normalisedAlititudeAngle
            
            let count = 10 + Int((coalescedTouch.force / coalescedTouch.maximumPossibleForce) * 100)
            
            for _ in 0 ... count
            {
                let randomAngle = drand48() * (M_PI * 2)
                
    let innerRandomRadius = drand48() * 20
    let innerRandomX = CGFloat(sin(randomAngle) * innerRandomRadius)
    let innerRandomY = CGFloat(cos(randomAngle) * innerRandomRadius)
                
    let outerRandomRadius = innerRandomRadius + drand48() * 40 * Double(normalisedAlititudeAngle)
    let outerRandomX = CGFloat(sin(randomAngle) * outerRandomRadius) - dx
    let outerRandomY = CGFloat(cos(randomAngle) * outerRandomRadius) - dy
                
    CGContextMoveToPoint(cgContext,
        touchLocation.x + innerRandomX,
        touchLocation.y + innerRandomY)
    
    CGContextAddLineToPoint(cgContext,
        touchLocation.x + outerRandomX,
        touchLocation.y + outerRandomY)
    
    CGContextStrokePath(cgContext)
            }
        }
        
    let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    compositeFilter.setValue(CIImage(image: drawnImage),
        forKey: kCIInputImageKey)
    compositeFilter.setValue(imageAccumulator.image(),
        forKey: kCIInputBackgroundImageKey)
    
    imageAccumulator.setImage(compositeFilter.valueForKey(kCIOutputImageKey) as! CIImage)
    
    imageView.image = UIImage(CIImage: imageAccumulator.image())
    }
    
    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds
        
        slider.frame = CGRect(x: 0,
            y: view.frame.height - slider.intrinsicContentSize().height - 20,
            width: view.frame.width,
            height: slider.intrinsicContentSize().height).insetBy(dx: 20, dy: 0)
    }
}