require 'batch_api/operation'

module BatchApi
  class BatchController < ::ApplicationController
    def batch
      render :json => BatchApi::Processor.new(params[:ops], request.env, params).execute!
    end
  end
end
