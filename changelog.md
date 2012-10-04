v0.1.4
* Refactor errors into ErrorWrapper/BatchError
* Allow specification of custom status codes raised for errors

v0.1.3
* Refactor config to use a struct
* Update readme to cover HTTP pipelining

v0.1.2
* Rewrite the readme
* Add travis icon

v0.1.1
* Fix dumb error

v0.1.0
* Add direct support for Rails for path params
* Fix spec bugs

v0.0.8
* Return the results wrapped in a hash, rather than a raw array
* Add process_start timestamp option

v0.0.7
* Return more specific error codes to alert clients to param errors

v0.0.6
* Refactor Rack middleware to be Sinatra-compatible

v0.0.5
* Add setting to decode JSON responses before sending batch results

v0.0.4
* Switch from Rails-based process to a Rack middleware
* Improve tests

v0.0.3
* Encapsulate processing into a Processor module
* Prepare for parallel processing in the future
* Add specific errors
* Allow controlling the routing target

v0.0.2
* Add config module
* Add options for operation limit, endpoint, and verb

v0.0.1
* Initial build
