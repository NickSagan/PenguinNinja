//
//  Constants.swift
//  PenguinNinja
//
//  Created by Nick Sagan on 25.11.2021.
//

import SpriteKit

struct K {
    
    public static let launchRangeX =  64...960
    public static let launchPositionY =  -128
    public static let AngularVelocity: ClosedRange<CGFloat> = -3...3
    public static let edgeVelocityX = 8...15
    public static let innerVelocityX = 3...5
    public static let velocityRangeY = 24...32
    public static let popupTimeMultiplier = 0.991
    public static let chainDelayMultiplier = 0.99
    public static let physicsWorldSpeedMultiplier = 1.02
    
}
