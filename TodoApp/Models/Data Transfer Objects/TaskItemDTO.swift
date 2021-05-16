//
//  TaskItemDTO.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 3/14/21.
//  Copyright © 2021 Ellen Nkonya. All rights reserved.
//

import RealmSwift

// MARK: - Task Item Data Transfer Object

struct TaskItemDTO {
    var id: String
    var name: String
    var desc: String
    var dateToComplete: String
    var dateCompleted: String
    var isComplete: Bool
    
    init(with item: ToDoListItem) {
        self.id = item.taskId
        self.name = item.name
        self.desc = item.desc
        self.isComplete = item.isComplete
        self.dateToComplete = TaskItemDTO.format(date: item.dateToComplete ?? Date())
        
        if let dateCompleted = item.dateCompleted {
            self.dateCompleted = TaskItemDTO.format(date: dateCompleted)
        } else {
            self.dateCompleted = "TBD"
        }
    }
    
    static func format(date: Date) -> String {
        let isToday = Calendar.current.isDateInToday(date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = isToday ? "'Today,' MMM d, yyyy" : "EEEE, MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}
