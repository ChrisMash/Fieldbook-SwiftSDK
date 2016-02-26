# Fieldbook-SwiftSDK

[![Version](https://img.shields.io/cocoapods/v/Fieldbook-SwiftSDK.svg?style=flat)](http://cocoapods.org/pods/Fieldbook-SwiftSDK)
[![License](https://img.shields.io/cocoapods/l/Fieldbook-SwiftSDK.svg?style=flat)](http://cocoapods.org/pods/Fieldbook-SwiftSDK)
[![Platform](https://img.shields.io/cocoapods/p/Fieldbook-SwiftSDK.svg?style=flat)](http://cocoapods.org/pods/Fieldbook-SwiftSDK)

## Intro

[Fieldbook](http://fieldbook.com); create a database as easily as a spreadsheet.

Basically it's a free cloud-based spreadsheet service with an API that is fairly thinly wrapped into this SDK.

I have no association with Fieldbook, just thought I'd package up and share my code!

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

The example project, unsurprisingly, shows some examples of how the SDK works. The app will pull in data from a public (read-only) Fieldbook sheet (https://fieldbook.com/books/56cb45f67753cf030003e42b) and display it in a list. Tapping on an item will allow you to edit the item's data and you can swipe to delete items too. The + icon in the top right will allow you to add more items. As the data is what all users are seeing let's try and keep it working ;)

```swift
/// Set the authentication details (key & secret / username & password)
/// Necessary if you wish to add/update/delete items or access a private book
///
/// - parameters:
///   - key: key / username from API-access on Fieldbook website
///   - secret: secret / password from API-access on Fieldbook website
public static func setAuthDetails( key: String, secret: String )

/// Get all the items at the specified path
///
/// - parameters:
///   - query: query path of the form "<book_id>/<sheet_name>"
///   - completion: block called upon completion of the query, with either an array of items or an error
public static func getItems( query: String, completion: (items: NSArray?, error: NSError?) -> Void )

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

/// Get a single item with the specified path (book_id/sheet_name) and id
///
/// - parameters:
///   - query: query path of the form "<book_id>/<sheet_name>"
///   - id: the id number of the item to return
///   - completion: block called upon completion of the query, with either the item or an error
public static func getItem( query: String, id: NSNumber, completion: (item: NSDictionary?, error: NSError?) -> Void )

/// Get a single item with the specified path (book_id/sheet_name) and id
///
/// - parameters:
///   - query: query path of the form "<book_id>/<sheet_name>"
///   - id: the id number of the item to return
///   - include: comma-separated string of fields of the item that should be included. Set to nil to get everything
///   - exclude: comma-separated string of fields of the item that should be excluded. Set to nil to get everything
///   - completion: block called upon completion of the query, with either the item or an error
public static func getItem( query: String, id: NSNumber, include: NSString?, exclude: NSString?, completion: (item: NSDictionary?, error: NSError?) -> Void )

/// Add a single item to the specified path (book_id/sheet_name)
/// Do not include an 'id' field in the item as Fieldbook will generate that itself (your sheet should NOT have an 'id' column as it will cause a clash)
///
/// - parameters:
///   - query: query path of the form "<book_id>/<sheet_name>"
///   - item: the fields of the item to be added
///   - completion: block called upon completion of the query, with either the newly added item or an error
public static func addToList( query: String, item: NSDictionary, completion: (item: NSDictionary?, error: NSError?) -> Void )

/// Update an item at the specified path (book_id/sheet_name)
///
/// - parameters:
///   - query: query path of the form "<book_id>/<sheet_name>"
///   - id: the id number of the item to be updated
///   - item: the fields of the item to be updated (don't need to include fileds that don't need to change)
///   - completion: block called upon completion of the query, with either the newly updated item or an error
public static func updateItem( query: String, id: NSNumber, item: NSDictionary, completion: (item: NSDictionary?, error: NSError?) -> Void )

/// Delete an item from the specified path (book_id/sheet_name)
///
/// - parameters:
///   - query: query path of the form "<book_id>/<sheet_name>"
///   - id: the id number of the item to be deleted
///   - completion: block called upon completion of the query, with either nil or an error
public static func deleteItem( query: String, id: NSNumber, completion: (error: NSError?) -> Void )
```

For more details on the API you can find some docs on [GitHub](https://github.com/fieldbook/api-docs).

## Installation

Fieldbook-SwiftSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Fieldbook-SwiftSDK"
```

You can of course also just copy the Fieldbook_SwiftSDK.swift file into your own project and reference its methods if you're unfamiliar with CocoaPods (though I strongly encourage you to try them out!)

## To Do

The API methods related to webhooks haven't been included, otherwise the current API is fully implemented (at least as of February 2016).

## Author

Chris Mash, chris.mash@gmx.com, @cjmash

## License

Fieldbook-SwiftSDK is available under the MIT license. See the LICENSE file for more info.
