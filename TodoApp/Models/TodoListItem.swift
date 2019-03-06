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

extension ToDoListItem {
    convenience init(name: String, desc: String, dateToComplete: Date) {
        self.init()
        self.name = name
        self.desc = desc
        self.dateToComplete = dateToComplete
    }

    func formatDateToComplete() -> String {
        return ToDoListItem.format(date: self.dateToComplete ?? Date())
    }

    func formateDateCompleted() -> String {
        if let dateCompleted = dateCompleted {
            return ToDoListItem.format(date: dateCompleted)
        }
        return "TBD"
    }

    static func format(date: Date) -> String {
        let isToday = Calendar.current.isDateInToday(date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = isToday ? "'Today,' MMM d, yyyy" : "EEEE, MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}
