//
//  TaskDetailVC.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 2/26/19.
//  Copyright © 2019 Ellen Nkonya. All rights reserved.
//

import Foundation
import UIKit

class TaskDetailVC: UIViewController {

    @IBOutlet weak var taskName: UILabel!
    @IBOutlet weak var dateToComplete: UILabel!
    @IBOutlet weak var dateCompleted: UILabel!
    @IBOutlet weak var taskDescription: UITextView!

    var taskItem: ToDoListItem?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let taskItem = taskItem {
            taskName.text = taskItem.name
            dateToComplete.text = taskItem.formatDateToComplete()
            dateCompleted.text = taskItem.formateDateCompleted()
            taskDescription.text = taskItem.desc.isEmpty ? "No description" : taskItem.desc
        }
    }
}
