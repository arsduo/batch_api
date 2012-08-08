# Add our route
Rails.application.routes.draw do
  match BatchAPI::Config.endpoint => "batch#batch", via: BatchAPI::Config.verb
end
