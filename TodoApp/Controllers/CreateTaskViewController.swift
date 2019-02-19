//
//  CreateTaskViewController.swift
//  TodoApp
//
//  Created by Ellen Nkonya on 2/19/19.
//  Copyright © 2019 Ellen Nkonya. All rights reserved.
//

import UIKit
import RealmSwift

class CreateTaskViewController: UIViewController{
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    
    var delegate: TaskCompletionDelegate?
    var datePicker = UIDatePicker()
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        
        return df
    }()
    
    lazy var todaysDate: String = {
        let today = Calendar.current.startOfDay(for: Date())
        return String(format:"Today, %@", dateFormatter.string(from: today))
    }()
    
    lazy var selectedDate: Date = {
        return Calendar.current.startOfDay(for: datePicker.date)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Calendar.current.startOfDay(for: Date())
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        
        dateTextField.text = todaysDate
        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = self.createDatePickerToolbar()
    }
    
    func createDatePickerToolbar() -> UIToolbar{
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
    }
    
    @objc func datePickerChanged(){
        if(selectedDate == Calendar.current.startOfDay(for: Date())){
            dateTextField.text = todaysDate
        }
        else{
            dateTextField.text = dateFormatter.string(for: selectedDate)
        }
    }
    
    @objc func hideDatePicker() {
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
