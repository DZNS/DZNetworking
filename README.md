# DZNetworking v3

`URLSession` based networking supporting Swift Concurrency and completion block handler style APIs.

DZNetworking exposes simple APIs that make constructing networking models with REST APIs easy. 

The API is straight-forward, well tested and extensible. DZNetworking should be treated as a simple wrapper around `URLSession`.

### Supports 
- `URLSession` data, download and upload tasks
- Uploads to S3 buckets
- OAuth2 session handler 

### Instantiating

DZURLSession makes it really easy to get started. Here's a sample:

```swift
let session = DZURLSession()
session.baseURL = URL(string:"http://api.myapp.com/")!

let (data, _) = try await session.GET("/posts", query: ["userID": "1"]) 
``` 

--
The `DZJSONResponseParser` implements the `DZResponseParser` protocol which handles parsing JSON responses. You can implement your own response parsers (example: XML, YAML, etc.) by conforming your parser to `DZResponseParser`.

You must then assign that response parser to the DZURLSession before making network requests.

```swift
let session = DZURLSession()
session.responseParser = DZJSONResponseParser()
``` 

--

The `DZURLSession` class also comes with `requestModifier` block. This is useful when you need to modify all or most requests in a similar fashion before they are sent over the wire. A good use-case would be appending oAuth headers/query parameters to requests. This leaves your networking methods in your subclass clean and easily debuggable. 

--

### Documentation

I've tried my best to document most methods properly. All documentation is in the `DocC` format in the source files. 

If you believe you require clarifcation on something, please open an issue, appropriately tagged, and I'll try to either:
- include documentation, if missing.
- improve documentation, if incorrect.
- try to answer the issue in the thread, if already correctly documented.

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

### Pull Requests & Issues

If you'd like to contribute, please open a Pull Request. If you are encountering bugs, please open an Issue. Don't forget to tag it appropriately, and be nice to others.

If you see an opportunity to improve the tests suite, your additions will be much appreciated.

--

### LICENSE

DZNetworking is licensed under the MIT License. Complete information can be found in the License file.
