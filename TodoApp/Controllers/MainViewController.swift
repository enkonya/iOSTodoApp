//
//  ViewController.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 11/27/18.
//  Copyright © 2018 Ellen Nkonya. All rights reserved.
//

import UIKit
import RealmSwift

class MainViewController: UITableViewController{
    var notificationToken: NotificationToken? = nil
    var results: Results<ToDoListItem>?
    
    @IBOutlet weak var segmentedControl: UISegmentedControl?
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            setupRealmDataSource(false)
        case 1:
            setupRealmDataSource(true)
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
        setupRealmDataSource(false)
      }
    
    func setupRealmDataSource(_ isComplete: Bool) {
        do{
            let realm = try Realm()
            results = realm.objects(ToDoListItem.self).filter("isComplete = %@", isComplete)
                                                      .sorted(byKeyPath: "dateEntered", ascending: false)
            
            // Observe Results Notifications
            notificationToken = results?.observe { [weak self] (changes: RealmCollectionChange) in
                guard let tableView = self?.tableView else { return }
                switch changes {
                case .initial:
                    // Results are now populated and can be accessed without blocking the UI
                    tableView.reloadData()
                case .update(_, let deletions, let insertions, let modifications):
                    // Query results have changed, so apply them to the UITableView
                    let fromRow = { (row: Int) in
                        return IndexPath(row: row, section: 0)
                    }
                    
                    tableView.beginUpdates()
                    tableView.insertRows(at: insertions.map(fromRow), with: .automatic)
                    tableView.reloadRows(at: modifications.map(fromRow), with: .automatic)
                    tableView.deleteRows(at: deletions.map(fromRow), with: .automatic)
                    tableView.endUpdates()
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError("\(error)")
                }
            }
        }
        catch{
            print("Unable to initialize realm")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = results?.count ?? 0
        
        if(count == 0){
            let emptyLabel = UILabel(frame: CGRect(x: 0,
                                                   y: 0,
                                                   width:  self.view.frame.width,
                                                   height: self.view.frame.height))
            emptyLabel.text = String(format: "No %@ Tasks",
                                     segmentedControl?.selectedSegmentIndex == 0 ? "Open" : "Completed")
            emptyLabel.textAlignment = NSTextAlignment.center
            
            tableView.backgroundView = emptyLabel
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        }
        else{
            tableView.backgroundView = nil
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        }
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for:indexPath)
        let item = results?[indexPath.row]
        cell.textLabel?.text = item?.name
        cell.accessoryType = item?.isComplete == true ? .checkmark : .none
        
        return cell
    }
    
    //marks and unmarks as done
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = results?[indexPath.row]{
            do{
                let realm = try Realm()
                try realm.write{
                    item.isComplete = !item.isComplete
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }
            catch{
                print("Unable to initialize realm")
            }
        }
    }
    
    //ability to edit row in table views
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //if the editing style is set to delete, create an item that represents the cell we want to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if let item = results?[indexPath.row], editingStyle == .delete{
            do{
                let realm = try Realm()
                try realm.write{
                    realm.delete(item)
                }
            }
            catch{
                print("Unable to initialize realm")
            }
        }
    }

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        //alert view controller collects input from user
        let alertVC = UIAlertController(title: "New Task", message: "Enter task name", preferredStyle: .alert)
        alertVC.addTextField(configurationHandler: nil)

        let cancelAction = UIAlertAction.init(title: "Cancel", style: .destructive, handler: nil)
        alertVC.addAction(cancelAction)
        
        let addAction = UIAlertAction(title: "Add", style: .default){ result -> Void in
            let todoItemTextField = alertVC.textFields?.first
            
            //creating a new item to add to realm
            let newTodoListItem = ToDoListItem()
            newTodoListItem.name = todoItemTextField?.text ?? ""
            newTodoListItem.isComplete = false
            newTodoListItem.dateEntered = Date()
            
            do{
                let realm = try Realm()
                try realm.write {
                    realm.add(newTodoListItem) //adding to realm
                }
            }
            catch{
                print("Unable to initialize realm")
            }
        }
        
        alertVC.addAction(addAction)
        present(alertVC, animated:true, completion: nil)
    }
}
