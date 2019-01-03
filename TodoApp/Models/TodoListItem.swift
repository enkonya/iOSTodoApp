//
//  TodoListItem.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 11/30/18.
//  Copyright © 2018 Ellen Nkonya. All rights reserved.
//

import Foundation
import RealmSwift

class ToDoListItem: Object{
    //@objc dynamic allows realm to monitor changes in property values
    @objc dynamic var name = "";
    @objc dynamic var desc = "";
    @objc dynamic var isComplete = false;
    @objc dynamic var dateEntered: Date?
    @objc dynamic var dateCompleted: Date?
}
