# DZNetworking
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Xcode CI](https://github.com/DZNS/DZNetworking/workflows/Xcode%20CI/badge.svg?branch=master) 
<img src="https://camo.githubusercontent.com/81fef85a8b1266b3890108413ab62ee96d8d39c9/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f6c2f496e7374616772616d4b69742e7376673f7374796c653d666c6174" /> 
<img src="https://camo.githubusercontent.com/c748fef80a903c7b5237f215139f9791c2d6cf8e/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f702f496e7374616772616d4b69742e7376673f7374796c653d666c6174" />

NSURLSession based networking using PromiseKit.

DZNetworking exposes simple APIs that make networking with REST APIs simple. The API is straight-forward, well tested and extensible. DZNetworking utilizes PromiseKit to provide a promises based API and OMGHTTPURLRQ for creating `NSURLRequests`. Thus, DZNetworking should be treated as a simple wrapper around NSURLSession for PromiseKit.

Here's a quick example of a `GET` request, right from the test suite:  
````obj-c
[_session GET:@"/posts/1" parameters:nil]
.thenInBackground(^(DZResponse *responded) {
    
    // ... handle the response
        
})
.catch(^(NSError *error) {
	// ... any errors thrown during the process of creating the request, 
	// networking or parsing the response will invoke this block.
});
````
--

### Chaining

As you will see, Promises vastly reduce the possibility of introducting Spaghetti code in your source files. You can chain requests as follows:  

````obj-c

[_session GET:@"/resource"]
.thenInBackground(^(DZResponse *responded) {
	
	return [_session POST:@"/resource/new"]
	
})
.thenInBackground(^(DZResponse *responded) {
	
	return [_session PATCH:@"/resource/200"]
	
})
.thenInBackground(^(DZResponse *responded) {
	
	// ... handle the response of the previous PATCH request.
	
})
.catch(^(NSError *error) {
	// ... any errors thrown during the process of creating the request, 
	// networking or parsing the response will invoke this block.
});

````

Chaining is not limited to networking requests and methods provided by DZNetworking. Any method that returns a `AnyPromise` is ready to be chained. 

### Installing

The recomended method to install DZNetworking is via Carthage.

Add the following to your Cartfile
````
github "dzns/DZNetworking" 
````

Don't forget to run `carthage update` and then following the [instructions here][2] to add DZNetworking under the frameworks path.

### Instantiating

DZURLSession makes it really easy to get started. Here's a sample:

````obj-c
self.session = [[DZURLSession alloc] init];
self.session.baseURL = [NSURL URLWithString:@"http://api.myapp.com/"];
self.session.responseParser = [DZJSONResponseParser new];
```` 
--
The `DZJSONResponseParser` is a subclass of `DZResponseParser` which handles parsing JSON responses. You can implement your own response parsers (example: XML, YAML, etc.) by subclassing `DZResponseParser` and implementing the following two compulsory methods:

````obj-c
- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError **)error;
- (NSSet *)contentTypes;
````

You must then assign that response parser to the DZURLSession before making network requests. 

--
  
The `DZURLSession` class has been configured to automatically use the `DZActivityIndicatorManager`. You can turn this off by setting NO on the `useActivityManager` property.
  
--

The `DZURLSession` class also comes with `requestModifier` block. This is useful when you need to modify all or most requests in a similar fashion before they are sent over the wire. A good use-case would be appending oAuth headers/query parameters to requests. This leaves your networking methods in your subclass clean and easibly debuggable. 

--

### Documentation

We've tried our best to document most headers properly. If you believe you require clarifcation on something, please open an issue, appropriately tagged, and we'll try to either:
- include documentation, if missing.
- improve documentation, if incorrect.
- try to answer the issue in the thread, if already correctly documented.

--

You can also generate HTML documentation using `AppleDocs`.

- First, [install appledocs][1] if you haven't already.
- Run the gendocs command file in terminal. 

When running `gendocs`, it'll automatically open the generated documentation in the default browser. If this behaviour is undesirable, you can pass the `-n` or `--no-open` flag to prevent that.

--

### Autocompletion
The `.thenInBackground()` method is from PromiseKit. PromiseKit allows resolving with Tuples which is what DZNetworking uses. However, typing the success syntax: `.thenInBackground(^(DZResponse *responded) {})` can quickly become tiresome. To aide you, we've also included two autocomplete snippets, one for the success and the other for the error block. You can find them in the `Autocomplete Snippets` folder.   

To install, simply copy them over to the `~/Library/Developer/Xcode/UserData/CodeSnippets/` folder. If the `CodeSnippets` folder does not exist, simply create it.

The success handle can be triggered by the `thenOnSuccess` shortcut and the error handler by the `catchError` shortcut.

--

### Supported HTTP Methods

- HEAD
- OPTIONS
- GET
- POST
- PUT
- PATCH
- DELETE

--
### ToDo

- ~~File Uploads~~
- Multi-part POST
- ~~Authentication challenge handling~~

--
### Pull Requests & Issues
If you'd like to contribute, please open a Pull Request. If you have any issues, please open an Issue. Don't forget to tag it appropriately, and be nice to others.

--

### LICENSE
DZNetworking is licensed under the MIT License. Complete information can be found in the License file.

[1]: https://github.com/tomaz/appledoc#quick-install
[2]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application
