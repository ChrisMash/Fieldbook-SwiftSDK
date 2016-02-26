//
//  FieldbookSDK.swift
//  Fieldbook-SwiftSDK
//
//  Created by Chris Mash on 22/02/2016.
//  Copyright © 2016 Chris Mash. All rights reserved.
//

import UIKit

public class FieldbookSDK : NSObject
{
    private static let SDK_ERROR_DOMAIN = "FieldbookSDK"
    private static let BASE_URL = "https://api.fieldbook.com/v1/"
    private static var username : String?
    private static var password : String?
    
    private enum RequestType
    {
        case Post
        case Get
        case Delete
        case Patch
    }
    
    /// Types of error specific to the SDK
    public enum FieldbookSDKError : Int
    {
        case UnexpectedAPIResponse
        case BadQueryURL
        case APIError
    }
    
    /// Set the authentication details (key & secret / username & password)
    /// Necessary if you wish to add/update/delete items or access a private book
    ///
    /// - parameters:
    ///   - key: key / username from API-access on Fieldbook website
    ///   - secret: secret / password from API-access on Fieldbook website
    public static func setAuthDetails( key: String, secret: String )
    {
        username = key
        password = secret
    }
    
    /// Get all the items at the specified path
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - completion: block called upon completion of the query, with either an array of items or an error
    public static func getItems( query: String, completion: (items: NSArray?, error: NSError?) -> Void )
    {
        getItems( query, limit: 0, offset: 0, filters: nil, include: nil, exclude: nil) {
            (items, more, error) -> Void in
            
            completion( items: items, error: error )
        }
    }
    
