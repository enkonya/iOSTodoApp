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

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!

    @IBOutlet weak var saveButton: UIBarButtonItem!

    weak var delegate: TaskCompletionDelegate?
    fileprivate var datePicker = UIDatePicker()

    fileprivate var selectedDate: Date {
        return Calendar.current.startOfDay(for: datePicker.date)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        saveButton.isEnabled = false
        nameTextField.addTarget(self, action: #selector(taskNameTextFieldCheck), for: .editingChanged)

        datePicker.datePickerMode = .date
        datePicker.minimumDate = Calendar.current.startOfDay(for: Date())
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)

        dateTextField.text = ToDoListItem.format(date: Date())
        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = datePickerToolbar
    }

    //task name is required -- disables/enables save button
    @objc fileprivate func taskNameTextFieldCheck(sender: UITextField) {
        let taskNameTrimmed: String = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        saveButton.isEnabled = !taskNameTrimmed.isEmpty ? true : false
    }

    fileprivate var datePickerToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        let cancelBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain,
                                                  target: self, action: #selector(hideDatePicker))
        let flexBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                                target: nil, action: nil)
        let doneBarButtonItem = UIBarButtonItem(title: "Done", style: .done,
                                                target: self, action: #selector(hideDatePicker))
        toolbar.setItems([cancelBarButtonItem, flexBarButtonItem, doneBarButtonItem],
                         animated: false)

        toolbar.barStyle = .default
        toolbar.tintColor = UIColor.black
        toolbar.isTranslucent = false
        toolbar.isUserInteractionEnabled = true
        toolbar.sizeToFit()

        return toolbar
    }()

    @objc fileprivate func datePickerChanged() {
        dateTextField.text = ToDoListItem.format(date: selectedDate)
    }

    @objc fileprivate func hideDatePicker() {
        self.view.endEditing(true)
    }

    @IBAction func cancelCreatingTask(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneCreatingTask(_ sender: UIBarButtonItem) {
        delegate?.onDone(taskName: nameTextField.text ?? "",
                         taskDesc: descriptionTextField.text ?? "",
                         dateToComplete: selectedDate)

        self.dismiss(animated: true, completion: nil)
    }
}

protocol TaskCompletionDelegate: class {
     func onDone(taskName: String, taskDesc: String, dateToComplete: Date)
}
