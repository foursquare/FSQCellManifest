FSQCellManifest
===============

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A UITableView and UICollectionView delegate and datasource that provides a simpler unified interface for describing your sections and cells.

Overview
========

FSQCellManifest gives you an improved interface to UITableView and UICollectionView versus manually implementing their delegate and datasource methods. You can describe your cell structure in one place in code and then the manifest will take care of returning the appropriate values to the delegate and datasource callbacks. There are extensive configuration options and convenience properties to support almost any kind of table or collection view you may have.

A few of the many other features the manifest provides are:
* Provides a unified interface for table and collection views, making it easier to write generic code that works for both types of views.
* Moves height and cell-reuse/configuration code out of view controllers / data sources into the cell classes themselves, making cells easier to reuse in different screens.
* Allows you to define cell behaviors using blocks instead of delegate callbacks.
* Removes need to pre-register cell identifiers.

The manifest classes are all thoroughly documented in their header file, but this readme will give you a brief overview of how to use FSQCellManifest in your own projects.

Setup
=====

## Carthage

If your minimum iOS version requirement is 8.0 or greater, Carthage is the recommended way to integrate FSQCellManifest with your app.
Add `github "foursquare/FSQCellManifest"` to your Cartfile and follow the instructions from [Carthage's README](https://github.com/Carthage/Carthage) for adding Carthage-built frameworks to your project.

## Cocoapods

If you use Cocoapods, you can add `pod 'FSQCellManifest', '~> [desired version here]'` to your Podfile. Further instructions on setting up and using Cocoapods can be found on [their website](https://cocoapods.org)

## Manual Installation

You can also simply add the objc files in the `FSQCellManifest` directoryto your project, either by copying them over, or using git submodules.

## FSQMessageForwarder

FSQCellManifest also requires [FSQMessageForwarder](https://github.com/foursquare/FSQMessageForwarder) to work. If you are using Carthage or Cocoapods, this should be taken care of for you automatically. Otherwise you will need to manually add that repo to your project as well (e.g. via git submodules or manually copying the files into your repo).

Example App
===========

An example app is included with this project that creates a simple table view with some dummy data. If you want to get quickly set up with FSQCellManifest you may want to look at that to see how easy it is to get started. 

The example app requires the FSQMessageForwarder framework to run, which is not included in this repo. If you have Carthage installed, you can simply run `carthage bootstrap` to get the framework set up in the correct location. Otherwise you will need to manually add the forwarder framework to the location specified in the example app's Xcode project settings.

Using FSQCellManifest
=====================

To use FSQCellManifest with your table or collection views, the object that owns the view should instantiate and retain a new instance of either FSQTableViewCellManifest or FSQCollectionViewCellManifest as appropriate and set that object as the view's datasource and delegate. You should then use the manifest's methods to describe and make changes to your view's contents and it will handle all the necessary method calls and callbacks to render your cells.

Note that if you are using a collection view with a layout other than UICollectionViewFlowLayout, you may need to subclass or add category methods to FSQCollectionViewCellManifest so it knows how to respond to any custom delegate/datasource callbacks for your layout.

Creating a Simple Manifest
==========================

To use the manifest, you will create FSQSectionRecord objects, each of which describes one section in your view. These in turn will have an array of FSQCellRecord objects which each describe one cell in that section.

There are many configuration options available on both records, but the two main required properties are cell record's `cellClass` and `model`. 

`cellClass` is the class of your UITableViewCell or UICollectionViewCell that you want to be dequeued for this row. This class should conform to either the FSQCellManifestTableViewCellProtocol or FSQCellManifestCollectionViewCellProtocol as appropriate. 

`model` should be an object that the cell class can use to render its contents and calculate its size. It can be any object that you like, from a simple string to a complicated custom data object (in Foursquare for example, a model for a cell might be a user or a venue). You can use whatever makes sense for your app as long as the cell class is written to receive the matching type of class in its implementation of the FSQCellManifestProtocol methods. The manifest will call these methods on your cell class, passing in the model object, when it needs to calculate sizing information for its view (eg tableView:heightForRowAtIndexPath:) and when the cell is dequeued so that it can render its new content.

You can get a simple table or collection view up and running using FSQCellManifest with just the above described properties and protocols. Check out the example app included with this project to see a barebones table view using these features.

Further Customization Options
=============================

For screens where you need more complicated customization there are a wealth of other properties and delegate callbacks you can use, a few of which are summarized here.

Section and cell records can be re-ordered or modified in a number of ways (such as inserting, removing, and replacing). All necessary data source and delegate callbacks needed to render your changes can be handled for your with a simple single-method call to the manifest.

Selection blocks can be added to FSQCellRecords to perform actions when users tap on cells. Relatedly, whether or not cells should allow highlighting/selection can be inferred automatically based on the presence of these blocks, or set manually.

Configuration blocks that get executed on dequeue can be added to FSQCellRecords for one-off customization of cells without having to create a new subclass or add complicated logic to existing classes.

There are delegate callbacks before and after almost every manifest operation, allowing you to add your custom code without having to create new subclasses. Additionally delegate and data source callbacks from UITableView or UICollectionView can be forwarded along to the manifest's delegate.

Extending Functionality
=======================

If you want to add extra features onto cell manifest, it is difficult to do so by subclassing since you would have to separately subclass both the table and collection view versions, potentially copy and pasting code. To get around this problem, cell manifest supports a plugin system that lets you more easily add on extra functionality in separate compartmentalized classes.

A plugin is like an extra delegate object that can receive all of the manifest's many delegate callbacks in addition to the actual delegate object. In these callbacks it can do any additional work that it would like to do to support its feature. For example, you could write a logging plugin that writes out to the console whenever records are modified. Or you could write a plugin that detects when cells have been scrolled fully on screen for more than a second (eg for logging ad impressions). Any code which you may have put in your base subclass of UI[Table/Collection]ViewController is a good candidate for a plugin.

Plugins can be set when the manifest is initialized, or added/removed later. In this way, features that are only needed by certain screens can be added when needed. Plugins also gives you the ability easily write generic code that will work on both table views or collection views, as the manifest methods are largely the same for both.


Contributors
============

FSQCellManifest was initially developed by Foursquare Labs for internal use. It was originally written and is currently maintained by Brian Dorfman ([@bdorfman](https://twitter.com/bdorfman)).