    /// Get a subset of the items at the specified path (book_id/sheet_name)
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - limit: the max number of items to be returned
    ///   - offset: the number of items to skip, for paging
    ///   - filters: key/value pairs to filter the results by, of the form "name=amy". Case-sensitive.
    ///   - include: comma-separated string of fields that should be included in the returned items. Set to nil to get everything
    ///   - exclude: comma-separated string of fields that should be excluded in the returned items. Set to nil to get everything
    ///   - completion: block called upon completion of the query, with either an array of items or an error and a flag specifying whethere there are more items that can be requested
    public static func getItems( query: String, limit: UInt, offset: UInt, filters: NSArray?, include: String?, exclude: String?, completion: (items: NSArray?, more: Bool, error: NSError?) -> Void )
    {
        var parameters = ""
        if limit > 0
        {
            parameters = "?limit=\(limit)&offset=\(offset)"
        }
        
        if let unwrappedFilters = filters
        {
            for filter in unwrappedFilters
            {
                // The filter could have spaces in it so let's percent encode it so it forms a URL correctly
                if let encodedFilter = filter.stringByAddingPercentEscapesUsingEncoding( NSUTF8StringEncoding )
                {
                    if parameters.characters.count == 0
                    {
                        parameters = "?"
                    }
                    else
                    {
                        parameters += "&"
                    }
                    
                    parameters += "\(encodedFilter)"
                }
            }
        }
        
        if let unwrappedInclude = include
        {
            if parameters.characters.count == 0
            {
                parameters = "?"
            }
            else
            {
                parameters += "&"
            }
            
            parameters += "include=\(unwrappedInclude)"
        }
        
        if let unwrappedExclude = exclude
        {
            if parameters.characters.count == 0
            {
                parameters = "?"
            }
            else
            {
                parameters += "&"
            }
            
            parameters += "exclude=\(unwrappedExclude)"
        }
        
        // We're going to get a GET request here of the form
        // https://api.fieldbook.com/v1/56cb45f67753cf030003e42b/sheet_1/?limit=5&offset=0
        let request = requestFor( query + parameters, type: .Get, data: nil )
        
        makeRequest( request, completion: {
            (json: AnyObject?, error: NSError?) -> Void in
            
            if error != nil
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( items: nil, more: false, error: error )
                    
                })
            }
            else if let unwrappedJson = json
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    // Depending on whether we applied any page limits or requested the full set of items
                    // we'll get a different response structure
                    if let unwrappedItems = unwrappedJson[ "items" ]
                    {
                        // Requested paged results
                        let items = unwrappedItems as! NSArray
                        let count = unwrappedJson[ "count" ]! as! NSNumber
                        let received = Int( offset ) + items.count
                        completion( items: items, more: received < count.integerValue, error: nil )
                    }
                    else
                    {
                        // Requested full results
                        completion( items: unwrappedJson as? NSArray, more: false, error: nil )
                    }
                    
                })
            }
            else
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( items: nil, more: false, error: unexpectedResponseError() )
                    
                })
            }
            
        })
        
    }

    /// Get a single item with the specified path (book_id/sheet_name) and id
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - id: the id number of the item to return
    ///   - completion: block called upon completion of the query, with either the item or an error
    public static func getItem( query: String, id: NSNumber, completion: (item: NSDictionary?, error: NSError?) -> Void )
    {
        getItem( query, id: id, include: nil, exclude: nil, completion: completion )
    }
    
    /// Get a single item with the specified path (book_id/sheet_name) and id
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - id: the id number of the item to return
    ///   - include: comma-separated string of fields of the item that should be included. Set to nil to get everything
    ///   - exclude: comma-separated string of fields of the item that should be excluded. Set to nil to get everything
    ///   - completion: block called upon completion of the query, with either the item or an error
    public static func getItem( query: String, id: NSNumber, include: NSString?, exclude: NSString?, completion: (item: NSDictionary?, error: NSError?) -> Void )
    {
        var parameters = ""
        if let unwrappedInclude = include
        {
            if parameters.characters.count == 0
            {
                parameters = "?"
            }
            else
            {
                parameters += "&"
            }
            
            parameters += "include=\(unwrappedInclude)"
        }
        
        if let unwrappedExclude = exclude
        {
            if parameters.characters.count == 0
            {
                parameters = "?"
            }
            else
            {
                parameters += "&"
            }
            
            parameters += "exclude=\(unwrappedExclude)"
        }
        
        // We're going to get a GET request here of the form
        // https://api.fieldbook.com/v1/56cb45f67753cf030003e42b/sheet_1/1
        let request = requestFor( query + "/\(id)" + parameters, type: .Get, data: nil )
        
        makeRequest( request, completion: {
            (json: AnyObject?, error: NSError?) -> Void in
            
            if error != nil
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: nil, error: error )
                    
                })
            }
            else if let unwrappedDict = json as? NSDictionary
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: unwrappedDict, error: nil )
                    
                })
            }
            else
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: nil, error: unexpectedResponseError() )
                    
                })
            }
            
        })
    
    }
    
    /// Add a single item to the specified path (book_id/sheet_name)
    /// Do not include an 'id' field in the item as Fieldbook will generate that itself (your sheet should NOT have an 'id' column as it will cause a clash)
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - item: the fields of the item to be added
    ///   - completion: block called upon completion of the query, with either the newly added item or an error
    public static func addToList( query: String, item: NSDictionary, completion: (item: NSDictionary?, error: NSError?) -> Void )
    {
        // We're going to get a POST request here of the form
        // https://api.fieldbook.com/v1/56cb45f67753cf030003e42b/sheet_1/
        let request = requestFor( query, type: .Post, data: item )
        
        makeRequest( request, completion: {
            (json: AnyObject?, error: NSError?) -> Void in
            
            if error != nil
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: nil, error: error )
                    
                })
            }
            else if let unwrappedDict = json as? NSDictionary
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: unwrappedDict, error: nil )
                    
                })
            }
            else
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: nil, error: unexpectedResponseError() )
                    
                })
            }
            
        })
    }
    
    /// Update an item at the specified path (book_id/sheet_name)
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - id: the id number of the item to be updated
    ///   - item: the fields of the item to be updated (don't need to include fileds that don't need to change)
    ///   - completion: block called upon completion of the query, with either the newly updated item or an error
    public static func updateItem( query: String, id: NSNumber, item: NSDictionary, completion: (item: NSDictionary?, error: NSError?) -> Void )
    {
        // We're going to get a PATCH request here of the form
        // https://api.fieldbook.com/v1/56cb45f67753cf030003e42b/sheet_1/1
        let request = requestFor( query + "/\(id)", type: .Patch, data: item )
        
        makeRequest( request, completion: {
            (json: AnyObject?, error: NSError?) -> Void in
            
            if error != nil
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: nil, error: error )
                    
                })
            }
            else if let unwrappedDict = json as? NSDictionary
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: unwrappedDict, error: nil )
                    
                })
            }
            else
            {
                // Need to make sure we call the completion method on the main thread
                dispatch_async(dispatch_get_main_queue(),{
                    
                    completion( item: nil, error: unexpectedResponseError() )
                    
                })
            }
            
        })
    }
    
    /// Delete an item from the specified path (book_id/sheet_name)
    ///
    /// - parameters:
    ///   - query: query path of the form "<book_id>/<sheet_name>"
    ///   - id: the id number of the item to be deleted
    ///   - completion: block called upon completion of the query, with either nil or an error
    public static func deleteItem( query: String, id: NSNumber, completion: (error: NSError?) -> Void )
    {
        // We're going to get a DELETE request here of the form
        // https://api.fieldbook.com/v1/56cb45f67753cf030003e42b/sheet_1/1
        let request = requestFor( query + "/\(id)", type: .Delete, data: nil )
        
        makeRequest( request, completion: {
            (json: AnyObject?, error: NSError?) -> Void in
            
            // Need to make sure we call the completion method on the main thread
            dispatch_async(dispatch_get_main_queue(),{
                
                completion( error: error )
                
            })
            
        })
    }
    
    // MARK: - Private methods
    private static func requestFor( additionalPath: String, type: RequestType, data: NSDictionary? ) -> NSMutableURLRequest?
    {
        // Create a request with the specified path applied to the base URL
        let url = NSURL( string: BASE_URL + additionalPath )
        if let unwrappedURL = url
        {
            let request = NSMutableURLRequest( URL: unwrappedURL )
            if type == .Post
            {
                request.HTTPMethod = "POST"
            }
            else if type == .Delete
            {
                request.HTTPMethod = "DELETE"
            }
            else if type == .Patch
            {
                request.HTTPMethod = "PATCH"
            }
            
            // If there's some data past in convert it from json to NSData
            if let unwrappedData = data
            {
                request.setValue( "application/json", forHTTPHeaderField: "Content-Type" )
                
                do
                {
                    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject( unwrappedData, options: [] )
                }
                catch let error as NSError
                {
                    NSLog( "Error forming json body: %@ from: %@", error, unwrappedData )
                }
            }
            
            request.setValue( "application/json", forHTTPHeaderField: "Accept" )
            
            // If we've got authentication details then put them in the request
            if  let unwrappedUsername = username,
                let unwrappedPassword = password
            {
                // Basic authentication with base64 encoding
                let auth = "Basic \(base64( unwrappedUsername + ":" + unwrappedPassword ))"
                request.setValue( auth, forHTTPHeaderField: "Authorization" )
            }
            
            return request
        }
        
        return nil
    }
    
    private static func makeRequest( request: NSURLRequest?, completion: (json: AnyObject?, error: NSError?) -> Void )
    {
        if let unwrappedRequest = request
        {
            let session = NSURLSession( configuration: NSURLSessionConfiguration.defaultSessionConfiguration() )
            let task = session.dataTaskWithRequest( unwrappedRequest ) {
                (data, response, error) -> Void in
                
                /*var dataString : String?
                if let unwrappedData = data
                {
                dataString = String( data: unwrappedData, encoding: NSUTF8StringEncoding )
                }
                
                print("Response: \(response)")
                print("Error: \(error)")
                print("Data: \(dataString)")*/
                
                var webServiceError = error
                
                if let httpResponse = response as? NSHTTPURLResponse
                {
                    if let unwrappedData = data
                    {
                        var json : AnyObject?
                        if unwrappedData.length > 0
                        {
                            json = convertDataToDictionary( unwrappedData, verbose: true )
                        }
                        
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                        {
                            completion( json: json, error: nil )
                            return
                        }
                        else
                        {
                            webServiceError = self.formatFieldbookAPIError( httpResponse, json: json )
                        }
                    }
                }
                
                completion( json: nil, error: webServiceError )
                
            }
            
            task.resume()
        }
        else
        {
            completion( json: nil, error: NSError( domain: SDK_ERROR_DOMAIN, code: FieldbookSDKError.BadQueryURL.rawValue, userInfo: [NSLocalizedDescriptionKey : "Failed to generate query URL. You may have spaces in your query string?"] ) )
        }
    }
    
    private static func formatFieldbookAPIError( response: NSHTTPURLResponse, json: AnyObject? ) -> NSError
    {
        var message = "No details"
        if  let unwrappedJson = json,
            let unwrappedMessage = unwrappedJson[ "message" ] as? String
        {
            message = unwrappedMessage
        }
        
        return NSError( domain: "FieldbookAPI", code: FieldbookSDKError.APIError.rawValue, userInfo: [ NSLocalizedDescriptionKey : "Unexpected FieldbookAPI error \(response.statusCode): \(message)" ] )
    }
    
    private static func convertDataToDictionary( data: NSData, verbose: Bool ) -> AnyObject?
    {
        do
        {
            return try NSJSONSerialization.JSONObjectWithData( data, options: [ .AllowFragments ] )
        }
        catch let error as NSError
        {
            if verbose
            {
                print( "JSON conversion error: \(error)" )
            }
        }
        
        return nil
    }
    
    private static func base64( string: String ) -> String
    {
        let utf8str = string.dataUsingEncoding( NSUTF8StringEncoding )
        
        if let base64Encoded = utf8str?.base64EncodedStringWithOptions( NSDataBase64EncodingOptions( rawValue: 0 ) )
        {
            return base64Encoded
        }
        
        return ""
    }
    
    private static func unexpectedResponseError() -> NSError
    {
        return NSError( domain: SDK_ERROR_DOMAIN, code: FieldbookSDKError.UnexpectedAPIResponse.rawValue, userInfo: [NSLocalizedDescriptionKey : "Unexpected response from API"] )
    }
    
}
