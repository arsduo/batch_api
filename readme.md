A proposal for a Batch API endpoint.

Batch requests take the form of a series of REST API requests,
each containing the following arguments:

* _url_ - the API endpoint to hit, formatted exactly as you would for a regular
REST API request (e.g. leading /, etc.)
* _method_ - what type of request to make -- GET, POST, PUT, etc.
* _args_ - a hash of arguments to the API. This can be used for both GET and
PUT/POST/PATCH requests.
* _headers_ - a hash of request-specific headers. (The headers sent in the
request will be included as well, with request-specific headers taking
precendence.)
* _options_ - a hash of additional batch request options. There are currently
none supported, but we plan to introduce some for dependency management,
supressing output, etc. in the future.

The Batch API endpoint itself (which lives at POST /batch) takes the
following arguments:

* _ops_ - an array of operations to perform, specified as described above.
* _sequential_ - execute all operations sequentially, rather than in parallel.
*THIS PARAMETER IS CURRENTLY REQUIRED AND MUST BE SET TO TRUE.* (In the future
we'll offer parallel processing by default, and hence this parameter must be
supplied in order topreserve expected behavior.

Other options may be defined in the future.

Users must be logged in to use the Batch API.

The Batch API returns an array of results in the same order the operations are
specified. Each result contains:

* _status_ - the HTTP status (200, 201, 400, etc.)
* _body_ - the rendered body
* _headers_ - any response headers
* _cookies_ - any cookies set by the request. (These will in the future be
pulled into the main response to be processed by the client.)

Errors in individual Batch API requests will be returned inline, with the
same status code and body they would return as individual requests. If the
Batch API itself returns a non-200 status code, that indicates a global
problem:

* _403_ - if the user isn't logged in
* _422_ - if the batch request isn't properly formatted
* _500_ - if there's an application error in the Batch API code

** Examples **

Given the following request:

```ruby
{
  ops: [
         {
            method: "post",
            url: "/resource/create",
            args: {title: "bar", data: "foo"}
          },
          {
            method: "get",
            url: "/other_resource/123/connections"
          },
          {
            method: "get",
            url: "/i/gonna/throw/an/error",
            header: { some: "headers" }
          }
       ]
}
```

You'd get the following back:

```ruby
  [
    {status: 201, body: "{json:\"data\"}", headers: {}, cookies: {}},
    {status: 200, body: "[{json:\"data\"}, {more:\"data\"}]", headers: {}, cookies: {}},
    {status: 500, body: "{error:\"message\"}", headers: {}, cookies: {}},
  ]
```

** Implementation**

For each request, we:
* attempt to route it as Rails would (identifying controller and action)
* create a customized request.env hash with the appropriate details
* instantiate the controller and invoke the action
* parse and process the result

The overall result is then returned to the client.

**Background**

Batch APIs, though unRESTful, are useful for reducing HTTP overhead
by combining requests; this is particularly valuable for mobile clients,
which may generate groups of offline actions and which desire to
reduce battery consumption while connected by making fewer, better-compressed
requests.

Generally, such interfaces fall into two categories:

* a set of limited, specialized instructions, usually to manage resources
* a general-purpose API that can take any operation the main API can
handle

The second approach minimizes code duplication and complexity. Rather than
have two systems that manage resources (or a more complicated one that can
handle both batch and individual requests), we simply route requests as we
always would.

This approach has several benefits:

* Less complexity - non-batch endpoints don't need any extra code
* Complete flexibility - as we add new features or endpoints to the API,
they become immediately available via the Batch API.
* More RESTful - as individual operations are simply actions on RESTful
resources, we preserve an important characteristic of the API.

As well as general benefits of using the Batch API:

* Parallelizable - in the future, we could run requests in parallel (if
our Rails app is running in thread-safe mode), allowing clients to
specify explicit dependencies between operations (or run all
sequentially).
* Reuse of state - user authentication, request stack processing, and
similar processing only needs to be done once.
* Better for clients - fewer requests, better compressibility, etc.
(as described above)

There are two main downsides to our implementation:

* Rails dependency - we use only public Rails interfaces, but these could
still change with major updates. (_Resolution:_ with good testing we
can identify changes and update code as needed.)
* Reduced ability to optimize cross-request - unlike a specialized API,
each request will be treated in isolation, and so you couldn't minimize
DB updates through more complicated SQL logic. (_Resolution:_ none, but
the main pain point currently is at the HTTP connection layer, so we
accept this.)

Once the Batch API is more developed, we'll spin it off into a gem, and
possibly make it easy to create versions for Sinatra or other frameworks,
if desired.