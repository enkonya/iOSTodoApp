//
//  ViewController.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 11/27/18.
//  Copyright © 2018 Ellen Nkonya. All rights reserved.
//

import UIKit
import EmptyDataSet_Swift

class MainViewController: UITableViewController {
    var searchBar: UISearchBar?

    var viewModel = MainViewViewModel()

    @IBOutlet var searchBarButton: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl?

    fileprivate var isOpenTaskTabSelected: Bool {
        return self.segmentedControl?.selectedSegmentIndex == 0
    }

    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            viewModel.set(queryText: self.searchBar?.text, isComplete: false)
        case 1:
            viewModel.set(queryText: self.searchBar?.text, isComplete: true)
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self

        searchBar = UISearchBar()
        searchBar?.delegate = self

        viewModel.resultsDidChange = { [weak self] updateSections, error in
          guard error == nil else {
            // An error occurred while opening the Realm file on the background worker thread
            let errorAlert = UIAlertController(title: "Error", message: "Error opening realm file",
                                               preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,
                                               handler: nil))
            self?.present(errorAlert, animated: true, completion: nil)

            return
          }

          if updateSections {
            self?.tableView.beginUpdates()
            //deleting rows and empty sections
            if let indexPath = self?.viewModel.updatedSection {
              self?.tableView.deleteRows(at: [indexPath], with: .automatic)

              let updatedSectionTitle: SectionTitle =
                self?.viewModel.availableSections[indexPath.section] ?? SectionTitle.today
              self?.viewModel.sectionTasks[updatedSectionTitle]?.remove(at: indexPath.row)

              if let sectionItems = self?.viewModel.sectionTasks[updatedSectionTitle], sectionItems.isEmpty {
                self?.viewModel.availableSections.remove(at: indexPath.section)
                self?.tableView.deleteSections(IndexSet.init(integer: indexPath.section), with: .automatic)
              }
            }
            self?.tableView.endUpdates()
          } else {
            self?.tableView.reloadData()
          }
       }
    }

    @IBAction func presentSearchBar(_ sender: UIBarButtonItem) {
        searchBar?.showsCancelButton = true
        searchBar?.becomeFirstResponder()

        self.navigationItem.titleView = searchBar
        self.navigationItem.setLeftBarButton(nil, animated: true)
    }

    //Opens up view to create a new task
    @IBAction func presentCreateTask(_ sender: UIBarButtonItem) {
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
        viewModel.set(queryText: self.searchBar?.text, isComplete: false)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.availableSections[section].description
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.availableSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let correctSection = viewModel.availableSections[section]
        return viewModel.sectionTasks[correctSection]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let taskItem = viewModel.getItem(from: indexPath) else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskTableViewCell

        cell?.taskName.text = taskItem.name
        cell?.taskDate.text = taskItem.dateCompleted

        return cell ?? UITableViewCell()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "segue" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let detailVC = segue.destination as? TaskDetailVC
                let taskItem = viewModel.getItem(from: indexPath)
                detailVC?.id = taskItem?.id
            }
        }
    }

    //marks and unmarks as done
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

            let actionTitle: String = isOpenTaskTabSelected ? "Done" : "Not Done"

            let completedAction = UIContextualAction(style: .normal,
                                                  title: actionTitle) { [weak self] (_, _, completionHandler) in
                self?.viewModel.handleSwipeAction(for: indexPath)
                completionHandler(true)
            }
            completedAction.backgroundColor = UIColor(red: 89/255, green: 87/255, blue: 153/255, alpha: 1)
            let configuration = UISwipeActionsConfiguration(actions: [completedAction])

            return configuration
    }

    //ability to edit row in table views
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    //if the editing style is set to delete, create an item that represents the cell we want to delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {

      if editingStyle == .delete {
        viewModel.handleEditingStyle(for: indexPath)
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
            return ToDoListItem.format(date: Date())
        case .nextseven:
            return "Next 7 Days"
        case .upcoming:
            return "Upcoming"
        }
    }
}

extension MainViewController: TaskCompletionDelegate {
    func onDone(taskName: String, taskDesc: String, dateToComplete: Date) {
        let newTodoListItem = ToDoListItem(name: taskName,
                                           desc: taskDesc,
                                           dateToComplete: dateToComplete)

        viewModel.save(item: newTodoListItem)
    }
}

extension MainViewController: EmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let noTasksText = String(format: "No %@ Tasks",
                                 isOpenTaskTabSelected ? "Open" : "Completed")

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

extension MainViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.showsCancelButton = false

        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }

        self.navigationItem.titleView = nil
        self.navigationItem.setLeftBarButton(searchBarButton, animated: true)
        viewModel.set(queryText: nil, isComplete: !isOpenTaskTabSelected)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchQuery: String = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.set(queryText: searchQuery, isComplete: !isOpenTaskTabSelected)
    }
}
