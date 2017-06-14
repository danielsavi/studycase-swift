//
//  FaceView.swift
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

// our delegate protocol
// gets the data for us
// (so that we can be a generic View component)
protocol FaceViewDataSource: class {
    func smilinessForFaceView(_ sender: FaceView) -> Double?
}

@IBDesignable
class FaceView: UIView
{
    @IBInspectable
    var lineWidth: CGFloat = 3 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.blue { didSet { setNeedsDisplay() } }
    @IBInspectable
    var scale: CGFloat = 0.90 { didSet { setNeedsDisplay() } }
    
    // in demo, this was mistakenly not made private ... fixed
    fileprivate var faceCenter: CGPoint {
        return convert(center, from: superview)
    }
    // in demo, this was mistakenly not made private ... fixed
    fileprivate var faceRadius: CGFloat {
        return min(bounds.size.width, bounds.size.height) / 2 * scale
    }
    
    // public (non-private) delegate property
    // anyone who wants to provide our View's data
    // should just set themselves to be this property
    weak var dataSource: FaceViewDataSource?
    
    // gesture handler for pinching
    // non-private so that Controllers can create a recognizer for pinch
    // and then add it to us if they want us to support pinching
    func scale(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            scale *= gesture.scale
            gesture.scale = 1
        }
    }
    
    // the rest of this class is the code to draw the face
    override func draw(_ rect: CGRect)
    {
        let facePath = UIBezierPath(
            arcCenter: faceCenter,
            radius: faceRadius,
            startAngle: 0,
            endAngle: CGFloat(2*Double.pi),
            clockwise: true
        )
        facePath.lineWidth = lineWidth
        color.set()
        facePath.stroke()
        
        bezierPathForEye(.left).stroke()
        bezierPathForEye(.right).stroke()
        
        // get the smiliness from our dataSource delegate
        // smiliness will default to zero if either the dataSource is nil or the dataSource returns nil
        let smiliness = dataSource?.smilinessForFaceView(self) ?? 0.0

        let smilePath = bezierPathForSmile(smiliness)
        smilePath.stroke()
    }
    
    fileprivate struct Scaling {
        static let FaceRadiusToEyeRadiusRatio: CGFloat = 10
        static let FaceRadiusToEyeOffsetRatio: CGFloat = 3
        static let FaceRadiusToEyeSeparationRatio: CGFloat = 1.5
        static let FaceRadiusToMouthWidthRatio: CGFloat = 1
        static let FaceRadiusToMouthHeightRatio: CGFloat = 3
        static let FaceRadiusToMouthOffsetRatio: CGFloat = 3
    }
    
    fileprivate enum Eye { case left, right }
    
    fileprivate func bezierPathForEye(_ whichEye: Eye) -> UIBezierPath
    {
        let eyeRadius = faceRadius / Scaling.FaceRadiusToEyeRadiusRatio
        let eyeVerticalOffset = faceRadius / Scaling.FaceRadiusToEyeOffsetRatio
        let eyeHorizontalSeparation = faceRadius / Scaling.FaceRadiusToEyeSeparationRatio
        
        var eyeCenter = faceCenter
        eyeCenter.y -= eyeVerticalOffset
        switch whichEye {
            case .left: eyeCenter.x -= eyeHorizontalSeparation / 2
            case .right: eyeCenter.x += eyeHorizontalSeparation / 2
        }
        
        let path = UIBezierPath(
            arcCenter: eyeCenter,
            radius: eyeRadius,
            startAngle: 0,
            endAngle: CGFloat(2*Double.pi),
            clockwise: true
        )
        path.lineWidth = lineWidth
        return path
    }

    fileprivate func bezierPathForSmile(_ fractionOfMaxSmile: Double) -> UIBezierPath
    {
        let mouthWidth = faceRadius / Scaling.FaceRadiusToMouthWidthRatio
        let mouthHeight = faceRadius / Scaling.FaceRadiusToMouthHeightRatio
        let mouthVerticalOffset = faceRadius / Scaling.FaceRadiusToMouthOffsetRatio
        
        let smileHeight = CGFloat(max(min(fractionOfMaxSmile, 1), -1)) * mouthHeight
        
        let start = CGPoint(x: faceCenter.x - mouthWidth / 2, y: faceCenter.y + mouthVerticalOffset)
        let end = CGPoint(x: start.x + mouthWidth, y: start.y)
        let cp1 = CGPoint(x: start.x + mouthWidth / 3, y: start.y + smileHeight)
        let cp2 = CGPoint(x: end.x - mouthWidth / 3, y: cp1.y)
        
        let path = UIBezierPath()
        path.move(to: start)
        path.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
        path.lineWidth = lineWidth
        return path
    }
}
