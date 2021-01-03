//
//  PostTweetViewController.swift
//  Tweeter
//
//  Created by Chien on 2019/11/7.
//  Copyright © 2019 Chien. All rights reserved.
//

import UIKit

enum SplitMessageError: Error {
    case SingleWordExceedLimit(invalidWords: [String])
    case PartIndicatorWithWordExceedLimit(thisPartIndicatorWithWord: [String])
}

protocol SendPostingDelegate: AnyObject {
    func mainPageRefreshData()
}

class PostTweetViewController: UIViewController {
    
    var timelineViewModel: TimelineViewModel?
    
    weak var sendPostingDelegate: SendPostingDelegate?

    let lengthLimit = 50
    
    // Assume current user's email is "Chien@gmail.com"
    private let currentUserInfo = UserModel(email: "Chien@gmail.com", name: "Chien", imageURL: "https://firebasestorage.googleapis.com/v0/b/tweeter-c88a8.appspot.com/o/User%2FMe.png?alt=media&token=7f695d1a-6f42-4893-acaa-fa069aee5f24")
    
    @IBOutlet weak var userPhotoImageView: UIImageView! {
        didSet {
            
            userPhotoImageView.roundedCorner(by: userPhotoImageView.frame.width / 2)
            userPhotoImageView.loadImage(from: URL(string: currentUserInfo.imageURL)) { (fetchImageError) in
                
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

    @IBOutlet weak var welcomeMessageLabel: UILabel! {
        didSet {
            welcomeMessageLabel.text = "Hello \(currentUserInfo.name),\nHow's going on ?"
        }
    }
    
    @IBOutlet weak var inputTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    private func setupUI() {
        
        navigationItem.title = "Let's post a tweet !"

        // Set up sendPostBarButtonItem
        let sendPostBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendPost))
        sendPostBarButtonItem.tintColor = .white
        navigationItem.setRightBarButton(sendPostBarButtonItem, animated: true)

        // Set up back button color
        navigationController?.navigationBar.tintColor = .white

        inputTextView.delegate = self
        setPlaceHolder()
    }
    
    @objc func sendPost() {
        
        guard let inputText = inputTextView.text else { return }

        // Message is empty or only contain placeholder
        if inputText.count == 0 || inputTextView.textColor == .lightGray {
            ShowAlert(with: "Oops !", message: "Tweet can not be empty :(")
            return
        }

        do {
            let totalMessage = try splitMessage(with: inputText, amount: lengthLimit)
            
            let dispatchGroup = DispatchGroup()
            for eachMessage in totalMessage {

                // Save data to firebase
                let thisTweet = TweetModel(authorEmail: currentUserInfo.email, message: eachMessage, createTime: Date().timeIntervalSince1970, latestUpdateTime: Date().timeIntervalSince1970)
                
                let data = try JSONEncoder().encode(thisTweet)
                let dataValue = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                dispatchGroup.enter()
                timelineViewModel?.operateTweet(do: .Insert, data: (key: nil, value: dataValue)) { (error) in
                    guard error == nil else {
                        self.ShowAlert(with: "Oops !", message: "Sending data fail, please try again later")
                        return
                    }

                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.sendPostingDelegate?.mainPageRefreshData()
                self.navigationController?.popViewController(animated: true)
            }
        } catch SplitMessageError.SingleWordExceedLimit(let invalidWords) {
            let allWords = invalidWords.joined(separator: ", ")
            ShowAlert(with: "Oops !", message: "These words are exceed the maximum length limit :\n\"\(allWords)\"")
        } catch SplitMessageError.PartIndicatorWithWordExceedLimit(let thisPartIndicatorWithWord) {
            let invalidStr = thisPartIndicatorWithWord.first!
            ShowAlert(with: "Oops !", message: "This word with part indicator exceed the maximum length limit :\n\"\(invalidStr)\"")
        } catch {
            ShowAlert(with: "Oops !", message: "Split message fail")
        }
    }

    func splitMessage(with text: String, amount lengthLimit: Int) throws -> [String] {
        
        // If text.count <= lengthLimit means that this text's length is valid
        if text.count <= lengthLimit { return [text] }
        
        let textSplitWithSpace = text.split(separator: " ").map({ String($0) })
        let exceedLimitWords = textSplitWithSpace.filter({ $0.count > lengthLimit})
        
        // If exceedLimitWords.count > 0 means there are words exceed max length limit
        guard exceedLimitWords.count == 0 else { throw SplitMessageError.SingleWordExceedLimit(invalidWords: exceedLimitWords)}

        // currentPart & totalPart are for counting current page
        // totalPartLength is for saving "Current totalPart's digit" temporarily
        var currentPart = 1, totalPart = 1, totalPartLength = 1
        
        // If totalPartLengthIsChanged == true,
        // That means totalPartDigit is carry and it may causes formor data which is already handled fail
        //
        // Ex: Before -> 9/9 Word(Length = 46)   => Total String Length = 50 (Success)
        //     After  -> 10/10 Word(Length = 46) => Total String Length = 52 (Fail)
        var totalPartLengthIsChanged = false
        
        var totalChunks: [[String]] = []
        var currentChunk: [String] = ["\(currentPart)/\(totalPart)"]
        
        /* ["1/1", "Hi", "Nice", "To", "Meet","You"] */
        
        var index = 0
        while index < textSplitWithSpace.count {

            if totalPartLengthIsChanged {
                
                // Means totalPartDigit is carry and it may causes formor data which is already handled fail
                currentPart = 1 ; totalPart = 1
                totalPartLengthIsChanged = false
                
                totalChunks = []
                currentChunk = ["\(currentPart)/\(totalPart)"]
            }

            // After text split by "Space", we should check all words if currentChunks join with "Space" is excced limit or not
            //
            // If no, then keep checking next word in textSplitWithSpace
            // If yes, then there are two case.
            //         Case1: N/N + Word -> This word is valid but with part indicator will exceed the maximum length limit
            //         Case2: N/N + Word + Word + ... -> That means currentChunk is setting finish then change to newline
            
            currentChunk.append(textSplitWithSpace[index])
            let currentChunkToString = currentChunk.joined(separator: " ")
            let currentChunkToStringIsExceedLimit = currentChunkToString.count > lengthLimit ? true : false
            
            // Case2: N/N + Word -> This word is valid but with part indicator will exceed the maximum length limit
            guard (currentChunk.count == 2 && currentChunkToStringIsExceedLimit) == false else {
                throw SplitMessageError.PartIndicatorWithWordExceedLimit(thisPartIndicatorWithWord: [currentChunkToString])
            }
            
            // Case1: N/N + Word -> This word is valid but with part indicator will exceed the maximum length limit
            if currentChunkToStringIsExceedLimit {
                
                // Remove last word because adding that word makes length exceed limit
                currentChunk.removeLast()

                // Index -- means that the round of while loop will keep looking at this word
                index = index - 1
                
                // Means currentChunk is setting finish
                totalChunks.append(currentChunk)
                
                // Then change to newline and keep checking
                currentPart = currentPart + 1
                totalPart = totalPart + 1

                currentChunk = ["\(currentPart)/\(totalPart)"]
                
                // Each time totalPart ++ may cause totalPart's digit carry, so we should check if it's carry or not
                if String(totalPart).count > totalPartLength {
                    totalPartLength = totalPartLength + 1
                    totalPartLengthIsChanged = true
                    
                    // totalPart's digit is carry and it may causes formor data which is already handled fail
                    // Then we should look again from beginning
                    index = -1
                }
            }
            
            // Keep checking next word in textSplitWithSpace
            index += 1
        }
        
        // Append last currentChunk after exit while loop
        totalChunks.append(currentChunk)
        
        
        // Checking finish, let's handle return data type
        //
        // Now the totalPart is already confirm
        let realTotalPart = totalChunks.count
        
        var totalMessage: [String] = []
        for i in 0 ..< totalChunks.count {

            var eachChunk = totalChunks[i]

            // Remove wrong Part Indicator
            eachChunk.removeFirst()

            // Insert correct Part Indicator
            eachChunk.insert("\(i + 1)/\(realTotalPart)", at: 0)

            totalMessage.append(eachChunk.joined(separator: " "))
        }
        
        return totalMessage
    }

    private func setPlaceHolder() {
        inputTextView.text = "What's on your mind ?"
        inputTextView.textColor = .lightGray
    }
    
    private func cleanPlaceHolder() {
        inputTextView.text = ""
        inputTextView.textColor = .black
    }
}

extension PostTweetViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            cleanPlaceHolder()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            setPlaceHolder()
        }
    }
}
