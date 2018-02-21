//
//  ViewController.swift
//  Test
//
//  Created by Yoni on 18/02/2018.
//  Copyright © 2018 Yoni. All rights reserved.
//

import UIKit
import YHUIKit

class ViewController: UIViewController {

    static let maxRandomViewSize = 70
    static let minRandomViewSize = 5
    static let numberOfPairs = 10

    //MARK: - Main UI
    
    lazy var mainView: UIView = {
        let mainView = UIView()
        mainView.width = 44
        mainView.height = mainView.width
        mainView.backgroundColor = UIColor.blue
        mainView.layer.borderColor = UIColor.black.cgColor
        mainView.layer.borderWidth = 1
        
        let panReco = UIPanGestureRecognizer(target: self, action: #selector(moveMainView))
        mainView.addGestureRecognizer(panReco)
        
        let tapReco = UITapGestureRecognizer(target: self, action: #selector(selectView))
        mainView.addGestureRecognizer(tapReco)
        
        return mainView
    }()
    
    lazy var pairViews: [UIView] = {
        var pairViews = [UIView]()
        
        for index in 0...ViewController.numberOfPairs {
            let randomPair = newRandomPair()
            
            randomPair.0.tag = index
            randomPair.1.tag = index
            
            pairViews.append(randomPair.0)
            pairViews.append(randomPair.1)
        }
        
        return pairViews
    }()
    
    var currentIntersectedView: UIView?
    
    //MARK: - View Lifecycle
    
    override func loadView() {
        super.loadView()
        buildViewTree()
        layout()
    }
    
    func buildViewTree() {
        
        for pairView in pairViews {
            view.addSubview(pairView)
        }
        view.addSubview(mainView)
    }

    func layout() {
        mainView.centerInSuperview()
    }
    
    
    //MARK: - Animation
    
    func updateColorIfMainViewIntersect() {
        var biggestIntersectedView: UIView?
        for pairView in pairViews {
            let isStaticViewIntersets = pairView.frame.intersects(mainView.frame)
            if isStaticViewIntersets {
                let staticViewArea = pairView.width * pairView.height
                let biggestIntersectedViewArea = (biggestIntersectedView?.width ?? 0) * (biggestIntersectedView?.height ?? 0)
                
                if staticViewArea > biggestIntersectedViewArea {
                    biggestIntersectedView = pairView
                }
            }
        }
        
        
        if let biggestIntersectedView = biggestIntersectedView, biggestIntersectedView != currentIntersectedView {
            mainView.backgroundColor = biggestIntersectedView.backgroundColor
        }
        currentIntersectedView = biggestIntersectedView

    }
    
    //MARK: - Helper
    
    func newRandomPair() -> (UIView, UIView) {
        let firstRandomView = UIView()
        let secondRandomView = UIView()
        
        let randomWidth = Int(arc4random()) % (ViewController.maxRandomViewSize - ViewController.minRandomViewSize) + ViewController.minRandomViewSize
        let randomHeight = Int(arc4random()) % (ViewController.maxRandomViewSize - ViewController.minRandomViewSize) + ViewController.minRandomViewSize
        let randomHue = CGFloat( Int(arc4random()) % 360 ) / 360.0
        
        firstRandomView.width = CGFloat(randomWidth)
        firstRandomView.height = CGFloat(randomHeight)
        firstRandomView.backgroundColor = UIColor(hue: randomHue, saturation: 1, brightness: 1, alpha: 1)

        secondRandomView.width = CGFloat(randomWidth)
        secondRandomView.height = CGFloat(randomHeight)
        secondRandomView.backgroundColor = UIColor(hue: randomHue, saturation: 1, brightness: 1, alpha: 1)

        firstRandomView.x = CGFloat(Int(arc4random()) % (Int(view.bounds.width) - randomWidth))
        firstRandomView.y = CGFloat(Int(arc4random()) % (Int(view.bounds.height) - randomHeight))

        secondRandomView.x = CGFloat(Int(arc4random()) % (Int(view.bounds.width) - randomWidth))
        secondRandomView.y = CGFloat(Int(arc4random()) % (Int(view.bounds.height) - randomHeight))


        return (firstRandomView, secondRandomView)
    }
    
    
}

//MARK: - Gesture

extension ViewController {
    
    @objc func moveMainView(_ panReco: UIPanGestureRecognizer) {
        struct Static {
            static var delta: CGPoint = CGPoint.zero
        }
        
        let location = panReco.location(in: view)
        
        if panReco.state == .began {
            Static.delta = CGPoint(x: mainView.centerX - location.x, y: mainView.centerY - location.y)
        } else if panReco.state == .changed{
            mainView.center = CGPoint(x: location.x + Static.delta.x, y: location.y + Static.delta.y)
            updateColorIfMainViewIntersect()
        }
    }
    
    @objc func selectView(_ tapReco: UITapGestureRecognizer) {
        
        struct Static {
            static var firstSelectedView: UIView?
        }
        
        guard let currentIntersectedView = currentIntersectedView else {
            return
        }
        
        setViewSelected(currentIntersectedView)
        
        bringToFrontAndBumpView(currentIntersectedView) {
            if let firstSelectedView = Static.firstSelectedView, currentIntersectedView != firstSelectedView {
                Static.firstSelectedView = nil

                let arePairsMatched = firstSelectedView.tag == currentIntersectedView.tag
                
                self.spinView(firstSelectedView, completion: nil)
                self.spinView(currentIntersectedView) {
                    
                    if !arePairsMatched {
                        self.animateViewsOnFail(first: firstSelectedView, second: currentIntersectedView)
                    }
                }
                
                if arePairsMatched {
                    self.animateViewsOnSuccess(first: firstSelectedView, second: currentIntersectedView, completion: {
                        self.pairViews.remove(at: self.pairViews.index(of: firstSelectedView)!)
                        self.pairViews.remove(at: self.pairViews.index(of: currentIntersectedView)!)
                    })
                }

            } else {
                Static.firstSelectedView = currentIntersectedView
            }
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            spinView(mainView, completion: nil)
        }
    }
}

//MARK: - Animation
extension ViewController {
    func spinView(_ currentView: UIView, completion: (() -> Void)? ) {
        UIView.animate(withDuration: 0.3, animations: {
            currentView.transform = CGAffineTransform(rotationAngle:CGFloat.pi)
        }, completion: { (success) in
            UIView.animate(withDuration: 0.3, animations: {
                currentView.transform = CGAffineTransform(rotationAngle:CGFloat.pi)
            }, completion: { (success) in
                currentView.transform = .identity
                
                if let completion = completion {
                    completion()
                }
            })
        })
    }
    
    func bringToFrontAndBumpView(_ currentView: UIView, completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.15, animations: {
            currentView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: { (success) in
            self.view.insertSubview(currentView, belowSubview: self.mainView)
            UIView.animate(withDuration: 0.15, animations: {
                currentView.transform = .identity
            }, completion: { (success) in
                
                if let completion = completion {
                    completion()
                }
            })
        })
    }
    
    func animateViewsOnSuccess(first firstCurrentView: UIView, second secondCurrentView: UIView, completion: (() -> Void)?) {
        let finalPosition = CGPoint(x: view.width * 1.5, y: view.height * 1.5)
        
        UIView.animate(withDuration: 0.6, animations: {
            firstCurrentView.center = finalPosition
            secondCurrentView.center = finalPosition
        }, completion: { (success) in
            if let completion = completion {
                completion()
            }
        })
    }

    func animateViewsOnFail(first firstCurrentView: UIView, second secondCurrentView: UIView) {
        firstCurrentView.layer.borderWidth = 0
        secondCurrentView.layer.borderWidth = 0
    }
    
    func setViewSelected(_ selectedView: UIView) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        selectedView.backgroundColor?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        hue += 0.5
        
        if hue > 1 {
            hue -= 1
        }
        
        selectedView.layer.borderColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha).cgColor
        selectedView.layer.borderWidth = 2
    }
}

