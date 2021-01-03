//
//  TimelineTableViewCell.swift
//  Tweeter
//
//  Created by Chien on 2019/11/6.
//  Copyright © 2019 Chien. All rights reserved.
//

import UIKit

enum FetchImageError: Error {
    case ObjectIsNil
    case FetchURLFail(thisURL: URL)
}

class TimelineTableViewCell: UITableViewCell {

    static let identifier = "TimelineTableViewCell"

    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timesAgoLabel: UILabel!
    @IBOutlet weak var contentMessageLabel: UILabel!
    
    @IBOutlet weak var timelineBackgroundView: UIView! {
        didSet {
            
            // Setting timelineBackgroundView
            timelineBackgroundView.roundedCorner(by: 10)
        }
    }

    var userInfo: UserModel? {
        didSet {

            guard let thisUserInfo = userInfo else { return }

            userNameLabel.text = thisUserInfo.name
            userPhotoImageView.loadImage(from: URL(string: thisUserInfo.imageURL)) { (fetchImageError) in

                // If fetchImageError == nil then means loading image success
                if fetchImageError == nil { return }
                
                switch fetchImageError! {
                    case .ObjectIsNil :
                        print(fetchImageError.debugDescription)

                    case .FetchURLFail(let thisURL) :
                        print("Fetch image from \(thisURL) fail")
                }
            }
        }
    }
    
    var tweetInfo: TweetModel? {
        didSet {
            
            guard let thisTweetInfo = tweetInfo else { return }

            timesAgoLabel.text = timeIntervalToDate(with: thisTweetInfo.latestUpdateTime)
            contentMessageLabel.text = thisTweetInfo.message
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userPhotoImageView.roundedCorner(by: userPhotoImageView.frame.width / 2)

        // Transparent Cell's BackgroundColor
        self.backgroundColor = .clear
        
        // Cancel Cell's Style When it be Selected
        self.selectionStyle = .none
        
        // Using Shadow Color
        self.usingShadowColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reuse cell then clean old informations
        userPhotoImageView.image = nil
        userNameLabel.text = nil
        timesAgoLabel.text = nil
        contentMessageLabel.text = nil
    }
    
    private func timeIntervalToDate(with timeStamp: Double) -> String {
        
        let secondDifference = Int(Date().timeIntervalSince1970 - timeStamp)
        
        let mins  = 60
        let hours = 60 * 60
        let days  = 60 * 60 * 24
        let week  = 60 * 60 * 24 * 7
        
        if secondDifference < mins {
            let plural = secondDifference > 1 ? "s" : ""
            
            return "\(secondDifference) sec\(plural) ago"
        } else if mins <= secondDifference && secondDifference <= hours {
            let amount = secondDifference / mins
            let plural = amount > 1 ? "s" : ""
            
            return "\(amount) min\(plural) ago"
        } else if hours <= secondDifference && secondDifference <= days {
            let amount = secondDifference / hours
            let plural = amount > 1 ? "s" : ""
            
            return "\(amount) hr\(plural) ago"
        } else if days <= secondDifference && secondDifference <= week {
            let amount = secondDifference / days
            let plural = amount > 1 ? "s" : ""
            
            return "\(amount) day\(plural) ago"
        } else {
            let timeDate = Date(timeIntervalSince1970: TimeInterval(timeStamp))
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .long
            dateFormatter.locale = Locale.current
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm"

            return dateFormatter.string(from: timeDate)
        }
    }
}
