require 'sinatra/base'
require 'rack/contrib'

class SinatraApp < Sinatra::Base
  use Rack::PostBodyContentTypeParser
  use BatchApi::Middleware

  get "/endpoint" do
    headers["GET"] = "hello"
    # including this in the body would mess the body up
    # due to the other headers inserted
    headers["REQUEST_HEADERS"] = header_output
    content_type :json

    status 422
    {
      result: "GET OK",
      params: params.except(:endpoint)
    }.to_json
  end

  post "/endpoint" do
    headers["POST"] = "guten tag"
    headers["REQUEST_HEADERS"] = header_output
    content_type :json
    status 203
    {
      result: "POST OK",
      params: params.except(:endpoint)
    }.to_json
  end

  get "/endpoint/error" do
    raise StandardError
  end

  private

  def header_output
    # we only want the headers that were sent by the client
    # request.headers has a ton of additional information we don't want
    # and that reference the request itself, causing an infinite loop
    headers.inject({}) do |h, (k, v)|
      h.tap {|hash| hash[k.to_s] = v.to_s}
    end
  end
end

