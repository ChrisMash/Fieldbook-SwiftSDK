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
