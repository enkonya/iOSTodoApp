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
    
    var realm: Realm!
    var toDoList: Results<ToDoListItem>{
        get{
            return realm.objects(ToDoListItem.self)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm() //put exclamation because realm init can throw exception
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoList.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for:indexPath)
        let item = toDoList[indexPath.row]
        cell.textLabel!.text = item.name
        
        cell.accessoryType = item.done == true ? .checkmark : .none
        
        return cell
    }
    
    //marks and unmarks as done
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = toDoList[indexPath.row]
        
        try! self.realm.write ({
            item.done = !item.done
        })
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    //ability to edit row in table views
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    //if the editing style is set to delete, create an item that represents the cell we want to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if(editingStyle == .delete){
            let item = toDoList[indexPath.row] //item we want to delete
            
            try! self.realm.write {
                self.realm.delete(item) //call realm to delete
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        //alert view controller collects input from user
        let alertVC = UIAlertController(title: "New Task", message: "Enter task name", preferredStyle: .alert)
        
        alertVC.addTextField{
            (UITextField) in
        }
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .destructive, handler: nil)
        alertVC.addAction(cancelAction)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (UIAlertAction) -> Void in
            
            let todoItemTextField = (alertVC.textFields?.first)! as UITextField
            
            //creating a new item to add to realm
            let newTodoListItem = ToDoListItem()
            newTodoListItem.name = todoItemTextField.text!
            newTodoListItem.done = false
            
            try! self.realm.write {
                self.realm.add(newTodoListItem) //adding to realm
                
                //inserting into tableview at end of list
                self.tableView.insertRows(at: [IndexPath.init(row: self.toDoList.count-1, section: 0)], with: .automatic)
            }
        }
        
        alertVC.addAction(addAction)
        present(alertVC, animated:true, completion: nil)
    }
}
