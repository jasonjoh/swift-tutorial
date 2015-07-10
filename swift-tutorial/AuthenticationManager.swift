//
//  AuthenticationManager.swift
//  swift-tutorial
//
//  Created by Jason Johnston on 7/8/15.
//  Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
//

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

// MIT License: 
 
// Permission is hereby granted, free of charge, to any person obtaining 
// a copy of this software and associated documentation files (the 
// ""Software""), to deal in the Software without restriction, including 
// without limitation the rights to use, copy, modify, merge, publish, 
// distribute, sublicense, and/or sell copies of the Software, and to 
// permit persons to whom the Software is furnished to do so, subject to 
// the following conditions: 
 
// The above copyright notice and this permission notice shall be 
// included in all copies or substantial portions of the Software. 
 
// THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, 
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.