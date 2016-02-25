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
    public static func setAuthDetails( key: String, secret: String )
    {
        username = key
        password = secret
    }
    
    /// Get all the items at the specified query (book_id/sheet_name)
    /// 'more' in the completion block will always be false
    public static func getItems( query: String, completion: (items: NSArray?, more: Bool, error: NSError?) -> Void )
    {
        getItems( query, limit: 0, offset: 0, filters: nil, include: nil, exclude: nil, completion: completion )
    }
    
    /// Get a subset of the items at the specified query (book_id/sheet_name)
    /// Use 'limit' & 'offset' to get pages of items, with 'more' in the completion block specifying whether
    /// there is more data available or the final page has been returned
    /// Use 'filters' to get only those items matching certain key/value pairs
    /// Use 'include' and 'exclude' to define which columns should be included/excluded from the response (comma delimited)
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

    /// Get a single item with the specified query (book_id/sheet_name) and id
    public static func getItem( query: String, id: NSNumber, completion: (item: NSDictionary?, error: NSError?) -> Void )
    {
        getItem( query, id: id, include: nil, exclude: nil, completion: completion )
    }
    
    /// Get a single item with the specified query (book_id/sheet_name) and id
    /// Use 'include' and 'exclude' to define which columns should be included/excluded from the response
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
    
    /// Add a single item to the specified query (book_id/sheet_name)
    /// Do not include an 'id' field in the item as Fieldbook will generate that itself (your sheet should NOT have an 'id' column as it will cause a clash)
    /// The resulting 'item' in the completion block will provide you with the newly added item (including its Fieldbook generated id which may be useful for subsequent update/delete calls)
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
    
    /// Update an item at the specified query (book_id/sheet_name)
    /// 'item' need only contain the changed fields
    /// The resulting 'item' in the completion block will provide you with the fully updated item fields
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
    
    /// Delete an item from the specified query (book_id/sheet_name)
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
