//
//  CreateTaskViewController.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 2/19/19.
//  Copyright © 2019 Ellen Nkonya. All rights reserved.
//

import UIKit
import RealmSwift

class CreateTaskViewController: UIViewController {

    // MARK: - Custom Views
   
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    weak var delegate: TaskCompletionDelegate?
    
    fileprivate var selectedDate: Date {
        return Calendar.current.startOfDay(for: datePicker.date)
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.saveButton.isEnabled = false
        self.datePicker.datePickerMode = .date
        self.datePicker.minimumDate = Calendar.current.startOfDay(for: Date())
        self.datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dateLabel.text = TaskItemDTO.format(date: Date())
        self.datePicker.isHidden = true
    }
    
    // MARK: - Controller Actions
    
    @objc fileprivate func datePickerChanged() {
        self.dateLabel.text = TaskItemDTO.format(date: self.selectedDate)
        self.datePicker.isHidden = true
    }
    
    @IBAction fileprivate func didTapDateLabel() {
       self.datePicker.isHidden = !self.datePicker.isHidden
    }
   
    @IBAction func taskNameTextChanged(_ sender: UITextField) {
        let taskNameTrimmed: String = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        saveButton.isEnabled = !taskNameTrimmed.isEmpty ? true : false
    }

    @IBAction func cancelCreatingTask(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneCreatingTask(_ sender: UIBarButtonItem) {
        self.delegate?.onDone(taskName: nameTextField.text ?? "",
                         taskDesc: descriptionTextField.text ?? "",
                         dateToComplete: selectedDate)

        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Task Completion Delegate

protocol TaskCompletionDelegate: AnyObject {
     func onDone(taskName: String, taskDesc: String, dateToComplete: Date)
}
