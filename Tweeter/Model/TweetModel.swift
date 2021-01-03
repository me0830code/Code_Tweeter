//
//  TweetModel.swift
//  Tweeter
//
//  Created by Chien on 2019/11/6.
//  Copyright © 2019 Chien. All rights reserved.
//

import Foundation

struct TweetModel: Codable {

    var authorEmail: String
    var message: String
    var createTime: Double
    var latestUpdateTime : Double
}
