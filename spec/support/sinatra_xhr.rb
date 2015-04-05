module SinatraXhr
  # add xhr method to specs for the Sinatra app
  # modeled on Rails
  # see
  def xhr(request_method, action, parameters = nil, session = nil, flash = nil)
    @request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
    @request.env['HTTP_ACCEPT'] ||=  [Mime::JS, Mime::HTML, Mime::XML, 'text/xml', Mime::ALL].join(', ')
    __send__(request_method, action, parameters, session, flash).tap do
      @request.env.delete 'HTTP_X_REQUESTED_WITH'
      @request.env.delete 'HTTP_ACCEPT'
    end
  end
end
