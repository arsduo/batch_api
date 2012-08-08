require 'batch_api/operation'

module BatchApi
  class BatchController < ::ApplicationController
    def batch
      ops = params[:ops].map {|o| BatchApi::Operation.new(o, request.env)}
      render :json => ops.map(&:execute)
    end
  end
end
