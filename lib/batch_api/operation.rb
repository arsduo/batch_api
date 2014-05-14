require 'batch_api/operation/rack'
require 'batch_api/operation/rails' if defined?(Rails)
require 'batch_api/operation/grape' if defined?(Grape)
