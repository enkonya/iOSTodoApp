//
//  TodoListItem.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 11/30/18.
//  Copyright © 2018 Ellen Nkonya. All rights reserved.
//

import Foundation
import RealmSwift

class ToDoListItem: Object {
    //@objc dynamic allows realm to monitor changes in property values
    @objc dynamic var name: String = ""
    @objc dynamic var desc: String = ""
    @objc dynamic var isComplete: Bool = false
    @objc dynamic var dateToComplete: Date?
    @objc dynamic var dateCompleted: Date?
}
