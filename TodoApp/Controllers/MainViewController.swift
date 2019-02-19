//
//  ViewController.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 11/27/18.
//  Copyright © 2018 Ellen Nkonya. All rights reserved.
//

import UIKit
import RealmSwift
import EmptyDataSet_Swift

class MainViewController: UITableViewController {
    var notificationToken: NotificationToken?
    
    var results: Results<ToDoListItem>?
    var availableSections = [SectionTitle]()
    var sectionTasks = [SectionTitle: [ToDoListItem]]()
    var updatedSection: IndexPath?
    
    var todaysDate: Date = Calendar.current.startOfDay(for: Date())
    var sevenDaysAwayDate: Date {
        let tomorrowsDate = Calendar.current.date(byAdding: .day, value: 1, to: todaysDate )
        return Calendar.current.date(byAdding: .day, value: 7, to: tomorrowsDate!)!
    }
    
    @IBOutlet weak var createTaskButton: UIBarButtonItem!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl?
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            setupRealmDataSource(false)
        case 1:
            setupRealmDataSource(true)
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        createTaskButton.action = #selector(presentCreateTask)
        createTaskButton.target = self
    }
    
    //Opens up view to create a new task
    @objc func presentCreateTask(_ sender: UIBarButtonItem) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        if let createVC =
            storyBoard.instantiateViewController(withIdentifier: "createTaskView") as? CreateTaskViewController {
            createVC.delegate = self
            let nvc = UINavigationController(rootViewController: createVC)
            self.present(nvc, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupRealmDataSource(false)
    }
    
    func setupRealmDataSource(_ isComplete: Bool) {
        do {
            let realm = try Realm()
            results = realm.objects(ToDoListItem.self).filter("isComplete = %@", isComplete)
                .sorted(byKeyPath: "dateToComplete", ascending: false)
            
            availableSections = [SectionTitle]() //resetting available sections list
            updatedSection = IndexPath()
            
            SectionTitle.allCases.forEach({ sectionTitle in
                if sectionTasks[sectionTitle] == nil {
                    sectionTasks[sectionTitle] = [ToDoListItem]()
                }
                
                fillSectionHelper(sectionTitle: sectionTitle)
            })
            
            // Observe Results Notifications
            notificationToken = results?.observe { [weak self] (changes: RealmCollectionChange) in
                guard let strongSelf = self else { return }
                guard let tableView = self?.tableView else { return }
                
                switch changes {
                case .initial:
                    // Results are now populated and can be accessed without blocking the UI
                    tableView.reloadData()
                case .update(_, _, let insertions, let modifications):
                    tableView.beginUpdates()
                    tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    
                    //deleting rows and empty sections
                    if let indexPath = strongSelf.updatedSection {
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        
                        let updatedSectionTitle: SectionTitle = strongSelf.availableSections[indexPath.section]
                        strongSelf.sectionTasks[updatedSectionTitle]?.remove(at: indexPath.row)
                        
                        if let sectionItems = strongSelf.sectionTasks[updatedSectionTitle] {
                            if sectionItems.isEmpty {
                                strongSelf.availableSections.remove(at: indexPath.section)
                                tableView.deleteSections(IndexSet.init(integer: indexPath.section), with: .automatic)
                            }
                        }
                    }
                    tableView.endUpdates()
                case .error:
                    // An error occurred while opening the Realm file on the background worker thread
                    let errorAlert = UIAlertController(title: "Error", message: "Error opening realm file",
                                                       preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,
                                                       handler: nil))
                    self?.present(errorAlert, animated: true, completion: nil)
                }
            }
        } catch {
            print("Unable to initialize realm")
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
    
    fileprivate func fillSection(forSectionTitle sectionTitle: SectionTitle,
                                 withTasks sectionItems: Results<ToDoListItem>) {
        if !sectionItems.isEmpty {
            sectionTasks[sectionTitle] = Array(sectionItems)
            availableSections.append(sectionTitle)
        }
    }
    
    fileprivate func getItem(from indexPath: IndexPath) -> ToDoListItem? {
        let sectionTitle = availableSections[indexPath.section]
        let sectionItems = sectionTasks[sectionTitle]
    
        return sectionItems?[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationToken?.invalidate()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return availableSections[section].description
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return availableSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let correctSection = availableSections[section]
        return sectionTasks[correctSection]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        cell?.textLabel?.text = self.getItem(from: indexPath)?.name ?? ""
        
        return cell ?? UITableViewCell()
    }
    
    //marks and unmarks as done
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = self.getItem(from: indexPath) {
            do {
                let realm = try Realm()
                try realm.write {
                    item.isComplete = !item.isComplete
                    item.dateCompleted = Date()
                }
                updatedSection = indexPath
            } catch {
                print("Unable to initialize realm")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //ability to edit row in table views
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //if the editing style is set to delete, create an item that represents the cell we want to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        
        if let item = self.getItem(from: indexPath), editingStyle == .delete {
            do {
                let realm = try Realm()
                try realm.write {
                    realm.delete(item)
                }
                updatedSection = indexPath
            } catch {
                print("Unable to initialize realm")
            }
        }
    }
}

enum SectionTitle: CaseIterable, CustomStringConvertible {
    case older, today, nextseven, upcoming
    
    public var description: String {
        switch self {
        case .older:
            return "Older"
        case .today:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            return String(format: "Today, %@", dateFormatter.string(from: Date()))
        case .nextseven:
            return "Next 7 Days"
        case .upcoming:
            return "Upcoming"
        }
    }
}

extension MainViewController: TaskCompletionDelegate {
    func onDone(taskName: String, taskDesc: String, dateToComplete: Date) {
        let newTodoListItem = ToDoListItem()
        newTodoListItem.name = taskName
        newTodoListItem.desc = taskDesc
        newTodoListItem.dateToComplete = dateToComplete
        
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(newTodoListItem) //adding to realm
            }
        } catch {
            print("Unable to initialize realm")
        }
    }
}

extension MainViewController: EmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let noTasksText = String(format: "No %@ Tasks",
                                 segmentedControl?.selectedSegmentIndex == 0 ? "Open" : "Completed")
        
        let paragraph = NSMutableParagraphStyle()
        
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 25.0),
                          NSAttributedString.Key.paragraphStyle: paragraph]
        return NSAttributedString(string: noTasksText, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let noTasksDesc = "To create a task, hit the + button on the top right corner."
        
        let paragraph = NSMutableParagraphStyle()
        
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0),
                          NSAttributedString.Key.paragraphStyle: paragraph]
        
        return NSAttributedString(string: noTasksDesc, attributes: attributes)
    }
}

extension MainViewController: EmptyDataSetDelegate {}
