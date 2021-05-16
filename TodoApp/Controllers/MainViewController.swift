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
    
    // MARK: - Custom Views
    
    fileprivate var searchBar: UISearchBar?
    @IBOutlet var searchBarButton: UIBarButtonItem!
    @IBOutlet weak var segmentedControl: UISegmentedControl?
    
    // MARK: - Properties
    
    fileprivate lazy var viewModel = MainViewModel()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        self.searchBar = UISearchBar()
        self.searchBar?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpViewModelNotification()
        self.viewModel.setUpRealmDataSource(withSearchText: self.searchBar?.text)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.removeNotifications()
    }
    
    deinit {
        self.searchBar?.delegate = nil
        self.tableView?.emptyDataSetSource = nil
        self.tableView?.emptyDataSetDelegate = nil
    }
    
    // MARK: - Setup View Model Notification 
    
    fileprivate func setUpViewModelNotification() {
        self.viewModel.notification = { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial, .update:
                self.tableView.reloadData()
            case .error:
                // An error occurred while opening the Realm file on the background worker thread
                let errorAlert = UIAlertController(title: "Error", message: "Error opening realm file", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                break
            }
        }
    }
    
    // MARK: - IB Actions
    
    /// Called when the selected tab in segmented control is changed
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        self.viewModel.didChangeTabSelection(toIndex: sender.selectedSegmentIndex)
    }
    
    /// Displays search bar to filter task items by text
    @IBAction func presentSearchBar(_ sender: UIBarButtonItem) {
        self.searchBar?.showsCancelButton = true
        self.searchBar?.becomeFirstResponder()
        
        self.navigationItem.titleView = searchBar
        self.navigationItem.setLeftBarButton(nil, animated: true)
    }
    
    /// Opens up view to create a new task
    @IBAction func presentCreateTask(_ sender: UIBarButtonItem) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        if let createVC =
            storyBoard.instantiateViewController(withIdentifier: "createTaskView") as? CreateTaskViewController {
            createVC.delegate = self.viewModel
            let nvc = UINavigationController(rootViewController: createVC)
            self.present(nvc, animated: true, completion: nil)
        }
    }
    
    // MARK: Table View Delegate + Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows(inSection: section)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.viewModel.title(forSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let taskItem = self.viewModel.item(at: indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskTableViewCell
        cell?.taskName.text = taskItem.name
        cell?.taskDate.text = taskItem.dateToComplete
        return cell ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        if let detailVC = storyBoard.instantiateViewController(withIdentifier: "taskDetailView") as? TaskDetailVC {
            detailVC.taskItem = self.viewModel.item(at: indexPath)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let actionTitle: String = (self.viewModel.selectedTab == .completed) ? "Not Done" : "Done"
        
        // marks and unmarks as done
        let completedAction = UIContextualAction(style: .normal, title: actionTitle) { (_, _, completionHandler) in
            self.viewModel.updateItem(at: indexPath, completion: { error in
                completionHandler(error == nil)
            })
        }
        completedAction.backgroundColor = UIColor(red: 89/255, green: 87/255, blue: 153/255, alpha: 1)
        let configuration = UISwipeActionsConfiguration(actions: [completedAction])
        
        return configuration
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        self.viewModel.deleteItem(at: indexPath, completion: { error in
            // TODO: display error message
        })
    }
}

// MARK: - Empty Data Set Delegate + Source

extension MainViewController: EmptyDataSetDelegate, EmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let noTasksText = String(format: "No %@ Tasks", self.viewModel.selectedTab.description)
        return self.emptySetAttributedString(text: noTasksText, fontSize: 25)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let noTasksDesc = "To create a task, tap the + button on the top right corner."
        return self.emptySetAttributedString(text: noTasksDesc, fontSize: 15.0)
    }
    
    /// Private helper that transforms a given text for empty view to an attributed string
    fileprivate func emptySetAttributedString(text: String, fontSize: CGFloat) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .center
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize),
                          NSAttributedString.Key.paragraphStyle: paragraph]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
}

// MARK: - UI Search Bar Delegate

extension MainViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.showsCancelButton = false
        
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
        
        self.navigationItem.titleView = nil
        self.navigationItem.setLeftBarButton(self.searchBarButton, animated: true)
        self.viewModel.setUpRealmDataSource(withSearchText: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.setUpRealmDataSource(withSearchText: searchText)
    }
}
