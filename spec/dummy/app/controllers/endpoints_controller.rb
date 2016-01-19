class EndpointsController < ApplicationController
  def get
    cookies["GET"] = "bye"
    response.headers["GET"] = "hello"
    # including this in the body would mess the body up
    # due to the other headers inserted
    response.headers["REQUEST_HEADERS"] = header_output
    render :json => {result: "GET OK", params: params.delete(:endpoint)}, status: 422
  end

  def capture
   render json: {result: params[:captured]}
  end

  def process_end_point
    render json: {result: params[:endpoint]}
  end

  def post
    cookies["POST"] = "tschussikowski"
    response.headers["POST"] = "guten tag"
    response.headers["REQUEST_HEADERS"] = header_output
    render :json => {result: "POST OK", params: params.delete(:endpoint)}, status: 203
  end

  def error
    raise StandardError
  end

  private

  def header_output
    # we only want the headers that were sent by the client
    # request.headers has a ton of additional information we don't want
    # and that reference the request itself, causing an infinite loop
    request.headers.inject({}) do |h, (k, v)|
      h.tap {|hash| hash[k.to_s] = v.to_s if k =~ /HTTP_/}
    end
  end
end
