//
//  ViewController.swift
//  Fieldbook-SwiftSDK
//
//  Created by Chris Mash on 22/02/2016.
//  Copyright © 2016 Chris Mash. All rights reserved.
//

import UIKit
import Fieldbook_SwiftSDK

let LIST_PAGE_SIZE : UInt = 5

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddEditViewControllerDelegate
{
    @IBOutlet weak var listTableView : UITableView?
    @IBOutlet weak var loadingIndicator : UIActivityIndicatorView?
    
    private var listData : NSMutableArray?
    private var selectedItem : NSDictionary?
    private var moreData : Bool = true
    private var loading : Bool = false

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadingIndicator?.hidden = true
        listTableView?.tableFooterView = UIView()
        
        UIApplication.sharedApplication().setStatusBarStyle( .LightContent, animated: true )

        // Authentication details to allow adding/updating/deleting from the public, read-only, shet
        FieldbookSDK.setAuthDetails( "key-3", secret: "ni2YUysqcSBhVQqhvH1r" )
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear( animated )
        
        // If we don't have any data yet then let's get some!
        if( listData == nil )
        {
            refreshListData()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        super.prepareForSegue( segue, sender: sender )
        
        if segue.identifier!.compare( "editSegue" ) == .OrderedSame
        {
            // Segueing to edit an item, so setup the view controller with some info!
            if let destVC = segue.destinationViewController as? AddEditViewController
            {
                destVC.delegate = self
                destVC.item = selectedItem
                selectedItem = nil
            }
        }
        else if segue.identifier!.compare( "addSegue" ) == .OrderedSame
        {
            // Segueing to add an item, so setup the view controller with some info!
            if let destVC = segue.destinationViewController as? AddEditViewController
            {
                destVC.delegate = self
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshListData()
    {
        FieldbookSDK.getItems( Constants.fieldbookPath(), limit: LIST_PAGE_SIZE, offset: 0, filters: [ "col_1=2 1", "col_2=22" ], include: nil, exclude: nil, completion: { (items, more, error) -> Void in
            
            NSLog( "Filtered items: %@", items! )
            
            })
            
        loading = true
        
        // Chuck away all the previously loaded data, we're starting again!
        listData = nil
        listTableView?.reloadData()
        
        loadingIndicator?.hidden = false
        loadingIndicator?.startAnimating()
        
        // Get the first 5 values from the Fieldbook sheet, without doing any filtering or inclduing/exluding different values
        FieldbookSDK.getItems( Constants.fieldbookPath(), limit: LIST_PAGE_SIZE, offset: 0, filters: nil, include: nil, exclude: nil, completion: { (items, more, error) -> Void in
            
            self.loading = false
            
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.hidden = true
            
            // 'more' tells us whether Fieldbook has anymore data on the sheet beyond the first 5 we asked for, so let's remember that for use later
            self.moreData = more
            
            if let unwrappedError = error
            {
                // Oh dear, something went wrong, let's popup an alert
                Utility.displayAlert( "Error", message: unwrappedError.localizedDescription, viewController: self )
            }
            else
            {
                // All good! Store the data and refresh the table view!
                if let unwrappedItems = items
                {
                    self.listData = unwrappedItems.mutableCopy() as? NSMutableArray
                }
                
                self.listTableView?.reloadData()
            }
            
        })
    }
    
    func loadMore()
    {
        if let unwrappedList = listData
        {
            loading = true
            
            // Get the next 5 items from Fieldbook, letting it know how many we've already got so it returns us the right ones!
            FieldbookSDK.getItems( Constants.fieldbookPath(), limit: LIST_PAGE_SIZE, offset: UInt( unwrappedList.count ), filters: nil, include: nil, exclude: nil, completion: { (items, more, error) -> Void in
                
                self.loading = false
                
                // Might still be more to come!
                self.moreData = more
                
                if let unwrappedError = error
                {
                    Utility.displayAlert( "Error", message: unwrappedError.localizedDescription, viewController: self )
                }
                else
                {
                    if let unwrappedItems = items
                    {
                        self.listData?.addObjectsFromArray( unwrappedItems as [ AnyObject ] )
                    }
                    
                    self.listTableView?.reloadData()
                }
                
            })
        }
    }
    
    // MARK: IBAction methods
    @IBAction func refreshPressed(sender: UIBarButtonItem?)
    {
        // Throw everything away and load the first 5 items again!
        refreshListData()
    }

    // MARK: UITableViewDataSource methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // 1 cell per item in listData and an extra one if we've got more data
        // because we'll be displaying a cell with a spinner while we're loading the next chunk
        if let unwrappedList = listData
        {
            return unwrappedList.count + (moreData ? 1 : 0)
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if moreData && indexPath.row == listData!.count
        {
            // Fieldbook has more data and this is the cell for the last item in the list
            // A special cell with a spinner to show we're loading more in!
            let cell = tableView.dequeueReusableCellWithIdentifier( "loadMoreCell" )
            return cell!
        }
        else
        {
            let unwrappedList = listData!
            let item = unwrappedList[ indexPath.row ] as! NSDictionary
            let cell = tableView.dequeueReusableCellWithIdentifier( "basicCell" )
            cell?.textLabel?.text = "\(item[ "col_1" ]!) | \(item[ "col_2" ]!) | \(item[ "col_3" ]!)"
            return cell!
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        if moreData && indexPath.row == listData!.count
        {
            // Don't let the user try to delete the 'loading more' spinner cell!
            return false
        }
        else
        {
            return true
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete
        {
            let unwrappedList = listData!
            let item = unwrappedList[ indexPath.row ] as! NSDictionary
            
            listTableView?.alpha = 0.5
            listTableView?.userInteractionEnabled = false
            
            loadingIndicator?.hidden = false
            loadingIndicator?.startAnimating()
            
            // Delete the specified item from Fieldbook
            FieldbookSDK.deleteItem( Constants.fieldbookPath(), id: item[ "id" ]! as! NSNumber, completion: { (error) -> Void in
                
                self.listTableView?.alpha = 1
                self.listTableView?.userInteractionEnabled = true
                
                self.loadingIndicator?.stopAnimating()
                self.loadingIndicator?.hidden = true
                
                if let unwrappedError = error
                {
                    Utility.displayAlert( "Error", message: unwrappedError.localizedDescription, viewController: self )
                }
                else
                {
                    unwrappedList.removeObjectAtIndex( indexPath.row )
                    tableView.deleteRowsAtIndexPaths( [ indexPath ], withRowAnimation: .Automatic )
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        // If we've got more data to load and this is the last cell in the list (the special 'loading more spinner')
        // and we've not already started loading more then trigger loading the next chunk of items
        if moreData && indexPath.row == listData!.count && !loading
        {
            loadMore()
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        // Don't let the user select the 'loading more data' spinner cell
        return !(moreData && indexPath.row == listData!.count)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let unwrappedList = listData!
        selectedItem = unwrappedList[ indexPath.row ] as? NSDictionary
        performSegueWithIdentifier( "editSegue", sender: nil )
    }
    
    // MARK: AddEditViewControllerDelegate
    func addEditViewControllerAddedItem( item: NSDictionary )
    {
        // The specified item has successfully been added to Fieldbook so let's add it to our local list
        if let unwrappedListData = listData
        {
            unwrappedListData.addObject( item )
        }
        
        self.listTableView?.reloadData()
        self.navigationController?.popViewControllerAnimated( true )
    }
    
    func addEditViewControllerUpdatedItem( item: NSDictionary )
    {
        // The specified item has successfully been updated on Fieldbook so let's reflect that in our local list
        if let unwrappedListData = listData
        {
            for var u = 0; u < unwrappedListData.count; ++u
            {
                let dict = unwrappedListData[ u ]
                if dict[ "id" ] as! NSNumber == item[ "id" ] as! NSNumber
                {
                    unwrappedListData.replaceObjectAtIndex( u, withObject: item )
                    break
                }
            }
        }
        
        self.listTableView?.reloadData()
        self.navigationController?.popViewControllerAnimated( true )
    }
    
}
