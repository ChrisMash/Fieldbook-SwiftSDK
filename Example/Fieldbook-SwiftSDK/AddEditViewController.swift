//
//  AddEditViewController.swift
//  Fieldbook-SwiftSDK
//
//  Created by Chris Mash on 22/02/2016.
//  Copyright © 2016 Chris Mash. All rights reserved.
//

import UIKit
import Fieldbook_SwiftSDK

protocol AddEditViewControllerDelegate
{
    func addEditViewControllerAddedItem( item: NSDictionary )
    func addEditViewControllerUpdatedItem( item: NSDictionary )
}


class AddEditViewController: UIViewController
{
    @IBOutlet weak var savingIndicator : UIActivityIndicatorView?
    @IBOutlet weak var col1TextField : UITextField?
    @IBOutlet weak var col2TextField : UITextField?
    @IBOutlet weak var col3TextField : UITextField?
    @IBOutlet weak var addButton : UIButton?
    
    var item : NSDictionary?
    var delegate : AddEditViewControllerDelegate?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
     
        savingIndicator?.hidden = true
        
        if let unwrappedItem = item
        {
            self.title = "Edit Item"
            addButton?.setTitle( self.title, forState: .Normal )
            
            col1TextField?.text = "\(unwrappedItem[ "col_1" ]!)"
            col2TextField?.text = "\(unwrappedItem[ "col_2" ]!)"
            col3TextField?.text = "\(unwrappedItem[ "col_3" ]!)"
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    private func onError( error: NSError )
    {
        savingIndicator?.stopAnimating()
        savingIndicator?.hidden = true
        addButton?.enabled = true
        col1TextField?.enabled = true
        col2TextField?.enabled = true
        col3TextField?.enabled = true
        
        Utility.displayAlert( "Error", message: error.localizedDescription, viewController: self )
    }
    
    // MARK: IBAction methods
    @IBAction func addButtonPressed( button: UIButton? )
    {
        let col1 = col1TextField?.text as String?
        let col2 = col2TextField?.text as String?
        let col3 = col3TextField?.text as String?
        
        // Validate the input first
        if  let unwrappedCol1 = col1,
            let unwrappedCol2 = col2,
            let unwrappedCol3 = col3
        {
            if unwrappedCol1.characters.count == 0
            {
                Utility.displayAlert( "Error", message: "Please enter a value for Col 1", viewController: self )
                return
            }
            else if unwrappedCol2.characters.count == 0
            {
                Utility.displayAlert( "Error", message: "Please enter a value for Col 2", viewController: self )
                return
            }
            else if unwrappedCol3.characters.count == 0
            {
                Utility.displayAlert( "Error", message: "Please enter a value for Col 3", viewController: self )
                return
            }
            
            savingIndicator?.hidden = false
            savingIndicator?.startAnimating()
            addButton?.enabled = false
            col1TextField?.enabled = false
            col2TextField?.enabled = false
            col3TextField?.enabled = false
            
            let dict = NSDictionary( dictionary: [ "col_1" : unwrappedCol1, "col_2" : unwrappedCol2, "col_3" : unwrappedCol3 ] )
            
            // If we've got an item referenced then we're intending to update it
            if let unwrappedItem = item
            {
                // Send Fieldbook the updated info
                FieldbookSDK.updateItem( Constants.fieldbookPath(), id: unwrappedItem[ "id" ]! as! NSNumber, item: dict ) {
                    (updatedItem, error) -> Void in
                    
                    if let unwrappedError = error
                    {
                        self.onError( unwrappedError )
                    }
                    else
                    {
                        // Success! Let the delegate know
                        if  let unwrappedDelegate = self.delegate,
                            let unwrappedItem = updatedItem
                        {
                            unwrappedDelegate.addEditViewControllerUpdatedItem( unwrappedItem )
                        }
                    }
                    
                }
            }
            else
            {
                // Send the new item's info to Fieldbook
                FieldbookSDK.addToList( Constants.fieldbookPath(), item: dict ) {
                    (newItem, error) -> Void in
                    
                    if let unwrappedError = error
                    {
                        self.onError( unwrappedError )
                    }
                    else
                    {
                        // Success! Let the delegate know
                        if  let unwrappedDelegate = self.delegate,
                            let unwrappedItem = newItem
                        {
                            unwrappedDelegate.addEditViewControllerAddedItem( unwrappedItem )
                        }
                    }
                    
                }
            }
        }
        else
        {
            Utility.displayAlert( "Error", message: "Please enter the full set of information for the item", viewController: self )
        }
    }

}
