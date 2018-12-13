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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let items : Results<ToDoListItem>
        do{
            let realm = try Realm()
            items = realm.objects(ToDoListItem.self)
            return items.count
        }
        catch{
            return 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for:indexPath)
        
        do{
            let realm = try Realm()
            let item = realm.objects(ToDoListItem.self)[indexPath.row]
            cell.textLabel!.text = item.name
            cell.accessoryType = item.done == true ? .checkmark : .none
        }
        catch{}
        
        return cell
    }
    
    //marks and unmarks as done
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        do{
            let realm = try Realm()
            let item = realm.objects(ToDoListItem.self)[indexPath.row]
            
            try realm.write{
                item.done = !item.done
            }
        }
        catch{}
    }
    
    //ability to edit row in table views
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    //if the editing style is set to delete, create an item that represents the cell we want to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        do{
            if(editingStyle == .delete){
                let realm = try Realm()
                let item = realm.objects(ToDoListItem.self)[indexPath.row]
                
                try realm.write{
                    realm.delete(item)
                }
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        catch{
            
        }
    }

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        //alert view controller collects input from user
        let alertVC = UIAlertController(title: "New Task", message: "Enter task name", preferredStyle: .alert)
        alertVC.addTextField(configurationHandler: nil)
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .destructive, handler: nil)
        alertVC.addAction(cancelAction)
        
        let addAction = UIAlertAction(title: "Add", style: .default){ result -> Void in
            let todoItemTextField = alertVC.textFields?.first as? UITextField
            
            //creating a new item to add to realm
            let newTodoListItem = ToDoListItem()
            newTodoListItem.name = todoItemTextField?.text ?? ""
            newTodoListItem.done = false
            
            do{
                let realm = try Realm()
                try realm.write {
                    realm.add(newTodoListItem) //adding to realm
                }
                let count = realm.objects(ToDoListItem.self).count - 1
                self.tableView.insertRows(at: [IndexPath.init(row: count, section: 0)], with: .automatic)
            }
            catch{
                
            }
        }
        
        alertVC.addAction(addAction)
        present(alertVC, animated:true, completion: nil)
    }
}
