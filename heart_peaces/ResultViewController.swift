//
//  ResultViewController.swift
//  HeartRate
//
//  Created by Aliona Kostenko on 23.04.2021.
//  Copyright © 2021 Svitlana. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    
    enum SelectCodeSegmented: Int {
        case rest = 0, normal, active
    }

    @IBOutlet weak var textView: UILabel!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var pulseView: UIView!
    @IBOutlet weak var pulseRate: UILabel!
    @IBOutlet weak var bpm: UILabel!
    private var navigationManager = NavigationManager.sharedInstance
    fileprivate var codeSegmented = CustomSegmentedControl(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 38), buttonTitle: [NSLocalizedString("rest", comment: ""),NSLocalizedString("normal", comment: ""), NSLocalizedString("active", comment: "")])
    let currentUser = SettingsUserDefaults.sharedInstance
    var widthBpm: Int!
    var sizePulseRate: Int!
    var conditionIndex = 0

    override func viewDidLoad() {
        setupSegmentedControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
    }
        
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            addConstraints()
            initData()
    }
    
    private func initData() {
            codeSegmented.setIndex(index: currentUser.gender)
    }
    
//    TODO: change gender to status
    func saveSelected() {
        switch codeSegmented.selectedIndex {
        case 0:
            currentUser.gender = SelectCodeSegmented.rest.rawValue
        case 1:
            currentUser.gender = SelectCodeSegmented.normal.rawValue
        case 2:
            currentUser.gender = SelectCodeSegmented.active.rawValue
        default:
            break
        }
    }
        
    private func setupSegmentedControl() {
            codeSegmented.removeFromSuperview()
            codeSegmented.delegate = self
            codeSegmented.backgroundColor = UIColor(named: "darkModeBackground")
            codeSegmented.selectorViewColor = UIColor(named: "selectColor")!
            codeSegmented.selectorTextColor = UIColor(named: "darkMode")!
            mainView.addSubview(codeSegmented)
        }
    
    func constaintInts() {
        if pulseRate.text?.count == 3 {
            widthBpm = 270
        }
        else {
            widthBpm = 350
        }
        if UIScreen.main.nativeBounds.height < 1792 {
            sizePulseRate = 100
        }
        else if UIScreen.main.nativeBounds.height >= 1792 {
            sizePulseRate = 300
        }
    }
    
    func addConstraints() {
        if UIScreen.main.nativeBounds.height < 1792 {
            textView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            pulseRate.font = UIFont.systemFont(ofSize: 130, weight: .regular)
        }
        else if UIScreen.main.nativeBounds.height >= 1792 {
            textView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            pulseRate.font = UIFont.systemFont(ofSize: 150, weight: .regular)
        }
        
        constaintInts()
        let newView = UIView()
            view.addSubview(newView)
            newView.addSubview(pulseRate)
            pulseRate.addSubview(bpm)
        pulseRate.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint1 = NSLayoutConstraint(item: pulseRate!, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: newView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint1 = NSLayoutConstraint(item: pulseRate!, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: newView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        let widthConstraint1 = NSLayoutConstraint(item: pulseRate!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(widthBpm))
        let heightConstraint1 = NSLayoutConstraint(item: pulseRate!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 350)
        NSLayoutConstraint.activate([horizontalConstraint1, verticalConstraint1, widthConstraint1, heightConstraint1])
        
        newView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: -10)
        let verticalConstraint = NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: -70)
        let widthConstraint = NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(sizePulseRate))
        let heightConstraint = NSLayoutConstraint(item: newView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(sizePulseRate))
            NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
    }
    
    @IBAction func saveResult(_ sender: Any) {
        navigationManager.display(view: FinishViewController.ID)
//        if currentUser.gender == SelectCodeSegmented.rest.rawValue{
//            conditionIndex = 0
//        }
//        else if currentUser.gender == SelectCodeSegmented.normal.rawValue {
//            conditionIndex = 1
//        }
//        else if currentUser.gender == SelectCodeSegmented.active.rawValue{
//            conditionIndex = 2
//        }
    }
}

extension ResultViewController: CustomSegmentedControlDelegate {
    
    func change(to index: Int) {
        
    }
}
