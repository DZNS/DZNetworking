# DZNetworking
--
<img src="https://api.travis-ci.org/DZNS/DZNetworking.svg" /> 
<img src="https://camo.githubusercontent.com/81fef85a8b1266b3890108413ab62ee96d8d39c9/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f6c2f496e7374616772616d4b69742e7376673f7374796c653d666c6174" /> 
<img src="https://camo.githubusercontent.com/c748fef80a903c7b5237f215139f9791c2d6cf8e/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f702f496e7374616772616d4b69742e7376673f7374796c653d666c6174" />

NSURLSession based networking for REST APIs using PromiseKit.

DZNetworking exposes simple APIs that make networking with REST APIs simple. The API is straight-forward, well tested and extensible. DZNetworking utilizes PromiseKit to provide a promises based API and OMGHTTPURLRQ for creating `NSURLRequests`. Thus, DZNetworking should be treated as a simple wrapper around NSURLSession for PromiseKit.

Here's a quick example of a `GET` request, right from the test suite:  
````obj-c
[_session GET:@"/posts/1" parameters:nil]
.thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
    
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
.thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
	
	return [_session POST:@"/resource/new"]
	
})
.thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
	
	return [_session PATCH:@"/resource/200"]
	
})
.thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
	
	// ... handle the response of the previous PATCH request.
	
})
.catch(^(NSError *error) {
	// ... any errors thrown during the process of creating the request, 
	// networking or parsing the response will invoke this block.
});

````

Chaining is not limited to networking requests and methods provided by DZNetworking. Any method that returns a `AnyPromise` is ready to be chained. 

--
### Autocompletion
The `.thenInBackground()` method is from PromiseKit. PromiseKit allows resolving with Tuples which is what DZNetworking uses. However, typing the success syntax: `.thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {})` can quickly become tiresome. To aide you, we've also included two autocomplete snippets, one for the success and the other for the error block. You can find them in the `Autocomplete Snippets` folder.   

To install, simply copy them over to the `~/Library/Developer/Xcode/UserData/CodeSnippets/` folder.  

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

- File Uploads
- Multi-part POST
- Authentication challenge handling (possibly as a Promise, to enable chaining)

--
### Pull Requests & Issues
If you'd like to contribute, please open a Pull Request. If you have any issues, please open an Issue. Don't forget to tag it appropriately, and be nice to others.

--

### LICENSE
DZNetworking is licensed under the MIT License. Complete information can be found in the License file.
