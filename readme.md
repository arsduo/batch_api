[![Build Status](https://travis-ci.org/arsduo/batch_api.svg?branch=master)](http://travis-ci.org/arsduo/batch_api)

## What's this?

A gem that provides a RESTful Batch API for Rails and other Rack applications.
In this system, batch requests are simply collections of regular REST calls,
whose results are returned as an equivalent collection of regular REST results.

This is heavily inspired by [Facebook's Batch API](https://developers.facebook.com/docs/graph-api/making-multiple-requests).

## A Quick Example

Making a batch request:

```
# POST /batch
# Content-Type: application/json

{
  ops: [
    {method: "get",    url: "/patrons"},
    {method: "post",   url: "/orders/new",  params: {dish_id: 123}},
    {method: "get",    url: "/oh/no/error", headers: {break: "fast"}},
    {method: "delete", url: "/patrons/456"}
  ],
  sequential: true
}
```

Reading the response:

```
{
  results: [
    {status: 200, body: [{id: 1, name: "Jim-Bob"}, ...], headers: {}},
    {status: 201, body: {id: 4, dish_name: "Spicy Crab Legs"}, headers: {}},
    {status: 500, body: {error: {oh: "noes!"}}, headers: {Problem: "woops"}},
    {status: 200, body: null, headers: {}}}
  ]
}
```

### How It Works

#### Requests

As you can see from the example above, each request in the batch (an
"operation", in batch parlance) describes the same features any HTTP request
would include:

* _url_ - the API endpoint to hit, formatted exactly as you would for a regular
REST API request, leading / and all. (required)
* _method_ - what type of request to make -- GET, POST, PUT, etc.  If no method
is supplied, GET is assumed. (optional)
* _args_ - a hash of arguments to the API. This can be used for both GET and
PUT/POST/PATCH requests. (optional)
* _headers_ - a hash of request-specific headers. The headers sent in the
request will be included as well, with operation-specific headers taking
precendence. (optional)
* _silent_ - whether to return a response for this request. You can save on
transfer if, for instance, you're making several PUT/POST requests, then
executing a GET at the end.

These individual operations are supplied as the "ops" parameter in the
overall request.  Other options include:

* _sequential_ - execute all operations sequentially, rather than in parallel.
*This parameter is currently REQUIRED and must be set to true.* (In the future
the Batch API will offer parallel processing for thread-safe apps, and hence
this parameter must be supplied in order to explicitly preserve expected
behavior.)

Other options may be provided in the future for both the global request
and individual operations.

### Responses

The Batch API will always return a 200, with a JSON body containing the
individual responses under the "results" key.  Those responses, in turn,
contain the same main components of any HTTP response:

* _status_ - the HTTP status (200, 201, 400, etc.)
* _body_ - the rendered body
* _headers_ - any response headers

### Errors

Errors in individual Batch API requests will be returned inline, with the
same status code and body they would return as individual requests.

If the Batch API itself returns a non-200 status code, that indicates a global
problem.

## Installation

Setting up the Batch API is simple.  Just add the gem to your middlewares:

```ruby
# in application.rb
config.middleware.use BatchApi::RackMiddleware do |batch_config|
  # you can set various configuration options:
  batch_config.verb = :put # default :post
  batch_config.endpoint = "/batchapi" # default /batch
  batch_config.limit = 100 # how many operations max per request, default 50

  # default middleware stack run for each batch request
  batch_config.batch_middleware = Proc.new { }
  # default middleware stack run for each individual operation
  batch_config.operation_middleware = Proc.new { }
end
```

That's it!  Just fire up your curl, hit your endpoint with the right verb and a properly formatted request, and enjoy some batch API action.

## Why a Batch API?

Batch APIs, though unRESTful, are useful for reducing HTTP overhead
by combining requests; this is particularly valuable for mobile clients,
which may generate groups of offline actions and which desire to
reduce battery consumption while connected by making fewer, better-compressed
requests.

### Why not HTTP Pipelining?

HTTP pipelining is an awesome and promising technology, and would provide a
simple and effortless way to parallel process many requests; however, using
pipelining raised several issues for us, one of which was a blocker:

* [Lack of browser
support](http://en.wikipedia.org/wiki/HTTP_pipelining#Implementation_in_web_browsers):
a number of key browsers do not yet support HTTP pipelining (or have it
disabled by default).  This will of course change in time,
but for now this takes pipelining out of consideration.  (There a similar but
more minor issue
with [many web
proxies](http://en.wikipedia.org/wiki/HTTP_pipelining#Implementation_in_web_proxies).)
* The HTTP pipelining specification states that non-idempotent requests (e.g.
[POST](http://en.wikipedia.org/wiki/HTTP_pipelining) and
[in some
descriptions](http://www-archive.mozilla.org/projects/netlib/http/pipelining-faq.html) PUT)
shouldn't be made via pipelining.  Though I have heard that some server
implementations do support POST requests (putting all subsequent requests on
hold until it's done), for applications that submit a lot of POSTs this raised
concerns as well.

Given this state of affairs -- and my desire to hack up a Batch API gem :P --,
we decided to implement an API-based solution.

### Why this Approach?

There are two main approaches to writing batch APIs:

* A limited, specialized batch endpoint (or endpoints), which usually handles
  updates and creates.  DHH sketched out such a bulk update/create endpoint
  for Rails 3.2 [in a gist](https://gist.github.com/981520) last year.
* A general-purpose RESTful API that can handle anything in your application,
  a la the Facebook Batch API.

The second approach, IMO, minimizes code duplication and complexity. Rather
than have two systems that manage resources (or a more complicated one that
can handle both batch and individual requests), we simply route requests as we
always would.

This solution has several specific benefits:

* Less complexity - non-batch endpoints don't need any extra code, which means
  less to maintain on your end.
* Complete flexibility - as you add new features to your application,
  they become immediately and automatically available via the Batch API.
* More RESTful - as individual operations are simply actions on RESTful
  resources, you preserve an important characteristic of your API.

As well as the general benefits of all batch operations:

* Reuse of state - user authentication, request stack processing, and
  similar processing only needs to be done once.
* Better for clients - clients need to make fewer requests, as described above.
* Parallelizable - in the future, we could run requests in parallel (if
  our app is thread-safe).  Clients would be able to explicitly specify
  dependencies between operations (or simply run all sequentially).  This
  should make for some fun experimentation :)

There's only one downside I can think of to this approach as opposed to a
specialized endpoint:

* Reduced ability to optimize - unlike a specialized API endpoint, each request
  will be treated in isolation, which makes it harder to optimize the
  underlying database queries via more efficient (read: complicated) SQL logic.
  (Better identity maps would help with this, and since the main pain point
  this approach addresses is at the HTTP connection layer, I submit we can
  accept this.)

## Implementation

The Batch API is implemented as a Rack middleware.  Here's how it works:

First, if the request isn't a batch request (as defined by the endpoint and
method in BatchApi.config), it gets processed normally by your app.

If it is a batch request, we:
* Read and validate the parameters for the request, constructing a
  representation of the operation.
* Compile a customized Rack environment hash with the appropriate parameters,
  so that your app interprets the request as being for the appropriate action.
  (This is requires a bit of extra processing for Rails.)
* Send each request up the middleware stack as normal, collecting the results.
  Errors are caught and recorded appropriately.
* Send you back the results.

At both the batch level (processing all requests) and the individual operation
request, there is an internal, customizable midleware stack that you can
customize to insert additional custom behavior, such as handling authentication
or decoding JSON bodies for individual requests (this latter comes
pre-included).  Check out the lib/batch_api/internal_middleware.rb for more
information.

## To Do

The core of the Batch API is complete and solid, and so ready to go that it's
in use at 6Wunderkinder already :P

Here are some immediate tasks:

* Test against additional frameworks (beyond Rails and Sinatra)
* Write more usage docs / create a wiki.
* Add additional features inspired by the Facebook API, such as the ability to
  surpress output for individual requests, etc.
* Add RDoc to the spec task and ensure all methods are documented.
* Research and implement parallelization and dependency management.

## Thanks

To 6Wunderkinder, for all their support for this open-source project, and their
general awesomeness.

To Facebook, for providing inspiration and a great implementation in this and
many other things.

To [JT Archie](http://github.com/jtarchie) for his help and feedback.

## Issues? Questions? Ideas?

Open a ticket or send a pull request!
