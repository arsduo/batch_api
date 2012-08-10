class EndpointsController < ApplicationController
  def get
    cookies["GET"] = "bye"
    response.headers["GET"] = "hi"
    render :json => {result: "GET OK", headers: header_output, params: params}, status: 422
  end

  def post
    cookies["POST"] = "goodbye"
    response.headers["POST"] = "hello"
    render :json => {result: "POST OK", headers: header_output, params: params}, status: 203
  end

  private

  def header_output
    # we only want the headers that were sent by the client
    # request.headers has a ton of additional information we don't want
    # and that reference the request itself, causing an infinite loop
    request.headers.inject({}) do |h, k, v|
      h.tap {|hash| hash[k.to_s] = v.to_s if k =~ /HTTP_/}
    end
  end
end
