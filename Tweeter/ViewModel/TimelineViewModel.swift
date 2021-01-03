//
//  TimelineViewModel.swift
//  Tweeter
//
//  Created by Chien on 2019/11/6.
//  Copyright © 2019 Chien. All rights reserved.
//

import Foundation
import FirebaseDatabase

enum RequestOperation {
    case Insert
    case Update
    case Delete
}

enum RequestError: Error {
    case FetchObjectIsNotDictionary
    case FetchDecodeFail
    case DataIsNil
    case GenerateAutoKeyIDFail
}

class TimelineViewModel {

    var totalTweetsInfo: [TweetModel]
    var totalTweetsAuthorDict: [String: UserModel]
    
    init() {
        totalTweetsInfo = []
        totalTweetsAuthorDict = [:]
    }

    private let userPath = "User"
    private let userOrderedChild = "email"
    private let tweetPath = "Tweet"
    private let tweeTOrderedChild = "latestUpdateTime"
    
    private func generateAutoKeyID(by ref: DatabaseReference) -> String? {
        return ref.childByAutoId().key
    }

    func fetchTweet(latestUpdateTime: Double? = nil, completion: @escaping(_ error: RequestError?) -> Void) {
        
        // Maximum loading amount per time
        let fetchTweetAmount = 10
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        requestTweet(by: latestUpdateTime, amount: UInt(fetchTweetAmount)) { (error) in
            guard error == nil else {
                completion(error)
                return
            }

            dispatchGroup.leave()
        }
        
        // Wait requestTweet Async finish then requestUser
        dispatchGroup.notify(queue: .main) {

            for eachTweetInfo in self.totalTweetsInfo {
                
                // Means that this userEmail is already reqeusted before
                if !self.totalTweetsAuthorDict.keys.contains(eachTweetInfo.authorEmail) {
                    
                    dispatchGroup.enter()
                    self.requestUser(by: eachTweetInfo.authorEmail, completion: { (error) in
                        guard error == nil else {
                            completion(error)
                            return
                        }

                        dispatchGroup.leave()
                    })
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.totalTweetsInfo.sort(by: {$0.latestUpdateTime > $1.latestUpdateTime})
                completion(nil)
            }
        }
    }
    
    private func requestUser(by authorEmail: String, completion: @escaping(_ error: RequestError?) -> Void) {
        
        Database.database().reference().child(userPath).queryOrdered(byChild: userOrderedChild).queryEqual(toValue: authorEmail).observeSingleEvent(of: .value, with: { (userSnapshot) in
            
            do {
                
                let decodeUserInfo: [UserModel] = try userSnapshot.decode()
                
                // An email can only have an account
                guard let userInfo = decodeUserInfo.first else {
                    completion(RequestError.DataIsNil)
                    return
                }
                
                self.totalTweetsAuthorDict[authorEmail] = userInfo
                completion(nil)
            } catch let decodeError {
                completion(decodeError as? RequestError)
            }
        })
    }

    private func requestTweet(by latestUpdateTime: Double? = nil, amount: UInt, completion: @escaping(_ error: RequestError?) -> Void) {
        
        var ref: DatabaseQuery {
            
            if latestUpdateTime == nil {
                return Database.database().reference().child(tweetPath).queryOrdered(byChild: tweeTOrderedChild).queryLimited(toLast: amount)
            } else {
                return Database.database().reference().child(tweetPath).queryOrdered(byChild: tweeTOrderedChild).queryEnding(atValue: latestUpdateTime).queryLimited(toLast: amount)
            }
        }

        ref.observeSingleEvent(of: .value, with: { (tweetSnapshot) in

            do {

                if latestUpdateTime == nil {
                    self.totalTweetsInfo = try tweetSnapshot.decode()
                } else {
                    let totalNewTweetsInfo: [TweetModel] = try tweetSnapshot.decode()

                    // Means that there are old data and also not repeat
                    for eachNewTweetsInfo in totalNewTweetsInfo {
                        let repeatTweet = self.totalTweetsInfo.filter({ $0.createTime == eachNewTweetsInfo.createTime })
                        if repeatTweet.count == 0 { self.totalTweetsInfo.append(eachNewTweetsInfo) }
                    }
                }

                completion(nil)
            } catch let decodeError {
                completion(decodeError as? RequestError)
            }
        })
    }

    func operateTweet(do operationType: RequestOperation, data:(key: String?, value: [String: Any]?),
                         completion: @escaping(_ error: RequestError?) -> Void) {
        
        switch operationType {
            case .Insert :
                
                // Insert only need data.value
                if data.value == nil { completion(RequestError.DataIsNil) }
                
                guard let autoKeyID = generateAutoKeyID(by: Database.database().reference().child(tweetPath)) else {
                    completion(RequestError.GenerateAutoKeyIDFail)
                    return
                }
                
                Database.database().reference().child(tweetPath).child(autoKeyID).updateChildValues(data.value!)
                completion(nil)
            
            case .Update :
                
                // Update need data.key & data.value
                if data.key == nil || data.value == nil { completion(RequestError.DataIsNil) }
                
                Database.database().reference().child(tweetPath).child(data.key!).updateChildValues(data.value!)
                completion(nil)
            
            case .Delete :
                
                // Delete only need data.key
                if data.key == nil { completion(RequestError.DataIsNil) }
                
                Database.database().reference().child(tweetPath).child(data.key!).removeValue()
                completion(nil)
        }
    }    
}
