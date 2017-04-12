//
//  TimerExtension.swift
//  Rapid
//
//  Created by Jan on 12/04/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

class TimerTarget: NSObject {
    
    let block: (_ userInfo: Any?) -> Void
    
    init(block: @escaping (_ userInfo: Any?) -> Void) {
        self.block = block
    }
    
    func timerFired(_ timer: Timer) {
        block(timer.userInfo)
    }
}

extension Timer {
    
    class func scheduledTimer(timeInterval ti: TimeInterval, userInfo: Any?, repeats yesOrNo: Bool, block: @escaping (_ userInfo: Any?) -> Void) -> Timer {
        let target = TimerTarget(block: block)
        
        return Timer.scheduledTimer(timeInterval: ti, target: target, selector: #selector(target.timerFired(_:)), userInfo: userInfo, repeats: yesOrNo)
    }
}
