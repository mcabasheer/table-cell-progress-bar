//
//  MasterViewController.swift
//  TableDownloadProgress
//
//  Created by Basheer on 23/8/17.
//  Copyright © 2017 Basheer. All rights reserved.
//

import UIKit

enum DownloadStatus {
    case none
    case inProgress
    case completed
    case failed
}
struct item {
    var title : String!
    let link = "https://www.videvo.net/?page_id=123&desc=OldFashionedFilmLeaderCountdownVidevo.mov&vid=1351"
    var downloadStatus : DownloadStatus = .none

    init(title: String) {
        self.title = title
    }
}

class MasterViewController: UITableViewController {
    typealias ProgressHandler = (Int, Float) -> ()
    var detailViewController: DetailViewController? = nil
    var objects = [Any]()
    var items = [item]()

    var onProgress : ProgressHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
//        if let split = splitViewController {
//            let controllers = split.viewControllers
//            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
//        }
        
        items.append(item(title: "Video 1"))
        items.append(item(title: "Video 2"))
        items.append(item(title: "Video 3"))
        items.append(item(title: "Video 4"))
        
        self.tableView.rowHeight = 100.0
        
        DownloadManager.shared.parentVC = self
//        self.onProgress = DownloadManager.shared.onProgress
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.masterVC = self
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    func insertNewObject(_ sender: Any) {
        objects.insert(NSDate(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        
        if item.downloadStatus != .completed {
            let progressRing = UICircularProgressRingView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            // Change any of the properties you'd like
            progressRing.maxValue = 100
            progressRing.innerRingColor = UIColor.blue
            cell.tag = indexPath.row
            cell.accessoryType = UITableViewCellAccessoryType.none
            cell.accessoryView = progressRing
        }
        else {
            cell.accessoryView = nil
        }
        
        
        
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        var item = items[indexPath.row]
        if item.downloadStatus == .inProgress || item.downloadStatus == .completed {
            print("video already downloaded")
        }
        else {
            let url = URL(string: item.link)!
            let downloadManager = DownloadManager.shared
            downloadManager.identifier = indexPath.row
            downloadManager.folderPath = "video"
            let downloadTaskLocal =  downloadManager.activate().downloadTask(with: url)
            downloadTaskLocal.resume()
              
            downloadManager.onProgress = { (row, progress) in
                //print("Downloading for \(row) with progress \(progress)")
                
                DispatchQueue.main.async {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if appDelegate.masterVC == nil {
                        print("master vc is nil")
                        return
                    }
                    let indexpath = IndexPath.init(row: row, section: 0)
                    let cell = appDelegate.masterVC.tableView.cellForRow(at: indexpath)
                    print("downloading for cell \(String(describing: cell?.tag))")
                    if progress <= 1.0 {
                        
                        let progressRing = cell?.accessoryView as! UICircularProgressRingView
                        progressRing.setProgress(value: CGFloat(progress * 100), animationDuration: 0.2)
                        
                        if progress == 1.0 {
                            item.downloadStatus = .completed
                            cell?.textLabel?.text = "Download Complete"
                        }
                        else {
                            cell?.textLabel?.text = "Download In Progress"
                        }
                        
                    }
                }
                
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
            
        }
    }


}

