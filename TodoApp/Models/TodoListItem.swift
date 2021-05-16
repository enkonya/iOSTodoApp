//
//  TodoListItem.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 11/30/18.
//  Copyright © 2018 Ellen Nkonya. All rights reserved.
//

import RealmSwift

// MARK: - To Do List Item
///
/// Realm object for a task item
/// `@objc` dynamic allows realm to monitor changes in property values
class ToDoListItem: Object {
    @objc dynamic var taskId: String = UUID().uuidString
    @objc dynamic var name: String = ""
    @objc dynamic var desc: String = ""
    @objc dynamic var isComplete: Bool = false
    @objc dynamic var dateToComplete: Date?
    @objc dynamic var dateCompleted: Date?
    override static func primaryKey() -> String? { return "taskId" }
}

extension ToDoListItem {
    convenience init(name: String, desc: String, dateToComplete: Date) {
        self.init()
        self.name = name
        self.desc = desc
        self.dateToComplete = dateToComplete
    }
}
