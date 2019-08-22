//
//  MainViewViewModel.swift
//  TodoApp
//
//  Created by Marquis Dennis on 8/22/19.
//  Copyright © 2019 Ellen Nkonya. All rights reserved.
//

import Foundation
import RealmSwift

class MainViewViewModel {
  var queryText: String?
  var results: Results<ToDoListItem>?
  var notificationToken: NotificationToken?
  var availableSections = [SectionTitle]()
  var sectionTasks = [SectionTitle: [ListItem]]()

  var updatedSection: IndexPath?

  var todaysDate: Date = Calendar.current.startOfDay(for: Date())
  var sevenDaysAwayDate: Date {
    let tomorrowsDate = Calendar.current.date(byAdding: .day, value: 1, to: todaysDate )
    return Calendar.current.date(byAdding: .day, value: 7, to: tomorrowsDate!)!
  }

  var resultsDidChange: ((Bool, TodoError?) -> Void)?

  init() {
    self.setupRealmDataSource(false, nil)
  }

  //to do list items
  var items: [ToDoListItem] = [] {
    didSet {
      resultsDidChange?(false, nil)
    }
  }

  func save(item: ToDoListItem) {
    do {
      let realm = try Realm()
      try realm.write {
        realm.add(item) //adding to realm
      }
    } catch {
      print("Unable to initialize realm")
    }
  }

  func set(queryText: String?, isComplete: Bool) {
    self.queryText = queryText
    self.setupRealmDataSource(isComplete, self.queryText)
  }

  fileprivate func fillSection(forSectionTitle sectionTitle: SectionTitle,
                               withTasks sectionItems: Results<ToDoListItem>) {
    if !sectionItems.isEmpty {
      sectionTasks[sectionTitle] = sectionItems.map { ListItem(with: $0)}
      availableSections.append(sectionTitle)
    }
  }

  fileprivate func fillSectionHelper(sectionTitle: SectionTitle) {
    switch sectionTitle {
    case .older:
      if let olderResults = results?.filter("dateToComplete < %@", todaysDate) {
        fillSection(forSectionTitle: sectionTitle, withTasks: olderResults)
      }
    case .today:
      if let todayResults = results?.filter("dateToComplete = %@", todaysDate) {
        fillSection(forSectionTitle: sectionTitle, withTasks: todayResults)
      }
    case .nextseven:
      if let nextSevenDaysResults = results?.filter("dateToComplete > %@ AND dateToComplete <= %@",
                                                    todaysDate, sevenDaysAwayDate) {
        fillSection(forSectionTitle: sectionTitle, withTasks: nextSevenDaysResults)
      }
    case .upcoming:
      if let upcomingResults = results?.filter("dateToComplete > %@", sevenDaysAwayDate) {
        fillSection(forSectionTitle: sectionTitle, withTasks: upcomingResults)
      }
    }
  }

  func getItem(from indexPath: IndexPath) -> ListItem? {
    let sectionTitle = availableSections[indexPath.section]
    let sectionItems = sectionTasks[sectionTitle]

    return sectionItems?[indexPath.row]
  }

  func handleSwipeAction(for indexPath: IndexPath) {
    if let itemForIndexPath = getItem(from: indexPath) {
      do {
        let realm = try Realm()
        if let item = realm.object(ofType: ToDoListItem.self, forPrimaryKey: itemForIndexPath.id) {
          try realm.write {
            item.isComplete = !item.isComplete
            item.dateCompleted = Date()
          }

          updatedSection = indexPath
        }
      } catch {
        print("Unable to initialize realm")
      }
    }
  }

  func handleEditingStyle(for indexPath: IndexPath) {
    if let itemForIndexPath = getItem(from: indexPath) {
      do {
        let realm = try Realm()
        if let item = realm.object(ofType: ToDoListItem.self, forPrimaryKey: itemForIndexPath.id) {
          try realm.write {
            realm.delete(item)
          }

          updatedSection = indexPath
        }
      } catch {
        print("Unable to initialize realm")
      }
    }
  }

  fileprivate func setupRealmDataSource(_ isComplete: Bool, _ searchQuery: String?) {
    do {
      let realm = try Realm()
      results = realm.objects(ToDoListItem.self)
        .filter("isComplete = %@", isComplete)

      if let searchQuery = searchQuery {
        results = results?.filter("name CONTAINS %@", searchQuery)
      }

      results = results?.sorted(byKeyPath: "dateToComplete", ascending: false)

      availableSections = [SectionTitle]() //resetting available sections list
      updatedSection = IndexPath()

      SectionTitle.allCases.forEach({ sectionTitle in
        if sectionTasks[sectionTitle] == nil {
          sectionTasks[sectionTitle] = []
        }

        fillSectionHelper(sectionTitle: sectionTitle)
      })

      // Observe Results Notifications
      notificationToken = results?.observe { [weak self] (changes: RealmCollectionChange) in
        switch changes {
        case .initial:
          self?.resultsDidChange?(false, nil)
        case .update:
          self?.resultsDidChange?(true, nil)
        case .error:
          self?.resultsDidChange?(false, .basicError)
        }
      }
    } catch {
      print("Unable to initialize realm")
    }
  }
}

enum TodoError {
  case basicError
}

struct ListItem {
  var id: String
  var dateCompleted: String
  var isComplete: Bool
  var name: String
  var desc: String

  init(with item: ToDoListItem) {
    id = item.id
    dateCompleted = item.formatDateToComplete()
    isComplete = item.isComplete
    name = item.name
    desc = item.desc
  }
}
