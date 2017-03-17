//
//  RapidRequest.swift
//  Rapid
//
//  Created by Jan on 17/03/2017.
//  Copyright © 2017 Rapid.io. All rights reserved.
//

import Foundation

protocol RapidRequest {
    func eventAcknowledged(_ acknowledgement: RapidSocketAcknowledgement)
    func eventFailed(withError error: RapidSocketError)
}
