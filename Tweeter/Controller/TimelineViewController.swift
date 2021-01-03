//
//  TimelineViewController.swift
//  Tweeter
//
//  Created by Chien on 2019/11/6.
//  Copyright © 2019 Chien. All rights reserved.
//

import UIKit
import FirebaseDatabase
import ESPullToRefresh

class TimelineViewController: UIViewController {

    @IBOutlet weak var timelineTableView: UITableView!

    private let timelineViewModel = TimelineViewModel()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        handleTweet()
    }
    
    private func setupUI() {

        navigationItem.title = "Tweeter"
        
        // Set up navigationBar title color
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        // Set up navigationBar
        navigationController?.navigationBar.barTintColor = UIColor(red: 0/255, green: 172/255, blue: 237/255, alpha: 1)
        
        // Set up sendPostBarButtonItem
        let goToPostingPageBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "PostButton"), style: .plain, target: self, action: #selector(goToPostingPage))
        goToPostingPageBarButtonItem.tintColor = .white
        navigationItem.setRightBarButton(goToPostingPageBarButtonItem, animated: true)
        
        timelineTableView.delegate = self
        timelineTableView.dataSource = self
        timelineTableView.separatorStyle = .none
        timelineTableView.showsVerticalScrollIndicator = false
        timelineTableView.backgroundColor = nil
        timelineTableView.register(UINib(nibName: TimelineTableViewCell.identifier, bundle: nil), forCellReuseIdentifier: TimelineTableViewCell.identifier)
        
        // Add pull to refresh
        timelineTableView.es.addPullToRefresh {
            self.handleTweet()
        }
    }

    @objc func goToPostingPage() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let postTweetViewController = mainStoryboard.instantiateViewController(withIdentifier: "PostTweetViewController") as? PostTweetViewController else { return }

        postTweetViewController.timelineViewModel = self.timelineViewModel
        postTweetViewController.sendPostingDelegate = self

        show(postTweetViewController, sender: nil)
    }

    private func handleTweet(latestUpdateTime: Double? = nil) {

        if latestUpdateTime == nil {

            // Fetch tweets from database by default
            timelineViewModel.fetchTweet { (error) in
                
                guard error == nil else {
                    print(error.debugDescription)
                    return
                }
                
                DispatchQueue.main.async {
                    
                    // Default from viewDidLoad or pull to refresh
                    self.timelineTableView.es.stopPullToRefresh()
                    self.timelineTableView.reloadData()
                }
            }
        } else {

            let beforeUpdateDataCount = timelineViewModel.totalTweetsInfo.count
            // Fetch tweets from database for more old tweets
            timelineViewModel.fetchTweet(latestUpdateTime: latestUpdateTime) { (error) in
                guard error == nil else {
                    print(error.debugDescription)
                    return
                }
              
                // Means there is no old data
                if beforeUpdateDataCount == self.timelineViewModel.totalTweetsInfo.count { return }

                DispatchQueue.main.async {
                    self.timelineTableView.reloadData()
                }
            }
        }
    }
}

extension TimelineViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timelineViewModel.totalTweetsInfo.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let timelineTableViewCell = tableView.dequeueReusableCell(withIdentifier: TimelineTableViewCell.identifier) as? TimelineTableViewCell else { return UITableViewCell() }
        
        timelineTableViewCell.tweetInfo = timelineViewModel.totalTweetsInfo[indexPath.row]
        timelineTableViewCell.userInfo = timelineViewModel.totalTweetsAuthorDict[timelineViewModel.totalTweetsInfo[indexPath.row].authorEmail]
        
        return timelineTableViewCell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        // When scroll to specific index item, then prepare fetch more tweets
        if indexPath.row == timelineViewModel.totalTweetsInfo.count - 1 {
            handleTweet(latestUpdateTime: timelineViewModel.totalTweetsInfo[indexPath.row].latestUpdateTime)
        }
    }
}

extension TimelineViewController: SendPostingDelegate {

    // Determine whether it's already sending new posting or not
    func mainPageRefreshData() {
        handleTweet()
    }
}
