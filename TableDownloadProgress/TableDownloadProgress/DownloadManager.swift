//
//  DownloadManager.swift
//  TableDownloadProgress
//
//  Created by Basheer on 23/8/17.
//  Copyright © 2017 Basheer. All rights reserved.
//

import Foundation
import UIKit

extension URLSession {
    func getSessionDescription () -> Int {
        return Int(self.sessionDescription!)!
    }
}

class DownloadManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    
    
    static var shared = DownloadManager()
    var identifier : Int = -1
    var folderPath : String = ""
    typealias ProgressHandler = (Int, Float) -> ()
    
    var parentVC : MasterViewController! = nil
    
    var onProgress : ProgressHandler? {
        didSet {
            if onProgress != nil {
                let _ = activate()
                self.parentVC.onProgress = onProgress
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    func activate() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background.\(NSUUID.init())")
        
        let urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        urlSession.sessionDescription = String(identifier)
        return urlSession
    }
    
    private func calculateProgress(session : URLSession, completionHandler : @escaping (Int, Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let progress = downloads.map({ (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            })

            completionHandler(session.getSessionDescription(), progress.reduce(0.0, +))
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL){
        
        let fileName = downloadTask.originalRequest?.url?.lastPathComponent
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        var destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appending("/\(folderPath)"))
        
        
        do {
            try fileManager.createDirectory(at: destinationURLForFile, withIntermediateDirectories: true, attributes: nil)
            destinationURLForFile.appendPathComponent(String(describing: fileName!))
            try fileManager.moveItem(at: location, to: destinationURLForFile)
        }catch(let error){
            print(error)
        }
        
        
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
            
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(String(describing: error))")
    }
    
}
