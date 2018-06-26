//
//  FirstViewController.swift
//  WorkP
//
//  Created by Anshul-Mobile-9098344194 on 25/06/18.
//  Copyright © 2018 anshul. All rights reserved.
//

import UIKit
import SafariServices
import CoreData

class NewsTableViewCell:UITableViewCell
{
    @IBOutlet weak var  lbl_title:UILabel!
    @IBOutlet weak var  lbl_score:UILabel!
     @IBOutlet weak var  lbl_readFlag:UILabel!
}

class FirstViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    
    // MARK: Properties
    let StoryTypeChildRefMap = [StoryType.top: "topstories", .new: "newstories", .show: "showstories"]
    var dataLimit: UInt = 30
    let DefaultStoryType = StoryType.top
    
    var firebase: DatabaseReference!
    var stories: [Story]! = []
    var storyType: StoryType!
    var retrievingStories: Bool!
    var refreshControl: UIRefreshControl!
    var errorMessageLabel: UILabel!
    var story: [NSManagedObject] = []
    
    @IBOutlet weak var tblVw_Stories: UITableView!
    
    // MARK: Enums
    enum StoryType {
        case top, new, show
    }
    
    // MARK: Structs
    struct Story {
        let title: String
        let url: String?
        let by: String
        let score: Int
        let id: Int
    }
    
    // MARK: Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FirebaseApp.configure()
        firebase = Database.database().reference()
        stories = []
        storyType = DefaultStoryType
        retrievingStories = false
        refreshControl = UIRefreshControl()
        
        
        setupUI()
        
        
        tblVw_Stories.tableFooterView = UIView();
        tblVw_Stories?.rowHeight = UITableViewAutomaticDimension
        tblVw_Stories?.estimatedRowHeight = 120.0
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchRequest()
        
    }
    
    // MARK: UI setup Botto refresh control
    func setupUI() {
        
        
        
        // Add refresh spinner at botto of Tableview.
        refreshControl.tintColor = UIColor.gray
        refreshControl.addTarget(self, action: #selector(FirstViewController.fetchStories), for: .valueChanged)
        refreshControl.triggerVerticalOffset = 100.0;
        self.tblVw_Stories.bottomRefreshControl = refreshControl;
        
        
    }
    
    //To fetch stories from local DB
    func fetchRequest()
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestStory = NSFetchRequest<NSManagedObject>(entityName: "Story")
        
        let sortDescriptor = NSSortDescriptor(key: "score", ascending: true)
        let sortDescriptors = [sortDescriptor]
        fetchRequestStory.sortDescriptors = sortDescriptors
        
        do {
            story = try managedContext.fetch(fetchRequestStory)
            if(story.count == 0)
            {
                fetchStories()
            }
            else
            {
                tblVw_Stories.reloadData()
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    
    
    
    //To fetch stories from firebase server

    @objc func fetchStories() {
        if retrievingStories! {
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        retrievingStories = true
        var storiesMap = [Int:Story]()
        //Show loader
        //  ActivityIndicatorVC.sharedInstance.startIndicator()
        
        let query = firebase.child("v0/topstories").queryLimited(toFirst:dataLimit)
        print("query",query)
        query.observeSingleEvent(of: .value, with: { response in
           // print("response",response)
            let storyIds = response.value as! [Int]
            
            for storyId in storyIds {
                let query = self.firebase.child("v0/item").child(String(storyId))
                query.observeSingleEvent(of: .value, with: { response in
                    let value = response.value as? NSDictionary
                    storiesMap[storyId] = self.extractStory(value!)
                    //Hide loader
                    //ActivityIndicatorVC.sharedInstance.stopIndicator()
                    
                    if storiesMap.count == Int(self.dataLimit) {
                        var sortedStories = [Story]()
                        //print("sortedStories",sortedStories)
                        for storyId in storyIds {
                            sortedStories.append(storiesMap[storyId]!)
                        }
                        
                        self.stories = sortedStories
                        self.fetchRequest()
                        self.dataLimit = self.dataLimit + 50
                        self.tblVw_Stories.reloadData()
                        self.refreshControl.endRefreshing()
                        self.retrievingStories = false
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }, withCancel: self.loadingFailed)
            }
        }, withCancel: self.loadingFailed)
    }
    
    func extractStory(_ data: NSDictionary) -> Story { 
        
        
        let title = data["title"] as! String
        let url = data["url"] as? String ?? ""
        let by = data["by"] as! String
        let score = data["score"] as! Int
        let id = data["id"] as! Int
        
        //Pass details of story to function, to save into local DB.
        saveStories(title: title, url: url, by: by, score: score, id: id)
        return Story(title: title, url: url, by: by, score: score,id:id)
    }
    
    
    // Save the stories into local DB.
    func saveStories(title: String, url: String, by: String, score: Int,id:Int)
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let entityName = NSEntityDescription.entity(forEntityName: "Story",
                                                    in: managedContext)!
        
        let story = NSManagedObject(entity: entityName,
                                    insertInto: managedContext)
        
        story.setValue(title, forKey: "title")
        story.setValue(url, forKey: "url")
        story.setValue(by, forKey: "by")
        story.setValue(score, forKey: "score")
        story.setValue(id, forKey: "id")
        story.setValue(false, forKey: "readStatus")
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func loadingFailed(_ error: Error?) -> Void {
        self.retrievingStories = false
        self.stories.removeAll()
        self.tblVw_Stories.reloadData()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func showErrorMessage(_ message: String) {
        errorMessageLabel.text = message
        self.tblVw_Stories.backgroundView = errorMessageLabel
        self.tblVw_Stories.separatorStyle = .none
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return story.count
        return story.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        //get particular object of DB row selected by user using indexpath
        let manageObject : NSManagedObject = story[indexPath.row];
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell") as! NewsTableViewCell?
        
        cell?.lbl_title?.text  = String.init(format: "%@",( manageObject.value(forKey: "title") as? String)!)
        cell?.lbl_score?.text  = String.init(format: "Score: - %d",( manageObject.value(forKey: "score") as! CVarArg))
       
        //Read/Unread status
        let aBoolVar:Bool = manageObject.value(forKey: "readStatus") as! Bool
        if(  aBoolVar)
        {
            cell?.lbl_readFlag?.text  = String.init(format: "Read")
            cell?.lbl_readFlag?.textColor  = UIColor.green
        }
        else
        {
             cell?.lbl_readFlag?.text  = String.init(format: "Unread")
            cell?.lbl_readFlag?.textColor  = UIColor.red
        }
        
        
        return cell!
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Make the Mark status as read in database
        let manageObject : NSManagedObject = story[indexPath.row];
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Story")
        
        let aObj:Int =  manageObject.value(forKey: "id") as! Int
        fetchRequest.predicate = NSPredicate(format: "id = %@",
                                             argumentArray: ["\(aObj)"])
        
        do {
            let results = try context.fetch(fetchRequest) as? [NSManagedObject]
            if results?.count != 0 { // Atleast one was returned
                
                //Change true status, as news is read now
                results![0].setValue(true, forKey: "readStatus")
            }
        } catch {
            print("Fetch Failed: \(error)")
        }
        
        do {
            try context.save()
        }
        catch {
            print("Saving Core Data Failed: \(error)")
        }
        
        

       //Load news details on SARARI View controller.
        if let url = manageObject.value(forKey: "url") as? String {
            let webViewController = SFSafariViewController(url: URL(string: url)!)
            webViewController.delegate = self
            present(webViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: SFSafariViewControllerDelegate
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}
