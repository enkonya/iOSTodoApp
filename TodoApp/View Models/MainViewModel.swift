//
//  MainViewModel.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 2/15/21.
//  Copyright © 2021 Ellen Nkonya. All rights reserved.
//

import RealmSwift

/// Enum representing a tab for Main view
enum TaskTab: Int32, CustomStringConvertible {
    case open = 0, completed
    
    var description: String {
        switch self {
        case .open: return "Open"
        case .completed: return "Completed"
        }
    }
    
    init?(rawValue: Int32) {
        switch rawValue {
        case 0: self = .open
        case 1: self = .completed
        default: return nil
        }
    }
}

/// Enum representing a section's title in the table view
enum SectionTitle: CaseIterable, CustomStringConvertible {
    case older, today, nextseven, upcoming
    
    public var description: String {
        switch self {
        case .older:
            return "Older"
        case .today:
            return TaskItemDTO.format(date: Date())
        case .nextseven:
            return "Next 7 Days"
        case .upcoming:
            return "Upcoming"
        }
    }
}



// MARK: - Main View Model
///
/// View Model for `MainViewController`
class MainViewModel {
    
    // MARK: - Properties
    
    var notification: ((RealmCollectionChange<Results<ToDoListItem>>) -> Void)?
    
    /// The currently selected tab in the view
    fileprivate(set) var selectedTab: TaskTab = .open
    
    fileprivate(set) var availableSections = [SectionTitle]()
    fileprivate(set) var sectionTasks = [SectionTitle: [TaskItemDTO]]()
    
    fileprivate var results: Results<ToDoListItem>?
    fileprivate var notificationToken: NotificationToken?
    fileprivate var latestSearchQuery: String?
    
    fileprivate var todaysDate: Date { Calendar.current.startOfDay(for: Date()) }
    fileprivate var sevenDaysAwayDate: Date {
        let tomorrowsDate = Calendar.current.date(byAdding: .day, value: 1, to: todaysDate )
        return Calendar.current.date(byAdding: .day, value: 7, to: tomorrowsDate!)!
    }
    
    // MARK: - Set Up Data Source + Notification Token
    
    func setUpRealmDataSource(withSearchText searchText: String?) {
        let searchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.latestSearchQuery = searchText.isEmpty ? nil : searchText
        
        do {
            let realm = try Realm()
            var results = realm.objects(ToDoListItem.self)
            
            let isCompleted = self.selectedTab == .completed
            results = results.filter("isComplete = %@", isCompleted)
            
            if let searchQuery = self.latestSearchQuery {
                results = results.filter("name CONTAINS[cd] %@", searchQuery)
            }
            
            self.results = results.sorted(byKeyPath: "dateToComplete", ascending: false)
            self.setUpNotificationToken()
            self.updateSectionResults()
        } catch let e {
            print("Unable to get task items from realm: \(e)")
        }
    }
    
    fileprivate func setUpNotificationToken() {
        self.notificationToken?.invalidate()
        self.notificationToken = self.results?.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            self.updateSectionResults()
            self.notification?(changes)
        }
    }
    
    func removeNotifications() {
        self.notification = nil
        self.notificationToken?.invalidate()
    }
    
    // MARK: - Private Helpers
    
    fileprivate func updateSectionResults() {
        self.availableSections = [SectionTitle]()
        SectionTitle.allCases.forEach({ [weak self] sectionTitle in
            guard let self = self else { return }
            if sectionTasks[sectionTitle] == nil { sectionTasks[sectionTitle] = [TaskItemDTO]() }
            
            switch sectionTitle {
            case .older:
                guard let olderResults = self.results?.filter("dateToComplete < %@", self.todaysDate) else { return }
                self.fillSection(forSectionTitle: sectionTitle, withTasks: olderResults)
            case .today:
                guard let todayResults = self.results?.filter("dateToComplete = %@", self.todaysDate) else { return }
                self.fillSection(forSectionTitle: sectionTitle, withTasks: todayResults)
            case .nextseven:
                guard let nextSevenDaysResults = self.results?.filter("dateToComplete > %@ AND dateToComplete <= %@", self.todaysDate, self.sevenDaysAwayDate) else { return }
                self.fillSection(forSectionTitle: sectionTitle, withTasks: nextSevenDaysResults)
            case .upcoming:
                guard let upcomingResults = self.results?.filter("dateToComplete > %@", self.sevenDaysAwayDate)  else { return }
                self.fillSection(forSectionTitle: sectionTitle, withTasks: upcomingResults)
            }
        })
    }
    
    fileprivate func fillSection(forSectionTitle sectionTitle: SectionTitle, withTasks sectionItems: Results<ToDoListItem>) {
        guard !sectionItems.isEmpty else { return }
        self.sectionTasks[sectionTitle] = sectionItems.map { TaskItemDTO(with: $0) }
        self.availableSections.append(sectionTitle)
    }
    
    // MARK: - Property Accessors
    
    /// Returns the number of available sections, `0` if empty
    func numberOfSections() -> Int {
        return self.availableSections.count
    }
    
    /// Returns the number rows for a given section, `0` if empty
    func numberOfRows(inSection section: Int) -> Int {
        let section = self.availableSections[section]
        return self.sectionTasks[section]?.count ?? 0
    }
    
    /// Returns an optional title for a given section
    func title(forSection section: Int) -> String? {
        return self.availableSections[section].description
    }
    
    /// Returns an optional item for a row at given index path
    func item(at indexPath: IndexPath) -> TaskItemDTO? {
        let sectionTitle = self.availableSections[indexPath.section]
        let sectionItems = self.sectionTasks[sectionTitle]
        return sectionItems?[indexPath.row]
    }
    
    // MARK: - View Helpers
    
    /// Updates tab selection from a given index
    func didChangeTabSelection(toIndex index: Int) {
        self.selectedTab = TaskTab(rawValue: Int32(index)) ?? .open
        self.setUpRealmDataSource(withSearchText: self.latestSearchQuery)
    }
    
    /// Deletes an item for a given index path in realm
    func deleteItem(at indexPath: IndexPath, completion: @escaping (Swift.Error?) -> Void) {
        guard let item = self.item(at: indexPath) else {
            completion(nil)
            return
        }
        
        do {
            let realm = try Realm()
            if let realmItem = realm.object(ofType: ToDoListItem.self, forPrimaryKey: item.id) {
                try realm.write {
                    realm.delete(realmItem)
                }
            }
            
            completion(nil)
        } catch let e {
            print("There was a problem deleting item: \(e)")
            completion(e)
        }
    }
    
    /// Marks or unmarks an item as done for a given index path
    func updateItem(at indexPath: IndexPath, completion: @escaping (Swift.Error?) -> Void) {
        guard let item = self.item(at: indexPath) else {
            completion(nil)
            return
        }
        
        do {
            let realm = try Realm()
            if let realmItem = realm.object(ofType: ToDoListItem.self, forPrimaryKey: item.id) {
                try realm.write {
                    realmItem.isComplete = !item.isComplete
                    realmItem.dateCompleted = Date()
                }
            }
            
            completion(nil)
        } catch let e {
            print("There was a problem saving item: \(e)")
            completion(e)
        }
    }
}

// MARK: - Task Completion Delegate

extension MainViewModel: TaskCompletionDelegate {
    func onDone(taskName: String, taskDesc: String, dateToComplete: Date) {
        let newTodoListItem = ToDoListItem(name: taskName,
                                           desc: taskDesc,
                                           dateToComplete: dateToComplete)
        
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(newTodoListItem) //adding to realm
            }
        } catch let e {
            print("Unable to save item to realm: \(e)")
        }
    }
}
