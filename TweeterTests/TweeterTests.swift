//
//  TweeterTests.swift
//  TweeterTests
//
//  Created by Chien on 2019/11/6.
//  Copyright © 2019 Chien. All rights reserved.
//

import XCTest

@testable import Tweeter

class TweeterTests: XCTestCase {

    var postTweetViewController: PostTweetViewController?

    let sampleInput = "I can't believe Tweeter now supports chunking my messages, so I don't have to do it myself."
    let sampleOutput = ["1/2 I can't believe Tweeter now supports chunking", "2/2 my messages, so I don't have to do it myself."]

    let input1 = "I love iOS, but I love Swift more :)"
    let output1 = ["I love iOS, but I love Swift more :)"]
    
    // SplitMessageError.SingleWordExceedLimit
    let input2 = "This input in invalid because ThisIsALongStringWhichContainExceedLengthLimitTokennnnnnnnnnnnn"
    let output2 = ["ThisIsALongStringWhichContainExceedLengthLimitTokennnnnnnnnnnnn"]

    // SplitMessageError.PartIndicatorWithWordExceedLimit
    let input3 = "The input looks great, ButWhenSplitTilChangeToTheNextLineWillCauseError"
    let output3 = ["2/2 ButWhenSplitTilChangeToTheNextLineWillCauseError"]

    let input4 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi auctor sed sem nec dictum. Quisque placerat vitae ligula ac interdum. Mauris massa massa, tincidunt non erat id, faucibus consectetur dolor. Interdum et malesuada fames ac ante ipsum primis in faucibus. Suspendisse viverra justo ante, sed lacinia velit porttitor in. Etiam tincidunt magna nec odio tempus dictum. Ut a elementum quam. Nunc venenatis lacus et nisi condimentum, non mattis erat dapibus. Nam maximus tempor est, eu lobortis lectus bibendum eget. Duis sollicitudin pharetra massa, et lobortis purus fermentum sed. Praesent a ornare massa. Duis consectetur ipsum eu auctor suscipit. Curabitur sagittis enim quis faucibus finibus. Nam vel nulla in libero accumsan vulputate id et massa. Vestibulum malesuada lacus sem, sit amet gravida mi laoreet vel. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos."

    let output4 = ["1/22 Lorem ipsum dolor sit amet, consectetur",
                   "2/22 adipiscing elit. Morbi auctor sed sem nec",
                   "3/22 dictum. Quisque placerat vitae ligula ac",
                   "4/22 interdum. Mauris massa massa, tincidunt non",
                   "5/22 erat id, faucibus consectetur dolor. Interdum",
                   "6/22 et malesuada fames ac ante ipsum primis in",
                   "7/22 faucibus. Suspendisse viverra justo ante, sed",
                   "8/22 lacinia velit porttitor in. Etiam tincidunt",
                   "9/22 magna nec odio tempus dictum. Ut a elementum",
                   "10/22 quam. Nunc venenatis lacus et nisi",
                   "11/22 condimentum, non mattis erat dapibus. Nam",
                   "12/22 maximus tempor est, eu lobortis lectus",
                   "13/22 bibendum eget. Duis sollicitudin pharetra",
                   "14/22 massa, et lobortis purus fermentum sed.",
                   "15/22 Praesent a ornare massa. Duis consectetur",
                   "16/22 ipsum eu auctor suscipit. Curabitur sagittis",
                   "17/22 enim quis faucibus finibus. Nam vel nulla in",
                   "18/22 libero accumsan vulputate id et massa.",
                   "19/22 Vestibulum malesuada lacus sem, sit amet",
                   "20/22 gravida mi laoreet vel. Class aptent taciti",
                   "21/22 sociosqu ad litora torquent per conubia",
                   "22/22 nostra, per inceptos himenaeos."]
    
    var inputArray: [String] {
        return [sampleInput, input1, input2, input3, input4]
    }
    var outputArray: [[String]] {
        return [sampleOutput, output1, output2, output3, output4]
    }
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    override func setUp() {
        super.setUp()
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postTweetVC = mainStoryboard.instantiateViewController(withIdentifier: "PostTweetViewController") as? PostTweetViewController else { return }

        postTweetViewController = postTweetVC
    }

    func testSplitMessage() {
        
        if postTweetViewController == nil { XCTFail("Can not find PostTweetViewController") }

        do {
            
            for index in 0 ..< inputArray.count {
                let output = try postTweetViewController!.splitMessage(with: inputArray[index], amount: postTweetViewController!.lengthLimit)
                XCTAssertEqual(output, outputArray[index])
            }
        } catch SplitMessageError.SingleWordExceedLimit(let invalidWords) {
            XCTAssertEqual(invalidWords, output2)
        } catch SplitMessageError.PartIndicatorWithWordExceedLimit(let thisPartIndicatorWithWord) {
            XCTAssertEqual(thisPartIndicatorWithWord, output3)
        } catch {
            XCTFail("Split message occur error")
        }
    }
}
