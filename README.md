# Getting Started with the Outlook Mail API and Swift #

The purpose of this guide is to walk through the process of creating a simple Swift app that retrieves messages in Office 365. The source code in this repository is what you should end up with if you follow the steps outlined here.

## Before you begin ##

This guide assumes:

- That you already have Xcode installed and working on your development machine, along with [CocoaPods](https://cocoapods.org).
- That you have an Office 365 tenant, with access to an account in that tenant.

## Create the app ##

Let's dive right in! Open Xcode, and on the **File** menu, choose **New** then **Project**. In the left-hand pane, choose **Application** under **iOS**, then choose **Single View Application**. Click **Next**.

IMAGE HERE

Enter `swift-tutorial` for **Product Name**, `Swift` for **Language**, and `Universal` for **Devices**, then click **Next**.

IMAGE HERE

Choose a location for the project and click **Create**. Once Xcode finishes creating the project, close Xcode.

Next, use CocoaPods to install dependencies. For this tutorial, we will need the following:

- [Microsoft Azure Active Directory Authentication Library (ADAL) for iOS and OSX](https://github.com/AzureAD/azure-activedirectory-library-for-objc)
- [Office 365 SDKs for iOS](https://github.com/OfficeDev/Office-365-SDK-for-iOS)

Open Terminal and change the directory to the location of your `swift-tutorial` project. Run the following command to initialize a Podfile for the project.

	pod init
	
Next, open the Podfile using the following command.

	open Podfile
	
Add the following lines between the `target 'swift-tutorial' do` and `end` lines:

	pod 'ADALiOS', '~> 1.2'
	pod 'Office365', '~> 0.10'
	
Close the Podfile, then run the following command to install the dependencies.

	pod install
	
Once that command finishes, open the newly created swift-tutorial.xcworkspace file in Xcode.

Finally, add a bridging header to enable use of the dependencies from Swift code. In the Project navigator, expand **swift-tutorial**->**swift-tutorial**, then select **Supporting Files**. CTRL + Click **Supporting Files** and select **New File**. Select **Header file** as the template and click **Next**. Enter `bridging` in the **Save As** field and click **Create**.

Open the **bridging.h** file and add the following lines 

	#import <ADALiOS/ADAL.h>
	#import <orc/orc.h>
	#import <outlook_services/outlook_services.h>
	
Select the **swift-tutorial** project in the Project navigator, then select the **Build Settings** tab. In the **Swift Compiler - Code Generation** section, set the value of the **Objective-C Bridging Header** setting to `bridging.h`.

IMAGE HERE

## Designing the app ##

The app itself will be fairly simple. Since it's a single-page app, we'll keep it to a minimum. 

In the Project navigator, expand **swift-tutorial**->**swift-tutorial**, then select **Main.storyboard**. In the document outline, expand **View Controller Scene**, then select **View Controller**.

IMAGE HERE

On the **Editor** menu, choose **Embed In**, then **Navigation Controller**. A new item named **Navigation Item** should appear in the document outline underneath **View Controller**. Select this item, then double-click the highlighted navigation bar and enter the text `Swift Tutorial`.

In the **Object Library** (bottom-right corner), find **Button**. Drag **Button** onto the visual representation of the view. Double-click the button and set the text to `Log In`.

IMAGE HERE

Now select **ViewController.swift** in the Project navigator. Add a new property to the `ViewController` class, right before the `viewDidLoad` function:

	@IBOutlet var logInButton : UIButton!
	
Then add a new method to the class:

	@IBAction func logInButtonTapped(sender : AnyObject) {
        NSLog("Hello World")
    }
	
In **Main.storyboard**, select **View Controller** in the document outline. Select the **Connections inspector** tab on the right-hand side.

IMAGE HERE
	
Under **Outlets**, you should see the `loginButton` property we added to the view controller earlier. Drag the small circle next to this property onto the button on the view.

Under **Received Actions**, you should see the `logInButtonTapped` method we added to the view controller earlier. Drag the small circle next to this method onto the button on the view. In the pop up menu that appears, select **Touch Up Inside**. The **Connections inspector** section should look like this once you are done.

IMAGE HERE
	
In **Main.storyboard**, select **View** in the document outline. On the **Editor** menu, select **Resolve Auto Layout Issues**, then **Add Missing Constraints**.

At this point the app should build and run. Tapping the **Log in** button should call the `loginButtonTapped` method (which at this point does nothing).

## Implementing OAuth2 ##

Our goal in this section is to make the **Log in** button use OAuth2 to obtain an access token that we can use with the Mail API. We'll start by registering the app to obtain a client ID.

Go to https://dev.outlook.com/appregistration. Sign in with your Office 365 account and register your app with the following details.

- App Name: swift-tutorial
- App Type: Native app
- Redirect URI: http://localhost/swift-tutorial
- APIs to access: Read mail

IMAGE HERE

Click **Register App** and copy the client ID that is generated.

Next we'll create a class to handle our authentication.

CTRL + Click the **swift-tutorial** folder in Project navigator and select **New File**. Select **Swift file** as the template and click **Next**. Enter `AuthenticationManager` in the **Save As** field and click **Create**.

Open the **AuthenticationManager.swift** file and replace its contents with the following.

### Contents of the `Authentication.swift` file ###

	import Foundation
	
	class AuthenticationManager {
	    // This value must match the value used when registering the app
	    let redirectURL = NSURL(string: "http://localhost/swift-tutorial")
	    // The Azure OAuth2 authority
	    let authority = "https://login.microsoftonline.com/common"
	    // The resource identifier for the Outlook APIs
	    let outlookResource = "https://outlook.office365.com"
	    // The client ID obtained by registering the app
	    let clientId = "YOUR CLIENT ID HERE"
	    // ADAL dependency resolver, used to enable logon UI
	    var dependencyResolver = ADALDependencyResolver()
	    
	    // Create a singleton instance of the AuthenticationManager
	    // class. The app uses this instance for all operations.
	    class var sharedInstance: AuthenticationManager {
	        struct Singleton {
	            static let instance = AuthenticationManager()
	        }
	        return Singleton.instance
	    }
	    
	    // Asynchronous function to retrieve a token. This will load the
	    // token from the cache (if present), otherwise it will use 
	    // ADAL to prompt the user to sign into Azure.
	    func getToken(completionHandler:((Bool, String) -> Void)) {
	        var err: ADAuthenticationError?
	        var authContext: ADAuthenticationContext = ADAuthenticationContext(authority: authority,
	            error: &err)
	        
	        // Acquire the token. This will prompt the user to login if there is not
	        // a valid token already in the app's cache.
	        authContext.acquireTokenWithResource(outlookResource, clientId: clientId, redirectUri: redirectURL) {
	            (result: ADAuthenticationResult!) -> Void in
	            
	            if result.status.value != AD_SUCCEEDED.value {
	                // Failed, return error description
	                completionHandler(false, result.error.description)
	            }
	            else {
	                // Succeeded, return the acess token
	                var token = result.accessToken
	                // Initialize the dependency resolver with the logged on context.
	                // The dependency resolver is passed to the Outlook library.
	                self.dependencyResolver = ADALDependencyResolver(context: authContext, resourceId: self.outlookResource, clientId: self.clientId, redirectUri: self.redirectURL)
	                completionHandler(true, token)
	            }
	        }
	    }
	    
	    // Logout function to clear the app's cache and remove the user's information.
	    func logout() {
	        var error: ADAuthenticationError?
	        var cache: ADTokenCacheStoring = ADAuthenticationSettings.sharedInstance().defaultTokenCacheStore
	        
	        // Clear the token cache
	        var allItemsArray = cache.allItemsWithError(&error)
	        if (!allItemsArray.isEmpty) {
	            cache.removeAllWithError(&error)
	        }
	        
	        // Remove all the cookies from this application's sandbox. The authorization code is stored in the
	        // cookies and ADAL will try to get to access tokens based on auth code in the cookie.
	        var cookieStore = NSHTTPCookieStorage.sharedHTTPCookieStorage()
	        if let cookies = cookieStore.cookies {
	            for cookie in cookies {
	                cookieStore.deleteCookie(cookie as! NSHTTPCookie)
	            }
	        }
	    }
	}
	
Replace the value of `clientId` with the client ID you generated earlier.

Switch back to **ViewController.swift**. Add another property to the `ViewController` class (just below the definition for `loginButton`:

	var loggedIn: Bool = false
	
Now let's add code to the empty `logInButtonTapped` function.

    @IBAction func logInButtonTapped(sender : AnyObject) {
        var authMgr = AuthenticationManager.sharedInstance
        
        if (loggedIn){
            // Logout and change the button to read "Log in"
            authMgr.logout()
            self.logInButton.setTitle("Log in", forState: UIControlState.Normal)
            self.loggedIn = false
        }
        else {
            // Attempt to get a token
            authMgr.getToken() {
                (authenticated: Bool, token: String) -> Void in
                
                if (authenticated) {
                    // Change the button to read "Log out"
                    NSLog("Authentication successful, token: %@", token)
                    self.logInButton.setTitle("Log out", forState: UIControlState.Normal)
                    self.loggedIn = true
                }
                else {
                    NSLog("Authentication failed: %@", token)
                }
            }
        }
    }
	
Run the app. Once the app loads in the iOS Simulator, tap the **Log in** button to login. After logging in, you should see a token printed to the output window, and the button should now say **Log out**.

IMAGE HERE

Copy the entire value of the token and head over to http://jwt.calebb.net/. If you paste that value in, you should see a JSON representation of an access token. For details and alternative parsers, see [Validating your Office 365 Access Token](https://github.com/jasonjoh/office365-azure-guides/blob/master/ValidatingYourToken.md).

Once you're convinced that the token is what it should be, let's move on to using the Mail API.

## Using the Mail API ##

Switch back to **ViewController.swift** and add a new function `getMessages`.

### `getMessages` function in `ViewController.swift` ###

    func getMessages(dependencyResolver: ADALDependencyResolver) {
        var apiEndpoint = "https://outlook.office365.com/api/v1.0"
        var client = MSOutlookClient(url: apiEndpoint, dependencyResolver: dependencyResolver)
		
        // Select at most 10 messages (.top(10))
        // Return only the subject, date/time received, and from fields (.select())
        // Sort by date/time received, newest first (.orderBy())
        client.me.messages.top(10).select("Subject,DateTimeReceived,From").orderBy("DateTimeReceived DESC").readWithCallback({
            (messages: [AnyObject]!, error: MSOrcError!) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                for msg in messages {
                    var olMsg: MSOutlookMessage = msg as! MSOutlookMessage
                    NSLog(olMsg.Subject)
                }
            })
        })
    }
	
Update the `loginButtonTapped` function to call `getMessages` after a successful login.

### Updated `loginButtonTapped` function in `ViewController.swift` ###

    @IBAction func logInButtonTapped(sender : AnyObject) {
        var authMgr = AuthenticationManager.sharedInstance
        
        if (loggedIn){
            // Logout and change the button to read "Log in"
            authMgr.logout()
            self.logInButton.setTitle("Log in", forState: UIControlState.Normal)
            self.loggedIn = false
        }
        else {
            // Attempt to get a token
            authMgr.getToken() {
                (authenticated: Bool, token: String) -> Void in
                
                if (authenticated) {
                    // Change the button to read "Log out"
                    NSLog("Authentication successful, token: %@", token)
                    self.logInButton.setTitle("Log out", forState: UIControlState.Normal)
                    self.loggedIn = true
					
                    // Get messages
                    // Pass in the ADALDependencyResolve from the AuthenticationManager
                    self.getMessages(authMgr.dependencyResolver)
                    
                }
                else {
                    NSLog("Authentication failed: %@", token)
                }
            }
        }
    }
	
Restart the app. After you tap the **Log in** button, you should see a list of message subjects appear in the output window.

IMAGE HERE

## Displaying the results ##

Let's add a table view to our app to display the list of messages. First, add two new properties to the `ViewController` class in **ViewController.swift**.

	@IBOutlet var msgTable: UITableView!
	var messages = NSArray()
	
`msgTable` is the table view, and `messages` will hold the list of messages retrieved via the Mail API.

Add the following line to the `viewDidLoad` function:

	self.msgTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

Next we need to add a couple of protocols to the `ViewController` class to allow it to interact with and update the table view. Change the following line:

	class ViewController: UIViewController {
	
To this:

	class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
Now add the following functions to the `ViewController` class to implement the new protocols.

	// Called when loading data to see how many rows to render
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of messages
        return self.messages.count
    }
    
	// Called to render each row in the table
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.msgTable.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        
        // Get the message from the array and cast to a MSOutlookMessage object
        var outlookMessage : MSOutlookMessage = self.messages.objectAtIndex(indexPath.row) as! MSOutlookMessage
        
        // Format the received date/time
        var formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        var received = formatter.stringFromDate(outlookMessage.DateTimeReceived)
        
        // Setting to 0 should allow the line to wrap to multiple lines
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = String(format: "%@ From: %@ - %@", received, outlookMessage.From.EmailAddress.Name, outlookMessage.Subject)
        
        return cell
    }
    
	// Empty function
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
	
Update the `getMessages` function to save the returned messages into the `messages` class property and call `reloadData` on the table view.

### Updated `getMessages` function in **ViewController.swift** ##

    func getMessages(dependencyResolver: ADALDependencyResolver) {
        var apiEndpoint = "https://outlook.office365.com/api/v1.0"
        var client = MSOutlookClient(url: apiEndpoint, dependencyResolver: dependencyResolver)
        
        // Select at most 10 messages (.top(10))
        // Return only the subject, date/time received, and from fields (.select())
        // Sort by date/time received, newest first (.orderBy())
        client.me.messages.top(10).select("Subject,DateTimeReceived,From").orderBy("DateTimeReceived DESC").readWithCallback({
            (messages: [AnyObject]!, error: MSOrcError!) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                for msg in messages {
                    var olMsg: MSOutlookMessage = msg as! MSOutlookMessage
                    NSLog(olMsg.Subject)
                }
                
                // Save the results and refresh the table view
                self.messages = messages
                self.msgTable.reloadData()
            })
        })
    }
	
Switch to **Main.storyboard**. In the Object library, locate **Table View**. Drag **Table View** onto the main view controller.

IMAGE HERE

Select the main view controller in the document outline. Select the **Connections inspector** tab on the right-hand side. Under **Outlets**, you should see `msgTable`. Drag the small circle next to it onto the table view you added to the main view controller. Repeat for `dataSource` and `delegate` under **Referencing Outlets**. When done, your **Connections inspector** should look like the following.

IMAGE HERE
	
Re-run the app. After tapping the **Log in** button and logging in, you should see a table of messages.

IMAGE HERE